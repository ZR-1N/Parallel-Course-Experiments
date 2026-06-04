#pragma once

#include "matrix.h"

struct Lab4MPIOptions
{
    int max_iter = 6000;
    double tol = 1e-12;

    int sweep_cap = 1;        // 第2轮开始真正用
    bool profile = true;
    bool master_work = false; // 增强项，后面再做
    int omp_threads = 1;      // 混合并行，后面再做
};

struct Lab4MPIStats
{
    double dispatch_ms = 0.0;
    double worker_compute_ms = 0.0;
    double master_compute_ms = 0.0;
    double merge_ms = 0.0;
    double total_ms = 0.0;

    long long tasks_sent = 0;
    long long tasks_done = 0;

    long long queue_rounds = 0;
    long long max_queue_size = 0;
};

bool gkh_svd_from_bidiagonal_mpi_blocking(
    Matrix &U, Matrix &B, Matrix &V,
    const Lab4MPIOptions &opts,
    Lab4MPIStats *stats);

bool gkh_svd_from_bidiagonal_mpi_pool(
    Matrix &U, Matrix &B, Matrix &V,
    const Lab4MPIOptions &opts,
    Lab4MPIStats *stats);

bool gkh_svd_from_bidiagonal_mpi_nonblocking(
    Matrix &U, Matrix &B, Matrix &V,
    const Lab4MPIOptions &opts,
    Lab4MPIStats *stats);