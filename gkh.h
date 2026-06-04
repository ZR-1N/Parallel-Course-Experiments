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

enum RotationSide
{
    ROT_RIGHT_V = 0,
    ROT_LEFT_U = 1
};

struct RotationLog
{
    int side;
    int k0;
    int k1;
    double c;
    double s;
};

Matrix gkh_extract_block(const Matrix &B, int l, int r);
void gkh_merge_block(Matrix &B, const Matrix &localB, int l, int r);

void gkh_replay_rotations(Matrix &U, Matrix &V,
                          const std::vector<RotationLog> &logs);

void gkh_replay_rotations_hybrid(Matrix &U, Matrix &V,
                                 const std::vector<RotationLog> &logs,
                                 int omp_threads);

// 记录版：只改局部 B，不直接改全局 U/V
void gkh_one_block_step_record(Matrix &B, int l, int r,
                               int global_offset,
                               std::vector<RotationLog> &logs);

bool gkh_handle_diagonal_zeros_record(Matrix &B,
                                      int global_offset,
                                      double tol,
                                      std::vector<RotationLog> &logs);