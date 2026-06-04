#include "gkh_mpi.h"
#include "gkh.h"
#include "mpi_protocol.h"

#include <mpi.h>
#include <iostream>

bool gkh_svd_from_bidiagonal_mpi_blocking(
    Matrix &U, Matrix &B, Matrix &V,
    const Lab4MPIOptions &opts,
    Lab4MPIStats *stats)
{
    int world_size = 1;
    int world_rank = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    Lab4MPIStats local_stats{};
    const double total_t0 = MPI_Wtime();

    // 第1轮先只做 MPI 路径打通：
    // rank 0 真正调用现有串行/共享内存版本，
    // 其他 rank 先不参与实际计算。
    bool converged = false;

    if (world_rank == 0)
    {
        const double t0 = MPI_Wtime();
        converged = gkh_svd_from_bidiagonal(U, B, V, opts.max_iter, opts.tol);
        const double t1 = MPI_Wtime();

        local_stats.dispatch_ms = 0.0;
        local_stats.worker_compute_ms = (t1 - t0) * 1000.0;
        local_stats.merge_ms = 0.0;
        local_stats.tasks_sent = 0;
        local_stats.tasks_done = 0;
    }

    MPI_Barrier(MPI_COMM_WORLD);

    const double total_t1 = MPI_Wtime();
    local_stats.total_ms = (total_t1 - total_t0) * 1000.0;

    if (world_rank == 0 && stats != nullptr)
    {
        *stats = local_stats;
    }

    int conv_int = converged ? 1 : 0;
    MPI_Bcast(&conv_int, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (opts.profile && world_rank == 0)
    {
        std::cerr << "[lab4_mpi_profile] "
                  << "impl=mpi_blocking_stub "
                  << "world_size=" << world_size << " "
                  << "dispatch_ms=" << local_stats.dispatch_ms << " "
                  << "worker_compute_ms=" << local_stats.worker_compute_ms << " "
                  << "merge_ms=" << local_stats.merge_ms << " "
                  << "total_ms=" << local_stats.total_ms << " "
                  << "tasks_sent=" << local_stats.tasks_sent << " "
                  << "tasks_done=" << local_stats.tasks_done
                  << std::endl;
    }

    return conv_int != 0;
}