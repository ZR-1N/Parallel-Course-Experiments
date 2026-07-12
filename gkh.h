#pragma once

#include "matrix.h"

struct GKHProfile
{
    int mode = 0;

    long long outer_iterations = 0;
    long long block_steps = 0;

    long long left_rotations = 0;
    long long right_rotations = 0;
    long long zero_chase_calls = 0;

    long long deflations = 0;

    long long total_nontrivial_blocks = 0;
    long long total_nontrivial_block_sizes = 0;

    long long iterations_with_multiple_blocks = 0;

    int max_nontrivial_blocks = 0;
    int max_block_size = 0;

    double cleanup_ms = 0.0;
    double zero_handle_ms = 0.0;
    double split_ms = 0.0;
    double block_step_ms = 0.0;
    double finalize_ms = 0.0;
};

// 在已上二对角化结果 A = U * B * V^T 上执行 GKH 迭代。
// 额外处理“主对角线收敛到 0”的压缩情形。
//
// 输入要求：
// - B 为 m x n 且 m >= n，且近似上二对角
// - U 为 m x m，V 为 n x n
//
// 输出：
// - 保持 A = U * B * V^T
// - 若收敛，B 变为非负降序对角（m x n）
//
// 返回：是否在 max_iter 轮内收敛。
bool gkh_svd_from_bidiagonal(Matrix &U, Matrix &B, Matrix &V,
                             int max_iter = 6000,
                             double tol = 1e-12,
                             GKHProfile *profile = nullptr);
