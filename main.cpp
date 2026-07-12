#include "matrix.h"
#include "gkh.h"
#include "bidiagonalization.h"
#ifdef USE_CUDA_BIDIAG
#include "bidiagonalization_gpu.h"
#endif

#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <string>
#include <vector>
#ifdef _OPENMP
#include <omp.h>
#endif
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

static Matrix transpose(const Matrix &A)
{
    Matrix T(A.cols(), A.rows());
    for (int i = 0; i < A.rows(); ++i)
    {
        for (int j = 0; j < A.cols(); ++j)
        {
            T.at(j, i) = A.at(i, j);
        }
    }
    return T;
}

static double fro_norm(const Matrix &A)
{
    double s = 0.0;
    for (int i = 0; i < A.rows(); ++i)
    {
        for (int j = 0; j < A.cols(); ++j)
        {
            s += A.at(i, j) * A.at(i, j);
        }
    }
    return std::sqrt(s);
}

static double orth_error(const Matrix &Q)
{
    Matrix I = transpose(Q) * Q;
    const int n = I.rows();
    for (int i = 0; i < n; ++i)
    {
        I.at(i, i) -= 1.0;
    }
    return fro_norm(I);
}

static double reconstruction_error(const Matrix &A, const Matrix &U, const Matrix &S, const Matrix &V)
{
    Matrix R = U * S * transpose(V);
    double s = 0.0;
    for (int i = 0; i < A.rows(); ++i)
    {
        for (int j = 0; j < A.cols(); ++j)
        {
            const double d = A.at(i, j) - R.at(i, j);
            s += d * d;
        }
    }
    return std::sqrt(s);
}

static double diagonal_structure_error(const Matrix &S)
{
    double max_abs = 0.0;
    for (int i = 0; i < S.rows(); ++i)
    {
        for (int j = 0; j < S.cols(); ++j)
        {
            if (i != j)
            {
                max_abs = std::max(max_abs, std::fabs(S.at(i, j)));
            }
        }
    }
    return max_abs;
}

static double bidiagonal_structure_error(const Matrix &B)
{
    double max_abs = 0.0;
    for (int i = 0; i < B.rows(); ++i)
    {
        for (int j = 0; j < B.cols(); ++j)
        {
            if (j != i && j != i + 1)
            {
                max_abs = std::max(max_abs, std::fabs(B.at(i, j)));
            }
        }
    }
    return max_abs;
}

static double order_error(const Matrix &S)
{
    const int n = S.cols();
    double worst = 0.0;
    for (int i = 0; i < n - 1; ++i)
    {
        double cur = S.at(i, i);
        double nxt = S.at(i + 1, i + 1);
        if (cur < nxt)
        {
            worst = std::max(worst, nxt - cur);
        }
    }
    return worst;
}

static bool nonnegative_diag(const Matrix &S)
{
    for (int i = 0; i < S.cols(); ++i)
    {
        if (S.at(i, i) < -1e-12)
        {
            return false;
        }
    }
    return true;
}

static Matrix identity_matrix(int n)
{
    Matrix I(n, n, 0.0);
    for (int i = 0; i < n; ++i)
    {
        I.at(i, i) = 1.0;
    }
    return I;
}

static bool valid_seed_policy(const std::string &seed_policy)
{
    return seed_policy == "fixed" || seed_policy == "sequence";
}

static bool valid_gkh_layout(const std::string &gkh_layout)
{
    return gkh_layout == "normal" || gkh_layout == "tuv";
}

static bool valid_gkh_accum(const std::string &gkh_accum)
{
    return gkh_accum == "immediate" || gkh_accum == "deferred";
}

static GKHLayout parse_gkh_layout(const std::string &gkh_layout)
{
    return (gkh_layout == "tuv") ? GKHLayout::TUV : GKHLayout::Normal;
}

static GKHAccumulation parse_gkh_accum(const std::string &gkh_accum)
{
    return (gkh_accum == "deferred") ? GKHAccumulation::Deferred
                                      : GKHAccumulation::Immediate;
}

static GKHOptions make_gkh_options(const std::string &gkh_layout,
                                   bool gkh_uv_update,
                                   const std::string &gkh_accum,
                                   int replay_threads,
                                   int replay_tile_rows)
{
    GKHOptions options;
    options.layout = parse_gkh_layout(gkh_layout);
    options.accumulation = parse_gkh_accum(gkh_accum);
    options.update_uv = gkh_uv_update;
    options.replay_threads = replay_threads;
    options.replay_tile_rows = replay_tile_rows;
    return options;
}

static long long bench_actual_seed(long long base_seed, int rep, const std::string &seed_policy)
{
    if (seed_policy == "fixed")
    {
        return base_seed + 1000;
    }

    return base_seed + 1000 + rep;
}

static void print_gkh_profile_line(int rep,
                                   long long seed,
                                   bool has_seed,
                                   bool converged,
                                   const GKHProfile &profile)
{
    const long long total_rotations = profile.left_rotations + profile.right_rotations;
    const double avg_nontrivial_blocks =
        (profile.outer_iterations > 0)
            ? static_cast<double>(profile.total_nontrivial_blocks) /
                  static_cast<double>(profile.outer_iterations)
            : 0.0;
    const double multiple_block_ratio =
        (profile.outer_iterations > 0)
            ? static_cast<double>(profile.iterations_with_multiple_blocks) /
                  static_cast<double>(profile.outer_iterations)
            : 0.0;
    const double avg_nontrivial_block_size =
        (profile.total_nontrivial_blocks > 0)
            ? static_cast<double>(profile.total_nontrivial_block_sizes) /
                  static_cast<double>(profile.total_nontrivial_blocks)
            : 0.0;

    std::cout << "[gkh-profile]";
    if (rep >= 0)
    {
        std::cout << " rep=" << rep;
    }
    if (has_seed)
    {
        std::cout << " seed=" << seed;
    }
    std::cout << " mode=" << profile.mode
              << " converged=" << (converged ? 1 : 0)
              << " outer_iterations=" << profile.outer_iterations
              << " block_steps=" << profile.block_steps
              << " left_rotations=" << profile.left_rotations
              << " right_rotations=" << profile.right_rotations
              << " total_rotations=" << total_rotations
              << " zero_chase_calls=" << profile.zero_chase_calls
              << " deflations=" << profile.deflations
              << " total_nontrivial_blocks=" << profile.total_nontrivial_blocks
              << " avg_nontrivial_blocks=" << avg_nontrivial_blocks
              << " iterations_with_multiple_blocks=" << profile.iterations_with_multiple_blocks
              << " multiple_block_ratio=" << multiple_block_ratio
              << " max_nontrivial_blocks=" << profile.max_nontrivial_blocks
              << " avg_nontrivial_block_size=" << avg_nontrivial_block_size
              << " max_block_size=" << profile.max_block_size
              << " u_log_count=" << profile.u_log_count
              << " v_log_count=" << profile.v_log_count
              << " logical_log_bytes=" << profile.logical_log_bytes
              << " allocated_log_bytes=" << profile.allocated_log_bytes
              << " log_bytes=" << profile.log_bytes;

    if (profile.mode == 2)
    {
        const double profiled_phase_total_ms = profile.cleanup_ms +
                                               profile.zero_handle_ms +
                                               profile.split_ms +
                                               profile.block_step_ms +
                                               profile.finalize_ms +
                                               profile.transpose_in_ms +
                                               profile.transpose_out_ms +
                                               profile.replay_total_ms;
        const double tuv_extra_ms = profile.transpose_in_ms + profile.transpose_out_ms;
        std::cout << " cleanup_ms=" << profile.cleanup_ms
                  << " zero_handle_ms=" << profile.zero_handle_ms
                  << " split_ms=" << profile.split_ms
                  << " block_step_ms=" << profile.block_step_ms
                  << " finalize_ms=" << profile.finalize_ms
                  << " transpose_in_ms=" << profile.transpose_in_ms
                  << " transpose_out_ms=" << profile.transpose_out_ms
                  << " tuv_extra_ms=" << tuv_extra_ms
                  << " log_generation_ms=" << profile.log_generation_ms
                  << " replay_u_ms=" << profile.replay_u_ms
                  << " replay_v_ms=" << profile.replay_v_ms
                  << " replay_total_ms=" << profile.replay_total_ms
                  << " profiled_phase_total_ms=" << profiled_phase_total_ms;
    }

    std::cout << "\n";
}

static bool run_case(const std::string &name, const Matrix &A,
                     double &sum_bidiag_ms, double &sum_gkh_ms,
                     const std::string &impl,
                     bool gpu_profile,
                     int gkh_profile,
                     const std::string &gkh_layout,
                     bool gkh_uv_update,
                     const std::string &gkh_accum,
                     int replay_threads,
                     int replay_tile_rows)
{
    std::cout << "=== " << name << " ===\n";

    using Clock = std::chrono::high_resolution_clock;

    Matrix U, V;

#ifdef USE_CUDA_BIDIAG
    GpuBidiagStats gpu_stats;
#endif

    const auto t_beg_bidiag = Clock::now();

    Matrix B;
    #ifdef USE_CUDA_BIDIAG
    if (impl == "gpu_kernel")
    {
        B = to_bidiagonal_gpu_kernel(A, U, V, &gpu_stats, gpu_profile);
    }
    else if (impl == "gpu_cublas")
    {
        B = to_bidiagonal_gpu_cublas(A, U, V, &gpu_stats, gpu_profile);
    }
    else
    #endif
    {
        B = to_bidiagonal(A, U, V);
    }

    const auto t_end_bidiag = Clock::now();

    GKHProfile gkh_stats;
    gkh_stats.mode = gkh_profile;
    GKHProfile *gkh_stats_ptr = (gkh_profile > 0) ? &gkh_stats : nullptr;
    const GKHOptions gkh_options = make_gkh_options(gkh_layout, gkh_uv_update,
                                                    gkh_accum, replay_threads,
                                                    replay_tile_rows);

    const auto t_beg_gkh = Clock::now();
    const bool converged = gkh_svd_from_bidiagonal(U, B, V, 6000, 1e-12,
                                                   gkh_stats_ptr, gkh_options);
    const auto t_end_gkh = Clock::now();

    const double time_bidiag_ms = std::chrono::duration<double, std::milli>(t_end_bidiag - t_beg_bidiag).count();
    const double time_gkh_ms = std::chrono::duration<double, std::milli>(t_end_gkh - t_beg_gkh).count();

    sum_bidiag_ms += time_bidiag_ms;
    sum_gkh_ms += time_gkh_ms;

    const double err_recon = reconstruction_error(A, U, B, V);
    const double err_recon_rel = err_recon / (fro_norm(A) + 1.0);
    const double err_u = orth_error(U);
    const double err_v = orth_error(V);
    const double err_diag = diagonal_structure_error(B);
    const double err_order = order_error(B);
    const bool ok_nonneg = nonnegative_diag(B);

    std::cout << "  converged                 : " << (converged ? "yes" : "no") << "\n";
    std::cout << "  ||A-U*S*V^T||_F           : " << err_recon << "\n";
    std::cout << "  relative recon error      : " << err_recon_rel << "\n";
    std::cout << "  ||U^T U-I||_F             : " << err_u << "\n";
    std::cout << "  ||V^T V-I||_F             : " << err_v << "\n";
    std::cout << "  diagonal structure error  : " << err_diag << "\n";
    std::cout << "  descending order error    : " << err_order << "\n";
    std::cout << "  nonnegative diagonal      : " << (ok_nonneg ? "yes" : "no") << "\n";
    std::cout << "  time bidiagonalization(ms): " << time_bidiag_ms << "\n";
    std::cout << "  time gkh iteration(ms)    : " << time_gkh_ms << "\n";
    std::cout << "  gkh profile mode          : " << gkh_profile << "\n";
    std::cout << "  gkh layout                : " << gkh_layout << "\n";
    std::cout << "  gkh uv update             : " << (gkh_uv_update ? 1 : 0) << "\n";
    std::cout << "  gkh accumulation          : " << gkh_accum << "\n";
    std::cout << "  replay threads            : " << replay_threads << "\n";
    std::cout << "  replay tile rows          : " << replay_tile_rows << "\n";
    if (gkh_profile > 0)
    {
        print_gkh_profile_line(-1, 0, false, converged, gkh_stats);
    }
    #ifdef USE_CUDA_BIDIAG
    if (impl == "gpu_kernel" || impl == "gpu_cublas")
    {
        std::cout << "  gpu total inside(ms)      : " << gpu_stats.total_ms << "\n";
        std::cout << "  gpu profile enabled       : " << (gpu_profile ? 1 : 0) << "\n";
        if (gpu_profile)
        {
            std::cout << "  gpu H2D memcpy(ms)        : " << gpu_stats.h2d_ms << "\n";
            std::cout << "  gpu D2H memcpy(ms)        : " << gpu_stats.d2h_ms << "\n";
            std::cout << "  gpu kernel time(ms)       : " << gpu_stats.kernel_ms << "\n";
            std::cout << "  gpu other overhead(ms)    : " << gpu_stats.other_ms << "\n";
        }
        else
        {
            std::cout << "  gpu profile breakdown     : disabled\n";
        }
    }
    #endif
    const double tol_recon_rel = 1e-8;
    const double tol_orth = 1e-7;
    const double tol_diag = 1e-10;
    const double tol_order = 1e-12;

    const bool pass = converged && (err_recon_rel < tol_recon_rel) && (err_u < tol_orth) &&
                      (err_v < tol_orth) && (err_diag < tol_diag) && (err_order < tol_order) && ok_nonneg;

    std::cout << "  结果: " << (pass ? "PASS" : "FAIL") << "\n\n";
    return pass;
}

static bool run_bench_case(int n,
                           long long base_seed,
                           int repeat,
                           bool full_svd,
                           bool verify,
                           const std::string &impl,
                           const std::string &seed_policy,
                           bool gpu_profile,
                           int gkh_profile,
                           const std::string &gkh_layout,
                           bool gkh_uv_update,
                           const std::string &gkh_accum,
                           int replay_threads,
                           int replay_tile_rows)
{
    const bool diagnostic_b_only = full_svd && !gkh_uv_update;
    std::cout << "[bench] impl=" << impl
              << " n=" << n
              << " repeat=" << repeat
              << " seed_policy=" << seed_policy
              << " gpu_profile=" << (gpu_profile ? 1 : 0)
              << " gkh_profile=" << gkh_profile
              << " gkh_layout=" << gkh_layout
              << " gkh_uv_update=" << (gkh_uv_update ? 1 : 0)
              << " gkh_accum=" << gkh_accum
              << " replay_threads=" << replay_threads
              << " replay_tile_rows=" << replay_tile_rows
              << " diagnostic_b_only=" << (diagnostic_b_only ? 1 : 0)
              << " full_svd=" << (full_svd ? 1 : 0)
              << " verify=" << (verify ? 1 : 0)
              << "\n";

    using Clock = std::chrono::high_resolution_clock;

    double sum_bidiag_ms = 0.0;
    double sum_gkh_ms = 0.0;
    double sum_total_ms = 0.0;

    double sum_gpu_total_ms = 0.0;
    double sum_gpu_h2d_ms = 0.0;
    double sum_gpu_d2h_ms = 0.0;
    double sum_gpu_kernel_ms = 0.0;
    double sum_gpu_other_ms = 0.0;

    bool all_pass = true;

    for (int rep = 0; rep < repeat; ++rep)
    {
        const long long actual_seed = bench_actual_seed(base_seed, rep, seed_policy);
        Matrix A = Matrix::random(n, n, -1.0, 1.0, actual_seed);

        Matrix U, V;

#ifdef USE_CUDA_BIDIAG
        GpuBidiagStats gpu_stats;
#endif

        const auto t_beg_bidiag = Clock::now();

        Matrix B;
#ifdef USE_CUDA_BIDIAG
        if (impl == "gpu_kernel")
        {
            B = to_bidiagonal_gpu_kernel(A, U, V, &gpu_stats, gpu_profile);
        }
        else if (impl == "gpu_cublas")
        {
            B = to_bidiagonal_gpu_cublas(A, U, V, &gpu_stats, gpu_profile);
        }
        else
#endif
        {
            B = to_bidiagonal(A, U, V);
        }

        const auto t_end_bidiag = Clock::now();

        double gkh_ms = 0.0;
        bool converged = true;
        GKHProfile gkh_stats;
        gkh_stats.mode = gkh_profile;
        const GKHOptions gkh_options = make_gkh_options(gkh_layout, gkh_uv_update,
                                                        gkh_accum, replay_threads,
                                                        replay_tile_rows);

        if (full_svd)
        {
            GKHProfile *gkh_stats_ptr = (gkh_profile > 0) ? &gkh_stats : nullptr;
            const auto t_beg_gkh = Clock::now();
            converged = gkh_svd_from_bidiagonal(U, B, V, 6000, 1e-12,
                                                gkh_stats_ptr, gkh_options);
            const auto t_end_gkh = Clock::now();
            gkh_ms = std::chrono::duration<double, std::milli>(t_end_gkh - t_beg_gkh).count();

            if (diagnostic_b_only)
            {
                std::cout << "[gkh-diagnostic] rep=" << rep
                          << " seed=" << actual_seed
                          << " uv_updates_skipped=1\n";
            }
            if (gkh_profile > 0)
            {
                print_gkh_profile_line(rep, actual_seed, true, converged, gkh_stats);
            }
        }

        const double bidiag_ms =
            std::chrono::duration<double, std::milli>(t_end_bidiag - t_beg_bidiag).count();

        bool pass = true;

        // 为避免大规模重复矩阵乘法过慢，只在第 1 次 repeat 做 correctness check。
        if (verify && rep == 0)
        {
            const double err_recon = reconstruction_error(A, U, B, V);
            const double err_recon_rel = err_recon / (fro_norm(A) + 1.0);
            const double err_u = orth_error(U);
            const double err_v = orth_error(V);

            if (full_svd)
            {
                const double err_diag = diagonal_structure_error(B);
                const double err_order = order_error(B);
                const bool ok_nonneg = nonnegative_diag(B);

                pass = converged &&
                       (err_recon_rel < 1e-8) &&
                       (err_u < 1e-7) &&
                       (err_v < 1e-7) &&
                       (err_diag < 1e-10) &&
                       (err_order < 1e-12) &&
                       ok_nonneg;

                std::cout << "[bench-verify] rep=" << rep
                          << " rel_recon=" << err_recon_rel
                          << " orth_u=" << err_u
                          << " orth_v=" << err_v
                          << " diag_err=" << err_diag
                          << " order_err=" << err_order
                          << " nonneg=" << (ok_nonneg ? 1 : 0)
                          << " converged=" << (converged ? 1 : 0)
                          << " pass=" << (pass ? 1 : 0)
                          << "\n";
            }
            else
            {
                const double err_bidiag = bidiagonal_structure_error(B);

                pass = (err_recon_rel < 1e-8) &&
                       (err_u < 1e-7) &&
                       (err_v < 1e-7) &&
                       (err_bidiag < 1e-10);

                std::cout << "[bench-verify] rep=" << rep
                          << " rel_recon=" << err_recon_rel
                          << " orth_u=" << err_u
                          << " orth_v=" << err_v
                          << " bidiag_structure_err=" << err_bidiag
                          << " pass=" << (pass ? 1 : 0)
                          << "\n";
            }
        }

        all_pass = all_pass && pass;

        const double total_ms = bidiag_ms + gkh_ms;

        sum_bidiag_ms += bidiag_ms;
        sum_gkh_ms += gkh_ms;
        sum_total_ms += total_ms;

#ifdef USE_CUDA_BIDIAG
        if (impl == "gpu_kernel" || impl == "gpu_cublas")
        {
            sum_gpu_total_ms += gpu_stats.total_ms;
            sum_gpu_h2d_ms += gpu_stats.h2d_ms;
            sum_gpu_d2h_ms += gpu_stats.d2h_ms;
            sum_gpu_kernel_ms += gpu_stats.kernel_ms;
            sum_gpu_other_ms += gpu_stats.other_ms;
        }
#endif

        std::cout << "[bench-run] rep=" << rep
                  << " seed=" << actual_seed
                  << " gpu_profile=" << (gpu_profile ? 1 : 0)
                  << " gkh_profile=" << gkh_profile
                  << " gkh_layout=" << gkh_layout
                  << " gkh_uv_update=" << (gkh_uv_update ? 1 : 0)
                  << " gkh_accum=" << gkh_accum
                  << " replay_threads=" << replay_threads
                  << " replay_tile_rows=" << replay_tile_rows
                  << " diagnostic_b_only=" << (diagnostic_b_only ? 1 : 0)
                  << " bidiag_ms=" << bidiag_ms
                  << " gkh_ms=" << gkh_ms
                  << " total_ms=" << total_ms;

#ifdef USE_CUDA_BIDIAG
        if (impl == "gpu_kernel" || impl == "gpu_cublas")
        {
            std::cout << " gpu_total_ms=" << gpu_stats.total_ms;
            if (gpu_profile)
            {
                std::cout << " gpu_h2d_ms=" << gpu_stats.h2d_ms
                          << " gpu_d2h_ms=" << gpu_stats.d2h_ms
                          << " gpu_kernel_ms=" << gpu_stats.kernel_ms
                          << " gpu_other_ms=" << gpu_stats.other_ms;
            }
            else
            {
                std::cout << " profile_breakdown=disabled";
            }
        }
#endif

        std::cout << "\n";
    }

    const double inv = 1.0 / repeat;

    std::cout << "[bench-summary] impl=" << impl
              << " n=" << n
              << " repeat=" << repeat
              << " seed_policy=" << seed_policy
              << " gpu_profile=" << (gpu_profile ? 1 : 0)
              << " gkh_profile=" << gkh_profile
              << " gkh_layout=" << gkh_layout
              << " gkh_uv_update=" << (gkh_uv_update ? 1 : 0)
              << " gkh_accum=" << gkh_accum
              << " replay_threads=" << replay_threads
              << " replay_tile_rows=" << replay_tile_rows
              << " diagnostic_b_only=" << (diagnostic_b_only ? 1 : 0)
              << " avg_bidiag_ms=" << sum_bidiag_ms * inv
              << " avg_gkh_ms=" << sum_gkh_ms * inv
              << " avg_total_ms=" << sum_total_ms * inv;

#ifdef USE_CUDA_BIDIAG
    if (impl == "gpu_kernel" || impl == "gpu_cublas")
    {
        std::cout << " avg_gpu_total_ms=" << sum_gpu_total_ms * inv;
        if (gpu_profile)
        {
            std::cout << " avg_gpu_h2d_ms=" << sum_gpu_h2d_ms * inv
                      << " avg_gpu_d2h_ms=" << sum_gpu_d2h_ms * inv
                      << " avg_gpu_kernel_ms=" << sum_gpu_kernel_ms * inv
                      << " avg_gpu_other_ms=" << sum_gpu_other_ms * inv;
        }
        else
        {
            std::cout << " profile_breakdown=disabled";
        }
    }
#endif

    std::cout << " pass=" << (all_pass ? 1 : 0) << "\n";

    return all_pass;
}

static bool run_one_gkh_special_case(const std::string &name,
                                     const Matrix &initial_B,
                                     const std::string &gkh_layout,
                                     const std::string &gkh_accum,
                                     int replay_threads,
                                     int replay_tile_rows,
                                     bool require_zero_chase)
{
    Matrix U = identity_matrix(initial_B.rows());
    Matrix V = identity_matrix(initial_B.cols());
    Matrix B = initial_B;
    const Matrix A = initial_B;

    GKHProfile profile;
    profile.mode = 1;
    const GKHOptions options = make_gkh_options(gkh_layout, true, gkh_accum,
                                                replay_threads, replay_tile_rows);

    const bool converged = gkh_svd_from_bidiagonal(U, B, V, 6000, 1e-12,
                                                   &profile, options);

    const double err_recon = reconstruction_error(A, U, B, V);
    const double err_recon_rel = err_recon / (fro_norm(A) + 1.0);
    const double err_u = orth_error(U);
    const double err_v = orth_error(V);
    const double err_diag = diagonal_structure_error(B);
    const double err_order = order_error(B);
    const bool ok_nonneg = nonnegative_diag(B);

    const bool pass = converged &&
                      (err_recon_rel < 1e-8) &&
                      (err_u < 1e-7) &&
                      (err_v < 1e-7) &&
                      (err_diag < 1e-10) &&
                      (err_order < 1e-12) &&
                      ok_nonneg &&
                      (!require_zero_chase || profile.zero_chase_calls > 0) &&
                      (gkh_accum != "deferred" ||
                       (profile.u_log_count == profile.left_rotations &&
                        profile.v_log_count == profile.right_rotations)) &&
                      (!require_zero_chase || gkh_accum != "deferred" ||
                       (profile.u_log_count > 0 && profile.v_log_count > 0));

    std::cout << "[gkh-special] case=" << name
              << " gkh_layout=" << gkh_layout
              << " gkh_accum=" << gkh_accum
              << " replay_threads=" << replay_threads
              << " replay_tile_rows=" << replay_tile_rows
              << " converged=" << (converged ? 1 : 0)
              << " rel_recon=" << err_recon_rel
              << " orth_u=" << err_u
              << " orth_v=" << err_v
              << " diag_err=" << err_diag
              << " order_err=" << err_order
              << " nonneg=" << (ok_nonneg ? 1 : 0)
              << " require_zero_chase=" << (require_zero_chase ? 1 : 0)
              << " zero_chase_calls=" << profile.zero_chase_calls
              << " pass=" << (pass ? 1 : 0)
              << "\n";
    print_gkh_profile_line(-1, 0, false, converged, profile);

    return pass;
}

static bool run_gkh_special_check(const std::string &gkh_layout,
                                  const std::string &gkh_accum,
                                  int replay_threads,
                                  int replay_tile_rows)
{
    bool all_pass = true;

    Matrix zero_chase(4, 4, 0.0);
    zero_chase.at(0, 0) = 0.0;
    zero_chase.at(1, 1) = 3.0;
    zero_chase.at(2, 2) = 2.0;
    zero_chase.at(3, 3) = 1.0;
    zero_chase.at(0, 1) = 1.10;
    zero_chase.at(1, 2) = 0.35;
    zero_chase.at(2, 3) = 0.20;
    all_pass = run_one_gkh_special_case("zero_diagonal_chase", zero_chase,
                                        gkh_layout, gkh_accum, replay_threads,
                                        replay_tile_rows, true) &&
               all_pass;

    Matrix already_diag(5, 5, 0.0);
    already_diag.at(0, 0) = 5.0;
    already_diag.at(1, 1) = 4.0;
    already_diag.at(2, 2) = 3.0;
    already_diag.at(3, 3) = 2.0;
    already_diag.at(4, 4) = 1.0;
    all_pass = run_one_gkh_special_case("already_diagonal", already_diag,
                                        gkh_layout, gkh_accum, replay_threads,
                                        replay_tile_rows, false) &&
               all_pass;

    Matrix two_blocks(6, 6, 0.0);
    two_blocks.at(0, 0) = 6.0;
    two_blocks.at(1, 1) = 5.0;
    two_blocks.at(2, 2) = 4.0;
    two_blocks.at(3, 3) = 3.0;
    two_blocks.at(4, 4) = 2.0;
    two_blocks.at(5, 5) = 1.0;
    two_blocks.at(0, 1) = 0.80;
    two_blocks.at(1, 2) = 0.60;
    two_blocks.at(2, 3) = 0.0;
    two_blocks.at(3, 4) = 0.50;
    two_blocks.at(4, 5) = 0.40;
    all_pass = run_one_gkh_special_case("two_active_blocks", two_blocks,
                                        gkh_layout, gkh_accum, replay_threads,
                                        replay_tile_rows, false) &&
               all_pass;

    std::cout << "[gkh-special-summary] gkh_layout=" << gkh_layout
              << " gkh_accum=" << gkh_accum
              << " replay_threads=" << replay_threads
              << " replay_tile_rows=" << replay_tile_rows
              << " pass=" << (all_pass ? 1 : 0)
              << "\n";
    return all_pass;
}

int main(int argc, char **argv)
{
#ifdef _WIN32
    SetConsoleOutputCP(65001);
#endif

    long long base_seed = 20260408LL;
    std::string impl = "cpu";
    std::string mode = "check";
    int bench_n = 1000;
    int repeat = 1;
    bool full_svd = false;
    bool verify = true;
    std::string seed_policy = "sequence";
    bool gpu_profile = true;
    int gkh_profile = 0;
    std::string gkh_layout = "normal";
    bool gkh_uv_update = true;
    std::string gkh_accum = "immediate";
    int replay_threads = 1;
    int replay_tile_rows = 1;

    for (int i = 1; i < argc; ++i)
    {
        std::string arg = argv[i];

        if (arg == "--impl" && i + 1 < argc)
        {
            impl = argv[++i];
        }
        else if (arg == "--mode" && i + 1 < argc)
        {
            mode = argv[++i];
        }
        else if (arg == "--n" && i + 1 < argc)
        {
            bench_n = std::stoi(argv[++i]);
        }
        else if (arg == "--repeat" && i + 1 < argc)
        {
            repeat = std::stoi(argv[++i]);
        }
        else if (arg == "--full-svd" && i + 1 < argc)
        {
            full_svd = (std::stoi(argv[++i]) != 0);
        }
        else if (arg == "--verify" && i + 1 < argc)
        {
            verify = (std::stoi(argv[++i]) != 0);
        }
        else if (arg == "--seed-policy" && i + 1 < argc)
        {
            seed_policy = argv[++i];
        }
        else if (arg == "--gpu-profile" && i + 1 < argc)
        {
            const int value = std::stoi(argv[++i]);
            if (value != 0 && value != 1)
            {
                std::cerr << "Invalid --gpu-profile value: " << value << "\n";
                std::cerr << "Available values: 0, 1\n";
                return 1;
            }
            gpu_profile = (value != 0);
        }
        else if (arg == "--gkh-profile" && i + 1 < argc)
        {
            gkh_profile = std::stoi(argv[++i]);
            if (gkh_profile < 0 || gkh_profile > 2)
            {
                std::cerr << "Invalid --gkh-profile value: " << gkh_profile << "\n";
                std::cerr << "Available values: 0, 1, 2\n";
                return 1;
            }
        }
        else if (arg == "--gkh-layout" && i + 1 < argc)
        {
            gkh_layout = argv[++i];
        }
        else if (arg == "--gkh-uv-update" && i + 1 < argc)
        {
            const int value = std::stoi(argv[++i]);
            if (value != 0 && value != 1)
            {
                std::cerr << "Invalid --gkh-uv-update value: " << value << "\n";
                std::cerr << "Available values: 0, 1\n";
                return 1;
            }
            gkh_uv_update = (value != 0);
        }
        else if (arg == "--gkh-accum" && i + 1 < argc)
        {
            gkh_accum = argv[++i];
        }
        else if (arg == "--replay-threads" && i + 1 < argc)
        {
            replay_threads = std::stoi(argv[++i]);
        }
        else if (arg == "--replay-tile-rows" && i + 1 < argc)
        {
            replay_tile_rows = std::stoi(argv[++i]);
        }
        else if (arg.rfind("--", 0) == 0)
        {
            std::cerr << "Unknown or incomplete option: " << arg << "\n";
            return 1;
        }
        else
        {
            base_seed = std::stoll(arg);
        }
    }

    if (!valid_seed_policy(seed_policy))
    {
        std::cerr << "Invalid --seed-policy value: " << seed_policy << "\n";
        std::cerr << "Available values: fixed, sequence\n";
        return 1;
    }
    if (!valid_gkh_layout(gkh_layout))
    {
        std::cerr << "Invalid --gkh-layout value: " << gkh_layout << "\n";
        std::cerr << "Available values: normal, tuv\n";
        return 1;
    }
    if (!valid_gkh_accum(gkh_accum))
    {
        std::cerr << "Invalid --gkh-accum value: " << gkh_accum << "\n";
        std::cerr << "Available values: immediate, deferred\n";
        return 1;
    }
    if (replay_threads != 1 && replay_threads != 2 &&
        replay_threads != 4 && replay_threads != 8)
    {
        std::cerr << "Invalid --replay-threads value: " << replay_threads << "\n";
        std::cerr << "Available values: 1, 2, 4, 8\n";
        return 1;
    }
    if (replay_tile_rows <= 0)
    {
        std::cerr << "Invalid --replay-tile-rows value: " << replay_tile_rows << "\n";
        std::cerr << "Value must be positive.\n";
        return 1;
    }
#ifndef _OPENMP
    if (gkh_accum == "deferred" && replay_threads > 1)
    {
        std::cerr << "--replay-threads > 1 requires an OpenMP-enabled build.\n";
        return 1;
    }
#endif

#ifdef USE_CUDA_BIDIAG
    if (impl != "cpu" && impl != "gpu_kernel" && impl != "gpu_cublas")
    {
        std::cerr << "Unknown impl: " << impl << "\n";
        std::cerr << "Available impl: cpu, gpu_kernel, gpu_cublas\n";
        return 1;
    }
#else
    if (impl != "cpu")
    {
        std::cerr << "This executable was built without CUDA support. Use --impl cpu.\n";
        return 1;
    }
#endif

    if (mode != "check" && mode != "bench" && mode != "gkh-special-check")
    {
        std::cerr << "Unknown mode: " << mode << "\n";
        std::cerr << "Available mode: check, bench, gkh-special-check\n";
        return 1;
    }
    if (!gkh_uv_update)
    {
        if (mode != "bench" || !full_svd || verify)
        {
            std::cerr << "--gkh-uv-update 0 is a diagnostic B-only mode and requires "
                      << "--mode bench --full-svd 1 --verify 0\n";
            return 1;
        }
        if (gkh_layout == "tuv")
        {
            std::cerr << "--gkh-layout tuv with --gkh-uv-update 0 is not supported.\n";
            return 1;
        }
    }
    if (gkh_accum == "deferred")
    {
        if (gkh_layout != "normal")
        {
            std::cerr << "--gkh-accum deferred currently supports only --gkh-layout normal.\n";
            return 1;
        }
        if (!gkh_uv_update)
        {
            std::cerr << "--gkh-accum deferred requires --gkh-uv-update 1.\n";
            return 1;
        }
    }

    if (bench_n <= 0 || repeat <= 0)
    {
        std::cerr << "Invalid bench parameters: n and repeat must be positive.\n";
        return 1;
    }

    std::cout << "GKH layout: " << gkh_layout << "\n";
    std::cout << "GKH U/V update: " << (gkh_uv_update ? 1 : 0) << "\n";
    std::cout << "GKH accumulation: " << gkh_accum << "\n";
    std::cout << "Replay threads: " << replay_threads << "\n";
    std::cout << "Replay tile rows: " << replay_tile_rows << "\n";
#ifdef _OPENMP
    std::cout << "[OpenMP] enabled=1\n";
    std::cout << "[OpenMP] max_threads=" << omp_get_max_threads() << "\n";
#else
    std::cout << "[OpenMP] enabled=0\n";
    std::cout << "[OpenMP] max_threads=1\n";
#endif

    if (mode == "gkh-special-check")
    {
        const bool ok = run_gkh_special_check(gkh_layout, gkh_accum,
                                              replay_threads, replay_tile_rows);
        return ok ? 0 : 1;
    }

    std::cout << "实现版本: " << impl << "\n";
#ifdef USE_CUDA_BIDIAG
    if (impl == "gpu_kernel" || impl == "gpu_cublas")
    {
        std::cout << "GPU profiling: " << (gpu_profile ? 1 : 0) << "\n";
        using Clock = std::chrono::high_resolution_clock;
        const auto t0 = Clock::now();
        cuda_bidiag_warmup();
        const auto t1 = Clock::now();
        const double warmup_ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
        std::cout << "CUDA warmup/context init(ms): " << warmup_ms << "\n";
    }
#endif

    if (mode == "bench")
    {
        const bool ok = run_bench_case(bench_n, base_seed, repeat, full_svd, verify,
                                       impl, seed_policy, gpu_profile, gkh_profile,
                                       gkh_layout, gkh_uv_update, gkh_accum,
                                       replay_threads, replay_tile_rows);
        return ok ? 0 : 1;
    }

    int total = 0;
    int passed = 0;
    double sum_bidiag_ms = 0.0;
    double sum_gkh_ms = 0.0;

    // 样例1：5x5 固定值矩阵
    {
        Matrix A(5, 5);
        A.at(0, 0) = 4.0;
        A.at(0, 1) = -1.0;
        A.at(0, 2) = 2.0;
        A.at(0, 3) = 0.5;
        A.at(0, 4) = 3.0;
        A.at(1, 0) = 0.0;
        A.at(1, 1) = 5.0;
        A.at(1, 2) = -2.0;
        A.at(1, 3) = 1.0;
        A.at(1, 4) = -1.5;
        A.at(2, 0) = 1.0;
        A.at(2, 1) = 0.5;
        A.at(2, 2) = 3.0;
        A.at(2, 3) = -4.0;
        A.at(2, 4) = 2.0;
        A.at(3, 0) = -2.0;
        A.at(3, 1) = 1.0;
        A.at(3, 2) = 0.0;
        A.at(3, 3) = 6.0;
        A.at(3, 4) = 1.0;
        A.at(4, 0) = 3.0;
        A.at(4, 1) = -2.0;
        A.at(4, 2) = 1.0;
        A.at(4, 3) = 2.0;
        A.at(4, 4) = 4.0;
        ++total;
        if (run_case("固定值 5x5", A, sum_bidiag_ms, sum_gkh_ms, impl, gpu_profile,
                     gkh_profile, gkh_layout, gkh_uv_update, gkh_accum,
                     replay_threads, replay_tile_rows))
        {
            ++passed;
        }
    }

    // 样例2：8x8 随机矩阵
    {
        Matrix A = Matrix::random(8, 8, -3.0, 3.0, base_seed + 1);
        ++total;
        if (run_case("随机 8x8", A, sum_bidiag_ms, sum_gkh_ms, impl, gpu_profile,
                     gkh_profile, gkh_layout, gkh_uv_update, gkh_accum,
                     replay_threads, replay_tile_rows))
        {
            ++passed;
        }
    }

    // 样例3（新增合适案例）：近秩亏损 10x8 矩阵
    // 构造方式：先随机生成，再让第3列接近第1列，以测试对近相关列的稳定性。
    {
        Matrix A = Matrix::random(10, 8, -2.0, 2.0, base_seed + 2);
        for (int i = 0; i < A.rows(); ++i)
        {
            A.at(i, 2) = A.at(i, 0) + 1e-8 * (i + 1);
        }
        ++total;
        if (run_case("近秩亏损 10x8", A, sum_bidiag_ms, sum_gkh_ms, impl, gpu_profile,
                     gkh_profile, gkh_layout, gkh_uv_update, gkh_accum,
                     replay_threads, replay_tile_rows))
        {
            ++passed;
        }
    }

    // 样例4：10x8 随机矩阵
    {
        Matrix A = Matrix::random(10, 8, -4.0, 4.0, base_seed + 3);
        ++total;
        if (run_case("随机 10x8", A, sum_bidiag_ms, sum_gkh_ms, impl, gpu_profile,
                     gkh_profile, gkh_layout, gkh_uv_update, gkh_accum,
                     replay_threads, replay_tile_rows))
        {
            ++passed;
        }
    }

    // 样例5：大规模 1000x1000 随机矩阵
    {
        Matrix A = Matrix::random(1000, 1000, -1.0, 1.0, base_seed + 4);
        ++total;
        if (run_case("随机 1000x1000", A, sum_bidiag_ms, sum_gkh_ms, impl, gpu_profile,
                     gkh_profile, gkh_layout, gkh_uv_update, gkh_accum,
                     replay_threads, replay_tile_rows))
        {
            ++passed;
        }
    }

    std::cout << "==============================\n";
    std::cout << "随机种子基值: " << base_seed << "\n";
    std::cout << "总上二对角化耗时(ms): " << sum_bidiag_ms << "\n";
    std::cout << "总GKH迭代耗时(ms): " << sum_gkh_ms << "\n";
    std::cout << "通过: " << passed << " / " << total << "\n";
    return (passed == total) ? 0 : 1;
}
