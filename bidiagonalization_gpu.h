#pragma once

#include "matrix.h"

struct GpuBidiagStats
{
    double total_ms = 0.0;
    double h2d_ms = 0.0;
    double d2h_ms = 0.0;
    double kernel_ms = 0.0;
    double other_ms = 0.0;
};

void cuda_bidiag_warmup();

Matrix to_bidiagonal_gpu_kernel(const Matrix &A, Matrix &U, Matrix &V,
                                GpuBidiagStats *stats = nullptr);

Matrix to_bidiagonal_gpu_cublas(const Matrix &A, Matrix &U, Matrix &V,
                                GpuBidiagStats *stats = nullptr);