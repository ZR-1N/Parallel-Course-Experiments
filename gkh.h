#pragma once

#include "matrix.h"
#include <vector>

struct GKHBlock
{
    int l;
    int r;
};

void gkh_cleanup_bidiagonal_auto(Matrix &B, double tol);

bool gkh_handle_diagonal_zeros(Matrix &U, Matrix &B, Matrix &V, double tol);

std::vector<GKHBlock> gkh_split_active_blocks(Matrix &B, int n, double tol);

void gkh_one_block_step(Matrix &U, Matrix &B, Matrix &V, int l, int r);

void gkh_finalize_result(Matrix &U, Matrix &B, Matrix &V, double tol);

// 在已上二对角化结果 A = U * B * V^T 上执行 GKH 迭代。
// 若收敛，B 最终变为非负降序对角（m x n）。
bool gkh_svd_from_bidiagonal(Matrix &U, Matrix &B, Matrix &V,
                             int max_iter = 6000,
                             double tol = 1e-12);