#include "gkh_mpi.h"
#include "gkh.h"
#include "mpi_protocol.h"

#include <mpi.h>

#include <algorithm>
#include <iostream>
#include <vector>

namespace
{
    static void pack_task_data(const Matrix &U, const Matrix &B, const Matrix &V,
                               const GKHBlock &blk,
                               std::vector<double> &u_buf,
                               std::vector<double> &b_buf,
                               std::vector<double> &v_buf)
    {
        const int m = U.rows();
        const int n = V.rows();
        const int bs = blk.r - blk.l + 1;

        u_buf.assign(static_cast<size_t>(m) * bs, 0.0);
        b_buf.assign(static_cast<size_t>(bs) * bs, 0.0);
        v_buf.assign(static_cast<size_t>(n) * bs, 0.0);

        // U(:, l:r)
        for (int i = 0; i < m; ++i)
        {
            for (int j = 0; j < bs; ++j)
            {
                u_buf[static_cast<size_t>(i) * bs + j] = U.at(i, blk.l + j);
            }
        }

        // B(l:r, l:r)
        for (int i = 0; i < bs; ++i)
        {
            for (int j = 0; j < bs; ++j)
            {
                b_buf[static_cast<size_t>(i) * bs + j] = B.at(blk.l + i, blk.l + j);
            }
        }

        // V(:, l:r)
        for (int i = 0; i < n; ++i)
        {
            for (int j = 0; j < bs; ++j)
            {
                v_buf[static_cast<size_t>(i) * bs + j] = V.at(i, blk.l + j);
            }
        }
    }

    static void unpack_task_result(Matrix &U, Matrix &B, Matrix &V,
                                   const GKHBlock &blk,
                                   const std::vector<double> &u_buf,
                                   const std::vector<double> &b_buf,
                                   const std::vector<double> &v_buf)
    {
        const int m = U.rows();
        const int n = V.rows();
        const int bs = blk.r - blk.l + 1;

        // 写回 U(:, l:r)
        for (int i = 0; i < m; ++i)
        {
            for (int j = 0; j < bs; ++j)
            {
                U.at(i, blk.l + j) = u_buf[static_cast<size_t>(i) * bs + j];
            }
        }

        // 写回 B(l:r, l:r)
        for (int i = 0; i < bs; ++i)
        {
            for (int j = 0; j < bs; ++j)
            {
                B.at(blk.l + i, blk.l + j) = b_buf[static_cast<size_t>(i) * bs + j];
            }
        }

        // 写回 V(:, l:r)
        for (int i = 0; i < n; ++i)
        {
            for (int j = 0; j < bs; ++j)
            {
                V.at(i, blk.l + j) = v_buf[static_cast<size_t>(i) * bs + j];
            }
        }
    }

    static void send_task_to_worker(int worker_rank,
                                    const Matrix &U, const Matrix &B, const Matrix &V,
                                    const GKHBlock &blk)
    {
        MPITaskHeader hdr;
        hdr.l = blk.l;
        hdr.r = blk.r;

        std::vector<double> u_buf, b_buf, v_buf;
        pack_task_data(U, B, V, blk, u_buf, b_buf, v_buf);

        MPI_Send(&hdr, sizeof(hdr), MPI_BYTE, worker_rank, MPI_TAG_TASK, MPI_COMM_WORLD);
        MPI_Send(u_buf.data(), static_cast<int>(u_buf.size()), MPI_DOUBLE, worker_rank, MPI_TAG_TASK, MPI_COMM_WORLD);
        MPI_Send(b_buf.data(), static_cast<int>(b_buf.size()), MPI_DOUBLE, worker_rank, MPI_TAG_TASK, MPI_COMM_WORLD);
        MPI_Send(v_buf.data(), static_cast<int>(v_buf.size()), MPI_DOUBLE, worker_rank, MPI_TAG_TASK, MPI_COMM_WORLD);
    }

    static void send_stop_to_worker(int worker_rank)
    {
        MPITaskHeader hdr;
        hdr.l = -1;
        hdr.r = -1;
        MPI_Send(&hdr, sizeof(hdr), MPI_BYTE, worker_rank, MPI_TAG_STOP, MPI_COMM_WORLD);
    }

    static void worker_loop_step_only(int m, int n,
                                      double *worker_compute_ms_sum,
                                      long long *tasks_done_sum)
    {
        while (true)
        {
            MPITaskHeader hdr{};
            MPI_Status st{};
            MPI_Recv(&hdr, sizeof(hdr), MPI_BYTE, 0, MPI_ANY_TAG, MPI_COMM_WORLD, &st);

            if (st.MPI_TAG == MPI_TAG_STOP)
            {
                break;
            }

            const int l = hdr.l;
            const int r = hdr.r;
            const int bs = r - l + 1;

            std::vector<double> u_buf(static_cast<size_t>(m) * bs);
            std::vector<double> b_buf(static_cast<size_t>(bs) * bs);
            std::vector<double> v_buf(static_cast<size_t>(n) * bs);

            MPI_Recv(u_buf.data(), static_cast<int>(u_buf.size()), MPI_DOUBLE, 0, MPI_TAG_TASK, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Recv(b_buf.data(), static_cast<int>(b_buf.size()), MPI_DOUBLE, 0, MPI_TAG_TASK, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Recv(v_buf.data(), static_cast<int>(v_buf.size()), MPI_DOUBLE, 0, MPI_TAG_TASK, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            Matrix U_sub(m, bs, 0.0);
            Matrix B_sub(bs, bs, 0.0);
            Matrix V_sub(n, bs, 0.0);

            for (int i = 0; i < m; ++i)
            {
                for (int j = 0; j < bs; ++j)
                {
                    U_sub.at(i, j) = u_buf[static_cast<size_t>(i) * bs + j];
                }
            }
            for (int i = 0; i < bs; ++i)
            {
                for (int j = 0; j < bs; ++j)
                {
                    B_sub.at(i, j) = b_buf[static_cast<size_t>(i) * bs + j];
                }
            }
            for (int i = 0; i < n; ++i)
            {
                for (int j = 0; j < bs; ++j)
                {
                    V_sub.at(i, j) = v_buf[static_cast<size_t>(i) * bs + j];
                }
            }

            const double t0 = MPI_Wtime();
            gkh_one_block_step(U_sub, B_sub, V_sub, 0, bs - 1);
            const double t1 = MPI_Wtime();
            const double compute_ms = (t1 - t0) * 1000.0;

            if (worker_compute_ms_sum != nullptr)
            {
                *worker_compute_ms_sum += compute_ms;
            }
            if (tasks_done_sum != nullptr)
            {
                *tasks_done_sum += 1;
            }

            for (int i = 0; i < m; ++i)
            {
                for (int j = 0; j < bs; ++j)
                {
                    u_buf[static_cast<size_t>(i) * bs + j] = U_sub.at(i, j);
                }
            }
            for (int i = 0; i < bs; ++i)
            {
                for (int j = 0; j < bs; ++j)
                {
                    b_buf[static_cast<size_t>(i) * bs + j] = B_sub.at(i, j);
                }
            }
            for (int i = 0; i < n; ++i)
            {
                for (int j = 0; j < bs; ++j)
                {
                    v_buf[static_cast<size_t>(i) * bs + j] = V_sub.at(i, j);
                }
            }

            MPIResultHeader rhdr{};
            rhdr.l = l;
            rhdr.r = r;
            rhdr.converged = 0;
            rhdr.split_count = 0;
            rhdr.sweep_count = 1;

            MPI_Send(&rhdr, sizeof(rhdr), MPI_BYTE, 0, MPI_TAG_RESULT, MPI_COMM_WORLD);
            MPI_Send(&compute_ms, 1, MPI_DOUBLE, 0, MPI_TAG_RESULT, MPI_COMM_WORLD);
            MPI_Send(u_buf.data(), static_cast<int>(u_buf.size()), MPI_DOUBLE, 0, MPI_TAG_RESULT, MPI_COMM_WORLD);
            MPI_Send(b_buf.data(), static_cast<int>(b_buf.size()), MPI_DOUBLE, 0, MPI_TAG_RESULT, MPI_COMM_WORLD);
            MPI_Send(v_buf.data(), static_cast<int>(v_buf.size()), MPI_DOUBLE, 0, MPI_TAG_RESULT, MPI_COMM_WORLD);
        }
    }

    static void recv_result_and_merge(int worker,
                                      const MPIResultHeader &rhdr,
                                      int m, int n,
                                      Matrix &U, Matrix &B, Matrix &V,
                                      Lab4MPIStats &stats)
    {
        const int l = rhdr.l;
        const int r = rhdr.r;
        const int bs = r - l + 1;

        double worker_compute_ms = 0.0;
        MPI_Recv(&worker_compute_ms, 1, MPI_DOUBLE, worker, MPI_TAG_RESULT, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        stats.worker_compute_ms += worker_compute_ms;

        std::vector<double> u_buf(static_cast<size_t>(m) * bs);
        std::vector<double> b_buf(static_cast<size_t>(bs) * bs);
        std::vector<double> v_buf(static_cast<size_t>(n) * bs);

        MPI_Recv(u_buf.data(), static_cast<int>(u_buf.size()), MPI_DOUBLE, worker, MPI_TAG_RESULT, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(b_buf.data(), static_cast<int>(b_buf.size()), MPI_DOUBLE, worker, MPI_TAG_RESULT, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(v_buf.data(), static_cast<int>(v_buf.size()), MPI_DOUBLE, worker, MPI_TAG_RESULT, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        const double t0 = MPI_Wtime();
        unpack_task_result(U, B, V, GKHBlock{l, r}, u_buf, b_buf, v_buf);
        const double t1 = MPI_Wtime();

        stats.merge_ms += (t1 - t0) * 1000.0;
        stats.tasks_done += 1;
    }

    static void print_profile_if_needed(const char *impl_name,
                                        int world_size,
                                        const Lab4MPIOptions &opts,
                                        const Lab4MPIStats &stats)
    {
        if (!opts.profile)
        {
            return;
        }

        std::cerr << "[lab4_mpi_profile] "
                  << "impl=" << impl_name << " "
                  << "world_size=" << world_size << " "
                  << "dispatch_ms=" << stats.dispatch_ms << " "
                  << "worker_compute_ms=" << stats.worker_compute_ms << " "
                  << "merge_ms=" << stats.merge_ms << " "
                  << "total_ms=" << stats.total_ms << " "
                  << "tasks_sent=" << stats.tasks_sent << " "
                  << "tasks_done=" << stats.tasks_done << " "
                  << "queue_rounds=" << stats.queue_rounds << " "
                  << "max_queue_size=" << stats.max_queue_size
                  << std::endl;
    }
} // namespace

bool gkh_svd_from_bidiagonal_mpi_blocking(
    Matrix &U, Matrix &B, Matrix &V,
    const Lab4MPIOptions &opts,
    Lab4MPIStats *stats)
{
    int world_size = 1;
    int world_rank = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    int dims[2] = {0, 0};
    if (world_rank == 0)
    {
        dims[0] = B.rows();
        dims[1] = B.cols();
    }
    MPI_Bcast(dims, 2, MPI_INT, 0, MPI_COMM_WORLD);

    const int m = dims[0];
    const int n = dims[1];

    Lab4MPIStats local_stats{};
    double worker_compute_ms_sum = 0.0;
    long long worker_tasks_done_sum = 0;

    const double total_t0 = MPI_Wtime();
    bool converged = false;

    if (world_rank == 0)
    {
        if (world_size <= 1)
        {
            const double t0 = MPI_Wtime();
            converged = gkh_svd_from_bidiagonal(U, B, V, opts.max_iter, opts.tol);
            const double t1 = MPI_Wtime();

            local_stats.worker_compute_ms = (t1 - t0) * 1000.0;
            local_stats.total_ms = local_stats.worker_compute_ms;

            if (stats != nullptr)
            {
                *stats = local_stats;
            }

            print_profile_if_needed("mpi_blocking_single", world_size, opts, local_stats);
            return converged;
        }

        for (int iter = 0; iter < opts.max_iter; ++iter)
        {
            gkh_cleanup_bidiagonal_auto(B, opts.tol);
            gkh_handle_diagonal_zeros(U, B, V, opts.tol);

            std::vector<GKHBlock> blocks = gkh_split_active_blocks(B, n, opts.tol);

            bool all_singletons = true;
            for (const auto &blk : blocks)
            {
                if (blk.r > blk.l)
                {
                    all_singletons = false;
                    break;
                }
            }

            if (all_singletons)
            {
                converged = true;
                break;
            }

            std::vector<GKHBlock> tasks;
            tasks.reserve(blocks.size());
            for (int i = static_cast<int>(blocks.size()) - 1; i >= 0; --i)
            {
                if (blocks[i].r > blocks[i].l)
                {
                    tasks.push_back(blocks[i]);
                }
            }

            const int task_count = static_cast<int>(tasks.size());
            const int worker_count = world_size - 1;

            if (task_count == 0)
            {
                continue;
            }

            int next_task = 0;
            int active_workers = 0;

            for (int worker = 1; worker <= worker_count && next_task < task_count; ++worker)
            {
                const double t0 = MPI_Wtime();
                send_task_to_worker(worker, U, B, V, tasks[next_task]);
                const double t1 = MPI_Wtime();

                local_stats.dispatch_ms += (t1 - t0) * 1000.0;
                local_stats.tasks_sent += 1;
                next_task += 1;
                active_workers += 1;
            }

            while (active_workers > 0)
            {
                MPIResultHeader rhdr{};
                MPI_Status st{};
                MPI_Recv(&rhdr, sizeof(rhdr), MPI_BYTE, MPI_ANY_SOURCE, MPI_TAG_RESULT, MPI_COMM_WORLD, &st);

                const int worker = st.MPI_SOURCE;
                recv_result_and_merge(worker, rhdr, m, n, U, B, V, local_stats);
                active_workers -= 1;

                if (next_task < task_count)
                {
                    const double ts0 = MPI_Wtime();
                    send_task_to_worker(worker, U, B, V, tasks[next_task]);
                    const double ts1 = MPI_Wtime();

                    local_stats.dispatch_ms += (ts1 - ts0) * 1000.0;
                    local_stats.tasks_sent += 1;
                    next_task += 1;
                    active_workers += 1;
                }
            }
        }

        for (int worker = 1; worker < world_size; ++worker)
        {
            send_stop_to_worker(worker);
        }

        gkh_finalize_result(U, B, V, opts.tol);
    }
    else
    {
        worker_loop_step_only(m, n, &worker_compute_ms_sum, &worker_tasks_done_sum);
    }

    MPI_Barrier(MPI_COMM_WORLD);

    const double total_t1 = MPI_Wtime();
    local_stats.total_ms = (total_t1 - total_t0) * 1000.0;

    int conv_int = converged ? 1 : 0;
    MPI_Bcast(&conv_int, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (world_rank == 0 && stats != nullptr)
    {
        *stats = local_stats;
    }

    if (world_rank == 0)
    {
        print_profile_if_needed("mpi_blocking_baseline", world_size, opts, local_stats);
    }

    return conv_int != 0;
}

bool gkh_svd_from_bidiagonal_mpi_pool(
    Matrix &U, Matrix &B, Matrix &V,
    const Lab4MPIOptions &opts,
    Lab4MPIStats *stats)
{
    int world_size = 1;
    int world_rank = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    int dims[2] = {0, 0};
    if (world_rank == 0)
    {
        dims[0] = B.rows();
        dims[1] = B.cols();
    }
    MPI_Bcast(dims, 2, MPI_INT, 0, MPI_COMM_WORLD);

    const int m = dims[0];
    const int n = dims[1];

    Lab4MPIStats local_stats{};
    double worker_compute_ms_sum = 0.0;
    long long worker_tasks_done_sum = 0;

    const double total_t0 = MPI_Wtime();
    bool converged = false;

    if (world_rank == 0)
    {
        if (world_size <= 1)
        {
            const double t0 = MPI_Wtime();
            converged = gkh_svd_from_bidiagonal(U, B, V, opts.max_iter, opts.tol);
            const double t1 = MPI_Wtime();

            local_stats.worker_compute_ms = (t1 - t0) * 1000.0;
            local_stats.total_ms = local_stats.worker_compute_ms;

            if (stats != nullptr)
            {
                *stats = local_stats;
            }

            print_profile_if_needed("mpi_pool_single", world_size, opts, local_stats);
            return converged;
        }

        const int worker_count = world_size - 1;

        for (int iter = 0; iter < opts.max_iter; ++iter)
        {
            gkh_cleanup_bidiagonal_auto(B, opts.tol);
            gkh_handle_diagonal_zeros(U, B, V, opts.tol);

            std::vector<GKHBlock> blocks = gkh_split_active_blocks(B, n, opts.tol);

            bool all_singletons = true;
            for (const auto &blk : blocks)
            {
                if (blk.r > blk.l)
                {
                    all_singletons = false;
                    break;
                }
            }

            if (all_singletons)
            {
                converged = true;
                break;
            }

            std::vector<GKHBlock> queue;
            queue.reserve(blocks.size());
            for (int i = static_cast<int>(blocks.size()) - 1; i >= 0; --i)
            {
                if (blocks[i].r > blocks[i].l)
                {
                    queue.push_back(blocks[i]);
                }
            }

            if (queue.empty())
            {
                continue;
            }

            local_stats.queue_rounds += 1;
            local_stats.max_queue_size = std::max<long long>(
                local_stats.max_queue_size,
                static_cast<long long>(queue.size()));

            int next_task = 0;
            int active_workers = 0;

            for (int worker = 1; worker <= worker_count && next_task < static_cast<int>(queue.size()); ++worker)
            {
                const double t0 = MPI_Wtime();
                send_task_to_worker(worker, U, B, V, queue[next_task]);
                const double t1 = MPI_Wtime();

                local_stats.dispatch_ms += (t1 - t0) * 1000.0;
                local_stats.tasks_sent += 1;
                next_task += 1;
                active_workers += 1;
            }

            while (active_workers > 0)
            {
                MPIResultHeader rhdr{};
                MPI_Status st{};
                MPI_Recv(&rhdr, sizeof(rhdr), MPI_BYTE, MPI_ANY_SOURCE, MPI_TAG_RESULT, MPI_COMM_WORLD, &st);

                const int worker = st.MPI_SOURCE;
                recv_result_and_merge(worker, rhdr, m, n, U, B, V, local_stats);
                active_workers -= 1;

                if (next_task < static_cast<int>(queue.size()))
                {
                    const double ts0 = MPI_Wtime();
                    send_task_to_worker(worker, U, B, V, queue[next_task]);
                    const double ts1 = MPI_Wtime();

                    local_stats.dispatch_ms += (ts1 - ts0) * 1000.0;
                    local_stats.tasks_sent += 1;
                    next_task += 1;
                    active_workers += 1;
                }
            }
        }

        for (int worker = 1; worker < world_size; ++worker)
        {
            send_stop_to_worker(worker);
        }

        gkh_finalize_result(U, B, V, opts.tol);
    }
    else
    {
        worker_loop_step_only(m, n, &worker_compute_ms_sum, &worker_tasks_done_sum);
    }

    MPI_Barrier(MPI_COMM_WORLD);

    const double total_t1 = MPI_Wtime();
    local_stats.total_ms = (total_t1 - total_t0) * 1000.0;

    int conv_int = converged ? 1 : 0;
    MPI_Bcast(&conv_int, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (world_rank == 0 && stats != nullptr)
    {
        *stats = local_stats;
    }

    if (world_rank == 0)
    {
        print_profile_if_needed("mpi_pool_step_queue", world_size, opts, local_stats);
    }

    return conv_int != 0;
}