#include "bidiagonalization_gpu.h"

#include <cuda_runtime.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <stdexcept>
#include <string>
#include <vector>

static void cuda_check(cudaError_t err, const char *expr, const char *file, int line)
{
    if (err != cudaSuccess)
    {
        throw std::runtime_error(std::string("CUDA error: ") +
                                 cudaGetErrorString(err) +
                                 " at " + file + ":" + std::to_string(line) +
                                 " expr=" + expr);
    }
}

#define CUDA_CHECK(expr) cuda_check((expr), #expr, __FILE__, __LINE__)

void cuda_bidiag_warmup()
{
    CUDA_CHECK(cudaSetDevice(0));
    CUDA_CHECK(cudaFree(0));
}

#define CUDA_LAUNCH_TIMED(kernel_ms_acc, ...)                                  \
    do                                                                         \
    {                                                                          \
        cudaEvent_t __start, __stop;                                            \
        CUDA_CHECK(cudaEventCreate(&__start));                                 \
        CUDA_CHECK(cudaEventCreate(&__stop));                                  \
        CUDA_CHECK(cudaEventRecord(__start));                                  \
        __VA_ARGS__;                                                           \
        CUDA_CHECK(cudaGetLastError());                                        \
        CUDA_CHECK(cudaEventRecord(__stop));                                   \
        CUDA_CHECK(cudaEventSynchronize(__stop));                              \
        float __ms = 0.0f;                                                     \
        CUDA_CHECK(cudaEventElapsedTime(&__ms, __start, __stop));              \
        kernel_ms_acc += static_cast<double>(__ms);                            \
        CUDA_CHECK(cudaEventDestroy(__start));                                 \
        CUDA_CHECK(cudaEventDestroy(__stop));                                  \
    } while (0)

static double timed_cuda_memcpy(void *dst, const void *src, size_t bytes, cudaMemcpyKind kind)
{
    auto t0 = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(dst, src, bytes, kind));
    auto t1 = std::chrono::high_resolution_clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

static double vector_norm_host(const std::vector<double> &v, int len)
{
    double sum = 0.0;
    for (int i = 0; i < len; ++i)
    {
        sum += v[i] * v[i];
    }
    return std::sqrt(sum);
}

static double dot_host(const std::vector<double> &a, int len)
{
    double sum = 0.0;
    for (int i = 0; i < len; ++i)
    {
        sum += a[i] * a[i];
    }
    return sum;
}

__global__ void extract_col_segment_kernel(const double *A, double *out,
                                           int lda,
                                           int row0, int col,
                                           int len)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < len)
    {
        out[i] = A[(row0 + i) * lda + col];
    }
}

__global__ void extract_row_segment_kernel(const double *A, double *out,
                                           int lda,
                                           int row, int col0,
                                           int len)
{
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    if (j < len)
    {
        out[j] = A[row * lda + (col0 + j)];
    }
}

// out[col] = sum_i vec[i] * A[row0+i, col0+col]
__global__ void dot_cols_kernel(const double *A, const double *vec, double *out,
                                int rows, int cols, int lda,
                                int row0, int col0)
{
    extern __shared__ double sdata[];

    int col = blockIdx.x;
    int tid = threadIdx.x;

    double sum = 0.0;
    for (int i = tid; i < rows; i += blockDim.x)
    {
        sum += vec[i] * A[(row0 + i) * lda + (col0 + col)];
    }

    sdata[tid] = sum;
    __syncthreads();

    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1)
    {
        if (tid < stride)
        {
            sdata[tid] += sdata[tid + stride];
        }
        __syncthreads();
    }

    if (tid == 0)
    {
        out[col] = sdata[0];
    }
}

// out[row] = sum_j A[row0+row, col0+j] * vec[j]
__global__ void dot_rows_kernel(const double *A, const double *vec, double *out,
                                int rows, int cols, int lda,
                                int row0, int col0)
{
    extern __shared__ double sdata[];

    int row = blockIdx.x;
    int tid = threadIdx.x;

    double sum = 0.0;
    for (int j = tid; j < cols; j += blockDim.x)
    {
        sum += A[(row0 + row) * lda + (col0 + j)] * vec[j];
    }

    sdata[tid] = sum;
    __syncthreads();

    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1)
    {
        if (tid < stride)
        {
            sdata[tid] += sdata[tid + stride];
        }
        __syncthreads();
    }

    if (tid == 0)
    {
        out[row] = sdata[0];
    }
}

// A[row0+i, col0+j] -= beta * left[i] * right[j]
__global__ void ger_row_major_kernel(double *A,
                                     const double *left,
                                     const double *right,
                                     double beta,
                                     int rows, int cols,
                                     int lda,
                                     int row0, int col0)
{
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    int i = blockIdx.y * blockDim.y + threadIdx.y;

    if (i < rows && j < cols)
    {
        A[(row0 + i) * lda + (col0 + j)] -= beta * left[i] * right[j];
    }
}

__global__ void zero_col_below_kernel(double *A, int lda,
                                      int k, int m)
{
    int t = blockIdx.x * blockDim.x + threadIdx.x;
    int row = k + 1 + t;
    if (row < m)
    {
        A[row * lda + k] = 0.0;
    }
}

__global__ void zero_row_after_kernel(double *A, int lda,
                                      int k, int n)
{
    int t = blockIdx.x * blockDim.x + threadIdx.x;
    int col = k + 2 + t;
    if (col < n)
    {
        A[k * lda + col] = 0.0;
    }
}

Matrix to_bidiagonal_gpu_kernel(const Matrix &A, Matrix &U, Matrix &V,
                                GpuBidiagStats *stats)
{
    if (A.rows() < A.cols())
    {
        throw std::invalid_argument("to_bidiagonal_gpu_kernel: requires m >= n");
    }

    using Clock = std::chrono::high_resolution_clock;
    const auto t_total_beg = Clock::now();

    GpuBidiagStats local_stats;

    const int m = A.rows();
    const int n = A.cols();

    Matrix B = A;

    U = Matrix(m, m, 0.0);
    for (int i = 0; i < m; ++i)
    {
        U.at(i, i) = 1.0;
    }

    V = Matrix(n, n, 0.0);
    for (int i = 0; i < n; ++i)
    {
        V.at(i, i) = 1.0;
    }

    double *d_B = nullptr;
    double *d_U = nullptr;
    double *d_V = nullptr;
    double *d_vec = nullptr;
    double *d_work = nullptr;

    const size_t bytes_B = static_cast<size_t>(m) * n * sizeof(double);
    const size_t bytes_U = static_cast<size_t>(m) * m * sizeof(double);
    const size_t bytes_V = static_cast<size_t>(n) * n * sizeof(double);

    int max_dim = std::max(m, n);
    if (max_dim < 1)
    {
        max_dim = 1;
    }

    CUDA_CHECK(cudaMalloc(&d_B, bytes_B));
    CUDA_CHECK(cudaMalloc(&d_U, bytes_U));
    CUDA_CHECK(cudaMalloc(&d_V, bytes_V));
    CUDA_CHECK(cudaMalloc(&d_vec, static_cast<size_t>(max_dim) * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_work, static_cast<size_t>(max_dim) * sizeof(double)));

    local_stats.h2d_ms += timed_cuda_memcpy(d_B, B.data(), bytes_B, cudaMemcpyHostToDevice);
    local_stats.h2d_ms += timed_cuda_memcpy(d_U, U.data(), bytes_U, cudaMemcpyHostToDevice);
    local_stats.h2d_ms += timed_cuda_memcpy(d_V, V.data(), bytes_V, cudaMemcpyHostToDevice);

    std::vector<double> h_tmp(max_dim, 0.0);
    std::vector<double> h_v(max_dim, 0.0);

    const int threads = 256;
    const size_t reduce_smem = threads * sizeof(double);
    const dim3 block2d(16, 16);

    for (int k = 0; k < n; ++k)
    {
        // ============================================================
        // Left Householder: Bsub <- Bsub - beta * v * (v^T Bsub)
        // ============================================================
        const int rows_left = m - k;
        const int cols_left = n - k;

        if (rows_left > 0)
        {
            const int grid_extract = (rows_left + threads - 1) / threads;
            CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                              extract_col_segment_kernel<<<grid_extract, threads>>>(
                                  d_B, d_vec, n, k, k, rows_left));

            local_stats.d2h_ms += timed_cuda_memcpy(h_tmp.data(), d_vec,
                                                    static_cast<size_t>(rows_left) * sizeof(double),
                                                    cudaMemcpyDeviceToHost);
        }

        const double norm_x = vector_norm_host(h_tmp, rows_left);

        if (norm_x > 1e-14 && k < m - 1)
        {
            const double sigma = (h_tmp[0] >= 0.0 ? 1.0 : -1.0) * norm_x;

            for (int i = 0; i < rows_left; ++i)
            {
                h_v[i] = h_tmp[i];
            }
            h_v[0] += sigma;

            const double vTv = dot_host(h_v, rows_left);

            if (vTv > 1e-28)
            {
                const double beta = 2.0 / vTv;

                local_stats.h2d_ms += timed_cuda_memcpy(d_vec, h_v.data(),
                                                        static_cast<size_t>(rows_left) * sizeof(double),
                                                        cudaMemcpyHostToDevice);

                // w = v^T * B[k:m, k:n], length = cols_left
                CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                  dot_cols_kernel<<<cols_left, threads, reduce_smem>>>(
                                      d_B, d_vec, d_work,
                                      rows_left, cols_left, n, k, k));

                // B[k:m, k:n] -= beta * v * w^T
                {
                    dim3 grid2d((cols_left + block2d.x - 1) / block2d.x,
                                (rows_left + block2d.y - 1) / block2d.y);
                    CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                      ger_row_major_kernel<<<grid2d, block2d>>>(
                                          d_B, d_vec, d_work, beta,
                                          rows_left, cols_left, n, k, k));
                }

                // wU = U[:, k:m] * v, length = m
                CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                  dot_rows_kernel<<<m, threads, reduce_smem>>>(
                                      d_U, d_vec, d_work,
                                      m, rows_left, m, 0, k));

                // U[:, k:m] -= beta * wU * v^T
                {
                    dim3 grid2d((rows_left + block2d.x - 1) / block2d.x,
                                (m + block2d.y - 1) / block2d.y);
                    CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                      ger_row_major_kernel<<<grid2d, block2d>>>(
                                          d_U, d_work, d_vec, beta,
                                          m, rows_left, m, 0, k));
                }
            }
        }

        if (k + 1 < m)
        {
            const int len_zero = m - (k + 1);
            const int grid_zero = (len_zero + threads - 1) / threads;
            CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                              zero_col_below_kernel<<<grid_zero, threads>>>(d_B, n, k, m));
        }

        // ============================================================
        // Right Householder: Bsub <- Bsub - beta * (Bsub v) * v^T
        // ============================================================
        if (k < n - 2)
        {
            const int len = n - k - 1;
            const int rows_right = m - k;

            const int grid_extract = (len + threads - 1) / threads;
            CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                              extract_row_segment_kernel<<<grid_extract, threads>>>(
                                  d_B, d_vec, n, k, k + 1, len));

            local_stats.d2h_ms += timed_cuda_memcpy(h_tmp.data(), d_vec,
                                                    static_cast<size_t>(len) * sizeof(double),
                                                    cudaMemcpyDeviceToHost);

            const double norm_y = vector_norm_host(h_tmp, len);

            if (norm_y > 1e-14)
            {
                const double sigma = (h_tmp[0] >= 0.0 ? 1.0 : -1.0) * norm_y;

                for (int j = 0; j < len; ++j)
                {
                    h_v[j] = h_tmp[j];
                }
                h_v[0] += sigma;

                const double vTv = dot_host(h_v, len);

                if (vTv > 1e-28)
                {
                    const double beta = 2.0 / vTv;

                    local_stats.h2d_ms += timed_cuda_memcpy(d_vec, h_v.data(),
                                                            static_cast<size_t>(len) * sizeof(double),
                                                            cudaMemcpyHostToDevice);

                    // w = B[k:m, k+1:n] * v, length = rows_right
                    CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                      dot_rows_kernel<<<rows_right, threads, reduce_smem>>>(
                                          d_B, d_vec, d_work,
                                          rows_right, len, n, k, k + 1));

                    // B[k:m, k+1:n] -= beta * w * v^T
                    {
                        dim3 grid2d((len + block2d.x - 1) / block2d.x,
                                    (rows_right + block2d.y - 1) / block2d.y);
                        CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                          ger_row_major_kernel<<<grid2d, block2d>>>(
                                              d_B, d_work, d_vec, beta,
                                              rows_right, len, n, k, k + 1));
                    }

                    // wV = V[:, k+1:n] * v, length = n
                    CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                      dot_rows_kernel<<<n, threads, reduce_smem>>>(
                                          d_V, d_vec, d_work,
                                          n, len, n, 0, k + 1));

                    // V[:, k+1:n] -= beta * wV * v^T
                    {
                        dim3 grid2d((len + block2d.x - 1) / block2d.x,
                                    (n + block2d.y - 1) / block2d.y);
                        CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                          ger_row_major_kernel<<<grid2d, block2d>>>(
                                              d_V, d_work, d_vec, beta,
                                              n, len, n, 0, k + 1));
                    }
                }
            }

            if (k + 2 < n)
            {
                const int len_zero = n - (k + 2);
                const int grid_zero = (len_zero + threads - 1) / threads;
                CUDA_LAUNCH_TIMED(local_stats.kernel_ms,
                                  zero_row_after_kernel<<<grid_zero, threads>>>(d_B, n, k, n));
            }
        }
    }

    local_stats.d2h_ms += timed_cuda_memcpy(B.data(), d_B, bytes_B, cudaMemcpyDeviceToHost);
    local_stats.d2h_ms += timed_cuda_memcpy(U.data(), d_U, bytes_U, cudaMemcpyDeviceToHost);
    local_stats.d2h_ms += timed_cuda_memcpy(V.data(), d_V, bytes_V, cudaMemcpyDeviceToHost);

    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_U));
    CUDA_CHECK(cudaFree(d_V));
    CUDA_CHECK(cudaFree(d_vec));
    CUDA_CHECK(cudaFree(d_work));

    const auto t_total_end = Clock::now();
    local_stats.total_ms = std::chrono::duration<double, std::milli>(t_total_end - t_total_beg).count();

    local_stats.other_ms = local_stats.total_ms
                        - local_stats.h2d_ms
                        - local_stats.d2h_ms
                        - local_stats.kernel_ms;

    if (local_stats.other_ms < 0.0 && local_stats.other_ms > -1e-6)
    {
        local_stats.other_ms = 0.0;
    }

    if (stats)
    {
        *stats = local_stats;
    }

    return B;
}