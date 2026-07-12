# 1. 修改前状态

Start state recorded before implementation: branch `svd-lab5-gpu`, HEAD `c08f9d7`. The working tree already contained uncommitted phase1 source changes and phase1/phase1b/final result files. This phase did not create/switch branches, did not reset/clean/checkout, and did not commit.

Initial commands run: `git status`, `git rev-parse --short HEAD`, `git diff --stat`.

# 2. 代码修改

- `gkh.h`: added public `GKHProfile` and optional `GKHProfile *profile=nullptr` argument on `gkh_svd_from_bidiagonal`.
- `gkh.cpp`: added count-only profiling and mode2 coarse `steady_clock` timing around cleanup, zero handling, split, all block steps per outer iteration, and final cleanup/sort. No GKH math, tolerance, order, active-block criterion, max_iter, or final sorting logic was changed.
- `main.cpp`: added `--gkh-profile 0|1|2`, GKH profile logging, and propagation through check/bench paths. `full_svd=0` does not emit fake `[gkh-profile]` lines.

# 3. 计数定义

- `outer_iterations`: incremented once at the top of each GKH outer loop, including the final all-singleton detection round.
- `block_steps`: incremented immediately before each actual `one_block_step` call.
- `left_rotations` / `right_rotations`: count actual Givens left/right applications in `one_block_step` and zero-diagonal chase only. Final sign fixes and sorting are not counted.
- `zero_chase_calls`: incremented only when `chase_zero_diagonal` passes its initial checks and enters the update path.
- `deflations`: incremented in `split_active_blocks` only when a formerly nonzero superdiagonal entry is set to zero by the convergence criterion. Already-zero entries are not recounted.
- `multiple_block_ratio`: `iterations_with_multiple_blocks / outer_iterations`; a nontrivial block is a block `[l,r]` with `r>l`.
- mode 1 performs counts only and does not call chrono. mode 2 performs only coarse timing at the requested boundaries.

# 4. 编译与正确性

Build output: `results_gpu/phase2_build.txt`. Build succeeded. The log shows compilation of `main.cpp`, `gkh.cpp`, `bidiagonalization.cpp`, and `bidiagonalization_gpu.cu`.

| check file | PASS count | has profile line | has mode2 timing fields |
|---|---:|---:|---:|
| phase2_check_cpu_profile0.txt | 5/5 | 0 | 0 |
| phase2_check_cpu_profile1.txt | 5/5 | 1 | 0 |
| phase2_check_cublas_profile1.txt | 5/5 | 1 | 0 |
| phase2_check_kernel_profile1.txt | 5/5 | 1 | 0 |

All four correctness checks are 5/5 PASS. Profile0 check has no `[gkh-profile]`; profile1 checks have count lines and no mode2 timing fields.

# 5. Profiling开销

| mode | mean gkh_ms | median | min | max | stddev | CV | median overhead vs mode0 |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 7536.827 | 7602.430 | 7370.580 | 7637.470 | 145.036 | 1.92% | 0.00% |
| 1 | 8032.617 | 7411.870 | 7395.820 | 9290.160 | 1089.094 | 13.56% | -2.51% |
| 2 | 7292.210 | 7254.110 | 7194.650 | 7427.870 | 121.188 | 1.66% | -4.58% |

Mode1 median overhead is negative in this small sample, so count-only profiling did not show measurable overhead above run-to-run noise. Mode2 also did not show a positive median overhead here; use it only for breakdown because it still adds chrono calls.

# 6. 多seed完整结果

| n | seed | bidiag_ms | gkh_ms | total_ms | outer_iterations | block_steps | total_rotations | zero_chase_calls | deflations | avg_nontrivial_blocks | multiple_block_ratio | max_nontrivial_blocks | avg_nontrivial_block_size | max_block_size |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 256 | 20261408 | 21.667 | 130.507 | 152.175 | 386 | 386 | 108190 | 0 | 255 | 1.000000 | 0.002591 | 2 | 141.142 | 256 |
| 256 | 20261409 | 18.898 | 163.172 | 182.070 | 390 | 389 | 109716 | 0 | 254 | 0.997436 | 0.000000 | 1 | 142.023 | 256 |
| 256 | 20261410 | 26.380 | 240.758 | 267.138 | 387 | 387 | 109334 | 0 | 255 | 1.000000 | 0.002584 | 2 | 142.258 | 256 |
| 256 | 20261411 | 18.523 | 163.647 | 182.170 | 388 | 387 | 109248 | 0 | 255 | 0.997423 | 0.000000 | 1 | 142.147 | 256 |
| 256 | 20261412 | 18.570 | 124.850 | 143.421 | 389 | 390 | 110014 | 0 | 255 | 1.002570 | 0.005141 | 2 | 142.044 | 256 |
| 512 | 20261408 | 186.921 | 4510.060 | 4696.980 | 750 | 757 | 420100 | 0 | 509 | 1.009330 | 0.010667 | 2 | 278.477 | 512 |
| 512 | 20261409 | 191.983 | 4316.860 | 4508.840 | 745 | 756 | 421470 | 0 | 510 | 1.014770 | 0.016107 | 2 | 279.750 | 512 |
| 512 | 20261410 | 190.258 | 4275.540 | 4465.800 | 743 | 748 | 420962 | 0 | 510 | 1.006730 | 0.008075 | 2 | 282.392 | 512 |
| 512 | 20261411 | 195.520 | 4680.210 | 4875.730 | 744 | 746 | 416666 | 0 | 510 | 1.002690 | 0.004032 | 2 | 280.267 | 512 |
| 512 | 20261412 | 175.164 | 4415.760 | 4590.930 | 753 | 753 | 419404 | 0 | 511 | 1.000000 | 0.001328 | 2 | 279.489 | 512 |
| 1000 | 20261408 | 1972.250 | 7200.130 | 9172.380 | 1434 | 1441 | 1558190 | 0 | 997 | 1.004880 | 0.004184 | 3 | 541.663 | 1000 |
| 1000 | 20261409 | 1960.060 | 7070.650 | 9030.710 | 1430 | 1433 | 1554058 | 0 | 999 | 1.002100 | 0.002797 | 2 | 543.239 | 1000 |
| 1000 | 20261410 | 1877.190 | 7231.920 | 9109.110 | 1435 | 1442 | 1560130 | 0 | 998 | 1.004880 | 0.005575 | 2 | 541.960 | 1000 |
| 1000 | 20261411 | 1863.720 | 7281.270 | 9144.990 | 1440 | 1446 | 1559558 | 0 | 996 | 1.004170 | 0.004861 | 2 | 540.266 | 1000 |
| 1000 | 20261412 | 1922.350 | 7114.840 | 9037.190 | 1428 | 1442 | 1555488 | 0 | 999 | 1.009800 | 0.008403 | 3 | 540.351 | 1000 |

# 7. 各规模统计

| n | gkh mean | median | min | max | CV | iter mean | iter min | iter max | rotations mean | rotations min | rotations max | avg blocks mean | multi-block ratio mean |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 256 | 164.587 | 163.172 | 124.850 | 240.758 | 28.08% | 388.00 | 386 | 390 | 109300.4 | 108190 | 110014 | 0.999486 | 0.002063 |
| 512 | 4439.686 | 4415.760 | 4275.540 | 4680.210 | 3.66% | 747.00 | 743 | 753 | 419720.4 | 416666 | 421470 | 1.006704 | 0.008042 |
| 1000 | 7179.762 | 7200.130 | 7070.650 | 7281.270 | 1.20% | 1433.40 | 1428 | 1440 | 1557484.8 | 1554058 | 1560130 | 1.005166 | 0.005164 |

# 8. 相关性分析

| scope | corr(gkh_ms, outer_iterations) | corr(gkh_ms, block_steps) | corr(gkh_ms, total_rotations) |
|---|---:|---:|---:|
| n=256 | -0.1730 | -0.2895 | 0.0899 |
| n=512 | 0.0889 | -0.3018 | -0.9155 |
| n=1000 | 0.9263 | 0.8348 | 0.9605 |
| all seeds pooled | 0.9535 | 0.9542 | 0.9024 |

Within a fixed n and only five seeds, correlations are noisy. Pooled across all n, all three correlations are very high because matrix size dominates both time and work. For a fixed size, total rotations usually tracks work better than raw outer iteration count, but seed-to-seed variation is small enough that Windows timing noise can blur this. No seed shows a different active-block structure large enough to create task-level parallelism.

# 9. 后端对比

| n | impl | bidiag_ms | gkh_ms | outer_iterations | block_steps | total_rotations | deflations | avg_nontrivial_blocks | max_nontrivial_blocks | rel_recon | orth_u | orth_v | diag_err | order_err | pass |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 512 | cpu | 186.861 | 4124.960 | 750 | 757 | 420100 | 509 | 1.009330 | 2 | 3.602e-13 | 1.278e-13 | 1.290e-13 | 0.000e+00 | 0.000e+00 | 1 |
| 512 | gpu_kernel | 106.703 | 3799.180 | 750 | 757 | 420100 | 511 | 1.009330 | 2 | 3.604e-13 | 1.225e-13 | 1.224e-13 | 0.000e+00 | 0.000e+00 | 1 |
| 512 | gpu_cublas | 167.646 | 3669.080 | 750 | 757 | 420632 | 510 | 1.009330 | 2 | 3.791e-13 | 1.229e-13 | 1.203e-13 | 0.000e+00 | 0.000e+00 | 1 |
| 1000 | cpu | 2052.910 | 7311.150 | 1434 | 1441 | 1558190 | 997 | 1.004880 | 3 | 3.518e-13 | 2.509e-13 | 2.469e-13 | 0.000e+00 | 0.000e+00 | 1 |
| 1000 | gpu_kernel | 287.128 | 6866.800 | 1434 | 1441 | 1558190 | 998 | 1.004880 | 3 | 3.521e-13 | 2.333e-13 | 2.377e-13 | 0.000e+00 | 0.000e+00 | 1 |
| 1000 | gpu_cublas | 254.172 | 6999.240 | 1434 | 1441 | 1558190 | 998 | 1.004880 | 3 | 3.521e-13 | 2.364e-13 | 2.321e-13 | 0.000e+00 | 0.000e+00 | 1 |

All backend variants pass. Where counts differ, the plausible cause is tiny floating-point differences in the bidiagonal matrix changing deflation timing, not a correctness issue.

# 10. GKH阶段耗时拆分

| phase | ms | ratio of profiled_phase_total |
|---|---:|---:|
| cleanup_ms | 1346.500 | 14.86% |
| zero_handle_ms | 7.092 | 0.08% |
| split_ms | 24.713 | 0.27% |
| block_step_ms | 7668.690 | 84.66% |
| finalize_ms | 11.625 | 0.13% |
| profiled_phase_total_ms | 9058.620 | 100.00% |

Measured `gkh_ms` for this run was 9063.520 ms. It need not exactly match profiled phase total because loop control and small uncovered overheads are outside the coarse timers.

# 11. 对前序多线程和MPI实验的解释

The data confirms that active-block task parallelism is limited: average nontrivial blocks per iteration is close to 1, multiple-block ratios are near zero, and max nontrivial block counts are small. A scheduler cannot create block-level parallelism when the algorithm exposes only one meaningful active block most iterations. After GPU bidiagonalization is accelerated, GKH becomes the end-to-end bottleneck because it remains mostly sequential bulge chasing dominated by rotations inside a small number of active blocks.

# 12. 异常与限制

- Only five seeds were tested per size, so seed sensitivity conclusions are limited.
- Pearson correlations reflect this test set and are strongly affected by pooling different n.
- Windows/WDDM background activity can still cause timing variation.
- Mode1 count-only profiling showed no positive median overhead in this sample; mode2 timing is coarse but still intended only for breakdown analysis.

# 13. 原始日志索引

- `phase2_backend_cpu_n1000.txt`
- `phase2_backend_cpu_n512.txt`
- `phase2_backend_cublas_n1000.txt`
- `phase2_backend_cublas_n512.txt`
- `phase2_backend_kernel_n1000.txt`
- `phase2_backend_kernel_n512.txt`
- `phase2_breakdown_cpu_n1000.txt`
- `phase2_build.txt`
- `phase2_check_cpu_profile0.txt`
- `phase2_check_cpu_profile1.txt`
- `phase2_check_cublas_profile1.txt`
- `phase2_check_kernel_profile1.txt`
- `phase2_overhead_mode0_run1.txt`
- `phase2_overhead_mode0_run2.txt`
- `phase2_overhead_mode0_run3.txt`
- `phase2_overhead_mode1_run1.txt`
- `phase2_overhead_mode1_run2.txt`
- `phase2_overhead_mode1_run3.txt`
- `phase2_overhead_mode2_run1.txt`
- `phase2_overhead_mode2_run2.txt`
- `phase2_overhead_mode2_run3.txt`
- `phase2_seed_cpu_n1000_s20261408.txt`
- `phase2_seed_cpu_n1000_s20261409.txt`
- `phase2_seed_cpu_n1000_s20261410.txt`
- `phase2_seed_cpu_n1000_s20261411.txt`
- `phase2_seed_cpu_n1000_s20261412.txt`
- `phase2_seed_cpu_n256_s20261408.txt`
- `phase2_seed_cpu_n256_s20261409.txt`
- `phase2_seed_cpu_n256_s20261410.txt`
- `phase2_seed_cpu_n256_s20261411.txt`
- `phase2_seed_cpu_n256_s20261412.txt`
- `phase2_seed_cpu_n512_s20261408.txt`
- `phase2_seed_cpu_n512_s20261409.txt`
- `phase2_seed_cpu_n512_s20261410.txt`
- `phase2_seed_cpu_n512_s20261411.txt`
- `phase2_seed_cpu_n512_s20261412.txt`

# 14. 最终Git状态

`git diff --stat`:

```text
warning: in the working copy of 'bidiagonalization_gpu.cu', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'bidiagonalization_gpu.h', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'build_gpu.bat', LF will be replaced by CRLF the next time Git touches it
 bidiagonalization_gpu.cu | 176 +++++++++++---------
 bidiagonalization_gpu.h  |   6 +-
 build_gpu.bat            |   3 +-
 gkh.cpp                  | 274 +++++++++++++++++++++++--------
 gkh.h                    |  37 ++++-
 main.cpp                 | 420 +++++++++++++++++++++++++++++++++--------------
 main_gpu.exe             | Bin 516608 -> 529920 bytes
 7 files changed, 641 insertions(+), 275 deletions(-)
```

`git status`:

```text
warning: unable to access 'C:\Users\shangwenxuan/.config/git/ignore': Permission denied
warning: unable to access 'C:\Users\shangwenxuan/.config/git/ignore': Permission denied
On branch svd-lab5-gpu
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   bidiagonalization_gpu.cu
	modified:   bidiagonalization_gpu.h
	modified:   build_gpu.bat
	modified:   gkh.cpp
	modified:   gkh.h
	modified:   main.cpp
	modified:   main_gpu.exe

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	results_gpu/final_bidiag_cpu_n2000.txt
	results_gpu/final_bidiag_cpu_n2000_probe.txt
	results_gpu/final_bidiag_cublas_n2000.txt
	results_gpu/final_bidiag_cublas_n2000_probe.txt
	results_gpu/final_bidiag_kernel_n2000.txt
	results_gpu/final_bidiag_kernel_n2000_probe.txt
	results_gpu/final_bidiag_n2000_summary.txt
	results_gpu/final_check_cpu.txt
	results_gpu/final_check_gpu_cublas.txt
	results_gpu/final_check_gpu_kernel.txt
	results_gpu/final_env_commit.txt
	results_gpu/final_env_git_status.txt
	results_gpu/final_env_gpu_query.txt
	results_gpu/final_env_nvidia_smi.txt
	results_gpu/final_full_cpu_n1000.txt
	results_gpu/final_full_cpu_n128.txt
	results_gpu/final_full_cpu_n256.txt
	results_gpu/final_full_cpu_n512.txt
	results_gpu/final_full_cublas_n1000.txt
	results_gpu/final_full_cublas_n128.txt
	results_gpu/final_full_cublas_n256.txt
	results_gpu/final_full_cublas_n512.txt
	results_gpu/final_full_kernel_n1000.txt
	results_gpu/final_full_kernel_n128.txt
	results_gpu/final_full_kernel_n256.txt
	results_gpu/final_full_kernel_n512.txt
	results_gpu/final_full_summary.txt
	results_gpu/final_full_summary_ps.txt
	results_gpu/phase1_check_cpu.txt
	results_gpu/phase1_check_gpu_cublas_profile0.txt
	results_gpu/phase1_check_gpu_cublas_profile1.txt
	results_gpu/phase1_check_gpu_kernel_profile0.txt
	results_gpu/phase1_fixed_cpu_n1000.txt
	results_gpu/phase1_fixed_cpu_n512.txt
	results_gpu/phase1_fixed_cublas_n1000_profile0.txt
	results_gpu/phase1_fixed_cublas_n512_profile0.txt
	results_gpu/phase1_fixed_kernel_n1000_profile0.txt
	results_gpu/phase1_fixed_kernel_n512_profile0.txt
	results_gpu/phase1_profile_cublas_n1000_off.txt
	results_gpu/phase1_profile_cublas_n1000_on.txt
	results_gpu/phase1_profile_kernel_n1000_off.txt
	results_gpu/phase1_profile_kernel_n1000_on.txt
	results_gpu/phase1b_ab_summary.md
	results_gpu/phase1b_current_cpu_run1.txt
	results_gpu/phase1b_current_cpu_run2.txt
	results_gpu/phase1b_current_cpu_run3.txt
	results_gpu/phase1b_current_cpu_run4.txt
	results_gpu/phase1b_current_cpu_run5.txt
	results_gpu/phase1b_current_cublas_profile0_run1.txt
	results_gpu/phase1b_current_cublas_profile0_run2.txt
	results_gpu/phase1b_current_cublas_profile0_run3.txt
	results_gpu/phase1b_current_cublas_profile0_run4.txt
	results_gpu/phase1b_current_cublas_profile0_run5.txt
	results_gpu/phase1b_current_cublas_profile1_run1.txt
	results_gpu/phase1b_current_cublas_profile1_run2.txt
	results_gpu/phase1b_current_cublas_profile1_run3.txt
	results_gpu/phase1b_current_cublas_profile1_run4.txt
	results_gpu/phase1b_current_cublas_profile1_run5.txt
	results_gpu/phase1b_current_kernel_profile0_run1.txt
	results_gpu/phase1b_current_kernel_profile0_run2.txt
	results_gpu/phase1b_current_kernel_profile0_run3.txt
	results_gpu/phase1b_current_kernel_profile0_run4.txt
	results_gpu/phase1b_current_kernel_profile0_run5.txt
	results_gpu/phase1b_current_kernel_profile1_run1.txt
	results_gpu/phase1b_current_kernel_profile1_run2.txt
	results_gpu/phase1b_current_kernel_profile1_run3.txt
	results_gpu/phase1b_current_kernel_profile1_run4.txt
	results_gpu/phase1b_current_kernel_profile1_run5.txt
	results_gpu/phase1b_environment_before.txt
	results_gpu/phase1b_gpu_telemetry.csv
	results_gpu/phase1b_old_host_o2_cpu_run1.txt
	results_gpu/phase1b_old_host_o2_cpu_run2.txt
	results_gpu/phase1b_old_host_o2_cpu_run3.txt
	results_gpu/phase1b_old_host_o2_cpu_run4.txt
	results_gpu/phase1b_old_host_o2_cpu_run5.txt
	results_gpu/phase1b_old_host_o2_cublas_run1.txt
	results_gpu/phase1b_old_host_o2_cublas_run2.txt
	results_gpu/phase1b_old_host_o2_cublas_run3.txt
	results_gpu/phase1b_old_host_o2_cublas_run4.txt
	results_gpu/phase1b_old_host_o2_cublas_run5.txt
	results_gpu/phase1b_old_host_o2_kernel_run1.txt
	results_gpu/phase1b_old_host_o2_kernel_run2.txt
	results_gpu/phase1b_old_host_o2_kernel_run3.txt
	results_gpu/phase1b_old_host_o2_kernel_run4.txt
	results_gpu/phase1b_old_host_o2_kernel_run5.txt
	results_gpu/phase1b_old_original_cpu_run1.txt
	results_gpu/phase1b_old_original_cpu_run2.txt
	results_gpu/phase1b_old_original_cpu_run3.txt
	results_gpu/phase1b_old_original_cpu_run4.txt
	results_gpu/phase1b_old_original_cpu_run5.txt
	results_gpu/phase1b_old_original_cublas_run1.txt
	results_gpu/phase1b_old_original_cublas_run2.txt
	results_gpu/phase1b_old_original_cublas_run3.txt
	results_gpu/phase1b_old_original_cublas_run4.txt
	results_gpu/phase1b_old_original_cublas_run5.txt
	results_gpu/phase1b_old_original_kernel_run1.txt
	results_gpu/phase1b_old_original_kernel_run2.txt
	results_gpu/phase1b_old_original_kernel_run3.txt
	results_gpu/phase1b_old_original_kernel_run4.txt
	results_gpu/phase1b_old_original_kernel_run5.txt
	results_gpu/phase2_backend_cpu_n1000.txt
	results_gpu/phase2_backend_cpu_n512.txt
	results_gpu/phase2_backend_cublas_n1000.txt
	results_gpu/phase2_backend_cublas_n512.txt
	results_gpu/phase2_backend_kernel_n1000.txt
	results_gpu/phase2_backend_kernel_n512.txt
	results_gpu/phase2_breakdown_cpu_n1000.txt
	results_gpu/phase2_build.txt
	results_gpu/phase2_check_cpu_profile0.txt
	results_gpu/phase2_check_cpu_profile1.txt
	results_gpu/phase2_check_cublas_profile1.txt
	results_gpu/phase2_check_kernel_profile1.txt
	results_gpu/phase2_overhead_mode0_run1.txt
	results_gpu/phase2_overhead_mode0_run2.txt
	results_gpu/phase2_overhead_mode0_run3.txt
	results_gpu/phase2_overhead_mode1_run1.txt
	results_gpu/phase2_overhead_mode1_run2.txt
	results_gpu/phase2_overhead_mode1_run3.txt
	results_gpu/phase2_overhead_mode2_run1.txt
	results_gpu/phase2_overhead_mode2_run2.txt
	results_gpu/phase2_overhead_mode2_run3.txt
	results_gpu/phase2_seed_cpu_n1000_s20261408.txt
	results_gpu/phase2_seed_cpu_n1000_s20261409.txt
	results_gpu/phase2_seed_cpu_n1000_s20261410.txt
	results_gpu/phase2_seed_cpu_n1000_s20261411.txt
	results_gpu/phase2_seed_cpu_n1000_s20261412.txt
	results_gpu/phase2_seed_cpu_n256_s20261408.txt
	results_gpu/phase2_seed_cpu_n256_s20261409.txt
	results_gpu/phase2_seed_cpu_n256_s20261410.txt
	results_gpu/phase2_seed_cpu_n256_s20261411.txt
	results_gpu/phase2_seed_cpu_n256_s20261412.txt
	results_gpu/phase2_seed_cpu_n512_s20261408.txt
	results_gpu/phase2_seed_cpu_n512_s20261409.txt
	results_gpu/phase2_seed_cpu_n512_s20261410.txt
	results_gpu/phase2_seed_cpu_n512_s20261411.txt
	results_gpu/phase2_seed_cpu_n512_s20261412.txt

no changes added to commit (use "git add" and/or "git commit -a")
```
# 14. ??Git??

`git diff --stat`:

```text
warning: in the working copy of 'bidiagonalization_gpu.cu', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'bidiagonalization_gpu.h', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'build_gpu.bat', LF will be replaced by CRLF the next time Git touches it
 bidiagonalization_gpu.cu | 176 +++++++++++---------
 bidiagonalization_gpu.h  |   6 +-
 build_gpu.bat            |   3 +-
 gkh.cpp                  | 274 +++++++++++++++++++++++--------
 gkh.h                    |  37 ++++-
 main.cpp                 | 420 +++++++++++++++++++++++++++++++++--------------
 main_gpu.exe             | Bin 516608 -> 529920 bytes
 7 files changed, 641 insertions(+), 275 deletions(-)
```

`git status`:

```text
warning: unable to access 'C:\Users\shangwenxuan/.config/git/ignore': Permission denied
warning: unable to access 'C:\Users\shangwenxuan/.config/git/ignore': Permission denied
On branch svd-lab5-gpu
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   bidiagonalization_gpu.cu
	modified:   bidiagonalization_gpu.h
	modified:   build_gpu.bat
	modified:   gkh.cpp
	modified:   gkh.h
	modified:   main.cpp
	modified:   main_gpu.exe

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	results_gpu/final_bidiag_cpu_n2000.txt
	results_gpu/final_bidiag_cpu_n2000_probe.txt
	results_gpu/final_bidiag_cublas_n2000.txt
	results_gpu/final_bidiag_cublas_n2000_probe.txt
	results_gpu/final_bidiag_kernel_n2000.txt
	results_gpu/final_bidiag_kernel_n2000_probe.txt
	results_gpu/final_bidiag_n2000_summary.txt
	results_gpu/final_check_cpu.txt
	results_gpu/final_check_gpu_cublas.txt
	results_gpu/final_check_gpu_kernel.txt
	results_gpu/final_env_commit.txt
	results_gpu/final_env_git_status.txt
	results_gpu/final_env_gpu_query.txt
	results_gpu/final_env_nvidia_smi.txt
	results_gpu/final_full_cpu_n1000.txt
	results_gpu/final_full_cpu_n128.txt
	results_gpu/final_full_cpu_n256.txt
	results_gpu/final_full_cpu_n512.txt
	results_gpu/final_full_cublas_n1000.txt
	results_gpu/final_full_cublas_n128.txt
	results_gpu/final_full_cublas_n256.txt
	results_gpu/final_full_cublas_n512.txt
	results_gpu/final_full_kernel_n1000.txt
	results_gpu/final_full_kernel_n128.txt
	results_gpu/final_full_kernel_n256.txt
	results_gpu/final_full_kernel_n512.txt
	results_gpu/final_full_summary.txt
	results_gpu/final_full_summary_ps.txt
	results_gpu/phase1_check_cpu.txt
	results_gpu/phase1_check_gpu_cublas_profile0.txt
	results_gpu/phase1_check_gpu_cublas_profile1.txt
	results_gpu/phase1_check_gpu_kernel_profile0.txt
	results_gpu/phase1_fixed_cpu_n1000.txt
	results_gpu/phase1_fixed_cpu_n512.txt
	results_gpu/phase1_fixed_cublas_n1000_profile0.txt
	results_gpu/phase1_fixed_cublas_n512_profile0.txt
	results_gpu/phase1_fixed_kernel_n1000_profile0.txt
	results_gpu/phase1_fixed_kernel_n512_profile0.txt
	results_gpu/phase1_profile_cublas_n1000_off.txt
	results_gpu/phase1_profile_cublas_n1000_on.txt
	results_gpu/phase1_profile_kernel_n1000_off.txt
	results_gpu/phase1_profile_kernel_n1000_on.txt
	results_gpu/phase1b_ab_summary.md
	results_gpu/phase1b_current_cpu_run1.txt
	results_gpu/phase1b_current_cpu_run2.txt
	results_gpu/phase1b_current_cpu_run3.txt
	results_gpu/phase1b_current_cpu_run4.txt
	results_gpu/phase1b_current_cpu_run5.txt
	results_gpu/phase1b_current_cublas_profile0_run1.txt
	results_gpu/phase1b_current_cublas_profile0_run2.txt
	results_gpu/phase1b_current_cublas_profile0_run3.txt
	results_gpu/phase1b_current_cublas_profile0_run4.txt
	results_gpu/phase1b_current_cublas_profile0_run5.txt
	results_gpu/phase1b_current_cublas_profile1_run1.txt
	results_gpu/phase1b_current_cublas_profile1_run2.txt
	results_gpu/phase1b_current_cublas_profile1_run3.txt
	results_gpu/phase1b_current_cublas_profile1_run4.txt
	results_gpu/phase1b_current_cublas_profile1_run5.txt
	results_gpu/phase1b_current_kernel_profile0_run1.txt
	results_gpu/phase1b_current_kernel_profile0_run2.txt
	results_gpu/phase1b_current_kernel_profile0_run3.txt
	results_gpu/phase1b_current_kernel_profile0_run4.txt
	results_gpu/phase1b_current_kernel_profile0_run5.txt
	results_gpu/phase1b_current_kernel_profile1_run1.txt
	results_gpu/phase1b_current_kernel_profile1_run2.txt
	results_gpu/phase1b_current_kernel_profile1_run3.txt
	results_gpu/phase1b_current_kernel_profile1_run4.txt
	results_gpu/phase1b_current_kernel_profile1_run5.txt
	results_gpu/phase1b_environment_before.txt
	results_gpu/phase1b_gpu_telemetry.csv
	results_gpu/phase1b_old_host_o2_cpu_run1.txt
	results_gpu/phase1b_old_host_o2_cpu_run2.txt
	results_gpu/phase1b_old_host_o2_cpu_run3.txt
	results_gpu/phase1b_old_host_o2_cpu_run4.txt
	results_gpu/phase1b_old_host_o2_cpu_run5.txt
	results_gpu/phase1b_old_host_o2_cublas_run1.txt
	results_gpu/phase1b_old_host_o2_cublas_run2.txt
	results_gpu/phase1b_old_host_o2_cublas_run3.txt
	results_gpu/phase1b_old_host_o2_cublas_run4.txt
	results_gpu/phase1b_old_host_o2_cublas_run5.txt
	results_gpu/phase1b_old_host_o2_kernel_run1.txt
	results_gpu/phase1b_old_host_o2_kernel_run2.txt
	results_gpu/phase1b_old_host_o2_kernel_run3.txt
	results_gpu/phase1b_old_host_o2_kernel_run4.txt
	results_gpu/phase1b_old_host_o2_kernel_run5.txt
	results_gpu/phase1b_old_original_cpu_run1.txt
	results_gpu/phase1b_old_original_cpu_run2.txt
	results_gpu/phase1b_old_original_cpu_run3.txt
	results_gpu/phase1b_old_original_cpu_run4.txt
	results_gpu/phase1b_old_original_cpu_run5.txt
	results_gpu/phase1b_old_original_cublas_run1.txt
	results_gpu/phase1b_old_original_cublas_run2.txt
	results_gpu/phase1b_old_original_cublas_run3.txt
	results_gpu/phase1b_old_original_cublas_run4.txt
	results_gpu/phase1b_old_original_cublas_run5.txt
	results_gpu/phase1b_old_original_kernel_run1.txt
	results_gpu/phase1b_old_original_kernel_run2.txt
	results_gpu/phase1b_old_original_kernel_run3.txt
	results_gpu/phase1b_old_original_kernel_run4.txt
	results_gpu/phase1b_old_original_kernel_run5.txt
	results_gpu/phase2_backend_cpu_n1000.txt
	results_gpu/phase2_backend_cpu_n512.txt
	results_gpu/phase2_backend_cublas_n1000.txt
	results_gpu/phase2_backend_cublas_n512.txt
	results_gpu/phase2_backend_kernel_n1000.txt
	results_gpu/phase2_backend_kernel_n512.txt
	results_gpu/phase2_breakdown_cpu_n1000.txt
	results_gpu/phase2_build.txt
	results_gpu/phase2_check_cpu_profile0.txt
	results_gpu/phase2_check_cpu_profile1.txt
	results_gpu/phase2_check_cublas_profile1.txt
	results_gpu/phase2_check_kernel_profile1.txt
	results_gpu/phase2_gkh_summary.md
	results_gpu/phase2_overhead_mode0_run1.txt
	results_gpu/phase2_overhead_mode0_run2.txt
	results_gpu/phase2_overhead_mode0_run3.txt
	results_gpu/phase2_overhead_mode1_run1.txt
	results_gpu/phase2_overhead_mode1_run2.txt
	results_gpu/phase2_overhead_mode1_run3.txt
	results_gpu/phase2_overhead_mode2_run1.txt
	results_gpu/phase2_overhead_mode2_run2.txt
	results_gpu/phase2_overhead_mode2_run3.txt
	results_gpu/phase2_seed_cpu_n1000_s20261408.txt
	results_gpu/phase2_seed_cpu_n1000_s20261409.txt
	results_gpu/phase2_seed_cpu_n1000_s20261410.txt
	results_gpu/phase2_seed_cpu_n1000_s20261411.txt
	results_gpu/phase2_seed_cpu_n1000_s20261412.txt
	results_gpu/phase2_seed_cpu_n256_s20261408.txt
	results_gpu/phase2_seed_cpu_n256_s20261409.txt
	results_gpu/phase2_seed_cpu_n256_s20261410.txt
	results_gpu/phase2_seed_cpu_n256_s20261411.txt
	results_gpu/phase2_seed_cpu_n256_s20261412.txt
	results_gpu/phase2_seed_cpu_n512_s20261408.txt
	results_gpu/phase2_seed_cpu_n512_s20261409.txt
	results_gpu/phase2_seed_cpu_n512_s20261410.txt
	results_gpu/phase2_seed_cpu_n512_s20261411.txt
	results_gpu/phase2_seed_cpu_n512_s20261412.txt

no changes added to commit (use "git add" and/or "git commit -a")
```
