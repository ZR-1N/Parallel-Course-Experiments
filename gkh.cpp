#include "gkh.h"

#include "givens.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <vector>
#include <atomic>
#include <pthread.h>

#ifdef _OPENMP
#include <omp.h>
#endif

namespace
{
#ifndef SVD_PARALLEL_MODE
#define SVD_PARALLEL_MODE 0
#endif

#ifndef SVD_NUM_THREADS
#define SVD_NUM_THREADS 8
#endif
static int get_svd_num_threads()
{
    int nthreads = SVD_NUM_THREADS;
    if (nthreads < 1)
    {
        nthreads = 1;
    }
    if (nthreads > 8)
    {
        nthreads = 8;
    }
    return nthreads;
}

#ifndef SVD_MIN_PARALLEL_TASKS
#define SVD_MIN_PARALLEL_TASKS 2
#endif

#ifndef SVD_PARALLEL_CLEANUP
#define SVD_PARALLEL_CLEANUP 1
#endif

#ifndef SVD_CLEANUP_MIN_ELEMENTS
#define SVD_CLEANUP_MIN_ELEMENTS 4096
#endif

// SVD_PARALLEL_MODE:
// 0 = serial block processing
// 1 = OpenMP static block processing
// 2 = OpenMP dynamic block processing, chunk size = 1
// 3 = OpenMP guided block processing, chunk size = 1
// 4 = Pthread dynamic block processing with atomic task index
// 5 = Pthread static block processing with fixed task assignment

    // 活动块 [l, r]（闭区间）表示一个尚未完全收敛的上二对角子问题。
    // 在该区间内，超对角线元素非零，你可以认为通过这个抽象结构给矩阵“分块”。
    using Block = GKHBlock;
    
    static double now_ms()
    {
        using clock = std::chrono::steady_clock;
        return std::chrono::duration<double, std::milli>(
                   clock::now().time_since_epoch())
            .count();
    }

    struct GKHProfile
    {
        double cleanup_ms = 0.0;
        double zero_ms = 0.0;
        double split_ms = 0.0;
        double block_ms = 0.0;
        double final_ms = 0.0;
        double total_ms = 0.0;

        long long iter_count = 0;
        long long total_blocks = 0;
        long long total_nontrivial_blocks = 0;
        long long total_block_size = 0;
        int max_block_size_seen = 0;
    };

    static bool profile_enabled()
    {
#ifndef SVD_LAB3_PROFILE
        return true;
#else
        return SVD_LAB3_PROFILE != 0;
#endif
    }
    static bool block_csv_enabled()
{
#ifndef SVD_LAB3_EMIT_BLOCK_CSV
    return false;
#else
    return SVD_LAB3_EMIT_BLOCK_CSV != 0;
#endif
}


    // 对矩阵 M 的两行 r0, r1 左乘 Givens 旋转 [c s; -s c]。
    // 即 M <- L * M，其中 L 只作用在第 r0/r1 两行上。
    // 这类逐元素线性组合很适合向量化，SIMD/多线程中你也可以顺手的事把他们做了。
    static void apply_left_rows(Matrix &M, int r0, int r1, double c, double s)
{
    int n = M.cols();
    double* row0 = &M.at(r0, 0);
    double* row1 = &M.at(r1, 0);

    int j = 0;
    // 手动展开4次
    for (; j + 3 < n; j += 4)
    {
        double a0 = row0[j], b0 = row1[j];
        double a1 = row0[j + 1], b1 = row1[j + 1];
        double a2 = row0[j + 2], b2 = row1[j + 2];
        double a3 = row0[j + 3], b3 = row1[j + 3];

        row0[j]     = c * a0 + s * b0; row1[j]     = -s * a0 + c * b0;
        row0[j + 1] = c * a1 + s * b1; row1[j + 1] = -s * a1 + c * b1;
        row0[j + 2] = c * a2 + s * b2; row1[j + 2] = -s * a2 + c * b2;
        row0[j + 3] = c * a3 + s * b3; row1[j + 3] = -s * a3 + c * b3;
    }

    // 处理尾部
    for (; j < n; ++j)
    {
        double a = row0[j];
        double b = row1[j];
        row0[j] = c * a + s * b;
        row1[j] = -s * a + c * b;
    }
}
    // 只在指定列区间 [col_l, col_r] 内对两行做左乘 Givens 旋转。
    // 该函数主要用于并行 one_block_step 中对 B 的局部更新，避免不同 block 写入彼此区域。
    static void apply_left_rows_range(Matrix &M, int r0, int r1, double c, double s,
                                      int col_l, int col_r)
    {
        col_l = std::max(col_l, 0);
        col_r = std::min(col_r, M.cols() - 1);

        if (col_l > col_r)
        {
            return;
        }

        double *row0 = &M.at(r0, col_l);
        double *row1 = &M.at(r1, col_l);
        const int n = col_r - col_l + 1;

        int j = 0;
        for (; j + 3 < n; j += 4)
        {
            double a0 = row0[j], b0 = row1[j];
            double a1 = row0[j + 1], b1 = row1[j + 1];
            double a2 = row0[j + 2], b2 = row1[j + 2];
            double a3 = row0[j + 3], b3 = row1[j + 3];

            row0[j]     = c * a0 + s * b0;
            row1[j]     = -s * a0 + c * b0;

            row0[j + 1] = c * a1 + s * b1;
            row1[j + 1] = -s * a1 + c * b1;

            row0[j + 2] = c * a2 + s * b2;
            row1[j + 2] = -s * a2 + c * b2;

            row0[j + 3] = c * a3 + s * b3;
            row1[j + 3] = -s * a3 + c * b3;
        }

        for (; j < n; ++j)
        {
            double a = row0[j];
            double b = row1[j];
            row0[j] = c * a + s * b;
            row1[j] = -s * a + c * b;
        }
    }

    // 对矩阵 M 的两列 c0, c1 右乘 Givens 旋转 [c s; -s c]。
    // 即 M <- M * R，其中 R 只作用在第 c0/c1 两列上。
    static void apply_right_cols(Matrix &M, int c0, int c1, double c, double s)
    {
        for (int i = 0; i < M.rows(); ++i)
        {
            double a = M.at(i, c0);
            double b = M.at(i, c1);
            M.at(i, c0) = a * c - b * s;
            M.at(i, c1) = a * s + b * c;
        }
    }
        // 只在指定行区间 [row_l, row_r] 内对两列做右乘 Givens 旋转。
    // 该函数主要用于并行 one_block_step 中对 B 的局部更新，避免不同 block 写入彼此区域。
    static void apply_right_cols_range(Matrix &M, int c0, int c1, double c, double s,
                                       int row_l, int row_r)
    {
        row_l = std::max(row_l, 0);
        row_r = std::min(row_r, M.rows() - 1);

        if (row_l > row_r)
        {
            return;
        }

        for (int i = row_l; i <= row_r; ++i)
        {
            double a = M.at(i, c0);
            double b = M.at(i, c1);
            M.at(i, c0) = a * c - b * s;
            M.at(i, c1) = a * s + b * c;
        }
    }

    static void accumulate_left_into_U(Matrix &U, int r0, int r1, double c, double s)
    {
        // 我们该怎样积累 U 和 V 的更新呢？
        // 以此处 U 的积累为例，让我们B <- L * B 时，我们必须维护的等式是 A = U * B * V^T
        // 如果 A = U * B * V^T 不成立，那么我们最终的SVD结果显然不是 A 的正确分解。
        // 由于正交矩阵和其转置的乘积是I，一个自然的想法是让 U <- U * L^T。
        // 这样就变成 A = (U * L^T) * (L * B) * V^T = U * B * V^T，等式得以保持。

        // 由于 L^T = [c -s; s c]，此处复用“右乘两列”接口并传入 -s。
        apply_right_cols(U, r0, r1, c, -s);
    }

    // 计算活动块 [l, r] 对应 B^T B 右下 2x2 主子块的 Wilkinson 偏移。
    // 偏移用于加速 QR 迭代收敛，并让 bulge chasing 过程更稳定。
    static double block_wilkinson_shift(const Matrix &B, int l, int r)
    {
        if (r == l)
        {
            return B.at(l, l) * B.at(l, l);
        }

        const double d1 = B.at(r - 1, r - 1);
        const double e1 = B.at(r - 1, r);
        const double d2 = B.at(r, r);
        const double e0 = (r - 1 > l) ? B.at(r - 2, r - 1) : 0.0;

        const double a = d1 * d1 + e0 * e0;
        const double b = d1 * e1;
        const double d = d2 * d2 + e1 * e1;

        const double tr = a + d;
        const double det = a * d - b * b;
        double disc = 0.25 * tr * tr - det;
        if (disc < 0.0)
        {
            disc = 0.0;
        }

        const double root = std::sqrt(disc);
        const double lam1 = 0.5 * tr + root;
        const double lam2 = 0.5 * tr - root;
        return (std::fabs(lam1 - d) <= std::fabs(lam2 - d)) ? lam1 : lam2;
    }

    // 将上二对角结构以外、且绝对值很小的元素强制置零。
    static void cleanup_bidiagonal(Matrix &B, double tol)
    {
        for (int i = 0; i < B.rows(); ++i)
        {
            for (int j = 0; j < B.cols(); ++j)
            {
                if (j != i && j != i + 1 && std::fabs(B.at(i, j)) <= tol)
                {
                    B.at(i, j) = 0.0;
                }
            }
        }
    }
    static void cleanup_bidiagonal_parallel_openmp(Matrix &B, double tol)
{
    const int rows = B.rows();
    const int cols = B.cols();
    const int total = rows * cols;

#ifndef _OPENMP
    cleanup_bidiagonal(B, tol);
    return;
#else
    // 小矩阵直接串行，避免每轮调用 OpenMP runtime 带来的固定开销。
    if (total < SVD_CLEANUP_MIN_ELEMENTS)
    {
        cleanup_bidiagonal(B, tol);
        return;
    }

    omp_set_num_threads(get_svd_num_threads());

#pragma omp parallel for schedule(static)
    for (int i = 0; i < rows; ++i)
    {
        for (int j = 0; j < cols; ++j)
        {
            if (j != i && j != i + 1 && std::fabs(B.at(i, j)) <= tol)
            {
                B.at(i, j) = 0.0;
            }
        }
    }
#endif
}

    static void cleanup_bidiagonal_auto(Matrix &B, double tol)
    {
#if SVD_PARALLEL_CLEANUP
        cleanup_bidiagonal_parallel_openmp(B, tol);
#else
        cleanup_bidiagonal(B, tol);
#endif
    }

    // 对活动块 [l, r] 执行一次“单块 GKH bulge chasing”迭代。
    // 流程：首次右乘引入 bulge -> 首次左乘消 bulge -> 交替右乘/左乘将 bulge 追赶到块末端。
    static void one_block_step(Matrix &U, Matrix &B, Matrix &V, int l, int r)
    {
        if (r <= l)
        {
            return;
        }

        const double mu = block_wilkinson_shift(B, l, r);

        double c = 1.0;
        double s = 0.0;
        double rr = 0.0;

        // 首次右乘：由 (d_l^2-mu, d_l*e_l) 构造。
        const double x = B.at(l, l) * B.at(l, l) - mu;
        const double z = B.at(l, l) * B.at(l, l + 1);
        givens_rotation(x, z, c, s, rr, false);
        apply_right_cols_range(B, l, l + 1, c, s, l, r);
        apply_right_cols(V, l, l + 1, c, s);

        // 首次左乘：消去 (l+1, l)。
        givens_rotation(B.at(l, l), B.at(l + 1, l), c, s, rr, true);
        apply_left_rows_range(B, l, l + 1, c, s, l, r);
        accumulate_left_into_U(U, l, l + 1, c, s);
        for (int k = l + 1; k <= r - 1; ++k)
        {
            // 右乘：消去 (k-1, k+1)
            givens_rotation(B.at(k - 1, k), B.at(k - 1, k + 1), c, s, rr, false);
            apply_right_cols_range(B, k, k + 1, c, s, l, r);
            apply_right_cols(V, k, k + 1, c, s);

            // 左乘：消去 (k+1, k)
            givens_rotation(B.at(k, k), B.at(k + 1, k), c, s, rr, true);
            apply_left_rows_range(B, k, k + 1, c, s, l, r);
            accumulate_left_into_U(U, k, k + 1, c, s);
        }
    }
    struct PthreadBlockContext
    {
        Matrix *U = nullptr;
        Matrix *B = nullptr;
        Matrix *V = nullptr;
        const std::vector<Block> *tasks = nullptr;
        std::atomic<int> next_task;
    };

    static void *pthread_block_worker(void *arg)
    {
        PthreadBlockContext *ctx = static_cast<PthreadBlockContext *>(arg);
        const int task_count = static_cast<int>(ctx->tasks->size());

        while (true)
        {
            const int task_id = ctx->next_task.fetch_add(1, std::memory_order_relaxed);
            if (task_id >= task_count)
            {
                break;
            }

            const Block &blk = (*(ctx->tasks))[task_id];
            gkh_one_block_step(*(ctx->U), *(ctx->B), *(ctx->V), blk.l, blk.r);
        }

        return nullptr;
    }

    static void run_block_steps_pthread_dynamic(Matrix &U, Matrix &B, Matrix &V,
                                                const std::vector<Block> &tasks)
    {
        const int task_count = static_cast<int>(tasks.size());
        if (task_count <= 0)
        {
            return;
        }

        int thread_count = get_svd_num_threads();
        if (thread_count < 1)
        {
            thread_count = 1;
        }
        thread_count = std::min(thread_count, task_count);

        if (thread_count <= 1)
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
            return;
        }

        PthreadBlockContext ctx;
        ctx.U = &U;
        ctx.B = &B;
        ctx.V = &V;
        ctx.tasks = &tasks;
        ctx.next_task.store(0, std::memory_order_relaxed);

        std::vector<pthread_t> workers(thread_count - 1);

        for (int i = 0; i < thread_count - 1; ++i)
        {
            pthread_create(&workers[i], nullptr, pthread_block_worker, &ctx);
        }

        // 主线程也作为 worker 参与任务计算，避免只创建线程后空等。
        pthread_block_worker(&ctx);

        for (int i = 0; i < thread_count - 1; ++i)
        {
            pthread_join(workers[i], nullptr);
        }
    }
        struct PthreadStaticWorkerArg
    {
        Matrix *U = nullptr;
        Matrix *B = nullptr;
        Matrix *V = nullptr;
        const std::vector<Block> *tasks = nullptr;
        int thread_id = 0;
        int thread_count = 1;
    };

    static void *pthread_block_worker_static(void *arg)
    {
        PthreadStaticWorkerArg *worker = static_cast<PthreadStaticWorkerArg *>(arg);
        const int task_count = static_cast<int>(worker->tasks->size());

        // 静态轮转分配：thread 0 处理 0, T, 2T...
        // thread 1 处理 1, T+1, 2T+1...
        for (int task_id = worker->thread_id; task_id < task_count; task_id += worker->thread_count)
        {
            const Block &blk = (*(worker->tasks))[task_id];
            gkh_one_block_step(*(worker->U), *(worker->B), *(worker->V), blk.l, blk.r);
        }

        return nullptr;
    }

    static void run_block_steps_pthread_static(Matrix &U, Matrix &B, Matrix &V,
                                               const std::vector<Block> &tasks)
    {
        const int task_count = static_cast<int>(tasks.size());
        if (task_count <= 0)
        {
            return;
        }

        int thread_count = get_svd_num_threads();
        if (thread_count < 1)
        {
            thread_count = 1;
        }
        thread_count = std::min(thread_count, task_count);

        if (thread_count <= 1)
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
            return;
        }

        std::vector<pthread_t> workers(thread_count - 1);
        std::vector<PthreadStaticWorkerArg> args(thread_count);

        for (int tid = 0; tid < thread_count; ++tid)
        {
            args[tid].U = &U;
            args[tid].B = &B;
            args[tid].V = &V;
            args[tid].tasks = &tasks;
            args[tid].thread_id = tid;
            args[tid].thread_count = thread_count;
        }

        for (int tid = 1; tid < thread_count; ++tid)
        {
            pthread_create(&workers[tid - 1], nullptr, pthread_block_worker_static, &args[tid]);
        }

        // 主线程负责 tid=0 的任务。
        pthread_block_worker_static(&args[0]);

        for (int tid = 1; tid < thread_count; ++tid)
        {
            pthread_join(workers[tid - 1], nullptr);
        }
    }

    // 处理“对角元 d_k 近零但超对角 e_k 未近零”的情况。
    // 思路与单块追赶类似：先右乘把 e_i 消掉，再左乘清理新引入的次对角 bulge，
    // 把这个问题逐步向右传递，直到块末端。
    static bool chase_zero_diagonal(Matrix &U, Matrix &B, Matrix &V, int k, double tol)
    {
        const int m = B.rows();
        const int n = B.cols();
        if (k < 0 || k >= n - 1)
        {
            return false;
        }

        // d_k ~ 0 且 e_k 还未收敛时，按 lim_1 思路进行压缩追赶：
        // 1) 右乘消去第 k 行的 e_k；2) 左乘消去引入的次对角 bulge；
        // 然后把问题传递到下一行，直到末端。
        if (std::fabs(B.at(k, k + 1)) <= tol)
        {
            return false;
        }

        bool changed = false;
        for (int i = k; i <= n - 2; ++i)
        {
            double c = 1.0;
            double s = 0.0;
            double rr = 0.0;

            // 右乘：使第 i 行满足 [d_i, e_i] * G = [r, 0]。
            givens_rotation(B.at(i, i), B.at(i, i + 1), c, s, rr, false);
            apply_right_cols(B, i, i + 1, c, s);
            apply_right_cols(V, i, i + 1, c, s);

            // 左乘：消去 (i+1, i) 处由右乘引入的 bulge。
            if (i + 1 < m)
            {
                givens_rotation(B.at(i, i), B.at(i + 1, i), c, s, rr, true);
                apply_left_rows(B, i, i + 1, c, s);
                accumulate_left_into_U(U, i, i + 1, c, s);
            }

            changed = true;
        }

        cleanup_bidiagonal(B, tol);
        return changed;
    }

    // 扫描所有 d_k≈0 的位置：若对应 e_k 仍显著非零，则调用追赶过程压缩该异常结构。
    // 返回值表示本轮是否对 B/U/V 做了实际更新。
    static bool handle_diagonal_zeros(Matrix &U, Matrix &B, Matrix &V, double tol)
    {
        const int n = B.cols();
        bool changed = false;

        const double eps = std::numeric_limits<double>::epsilon();
        const double diag_tol = tol;
        const double super_tol = tol * (1.0 + 10.0 * eps);

        for (int k = 0; k < n - 1; ++k)
        {
            if (std::fabs(B.at(k, k)) <= diag_tol && std::fabs(B.at(k, k + 1)) > super_tol)
            {
                if (chase_zero_diagonal(U, B, V, k, tol))
                {
                    changed = true;
                }
            }
        }

        return changed;
    }

    // 根据超对角线是否“足够小”对问题进行分块。
    // 若 |e_k| <= tol*(|d_k|+|d_{k+1}|+1)，认为该位置可解耦并直接置零。
    // 最终会得到一系列小矩阵。
    static std::vector<Block> split_active_blocks(Matrix &B, int n, double tol)
    {
        for (int k = 0; k < n - 1; ++k)
        {
            const double a = std::fabs(B.at(k, k));
            const double d = std::fabs(B.at(k + 1, k + 1));
            const double crit = tol * (a + d + 1.0);
            if (std::fabs(B.at(k, k + 1)) <= crit)
            {
                B.at(k, k + 1) = 0.0;
            }
        }

        std::vector<Block> blocks;
        int l = 0;
        while (l < n)
        {
            int r = l;
            while (r < n - 1 && std::fabs(B.at(r, r + 1)) > 0.0)
            {
                ++r;
            }
            blocks.push_back({l, r});
            l = r + 1;
        }
        return blocks;
    }

    // 收尾步骤：
    // 1) 把奇异值（对角元）统一调整为非负；
    // 2) 按降序重排奇异值，同时同步重排 U、V 对应列。
    // 最终得到常见的 SVD 规范形式：sigma_1 >= sigma_2 >= ... >= 0。
    // 这个函数你不用太在意，后续任务也不会明确涉及它。
    static void make_nonnegative_and_sort(Matrix &U, Matrix &B, Matrix &V)
    {
        const int m = B.rows();
        const int n = B.cols();

        for (int i = 0; i < n; ++i)
        {
            if (B.at(i, i) < 0.0)
            {
                B.at(i, i) = -B.at(i, i);
                for (int r = 0; r < m; ++r)
                {
                    U.at(r, i) = -U.at(r, i);
                }
            }
        }

        std::vector<int> idx(n);
        for (int i = 0; i < n; ++i)
        {
            idx[i] = i;
        }
        std::sort(idx.begin(), idx.end(), [&](int a, int b)
                  { return B.at(a, a) > B.at(b, b); });

        Matrix U2 = U;
        Matrix V2 = V;
        Matrix D(B.rows(), B.cols(), 0.0);

        for (int new_i = 0; new_i < n; ++new_i)
        {
            const int old_i = idx[new_i];
            D.at(new_i, new_i) = B.at(old_i, old_i);

            for (int r = 0; r < U.rows(); ++r)
            {
                U2.at(r, new_i) = U.at(r, old_i);
            }
            for (int r = 0; r < V.rows(); ++r)
            {
                V2.at(r, new_i) = V.at(r, old_i);
            }
        }

        U = U2;
        V = V2;
        B = D;
    }

} // namespace

void gkh_cleanup_bidiagonal_auto(Matrix &B, double tol)
{
    cleanup_bidiagonal_auto(B, tol);
}

bool gkh_handle_diagonal_zeros(Matrix &U, Matrix &B, Matrix &V, double tol)
{
    return handle_diagonal_zeros(U, B, V, tol);
}

std::vector<GKHBlock> gkh_split_active_blocks(Matrix &B, int n, double tol)
{
    return split_active_blocks(B, n, tol);
}

void gkh_one_block_step(Matrix &U, Matrix &B, Matrix &V, int l, int r)
{
    one_block_step(U, B, V, l, r);
}

void gkh_finalize_result(Matrix &U, Matrix &B, Matrix &V, double tol)
{
    gkh_cleanup_bidiagonal_auto(B, tol);
    for (int i = 0; i < B.cols() - 1; ++i)
    {
        B.at(i, i + 1) = 0.0;
    }
    make_nonnegative_and_sort(U, B, V);
}

// 从“上二对角矩阵 B”出发执行 Golub-Kahan SVD 迭代（改进版）：
// - 输入输出满足 A = U * B * V^T 不变；
// - 迭代中自动分块、处理对角近零、并在每个活动块上做 bulge chasing；
// - 成功收敛后，B 被整理为非负且降序的对角矩阵（其对角元即奇异值）。
bool gkh_svd_from_bidiagonal(Matrix &U, Matrix &B, Matrix &V, int max_iter, double tol)
{
    const int m = B.rows();
    const int n = B.cols();

    if (m < n)
    {
        throw std::invalid_argument("gkh_svd_from_bidiagonal_v2: requires m >= n");
    }
    if (U.rows() != m || U.cols() != m)
    {
        throw std::invalid_argument("gkh_svd_from_bidiagonal_v2: U must be m x m");
    }
    if (V.rows() != n || V.cols() != n)
    {
        throw std::invalid_argument("gkh_svd_from_bidiagonal_v2: V must be n x n");
    }

    GKHProfile profile;
    const double total_t0 = now_ms();

    const bool emit_block_csv_to_stderr = block_csv_enabled() && (m >= 1000 && n >= 1000);

    if (emit_block_csv_to_stderr)
    {
        std::cerr << "[lab3_block_csv] "
                  << "m,n,iter,num_blocks,nontrivial_blocks,min_block_size,max_block_size,avg_block_size"
                  << std::endl;
    }

    bool converged = false;

    for (int iter = 0; iter < max_iter; ++iter)
    {
        profile.iter_count++;

        double t0 = now_ms();
        gkh_cleanup_bidiagonal_auto(B, tol);
        profile.cleanup_ms += now_ms() - t0;

        t0 = now_ms();
        gkh_handle_diagonal_zeros(U, B, V, tol);
        profile.zero_ms += now_ms() - t0;

        t0 = now_ms();
        std::vector<GKHBlock> blocks = gkh_split_active_blocks(B, n, tol);
        profile.split_ms += now_ms() - t0;

        int nontrivial_blocks = 0;
        int min_block_size = n > 0 ? n : 0;
        int max_block_size = 0;
        long long block_size_sum = 0;

        bool all_singletons = true;
        for (const auto &blk : blocks)
        {
            const int block_size = blk.r - blk.l + 1;
            min_block_size = std::min(min_block_size, block_size);
            max_block_size = std::max(max_block_size, block_size);
            block_size_sum += block_size;

            if (blk.r > blk.l)
            {
                all_singletons = false;
                nontrivial_blocks++;
            }
        }

        profile.total_blocks += static_cast<long long>(blocks.size());
        profile.total_nontrivial_blocks += nontrivial_blocks;
        profile.total_block_size += block_size_sum;
        profile.max_block_size_seen = std::max(profile.max_block_size_seen, max_block_size);

        if (emit_block_csv_to_stderr)
        {
            const double avg_block_size =
                blocks.empty() ? 0.0 : static_cast<double>(block_size_sum) / static_cast<double>(blocks.size());

            std::cerr << "[lab3_block_csv] "
                      << m << ","
                      << n << ","
                      << iter << ","
                      << blocks.size() << ","
                      << nontrivial_blocks << ","
                      << min_block_size << ","
                      << max_block_size << ","
                      << std::setprecision(10) << avg_block_size << std::endl;
        }

        if (all_singletons)
        {
            converged = true;
            break;
        }

        std::vector<Block> tasks;
        tasks.reserve(blocks.size());

        for (int i = static_cast<int>(blocks.size()) - 1; i >= 0; --i)
        {
            if (blocks[i].r > blocks[i].l)
            {
                tasks.push_back(blocks[i]);
            }
        }

#ifdef _OPENMP
        if (SVD_PARALLEL_MODE >= 1 && SVD_PARALLEL_MODE <= 3)
        {
            omp_set_num_threads(get_svd_num_threads());
        }
#endif

        const int task_count = static_cast<int>(tasks.size());
        const bool use_parallel_blocks = task_count >= SVD_MIN_PARALLEL_TASKS;

        t0 = now_ms();

#if SVD_PARALLEL_MODE == 1
        if (use_parallel_blocks)
        {
#pragma omp parallel for schedule(static)
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
        else
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
#elif SVD_PARALLEL_MODE == 2
        if (use_parallel_blocks)
        {
#pragma omp parallel for schedule(dynamic, 1)
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
        else
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
#elif SVD_PARALLEL_MODE == 3
        if (use_parallel_blocks)
        {
#pragma omp parallel for schedule(guided, 1)
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
        else
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
#elif SVD_PARALLEL_MODE == 4
        if (use_parallel_blocks)
        {
            run_block_steps_pthread_dynamic(U, B, V, tasks);
        }
        else
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
#elif SVD_PARALLEL_MODE == 5
        if (use_parallel_blocks)
        {
            run_block_steps_pthread_static(U, B, V, tasks);
        }
        else
        {
            for (int task_id = 0; task_id < task_count; ++task_id)
            {
                gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
            }
        }
#else
        for (int task_id = 0; task_id < task_count; ++task_id)
        {
            gkh_one_block_step(U, B, V, tasks[task_id].l, tasks[task_id].r);
        }
#endif

        profile.block_ms += now_ms() - t0;
    }

    double t0 = now_ms();
    gkh_cleanup_bidiagonal_auto(B, tol);
    for (int i = 0; i < n - 1; ++i)
    {
        B.at(i, i + 1) = 0.0;
    }
    make_nonnegative_and_sort(U, B, V);
    profile.final_ms += now_ms() - t0;

    profile.total_ms = now_ms() - total_t0;

    if (profile_enabled())
    {
        std::cerr << std::fixed << std::setprecision(3)
                  << "[lab3_gkh_profile] "
                  << "m=" << m << " "
                  << "n=" << n << " "
                  << "converged=" << (converged ? "yes" : "no") << " "
                  << "iters=" << profile.iter_count << " "
                  << "cleanup_ms=" << profile.cleanup_ms << " "
                  << "zero_ms=" << profile.zero_ms << " "
                  << "split_ms=" << profile.split_ms << " "
                  << "block_ms=" << profile.block_ms << " "
                  << "final_ms=" << profile.final_ms << " "
                  << "total_ms=" << profile.total_ms << " "
                  << "total_blocks=" << profile.total_blocks << " "
                  << "nontrivial_blocks=" << profile.total_nontrivial_blocks << " "
                  << "max_block_size=" << profile.max_block_size_seen << " "
                  << "parallel_mode=" << SVD_PARALLEL_MODE << " "
                  << "num_threads=" << get_svd_num_threads() << " "
                  << "min_parallel_tasks=" << SVD_MIN_PARALLEL_TASKS << " "
                  << "parallel_cleanup=" << SVD_PARALLEL_CLEANUP << " "
                  << "avg_nontrivial_blocks_per_iter="
                  << (profile.iter_count == 0 ? 0.0
                                              : static_cast<double>(profile.total_nontrivial_blocks) /
                                                    static_cast<double>(profile.iter_count))
                  << std::endl;
    }

    return converged;
}