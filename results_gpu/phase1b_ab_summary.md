# 1. Current State And Anomaly Background

Repository: `E:\Parallel-Course-Experiments`. Branch: `svd-lab5-gpu`. HEAD: `c08f9d7`. Phase 1 source changes and `main_gpu.exe` are still uncommitted. This run did not create or switch branches, did not commit, and did not delete existing result files.

Background: prior phase1 fixed-input profile-off results were much slower than the older report. Old report at n=1000 Householder-only was roughly CPU 2226 ms, gpu_kernel 530 ms, gpu_cublas 490 ms. Phase1 had CPU 2830 ms, gpu_kernel 2105 ms, gpu_cublas 1725 ms. This phase1b run built c08f9d7 in a temporary worktree and compared it against the current executable with seed-equivalent input `20261408`.

# 2. New Vs Old Source Diff Audit

Call/token counts in `bidiagonalization_gpu.cu`:

```text
old:
  cudaEventCreate: 2 lines 53,54
  cudaEventSynchronize: 1 line 59
  cudaDeviceSynchronize: 0
  cudaMemcpy token count: 22; semantically 20 timed_cuda_memcpy call sites plus helper signature/body
  cudaGetLastError: 1 line 57
  cublasDgemv: 4 lines 608,635,713,739
  cublasDger: 4 lines 621,648,726,752
  CUDA_LAUNCH_TIMED: 25 occurrences including macro definition
current:
  cudaEventCreate: 2 lines 55,56, profile-on branch only
  cudaEventSynchronize: 1 line 61, profile-on branch only
  cudaDeviceSynchronize: 0
  cudaMemcpy token count: 23; semantically the same 20 copy call sites, plus helper signature and two branch bodies
  cudaGetLastError: 2 lines 59,71; exactly one branch executes per wrapped launch
  cublasDgemv: 4 lines 629,656,734,760
  cublasDger: 4 lines 642,669,747,773
  CUDA_LAUNCH_PROFILED: 25 occurrences including macro definition
```

Pure timing-structure changes: `CUDA_LAUNCH_TIMED` became `CUDA_LAUNCH_PROFILED(enable_profile, ...)`. The profile-on branch preserves the old ordering: create events, record start, execute the original kernel/cuBLAS expression, `cudaGetLastError`, record stop, `cudaEventSynchronize(stop)`, elapsed time, accumulate, destroy events. The profile-off branch executes the original expression and `cudaGetLastError` only.

Performance-only changes: profile-off removes per-call event synchronization, so it is expected to be faster while preserving math. H2D/D2H/kernel/other split fields are not reported as meaningful values in profile-off. `build_gpu.bat` adds host `/O2`; controlled old_host_o2 results do not show a regression from it.

Accidental algorithm changes: none found. Launch wrapper occurrence count is unchanged, cuBLAS call counts are unchanged, copy call sites are unchanged, no `cudaDeviceSynchronize` was introduced, and total timer boundaries remain function-entry to after D2H/free/destroy. `enable_profile` is passed as `(stats, enable_profile)` and defaults to `true`, so old-style calls remain compatible.

Audit conclusion: no source-level bug was found that can explain a 3-4x slowdown.

# 3. Build Matrix

old_original used the original c08f9d7 command:

```bat
nvcc -O2 -arch=sm_89 -std=c++17 ^
    -Xcompiler /utf-8 ^
    -Xcompiler /EHsc ^
    -Xcompiler /DNOMINMAX ^
    -DUSE_CUDA_BIDIAG ^
    main.cpp gkh.cpp bidiagonalization.cpp bidiagonalization_gpu.cu ^
    -I"%CUDA_PATH%\include" ^
    -L"%CUDA_PATH%\lib\x64" ^
    -lcublas ^
    -o main_gpu.exe
```

old_host_o2 used identical old source, with this extra line in the temporary worktree build script:

```bat
-Xcompiler /O2 ^
```

current used the repository root `main_gpu.exe`, built from the phase1 source and current `build_gpu.bat` containing both nvcc `-O2` and host `-Xcompiler /O2`. Temporary worktree `%TEMP%\svd_gpu_c08f9d7` was removed and pruned after testing.

# 4. Environment Information

Environment log: `results_gpu\phase1b_environment_before.txt`.

- Timestamp before run: 2026-07-12T03:01:18+08:00
- Windows power scheme: Balanced
- GPU: NVIDIA GeForce RTX 4060 Laptop GPU
- Driver: 560.94; nvidia-smi CUDA version display: 12.6; WDDM mode
- Initial GPU state: P5, 48 C, about 7.41 W, SM 510 MHz, memory 810 MHz, memory used about 1111 MiB
- Visible graphics/background users included Weixin, wallpaper_engine, Explorer, Edge, WindowsTerminal, NVIDIA Share, etc. `nvidia-smi pmon` is unsupported on this configuration.
- AC status could not be reliably read from WMI; no battery object was returned.

Telemetry `phase1b_gpu_telemetry.csv`: 111 rows. P-state counts: {'P3': 43, 'P8': 47, 'P0': 7, 'P5': 14}. Temperature min=46.00, max=51.00, mean=49.04 C. Power min=4.04, max=16.12, mean=9.34 W. SM clocks min=210.00, max=1890.00, mean=965.95 MHz. Memory clocks min=405.00, max=8000.00, mean=3374.68 MHz. GPU utilization min=0.00, max=23.00, mean=3.68%.

# 5. CPU A/B Results

| version | mean | median | min | max | stddev | CV | ratio_vs_old | pass | verify |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| old_original | 1771.304 | 1755.480 | 1742.890 | 1834.110 | 37.722 | 2.13% | 1.000 | 1 | 1 |
| old_host_o2 | 1791.410 | 1801.190 | 1709.740 | 1881.200 | 63.057 | 3.52% | 1.026 | 1 | 1 |
| current | 1822.484 | 1808.970 | 1765.490 | 1908.770 | 54.845 | 3.01% | 1.030 | 1 | 1 |

# 6. gpu_kernel A/B Results

| version | profile | mean | median | min | max | stddev | CV | ratio_vs_old | pass | verify |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| old_original | old | 472.220 | 469.270 | 467.281 | 482.068 | 6.070 | 1.29% | 1.000 | 1 | 1 |
| old_host_o2 | old+hostO2 | 474.606 | 466.195 | 465.905 | 508.622 | 19.017 | 4.01% | 0.993 | 1 | 1 |
| current_profile0 | off | 293.933 | 293.433 | 287.884 | 299.303 | 4.640 | 1.58% | 0.625 | 1 | 1 |
| current_profile1 | on | 478.789 | 479.628 | 470.375 | 486.800 | 7.636 | 1.59% | 1.022 | 1 | 1 |

# 7. gpu_cublas A/B Results

| version | profile | mean | median | min | max | stddev | CV | ratio_vs_old | pass | verify |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| old_original | old | 451.378 | 449.675 | 442.132 | 466.781 | 10.248 | 2.27% | 1.000 | 1 | 1 |
| old_host_o2 | old+hostO2 | 448.791 | 449.931 | 443.757 | 453.239 | 3.696 | 0.82% | 1.001 | 1 | 1 |
| current_profile0 | off | 254.022 | 251.558 | 248.748 | 265.940 | 6.812 | 2.68% | 0.559 | 1 | 1 |
| current_profile1 | on | 446.140 | 448.326 | 438.373 | 449.541 | 4.525 | 1.01% | 0.997 | 1 | 1 |

# 8. Raw Summary Lines

```text
phase1b_current_cpu_run1.txt: [bench-summary] impl=cpu n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=1808.97 avg_gkh_ms=0 avg_total_ms=1808.97 pass=1
phase1b_current_cpu_run2.txt: [bench-summary] impl=cpu n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=1837.3 avg_gkh_ms=0 avg_total_ms=1837.3 pass=1
phase1b_current_cpu_run3.txt: [bench-summary] impl=cpu n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=1791.89 avg_gkh_ms=0 avg_total_ms=1791.89 pass=1
phase1b_current_cpu_run4.txt: [bench-summary] impl=cpu n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=1765.49 avg_gkh_ms=0 avg_total_ms=1765.49 pass=1
phase1b_current_cpu_run5.txt: [bench-summary] impl=cpu n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=1908.77 avg_gkh_ms=0 avg_total_ms=1908.77 pass=1
phase1b_current_cublas_profile0_run1.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=251.558 avg_gkh_ms=0 avg_total_ms=251.558 avg_gpu_total_ms=251.542 profile_breakdown=disabled pass=1
phase1b_current_cublas_profile0_run2.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=248.748 avg_gkh_ms=0 avg_total_ms=248.748 avg_gpu_total_ms=248.733 profile_breakdown=disabled pass=1
phase1b_current_cublas_profile0_run3.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=265.94 avg_gkh_ms=0 avg_total_ms=265.94 avg_gpu_total_ms=265.921 profile_breakdown=disabled pass=1
phase1b_current_cublas_profile0_run4.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=252.625 avg_gkh_ms=0 avg_total_ms=252.625 avg_gpu_total_ms=252.611 profile_breakdown=disabled pass=1
phase1b_current_cublas_profile0_run5.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=251.241 avg_gkh_ms=0 avg_total_ms=251.241 avg_gpu_total_ms=251.22 profile_breakdown=disabled pass=1
phase1b_current_cublas_profile1_run1.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=448.426 avg_gkh_ms=0 avg_total_ms=448.426 avg_gpu_total_ms=448.409 avg_gpu_h2d_ms=21.2465 avg_gpu_d2h_ms=33.7642 avg_gpu_kernel_ms=202.163 avg_gpu_other_ms=191.235 pass=1
phase1b_current_cublas_profile1_run2.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=438.373 avg_gkh_ms=0 avg_total_ms=438.373 avg_gpu_total_ms=438.358 avg_gpu_h2d_ms=20.9137 avg_gpu_d2h_ms=33.3468 avg_gpu_kernel_ms=202.283 avg_gpu_other_ms=181.814 pass=1
phase1b_current_cublas_profile1_run3.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=446.034 avg_gkh_ms=0 avg_total_ms=446.034 avg_gpu_total_ms=446.015 avg_gpu_h2d_ms=20.6789 avg_gpu_d2h_ms=33.9534 avg_gpu_kernel_ms=204.996 avg_gpu_other_ms=186.387 pass=1
phase1b_current_cublas_profile1_run4.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=448.326 avg_gkh_ms=0 avg_total_ms=448.326 avg_gpu_total_ms=448.307 avg_gpu_h2d_ms=19.4945 avg_gpu_d2h_ms=34.5535 avg_gpu_kernel_ms=202.45 avg_gpu_other_ms=191.809 pass=1
phase1b_current_cublas_profile1_run5.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=449.541 avg_gkh_ms=0 avg_total_ms=449.541 avg_gpu_total_ms=449.525 avg_gpu_h2d_ms=19.8521 avg_gpu_d2h_ms=34.149 avg_gpu_kernel_ms=202.839 avg_gpu_other_ms=192.685 pass=1
phase1b_current_kernel_profile0_run1.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=287.884 avg_gkh_ms=0 avg_total_ms=287.884 avg_gpu_total_ms=287.867 profile_breakdown=disabled pass=1
phase1b_current_kernel_profile0_run2.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=299.303 avg_gkh_ms=0 avg_total_ms=299.303 avg_gpu_total_ms=299.284 profile_breakdown=disabled pass=1
phase1b_current_kernel_profile0_run3.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=297.664 avg_gkh_ms=0 avg_total_ms=297.664 avg_gpu_total_ms=297.653 profile_breakdown=disabled pass=1
phase1b_current_kernel_profile0_run4.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=291.381 avg_gkh_ms=0 avg_total_ms=291.381 avg_gpu_total_ms=291.367 profile_breakdown=disabled pass=1
phase1b_current_kernel_profile0_run5.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=0 avg_bidiag_ms=293.433 avg_gkh_ms=0 avg_total_ms=293.433 avg_gpu_total_ms=293.423 profile_breakdown=disabled pass=1
phase1b_current_kernel_profile1_run1.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=486.8 avg_gkh_ms=0 avg_total_ms=486.8 avg_gpu_total_ms=486.788 avg_gpu_h2d_ms=27.5199 avg_gpu_d2h_ms=32.8903 avg_gpu_kernel_ms=234.836 avg_gpu_other_ms=191.541 pass=1
phase1b_current_kernel_profile1_run2.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=485.55 avg_gkh_ms=0 avg_total_ms=485.55 avg_gpu_total_ms=485.538 avg_gpu_h2d_ms=25.2086 avg_gpu_d2h_ms=34.2297 avg_gpu_kernel_ms=236.232 avg_gpu_other_ms=189.868 pass=1
phase1b_current_kernel_profile1_run3.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=471.59 avg_gkh_ms=0 avg_total_ms=471.59 avg_gpu_total_ms=471.571 avg_gpu_h2d_ms=25.3378 avg_gpu_d2h_ms=34.1814 avg_gpu_kernel_ms=235.131 avg_gpu_other_ms=176.921 pass=1
phase1b_current_kernel_profile1_run4.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=470.375 avg_gkh_ms=0 avg_total_ms=470.375 avg_gpu_total_ms=470.362 avg_gpu_h2d_ms=27.4795 avg_gpu_d2h_ms=32.8266 avg_gpu_kernel_ms=231.483 avg_gpu_other_ms=178.573 pass=1
phase1b_current_kernel_profile1_run5.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 seed_policy=fixed gpu_profile=1 avg_bidiag_ms=479.628 avg_gkh_ms=0 avg_total_ms=479.628 avg_gpu_total_ms=479.618 avg_gpu_h2d_ms=27.7774 avg_gpu_d2h_ms=33.2505 avg_gpu_kernel_ms=236.709 avg_gpu_other_ms=181.881 pass=1
phase1b_old_host_o2_cpu_run1.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1709.74 avg_gkh_ms=0 avg_total_ms=1709.74 pass=1
phase1b_old_host_o2_cpu_run2.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1761.05 avg_gkh_ms=0 avg_total_ms=1761.05 pass=1
phase1b_old_host_o2_cpu_run3.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1803.87 avg_gkh_ms=0 avg_total_ms=1803.87 pass=1
phase1b_old_host_o2_cpu_run4.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1801.19 avg_gkh_ms=0 avg_total_ms=1801.19 pass=1
phase1b_old_host_o2_cpu_run5.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1881.2 avg_gkh_ms=0 avg_total_ms=1881.2 pass=1
phase1b_old_host_o2_cublas_run1.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=449.931 avg_gkh_ms=0 avg_total_ms=449.931 avg_gpu_total_ms=449.928 avg_gpu_h2d_ms=21.8433 avg_gpu_d2h_ms=34.2077 avg_gpu_kernel_ms=204.886 avg_gpu_other_ms=188.991 pass=1
phase1b_old_host_o2_cublas_run2.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=443.757 avg_gkh_ms=0 avg_total_ms=443.757 avg_gpu_total_ms=443.754 avg_gpu_h2d_ms=20.2911 avg_gpu_d2h_ms=34.6485 avg_gpu_kernel_ms=204.686 avg_gpu_other_ms=184.128 pass=1
phase1b_old_host_o2_cublas_run3.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=450.524 avg_gkh_ms=0 avg_total_ms=450.524 avg_gpu_total_ms=450.521 avg_gpu_h2d_ms=20.4392 avg_gpu_d2h_ms=34.2104 avg_gpu_kernel_ms=207.451 avg_gpu_other_ms=188.42 pass=1
phase1b_old_host_o2_cublas_run4.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=446.505 avg_gkh_ms=0 avg_total_ms=446.505 avg_gpu_total_ms=446.502 avg_gpu_h2d_ms=20.6217 avg_gpu_d2h_ms=33.4488 avg_gpu_kernel_ms=203.211 avg_gpu_other_ms=189.221 pass=1
phase1b_old_host_o2_cublas_run5.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=453.239 avg_gkh_ms=0 avg_total_ms=453.239 avg_gpu_total_ms=453.236 avg_gpu_h2d_ms=22.1913 avg_gpu_d2h_ms=33.5694 avg_gpu_kernel_ms=205.503 avg_gpu_other_ms=191.973 pass=1
phase1b_old_host_o2_kernel_run1.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=508.622 avg_gkh_ms=0 avg_total_ms=508.622 avg_gpu_total_ms=508.597 avg_gpu_h2d_ms=25.5794 avg_gpu_d2h_ms=33.6052 avg_gpu_kernel_ms=246.589 avg_gpu_other_ms=202.824 pass=1
phase1b_old_host_o2_kernel_run2.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=466.195 avg_gkh_ms=0 avg_total_ms=466.195 avg_gpu_total_ms=466.184 avg_gpu_h2d_ms=26.2435 avg_gpu_d2h_ms=33.0887 avg_gpu_kernel_ms=227.701 avg_gpu_other_ms=179.151 pass=1
phase1b_old_host_o2_kernel_run3.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=465.905 avg_gkh_ms=0 avg_total_ms=465.905 avg_gpu_total_ms=465.893 avg_gpu_h2d_ms=26.7382 avg_gpu_d2h_ms=33.0239 avg_gpu_kernel_ms=226.762 avg_gpu_other_ms=179.369 pass=1
phase1b_old_host_o2_kernel_run4.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=466.394 avg_gkh_ms=0 avg_total_ms=466.394 avg_gpu_total_ms=466.384 avg_gpu_h2d_ms=26.8017 avg_gpu_d2h_ms=32.8693 avg_gpu_kernel_ms=229.317 avg_gpu_other_ms=177.396 pass=1
phase1b_old_host_o2_kernel_run5.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=465.912 avg_gkh_ms=0 avg_total_ms=465.912 avg_gpu_total_ms=465.901 avg_gpu_h2d_ms=25.1349 avg_gpu_d2h_ms=32.1957 avg_gpu_kernel_ms=232.056 avg_gpu_other_ms=176.514 pass=1
phase1b_old_original_cpu_run1.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1755.48 avg_gkh_ms=0 avg_total_ms=1755.48 pass=1
phase1b_old_original_cpu_run2.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1834.11 avg_gkh_ms=0 avg_total_ms=1834.11 pass=1
phase1b_old_original_cpu_run3.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1778.1 avg_gkh_ms=0 avg_total_ms=1778.1 pass=1
phase1b_old_original_cpu_run4.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1745.94 avg_gkh_ms=0 avg_total_ms=1745.94 pass=1
phase1b_old_original_cpu_run5.txt: [bench-summary] impl=cpu n=1000 repeat=1 avg_bidiag_ms=1742.89 avg_gkh_ms=0 avg_total_ms=1742.89 pass=1
phase1b_old_original_cublas_run1.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=442.132 avg_gkh_ms=0 avg_total_ms=442.132 avg_gpu_total_ms=442.129 avg_gpu_h2d_ms=20.4169 avg_gpu_d2h_ms=34.1407 avg_gpu_kernel_ms=201.081 avg_gpu_other_ms=186.49 pass=1
phase1b_old_original_cublas_run2.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=455.651 avg_gkh_ms=0 avg_total_ms=455.651 avg_gpu_total_ms=455.647 avg_gpu_h2d_ms=19.4312 avg_gpu_d2h_ms=34.4369 avg_gpu_kernel_ms=206.482 avg_gpu_other_ms=195.297 pass=1
phase1b_old_original_cublas_run3.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=449.675 avg_gkh_ms=0 avg_total_ms=449.675 avg_gpu_total_ms=449.671 avg_gpu_h2d_ms=21.5132 avg_gpu_d2h_ms=34.0489 avg_gpu_kernel_ms=203.686 avg_gpu_other_ms=190.423 pass=1
phase1b_old_original_cublas_run4.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=466.781 avg_gkh_ms=0 avg_total_ms=466.781 avg_gpu_total_ms=466.778 avg_gpu_h2d_ms=21.1263 avg_gpu_d2h_ms=36.0286 avg_gpu_kernel_ms=215.076 avg_gpu_other_ms=194.547 pass=1
phase1b_old_original_cublas_run5.txt: [bench-summary] impl=gpu_cublas n=1000 repeat=1 avg_bidiag_ms=442.65 avg_gkh_ms=0 avg_total_ms=442.65 avg_gpu_total_ms=442.648 avg_gpu_h2d_ms=22.4722 avg_gpu_d2h_ms=33.3429 avg_gpu_kernel_ms=203.721 avg_gpu_other_ms=183.111 pass=1
phase1b_old_original_kernel_run1.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=482.068 avg_gkh_ms=0 avg_total_ms=482.068 avg_gpu_total_ms=482.051 avg_gpu_h2d_ms=27.3216 avg_gpu_d2h_ms=33.0036 avg_gpu_kernel_ms=226.364 avg_gpu_other_ms=195.362 pass=1
phase1b_old_original_kernel_run2.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=469.27 avg_gkh_ms=0 avg_total_ms=469.27 avg_gpu_total_ms=469.254 avg_gpu_h2d_ms=24.7156 avg_gpu_d2h_ms=33.8446 avg_gpu_kernel_ms=235.409 avg_gpu_other_ms=175.285 pass=1
phase1b_old_original_kernel_run3.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=467.281 avg_gkh_ms=0 avg_total_ms=467.281 avg_gpu_total_ms=467.272 avg_gpu_h2d_ms=27.7848 avg_gpu_d2h_ms=32.7646 avg_gpu_kernel_ms=227.898 avg_gpu_other_ms=178.824 pass=1
phase1b_old_original_kernel_run4.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=474.016 avg_gkh_ms=0 avg_total_ms=474.016 avg_gpu_total_ms=474.008 avg_gpu_h2d_ms=23.9568 avg_gpu_d2h_ms=32.4204 avg_gpu_kernel_ms=236.609 avg_gpu_other_ms=181.021 pass=1
phase1b_old_original_kernel_run5.txt: [bench-summary] impl=gpu_kernel n=1000 repeat=1 avg_bidiag_ms=468.466 avg_gkh_ms=0 avg_total_ms=468.466 avg_gpu_total_ms=468.454 avg_gpu_h2d_ms=27.6461 avg_gpu_d2h_ms=33.0137 avg_gpu_kernel_ms=229.514 avg_gpu_other_ms=178.28 pass=1
```

# 9. Performance Regression Diagnosis

Selected conclusion: runtime environment change.

Evidence: old_original still matches or beats the old report in this controlled run: gpu_kernel median 469.270 ms and gpu_cublas median 449.675 ms. current_profile1 is essentially equal to old_original: gpu_kernel ratio 1.022 and gpu_cublas ratio 0.997. current_profile0 is faster, not slower: gpu_kernel median 293.433 ms and gpu_cublas median 251.558 ms. old_host_o2 is also close to old_original, so host `/O2` is not the regression cause.

The phase1 slow numbers were not reproduced in independent-process A/B testing. The best-supported explanation is transient runtime state: GPU power/frequency behavior, WDDM/background graphics tasks, system load, or similar environment variation during the earlier run.

# 10. Need For Fix

No source code was modified in phase1b. No specific code location satisfied the required conditions for a source fix. Therefore no `phase1b_fixed_` repair experiment was run.

# 11. Final Git Status

`git diff --stat`:

```text
warning: in the working copy of 'bidiagonalization_gpu.cu', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'bidiagonalization_gpu.h', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'build_gpu.bat', LF will be replaced by CRLF the next time Git touches it
 bidiagonalization_gpu.cu | 176 +++++++++++++++-------------
 bidiagonalization_gpu.h  |   6 +-
 build_gpu.bat            |   3 +-
 main.cpp                 | 290 ++++++++++++++++++++++++++++++-----------------
 main_gpu.exe             | Bin 516608 -> 522240 bytes
 5 files changed, 290 insertions(+), 185 deletions(-)
```

`git status --short`:

```text
warning: unable to access 'C:\Users\shangwenxuan/.config/git/ignore': Permission denied
warning: unable to access 'C:\Users\shangwenxuan/.config/git/ignore': Permission denied
 M bidiagonalization_gpu.cu
 M bidiagonalization_gpu.h
 M build_gpu.bat
 M main.cpp
 M main_gpu.exe
?? results_gpu/final_bidiag_cpu_n2000.txt
?? results_gpu/final_bidiag_cpu_n2000_probe.txt
?? results_gpu/final_bidiag_cublas_n2000.txt
?? results_gpu/final_bidiag_cublas_n2000_probe.txt
?? results_gpu/final_bidiag_kernel_n2000.txt
?? results_gpu/final_bidiag_kernel_n2000_probe.txt
?? results_gpu/final_bidiag_n2000_summary.txt
?? results_gpu/final_check_cpu.txt
?? results_gpu/final_check_gpu_cublas.txt
?? results_gpu/final_check_gpu_kernel.txt
?? results_gpu/final_env_commit.txt
?? results_gpu/final_env_git_status.txt
?? results_gpu/final_env_gpu_query.txt
?? results_gpu/final_env_nvidia_smi.txt
?? results_gpu/final_full_cpu_n1000.txt
?? results_gpu/final_full_cpu_n128.txt
?? results_gpu/final_full_cpu_n256.txt
?? results_gpu/final_full_cpu_n512.txt
?? results_gpu/final_full_cublas_n1000.txt
?? results_gpu/final_full_cublas_n128.txt
?? results_gpu/final_full_cublas_n256.txt
?? results_gpu/final_full_cublas_n512.txt
?? results_gpu/final_full_kernel_n1000.txt
?? results_gpu/final_full_kernel_n128.txt
?? results_gpu/final_full_kernel_n256.txt
?? results_gpu/final_full_kernel_n512.txt
?? results_gpu/final_full_summary.txt
?? results_gpu/final_full_summary_ps.txt
?? results_gpu/phase1_check_cpu.txt
?? results_gpu/phase1_check_gpu_cublas_profile0.txt
?? results_gpu/phase1_check_gpu_cublas_profile1.txt
?? results_gpu/phase1_check_gpu_kernel_profile0.txt
?? results_gpu/phase1_fixed_cpu_n1000.txt
?? results_gpu/phase1_fixed_cpu_n512.txt
?? results_gpu/phase1_fixed_cublas_n1000_profile0.txt
?? results_gpu/phase1_fixed_cublas_n512_profile0.txt
?? results_gpu/phase1_fixed_kernel_n1000_profile0.txt
?? results_gpu/phase1_fixed_kernel_n512_profile0.txt
?? results_gpu/phase1_profile_cublas_n1000_off.txt
?? results_gpu/phase1_profile_cublas_n1000_on.txt
?? results_gpu/phase1_profile_kernel_n1000_off.txt
?? results_gpu/phase1_profile_kernel_n1000_on.txt
?? results_gpu/phase1b_ab_summary.md
?? results_gpu/phase1b_current_cpu_run1.txt
?? results_gpu/phase1b_current_cpu_run2.txt
?? results_gpu/phase1b_current_cpu_run3.txt
?? results_gpu/phase1b_current_cpu_run4.txt
?? results_gpu/phase1b_current_cpu_run5.txt
?? results_gpu/phase1b_current_cublas_profile0_run1.txt
?? results_gpu/phase1b_current_cublas_profile0_run2.txt
?? results_gpu/phase1b_current_cublas_profile0_run3.txt
?? results_gpu/phase1b_current_cublas_profile0_run4.txt
?? results_gpu/phase1b_current_cublas_profile0_run5.txt
?? results_gpu/phase1b_current_cublas_profile1_run1.txt
?? results_gpu/phase1b_current_cublas_profile1_run2.txt
?? results_gpu/phase1b_current_cublas_profile1_run3.txt
?? results_gpu/phase1b_current_cublas_profile1_run4.txt
?? results_gpu/phase1b_current_cublas_profile1_run5.txt
?? results_gpu/phase1b_current_kernel_profile0_run1.txt
?? results_gpu/phase1b_current_kernel_profile0_run2.txt
?? results_gpu/phase1b_current_kernel_profile0_run3.txt
?? results_gpu/phase1b_current_kernel_profile0_run4.txt
?? results_gpu/phase1b_current_kernel_profile0_run5.txt
?? results_gpu/phase1b_current_kernel_profile1_run1.txt
?? results_gpu/phase1b_current_kernel_profile1_run2.txt
?? results_gpu/phase1b_current_kernel_profile1_run3.txt
?? results_gpu/phase1b_current_kernel_profile1_run4.txt
?? results_gpu/phase1b_current_kernel_profile1_run5.txt
?? results_gpu/phase1b_environment_before.txt
?? results_gpu/phase1b_gpu_telemetry.csv
?? results_gpu/phase1b_old_host_o2_cpu_run1.txt
?? results_gpu/phase1b_old_host_o2_cpu_run2.txt
?? results_gpu/phase1b_old_host_o2_cpu_run3.txt
?? results_gpu/phase1b_old_host_o2_cpu_run4.txt
?? results_gpu/phase1b_old_host_o2_cpu_run5.txt
?? results_gpu/phase1b_old_host_o2_cublas_run1.txt
?? results_gpu/phase1b_old_host_o2_cublas_run2.txt
?? results_gpu/phase1b_old_host_o2_cublas_run3.txt
?? results_gpu/phase1b_old_host_o2_cublas_run4.txt
?? results_gpu/phase1b_old_host_o2_cublas_run5.txt
?? results_gpu/phase1b_old_host_o2_kernel_run1.txt
?? results_gpu/phase1b_old_host_o2_kernel_run2.txt
?? results_gpu/phase1b_old_host_o2_kernel_run3.txt
?? results_gpu/phase1b_old_host_o2_kernel_run4.txt
?? results_gpu/phase1b_old_host_o2_kernel_run5.txt
?? results_gpu/phase1b_old_original_cpu_run1.txt
?? results_gpu/phase1b_old_original_cpu_run2.txt
?? results_gpu/phase1b_old_original_cpu_run3.txt
?? results_gpu/phase1b_old_original_cpu_run4.txt
?? results_gpu/phase1b_old_original_cpu_run5.txt
?? results_gpu/phase1b_old_original_cublas_run1.txt
?? results_gpu/phase1b_old_original_cublas_run2.txt
?? results_gpu/phase1b_old_original_cublas_run3.txt
?? results_gpu/phase1b_old_original_cublas_run4.txt
?? results_gpu/phase1b_old_original_cublas_run5.txt
?? results_gpu/phase1b_old_original_kernel_run1.txt
?? results_gpu/phase1b_old_original_kernel_run2.txt
?? results_gpu/phase1b_old_original_kernel_run3.txt
?? results_gpu/phase1b_old_original_kernel_run4.txt
?? results_gpu/phase1b_old_original_kernel_run5.txt
```
