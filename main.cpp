#include "matrix.h"
#include "gkh.h"
#include "gkh_mpi.h"
#include "bidiagonalization.h"

#include <mpi.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <string>

#ifdef _WIN32
#include <windows.h>
#endif

struct Args
{
    std::string mode = "check";        // check / bench
    std::string impl = "serial_simd";  // serial_simd / mpi_blocking
    int n = 256;
    long long seed = 20260408LL;
    int repeat = 1;
    int sweep_cap = 1;
    int profile = 1;
    int master_work = 0;
    int omp_threads = 1;
};

static Args parse_args(int argc, char **argv)
{
    Args args;
    for (int i = 1; i < argc; ++i)
    {
        std::string s = argv[i];
        auto need_value = [&](const std::string &name) {
            if (i + 1 >= argc)
            {
                throw std::runtime_error("missing value for " + name);
            }
            return std::string(argv[++i]);
        };

        if (s == "--mode")
        {
            args.mode = need_value(s);
        }
        else if (s == "--impl")
        {
            args.impl = need_value(s);
        }
        else if (s == "--n")
        {
            args.n = std::stoi(need_value(s));
        }
        else if (s == "--seed")
        {
            args.seed = std::stoll(need_value(s));
        }
        else if (s == "--repeat")
        {
            args.repeat = std::stoi(need_value(s));
        }
        else if (s == "--sweep-cap")
        {
            args.sweep_cap = std::stoi(need_value(s));
        }
        else if (s == "--profile")
        {
            args.profile = std::stoi(need_value(s));
        }
        else if (s == "--master-work")
        {
            args.master_work = std::stoi(need_value(s));
        }
        else if (s == "--omp-threads")
        {
            args.omp_threads = std::stoi(need_value(s));
        }
        else
        {
            throw std::runtime_error("unknown argument: " + s);
        }
    }
    return args;
}

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

static double order_error(const Matrix &S)
{
    const int n = S.cols();
    double worst = 0.0;
    for (int i = 0; i < n - 1; ++i)
    {
        const double cur = S.at(i, i);
        const double nxt = S.at(i + 1, i + 1);
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

static bool run_case(const std::string &name,
                     const Matrix &A_root,
                     const Args &args,
                     int world_rank,
                     int world_size,
                     double &sum_bidiag_ms,
                     double &sum_gkh_ms)
{
    if (world_rank == 0)
    {
        std::cout << "=== " << name << " ===\n";
    }

    Matrix U, V, B;
    bool converged = false;

    double time_bidiag_ms = 0.0;
    double time_gkh_ms = 0.0;

    Lab4MPIStats mpi_stats;

    if (args.impl == "serial_simd")
    {
        if (world_size != 1 && world_rank == 0)
        {
            std::cout << "[warning] impl=serial_simd is intended for -np 1; only rank 0 will compute.\n";
        }

        if (world_rank == 0)
        {
            using Clock = std::chrono::high_resolution_clock;

            const auto t_beg_bidiag = Clock::now();
            B = to_bidiagonal(A_root, U, V);
            const auto t_end_bidiag = Clock::now();

            const auto t_beg_gkh = Clock::now();
            converged = gkh_svd_from_bidiagonal(U, B, V, 6000, 1e-12);
            const auto t_end_gkh = Clock::now();

            time_bidiag_ms =
                std::chrono::duration<double, std::milli>(t_end_bidiag - t_beg_bidiag).count();
            time_gkh_ms =
                std::chrono::duration<double, std::milli>(t_end_gkh - t_beg_gkh).count();

            sum_bidiag_ms += time_bidiag_ms;
            sum_gkh_ms += time_gkh_ms;
        }
    }
    else if (args.impl == "mpi_blocking")
    {
        if (world_rank == 0)
        {
            using Clock = std::chrono::high_resolution_clock;
            const auto t_beg_bidiag = Clock::now();
            B = to_bidiagonal(A_root, U, V);
            const auto t_end_bidiag = Clock::now();

            time_bidiag_ms =
                std::chrono::duration<double, std::milli>(t_end_bidiag - t_beg_bidiag).count();
            sum_bidiag_ms += time_bidiag_ms;
        }

        MPI_Barrier(MPI_COMM_WORLD);

        Lab4MPIOptions opts;
        opts.max_iter = 6000;
        opts.tol = 1e-12;
        opts.sweep_cap = args.sweep_cap;
        opts.profile = (args.profile != 0);
        opts.master_work = (args.master_work != 0);
        opts.omp_threads = args.omp_threads;

        const double t0 = MPI_Wtime();
        converged = gkh_svd_from_bidiagonal_mpi_blocking(U, B, V, opts, &mpi_stats);
        MPI_Barrier(MPI_COMM_WORLD);
        const double t1 = MPI_Wtime();

        if (world_rank == 0)
        {
            time_gkh_ms = (t1 - t0) * 1000.0;
            sum_gkh_ms += time_gkh_ms;
        }
    }
    else
    {
        if (world_rank == 0)
        {
            std::cerr << "Unknown impl: " << args.impl << "\n";
        }
        MPI_Abort(MPI_COMM_WORLD, 2);
    }

    if (world_rank != 0)
    {
        return true;
    }

    const double err_recon = reconstruction_error(A_root, U, B, V);
    const double err_recon_rel = err_recon / (fro_norm(A_root) + 1.0);
    const double err_u = orth_error(U);
    const double err_v = orth_error(V);
    const double err_diag = diagonal_structure_error(B);
    const double err_order = order_error(B);
    const bool ok_nonneg = nonnegative_diag(B);

    if (args.mode == "check")
    {
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

        if (args.impl == "mpi_blocking")
        {
            std::cout << "  mpi dispatch_ms           : " << mpi_stats.dispatch_ms << "\n";
            std::cout << "  mpi worker_compute_ms     : " << mpi_stats.worker_compute_ms << "\n";
            std::cout << "  mpi merge_ms              : " << mpi_stats.merge_ms << "\n";
            std::cout << "  mpi total_ms              : " << mpi_stats.total_ms << "\n";
            std::cout << "  mpi tasks_sent            : " << mpi_stats.tasks_sent << "\n";
            std::cout << "  mpi tasks_done            : " << mpi_stats.tasks_done << "\n";
        }
    }
    else
    {
        std::cout << "[bench] "
                  << "impl=" << args.impl << " "
                  << "n=" << A_root.rows() << " "
                  << "seed=" << args.seed << " "
                  << "converged=" << (converged ? "yes" : "no") << " "
                  << "bidiag_ms=" << time_bidiag_ms << " "
                  << "gkh_ms=" << time_gkh_ms << " "
                  << "recon_rel=" << err_recon_rel << " "
                  << "orth_u=" << err_u << " "
                  << "orth_v=" << err_v << " "
                  << "diag_err=" << err_diag << " "
                  << "order_err=" << err_order << " "
                  << "nonneg=" << (ok_nonneg ? "yes" : "no");

        if (args.impl == "mpi_blocking")
        {
            std::cout << " "
                      << "dispatch_ms=" << mpi_stats.dispatch_ms << " "
                      << "worker_compute_ms=" << mpi_stats.worker_compute_ms << " "
                      << "merge_ms=" << mpi_stats.merge_ms << " "
                      << "mpi_total_ms=" << mpi_stats.total_ms << " "
                      << "tasks_sent=" << mpi_stats.tasks_sent << " "
                      << "tasks_done=" << mpi_stats.tasks_done;
        }
        std::cout << "\n";
    }

    const double tol_recon_rel = 1e-8;
    const double tol_orth = 1e-7;
    const double tol_diag = 1e-10;
    const double tol_order = 1e-12;

    const bool pass = converged &&
                      (err_recon_rel < tol_recon_rel) &&
                      (err_u < tol_orth) &&
                      (err_v < tol_orth) &&
                      (err_diag < tol_diag) &&
                      (err_order < tol_order) &&
                      ok_nonneg;

    if (args.mode == "check")
    {
        std::cout << "  结果: " << (pass ? "PASS" : "FAIL") << "\n\n";
    }

    return pass;
}

int main(int argc, char **argv)
{
#ifdef _WIN32
    SetConsoleOutputCP(65001);
#endif

    MPI_Init(&argc, &argv);

    int world_size = 1;
    int world_rank = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    int exit_code = 0;

    try
    {
        const Args args = parse_args(argc, argv);

        if (args.mode != "check" && args.mode != "bench")
        {
            throw std::runtime_error("mode must be check or bench");
        }

        int total = 0;
        int passed = 0;
        double sum_bidiag_ms = 0.0;
        double sum_gkh_ms = 0.0;

        if (args.mode == "check")
        {
            {
                Matrix A;
                if (world_rank == 0)
                {
                    A.resize(5, 5, 0.0);
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
                }
                const bool ok = run_case("固定值 5x5", A, args, world_rank, world_size,
                                         sum_bidiag_ms, sum_gkh_ms);
                if (world_rank == 0)
                {
                    ++total;
                    if (ok)
                    {
                        ++passed;
                    }
                }
            }

            {
                Matrix A;
                if (world_rank == 0)
                {
                    A = Matrix::random(8, 8, -3.0, 3.0, args.seed + 1);
                }
                const bool ok = run_case("随机 8x8", A, args, world_rank, world_size,
                                         sum_bidiag_ms, sum_gkh_ms);
                if (world_rank == 0)
                {
                    ++total;
                    if (ok)
                    {
                        ++passed;
                    }
                }
            }

            {
                Matrix A;
                if (world_rank == 0)
                {
                    A = Matrix::random(10, 8, -2.0, 2.0, args.seed + 2);
                    for (int i = 0; i < A.rows(); ++i)
                    {
                        A.at(i, 2) = A.at(i, 0) + 1e-8 * (i + 1);
                    }
                }
                const bool ok = run_case("近秩亏损 10x8", A, args, world_rank, world_size,
                                         sum_bidiag_ms, sum_gkh_ms);
                if (world_rank == 0)
                {
                    ++total;
                    if (ok)
                    {
                        ++passed;
                    }
                }
            }

            {
                Matrix A;
                if (world_rank == 0)
                {
                    A = Matrix::random(10, 8, -4.0, 4.0, args.seed + 3);
                }
                const bool ok = run_case("随机 10x8", A, args, world_rank, world_size,
                                         sum_bidiag_ms, sum_gkh_ms);
                if (world_rank == 0)
                {
                    ++total;
                    if (ok)
                    {
                        ++passed;
                    }
                }
            }

            {
                Matrix A;
                if (world_rank == 0)
                {
                    A = Matrix::random(1000, 1000, -1.0, 1.0, args.seed + 4);
                }
                const bool ok = run_case("随机 1000x1000", A, args, world_rank, world_size,
                                         sum_bidiag_ms, sum_gkh_ms);
                if (world_rank == 0)
                {
                    ++total;
                    if (ok)
                    {
                        ++passed;
                    }
                }
            }

            if (world_rank == 0)
            {
                std::cout << "==============================\n";
                std::cout << "mode: " << args.mode << "\n";
                std::cout << "impl: " << args.impl << "\n";
                std::cout << "seed: " << args.seed << "\n";
                std::cout << "total bidiagonalization(ms): " << sum_bidiag_ms << "\n";
                std::cout << "total gkh(ms): " << sum_gkh_ms << "\n";
                std::cout << "passed: " << passed << " / " << total << "\n";
                exit_code = (passed == total) ? 0 : 1;
            }
        }
        else
        {
            double bench_bidiag_sum = 0.0;
            double bench_gkh_sum = 0.0;
            int bench_passed = 0;

            for (int rep = 0; rep < args.repeat; ++rep)
            {
                Matrix A;
                if (world_rank == 0)
                {
                    A = Matrix::random(args.n, args.n, -1.0, 1.0, args.seed + rep);
                }

                Args rep_args = args;
                rep_args.seed = args.seed + rep;

                const bool ok = run_case("bench-rep-" + std::to_string(rep), A, rep_args,
                                         world_rank, world_size, bench_bidiag_sum, bench_gkh_sum);
                if (world_rank == 0 && ok)
                {
                    ++bench_passed;
                }
            }

            if (world_rank == 0)
            {
                std::cout << "==============================\n";
                std::cout << "[bench-summary] "
                          << "impl=" << args.impl << " "
                          << "n=" << args.n << " "
                          << "repeat=" << args.repeat << " "
                          << "avg_bidiag_ms=" << (bench_bidiag_sum / std::max(1, args.repeat)) << " "
                          << "avg_gkh_ms=" << (bench_gkh_sum / std::max(1, args.repeat)) << " "
                          << "passed=" << bench_passed << "/" << args.repeat
                          << "\n";
                exit_code = (bench_passed == args.repeat) ? 0 : 1;
            }
        }
    }
    catch (const std::exception &e)
    {
        if (world_rank == 0)
        {
            std::cerr << "Error: " << e.what() << "\n";
        }
        exit_code = 1;
    }

    MPI_Finalize();
    return exit_code;
}