# 1. 实际 Git 起点

Actual HEAD: `9f5acfd`. Recent commits:

```text
9f5acfd Add low-overhead GPU timing and GKH workload profiling
c08f9d7 Add GPU scaling benchmark for SVD bidiagonalization
46a0ff7 Add handwritten CUDA kernel bidiagonalization implementation
9f999e2 Prepare baseline structure for GPU SVD experiment
7404eb3 update report
```

Initial/final worktree contains prior Phase 3 edits plus Phase 4 changes; this differs from older context that mentioned `c08f9d7`, so the actual repository state was used. No branch switch, reset, clean, checkout, or commit was performed.

# 2. 数学等价性

B advancement is unchanged: every right and left Givens rotation is still applied to `B` at the original point in `one_block_step` and `chase_zero_diagonal`. Deferred mode only changes U/V accumulation from immediate column updates into ordered logs. U logs must preserve their own order because all updates act on the same U columns over time; V logs likewise must preserve V order. U and V logs may be replayed separately because they act on different matrices. Rows within a replay tile partition are independent writes, so different row tiles can be processed in parallel without locks. Logs are replayed before `make_nonnegative_and_sort`, so final sign fixes and column sorting still operate on the completed U/V.

# 3. 代码修改

- `gkh.h`: added `GKHAccumulation`, replay options, log counts/bytes, and replay timing fields.
- `gkh.cpp`: added `RotationLog`, deferred log recording at every U/V rotation path, cache-blocked row replay, OpenMP tile-level parallelism, and deferred validation. B updates and GKH convergence logic were not changed.
- `main.cpp`: added `--gkh-accum`, `--replay-threads`, `--replay-tile-rows`, OpenMP capability output, replay fields in logs, and deferred special-check support.
- `build_gpu.bat`: added `-Xcompiler /openmp` while preserving existing CUDA/MSVC options.

# 4. 正确性

Build succeeded in `phase4_build.txt`, and OpenMP runtime output reports `enabled=1`.

| file | PASS | FAIL | OpenMP enabled |
|---|---|---|---|
| phase4_check_normal.txt | 5/5 | 0 | True |
| phase4_check_tuv.txt | 5/5 | 0 | True |
| phase4_check_deferred_t1.txt | 5/5 | 0 | True |
| phase4_check_deferred_t4.txt | 5/5 | 0 | True |
| phase4_check_cublas_deferred_t4.txt | 5/5 | 0 | True |
| phase4_check_kernel_deferred_t4.txt | 5/5 | 0 | True |

| file | case | accum | threads | zero_chase | u_logs | v_logs | pass | rel_recon |
|---|---|---|---|---|---|---|---|---|
| phase4_special_normal.txt | zero_diagonal_chase | immediate | 1 | 1 | 0 | 0 | 1 | 8.663e-16 |
| phase4_special_normal.txt | already_diagonal | immediate | 1 | 0 | 0 | 0 | 1 | 0.000e+00 |
| phase4_special_normal.txt | two_active_blocks | immediate | 1 | 0 | 0 | 0 | 1 | 3.383e-16 |
| phase4_special_deferred_t1.txt | zero_diagonal_chase | deferred | 1 | 1 | 8 | 8 | 1 | 8.663e-16 |
| phase4_special_deferred_t1.txt | already_diagonal | deferred | 1 | 0 | 0 | 0 | 1 | 0.000e+00 |
| phase4_special_deferred_t1.txt | two_active_blocks | deferred | 1 | 0 | 14 | 14 | 1 | 3.383e-16 |
| phase4_special_deferred_t4.txt | zero_diagonal_chase | deferred | 4 | 1 | 8 | 8 | 1 | 8.663e-16 |
| phase4_special_deferred_t4.txt | already_diagonal | deferred | 4 | 0 | 0 | 0 | 1 | 0.000e+00 |
| phase4_special_deferred_t4.txt | two_active_blocks | deferred | 4 | 0 | 14 | 14 | 1 | 3.383e-16 |

| version | iterations | block_steps | left_rot | right_rot | total_rot | deflations | u_logs | v_logs | rel_recon | orth_u | orth_v | pass |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| normal | 1434 | 1441 | 779095 | 779095 | 1558190 | 997 | 0 | 0 | 3.518e-13 | 2.509e-13 | 2.469e-13 | 1 |
| tuv | 1434 | 1441 | 779095 | 779095 | 1558190 | 997 | 0 | 0 | 3.518e-13 | 2.509e-13 | 2.469e-13 | 1 |
| deferred_t1 | 1434 | 1441 | 779095 | 779095 | 1558190 | 997 | 779095 | 779095 | 3.518e-13 | 2.509e-13 | 2.469e-13 | 1 |
| deferred_t4 | 1434 | 1441 | 779095 | 779095 | 1558190 | 997 | 779095 | 779095 | 3.518e-13 | 2.509e-13 | 2.469e-13 | 1 |

# 5. 日志数量与内存

| n | U logs | V logs | logical bytes | allocated bytes | logical / U+V | allocated / U+V |
|---|---|---|---|---|---|---|
| 1000 | 779095 | 779095 | 37396560 | 50393712 | 2.34x | 3.15x |

# 6. Tile 调优

| tile rows | mean gkh | median | min | max | stddev | CV |
|---|---|---|---|---|---|---|
| 1 | 4466.377 | 4343.400 | 4235.720 | 4820.010 | 310.952 | 6.96% |
| 4 | 3658.073 | 3583.990 | 3512.220 | 3878.010 | 193.822 | 5.30% |
| 8 | 3580.430 | 3590.070 | 3487.390 | 3663.830 | 88.614 | 2.47% |
| 16 | 3693.107 | 3745.680 | 3561.740 | 3771.900 | 114.520 | 3.10% |
| 32 | 3543.107 | 3715.160 | 3116.220 | 3797.940 | 372.004 | 10.50% |
| 64 | 3614.853 | 3625.840 | 3534.270 | 3684.450 | 75.690 | 2.09% |
| 128 | 3819.020 | 3805.340 | 3771.030 | 3880.690 | 56.095 | 1.47% |

Selected best tile by median: `4`.

# 7. 线程扩展性

| threads | mean gkh | median | min | max | stddev | CV | speedup | efficiency |
|---|---|---|---|---|---|---|---|---|
| 1 | 5054.882 | 4929.920 | 4911.690 | 5311.230 | 185.594 | 3.67% | 1.000 | 1.000 |
| 2 | 4458.698 | 4454.780 | 4278.480 | 4621.520 | 156.395 | 3.51% | 1.107 | 0.553 |
| 4 | 3761.220 | 3700.420 | 3669.920 | 4002.320 | 139.599 | 3.71% | 1.332 | 0.333 |
| 8 | 3313.414 | 3309.980 | 3283.140 | 3361.440 | 29.096 | 0.88% | 1.489 | 0.186 |

Selected best thread count by median: `8`.

# 8. normal/TUV/deferred对比

| n | version | bidiag med | GKH med | total med | speedup vs normal | iterations | rotations | u_logs | v_logs | logical bytes | allocated bytes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 256 | normal | 17.649 | 133.574 | 150.885 | 1.000 | 386 | 108190 | 0 | 0 | 0 | 0 |
| 256 | tuv | 18.614 | 83.604 | 102.347 | 1.474 | 386 | 108190 | 0 | 0 | 0 | 0 |
| 256 | deferred_t1 | 17.588 | 104.216 | 121.591 | 1.241 | 386 | 108190 | 54095 | 54095 | 2596560 | 2949456 |
| 256 | deferred_t8 | 17.823 | 78.147 | 96.599 | 1.562 | 386 | 108190 | 54095 | 54095 | 2596560 | 2949456 |
| 512 | normal | 177.838 | 4279.480 | 4450.200 | 1.000 | 750 | 420100 | 0 | 0 | 0 | 0 |
| 512 | tuv | 193.552 | 1794.220 | 2004.130 | 2.221 | 750 | 420100 | 0 | 0 | 0 | 0 |
| 512 | deferred_t1 | 203.230 | 1845.750 | 2029.570 | 2.193 | 750 | 420100 | 210050 | 210050 | 10082400 | 14931504 |
| 512 | deferred_t8 | 175.352 | 1692.500 | 1867.850 | 2.383 | 750 | 420100 | 210050 | 210050 | 10082400 | 14931504 |
| 1000 | normal | 2263.460 | 7274.360 | 9817.590 | 1.000 | 1434 | 1558190 | 0 | 0 | 0 | 0 |
| 1000 | tuv | 2043.340 | 4658.850 | 6702.200 | 1.465 | 1434 | 1558190 | 0 | 0 | 0 | 0 |
| 1000 | deferred_t1 | 2106.520 | 4994.250 | 7100.770 | 1.383 | 1434 | 1558190 | 779095 | 779095 | 37396560 | 50393712 |
| 1000 | deferred_t8 | 2029.390 | 3350.930 | 5542.020 | 1.771 | 1434 | 1558190 | 779095 | 779095 | 37396560 | 50393712 |

# 9. GPU Householder + OpenMP replay

| n | version | bidiag med | GKH med | total med | speedup vs cpu normal | speedup vs cublas TUV | rel_recon | pass |
|---|---|---|---|---|---|---|---|---|
| 512 | cpu+normal | 177.521 | 4498.850 | 4672.850 | 1.000 | 0.423 | 3.602e-13 | 1 |
| 512 | gpu_cublas+tuv | 109.764 | 1843.170 | 1977.140 | 2.363 | 1.000 | 3.791e-13 | 1 |
| 512 | gpu_cublas+deferred | 110.600 | 1692.810 | 1810.100 | 2.582 | 1.092 | 3.791e-13 | 1 |
| 512 | gpu_kernel+deferred | 107.238 | 1710.290 | 1813.790 | 2.576 | 1.090 | 3.604e-13 | 1 |
| 1000 | cpu+normal | 1953.710 | 7136.100 | 9309.620 | 1.000 | 0.517 | 3.518e-13 | 1 |
| 1000 | gpu_cublas+tuv | 254.526 | 4532.130 | 4809.920 | 1.936 | 1.000 | 3.521e-13 | 1 |
| 1000 | gpu_cublas+deferred | 254.695 | 3121.380 | 3377.720 | 2.756 | 1.424 | 3.521e-13 | 1 |
| 1000 | gpu_kernel+deferred | 294.356 | 3152.320 | 3446.670 | 2.701 | 1.396 | 3.521e-13 | 1 |

# 10. 多seed稳健性

| seed | TUV gkh | deferred gkh | GKH speedup | TUV total | deferred total | total speedup | TUV iter | def iter | TUV rotations | def rotations | def U logs | pass |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 20261408 | 4455.790 | 3330.100 | 1.338 | 6265.070 | 5177.760 | 1.210 | 1434 | 1434 | 1558190 | 1558190 | 779095 | 1 |
| 20261409 | 4915.620 | 3624.930 | 1.356 | 7068.660 | 5567.180 | 1.270 | 1430 | 1430 | 1554058 | 1554058 | 777029 | 1 |
| 20261410 | 5944.870 | 3602.480 | 1.650 | 8565.220 | 5619.010 | 1.524 | 1435 | 1435 | 1560130 | 1560130 | 780065 | 1 |

# 11. 时间拆分

| version | gkh_ms | generation_ms | replay_u_ms | replay_v_ms | replay_total_ms | finalize_ms | logical bytes | allocated bytes | replay/GKH |
|---|---|---|---|---|---|---|---|---|---|
| normal | 7817.720 | 0 | 0 | 0 | 0 | 11.387 | 0 | 0 | 0.00% |
| tuv | 4500.400 | 0 | 0 | 0 | 0 | 10.298 | 0 | 0 | 0.00% |
| deferred_t1 | 5277.840 | 3010.660 | 1141.820 | 1114.410 | 2256.230 | 9.870 | 37396560 | 50393712 | 42.75% |
| deferred_t8 | 3559.030 | 3153.230 | 197.787 | 194.464 | 392.251 | 11.890 | 37396560 | 50393712 | 11.02% |

# 12. 与前序实验融合

SIMD results emphasized contiguous memory and cache locality; TUV already improved layout for immediate updates. Pthread/OpenMP active-block experiments showed that block-level parallelism is scarce, so this phase parallelizes independent matrix rows during replay instead. MPI rotation-log work suggested separating rotation generation from accumulation; deferred replay implements that idea on shared memory. GPU Householder reduces bidiagonalization, making GKH accumulation the bottleneck; cache-blocked replay directly targets that remaining bottleneck.

# 13. 与 TUV 的关系

TUV is an immediate-update layout optimization: it keeps applying rotations during GKH but stores U/V transposed for row-contiguous updates. Deferred replay is an execution-order and loop-order restructuring: it first generates the same B path and rotation sequence, then replays U/V by row tiles. The result should not be described simply as more OpenMP threads being faster; the main change is separating generation from row-block replay and reducing synchronization opportunities to one tile-level parallel loop.

# 14. 负结果和限制

Results should be read with Windows/WDDM timing variability in mind. No hardware cache counters were collected. Deferred serial replay is not always better than TUV at every size, and log scanning plus memory allocation can dominate small cases. The current implementation is CPU OpenMP replay only; no MPI, CUDA GKH, or GPU replay was implemented.

# 15. 原始日志索引

- `phase4_breakdown_deferred_best.txt`
- `phase4_breakdown_deferred_t1.txt`
- `phase4_breakdown_normal.txt`
- `phase4_breakdown_tuv.txt`
- `phase4_build.txt`
- `phase4_check_cublas_deferred_t4.txt`
- `phase4_check_deferred_t1.txt`
- `phase4_check_deferred_t4.txt`
- `phase4_check_kernel_deferred_t4.txt`
- `phase4_check_normal.txt`
- `phase4_check_tuv.txt`
- `phase4_compare_deferred_t1_n1000_run1.txt`
- `phase4_compare_deferred_t1_n1000_run2.txt`
- `phase4_compare_deferred_t1_n1000_run3.txt`
- `phase4_compare_deferred_t1_n1000_run4.txt`
- `phase4_compare_deferred_t1_n1000_run5.txt`
- `phase4_compare_deferred_t1_n256_run1.txt`
- `phase4_compare_deferred_t1_n256_run2.txt`
- `phase4_compare_deferred_t1_n256_run3.txt`
- `phase4_compare_deferred_t1_n256_run4.txt`
- `phase4_compare_deferred_t1_n256_run5.txt`
- `phase4_compare_deferred_t1_n512_run1.txt`
- `phase4_compare_deferred_t1_n512_run2.txt`
- `phase4_compare_deferred_t1_n512_run3.txt`
- `phase4_compare_deferred_t1_n512_run4.txt`
- `phase4_compare_deferred_t1_n512_run5.txt`
- `phase4_compare_deferred_t8_n1000_run1.txt`
- `phase4_compare_deferred_t8_n1000_run2.txt`
- `phase4_compare_deferred_t8_n1000_run3.txt`
- `phase4_compare_deferred_t8_n1000_run4.txt`
- `phase4_compare_deferred_t8_n1000_run5.txt`
- `phase4_compare_deferred_t8_n256_run1.txt`
- `phase4_compare_deferred_t8_n256_run2.txt`
- `phase4_compare_deferred_t8_n256_run3.txt`
- `phase4_compare_deferred_t8_n256_run4.txt`
- `phase4_compare_deferred_t8_n256_run5.txt`
- `phase4_compare_deferred_t8_n512_run1.txt`
- `phase4_compare_deferred_t8_n512_run2.txt`
- `phase4_compare_deferred_t8_n512_run3.txt`
- `phase4_compare_deferred_t8_n512_run4.txt`
- `phase4_compare_deferred_t8_n512_run5.txt`
- `phase4_compare_normal_n1000_run1.txt`
- `phase4_compare_normal_n1000_run2.txt`
- `phase4_compare_normal_n1000_run3.txt`
- `phase4_compare_normal_n1000_run4.txt`
- `phase4_compare_normal_n1000_run5.txt`
- `phase4_compare_normal_n256_run1.txt`
- `phase4_compare_normal_n256_run2.txt`
- `phase4_compare_normal_n256_run3.txt`
- `phase4_compare_normal_n256_run4.txt`
- `phase4_compare_normal_n256_run5.txt`
- `phase4_compare_normal_n512_run1.txt`
- `phase4_compare_normal_n512_run2.txt`
- `phase4_compare_normal_n512_run3.txt`
- `phase4_compare_normal_n512_run4.txt`
- `phase4_compare_normal_n512_run5.txt`
- `phase4_compare_tuv_n1000_run1.txt`
- `phase4_compare_tuv_n1000_run2.txt`
- `phase4_compare_tuv_n1000_run3.txt`
- `phase4_compare_tuv_n1000_run4.txt`
- `phase4_compare_tuv_n1000_run5.txt`
- `phase4_compare_tuv_n256_run1.txt`
- `phase4_compare_tuv_n256_run2.txt`
- `phase4_compare_tuv_n256_run3.txt`
- `phase4_compare_tuv_n256_run4.txt`
- `phase4_compare_tuv_n256_run5.txt`
- `phase4_compare_tuv_n512_run1.txt`
- `phase4_compare_tuv_n512_run2.txt`
- `phase4_compare_tuv_n512_run3.txt`
- `phase4_compare_tuv_n512_run4.txt`
- `phase4_compare_tuv_n512_run5.txt`
- `phase4_equiv_deferred_t1.txt`
- `phase4_equiv_deferred_t4.txt`
- `phase4_equiv_normal.txt`
- `phase4_equiv_tuv.txt`
- `phase4_gpu_cpu_normal_n1000_run1.txt`
- `phase4_gpu_cpu_normal_n1000_run2.txt`
- `phase4_gpu_cpu_normal_n1000_run3.txt`
- `phase4_gpu_cpu_normal_n1000_run4.txt`
- `phase4_gpu_cpu_normal_n1000_run5.txt`
- `phase4_gpu_cpu_normal_n512_run1.txt`
- `phase4_gpu_cpu_normal_n512_run2.txt`
- `phase4_gpu_cpu_normal_n512_run3.txt`
- `phase4_gpu_cpu_normal_n512_run4.txt`
- `phase4_gpu_cpu_normal_n512_run5.txt`
- `phase4_gpu_cublas_deferred_t8_n1000_run1.txt`
- `phase4_gpu_cublas_deferred_t8_n1000_run2.txt`
- `phase4_gpu_cublas_deferred_t8_n1000_run3.txt`
- `phase4_gpu_cublas_deferred_t8_n1000_run4.txt`
- `phase4_gpu_cublas_deferred_t8_n1000_run5.txt`
- `phase4_gpu_cublas_deferred_t8_n512_run1.txt`
- `phase4_gpu_cublas_deferred_t8_n512_run2.txt`
- `phase4_gpu_cublas_deferred_t8_n512_run3.txt`
- `phase4_gpu_cublas_deferred_t8_n512_run4.txt`
- `phase4_gpu_cublas_deferred_t8_n512_run5.txt`
- `phase4_gpu_cublas_tuv_n1000_run1.txt`
- `phase4_gpu_cublas_tuv_n1000_run2.txt`
- `phase4_gpu_cublas_tuv_n1000_run3.txt`
- `phase4_gpu_cublas_tuv_n1000_run4.txt`
- `phase4_gpu_cublas_tuv_n1000_run5.txt`
- `phase4_gpu_cublas_tuv_n512_run1.txt`
- `phase4_gpu_cublas_tuv_n512_run2.txt`
- `phase4_gpu_cublas_tuv_n512_run3.txt`
- `phase4_gpu_cublas_tuv_n512_run4.txt`
- `phase4_gpu_cublas_tuv_n512_run5.txt`
- `phase4_gpu_kernel_deferred_t8_n1000_run1.txt`
- `phase4_gpu_kernel_deferred_t8_n1000_run2.txt`
- `phase4_gpu_kernel_deferred_t8_n1000_run3.txt`
- `phase4_gpu_kernel_deferred_t8_n1000_run4.txt`
- `phase4_gpu_kernel_deferred_t8_n1000_run5.txt`
- `phase4_gpu_kernel_deferred_t8_n512_run1.txt`
- `phase4_gpu_kernel_deferred_t8_n512_run2.txt`
- `phase4_gpu_kernel_deferred_t8_n512_run3.txt`
- `phase4_gpu_kernel_deferred_t8_n512_run4.txt`
- `phase4_gpu_kernel_deferred_t8_n512_run5.txt`
- `phase4_replay_summary.md`
- `phase4_seed_deferred_t8_s20261408.txt`
- `phase4_seed_deferred_t8_s20261409.txt`
- `phase4_seed_deferred_t8_s20261410.txt`
- `phase4_seed_tuv_s20261408.txt`
- `phase4_seed_tuv_s20261409.txt`
- `phase4_seed_tuv_s20261410.txt`
- `phase4_special_deferred_t1.txt`
- `phase4_special_deferred_t4.txt`
- `phase4_special_normal.txt`
- `phase4_threads_t1_tile4_run1.txt`
- `phase4_threads_t1_tile4_run2.txt`
- `phase4_threads_t1_tile4_run3.txt`
- `phase4_threads_t1_tile4_run4.txt`
- `phase4_threads_t1_tile4_run5.txt`
- `phase4_threads_t2_tile4_run1.txt`
- `phase4_threads_t2_tile4_run2.txt`
- `phase4_threads_t2_tile4_run3.txt`
- `phase4_threads_t2_tile4_run4.txt`
- `phase4_threads_t2_tile4_run5.txt`
- `phase4_threads_t4_tile4_run1.txt`
- `phase4_threads_t4_tile4_run2.txt`
- `phase4_threads_t4_tile4_run3.txt`
- `phase4_threads_t4_tile4_run4.txt`
- `phase4_threads_t4_tile4_run5.txt`
- `phase4_threads_t8_tile4_run1.txt`
- `phase4_threads_t8_tile4_run2.txt`
- `phase4_threads_t8_tile4_run3.txt`
- `phase4_threads_t8_tile4_run4.txt`
- `phase4_threads_t8_tile4_run5.txt`
- `phase4_tile_t4_tile128_run1.txt`
- `phase4_tile_t4_tile128_run2.txt`
- `phase4_tile_t4_tile128_run3.txt`
- `phase4_tile_t4_tile16_run1.txt`
- `phase4_tile_t4_tile16_run2.txt`
- `phase4_tile_t4_tile16_run3.txt`
- `phase4_tile_t4_tile1_run1.txt`
- `phase4_tile_t4_tile1_run2.txt`
- `phase4_tile_t4_tile1_run3.txt`
- `phase4_tile_t4_tile32_run1.txt`
- `phase4_tile_t4_tile32_run2.txt`
- `phase4_tile_t4_tile32_run3.txt`
- `phase4_tile_t4_tile4_run1.txt`
- `phase4_tile_t4_tile4_run2.txt`
- `phase4_tile_t4_tile4_run3.txt`
- `phase4_tile_t4_tile64_run1.txt`
- `phase4_tile_t4_tile64_run2.txt`
- `phase4_tile_t4_tile64_run3.txt`
- `phase4_tile_t4_tile8_run1.txt`
- `phase4_tile_t4_tile8_run2.txt`
- `phase4_tile_t4_tile8_run3.txt`

# 16. 最终Git状态
`git diff --stat`:

```text
build_gpu.bat |   1 +
 gkh.cpp       | 357 ++++++++++++++++++++++++++++++++++++++++++------
 gkh.h         |  37 ++++-
 main.cpp      | 432 +++++++++++++++++++++++++++++++++++++++++++++++++++++-----
 main_gpu.exe  | Bin 529920 -> 546816 bytes
 5 files changed, 747 insertions(+), 80 deletions(-)
```

`git status`:

```text
On branch svd-lab5-gpu
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   build_gpu.bat
	modified:   gkh.cpp
	modified:   gkh.h
	modified:   main.cpp
	modified:   main_gpu.exe

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	results_gpu/phase3_ablation_normal_bonly_run1.txt
	results_gpu/phase3_ablation_normal_bonly_run2.txt
	results_gpu/phase3_ablation_normal_bonly_run3.txt
	results_gpu/phase3_ablation_normal_bonly_run4.txt
	results_gpu/phase3_ablation_normal_bonly_run5.txt
	results_gpu/phase3_ablation_normal_full_run1.txt
	results_gpu/phase3_ablation_normal_full_run2.txt
	results_gpu/phase3_ablation_normal_full_run3.txt
	results_gpu/phase3_ablation_normal_full_run4.txt
	results_gpu/phase3_ablation_normal_full_run5.txt
	results_gpu/phase3_ablation_tuv_full_run1.txt
	results_gpu/phase3_ablation_tuv_full_run2.txt
	results_gpu/phase3_ablation_tuv_full_run3.txt
	results_gpu/phase3_ablation_tuv_full_run4.txt
	results_gpu/phase3_ablation_tuv_full_run5.txt
	results_gpu/phase3_breakdown_normal_n1000.txt
	results_gpu/phase3_breakdown_tuv_n1000.txt
	results_gpu/phase3_build.txt
	results_gpu/phase3_check_cpu_normal.txt
	results_gpu/phase3_check_cpu_tuv.txt
	results_gpu/phase3_check_cublas_tuv.txt
	results_gpu/phase3_check_kernel_tuv.txt
	results_gpu/phase3_e2e_cpu_normal_n1000_run1.txt
	results_gpu/phase3_e2e_cpu_normal_n1000_run2.txt
	results_gpu/phase3_e2e_cpu_normal_n1000_run3.txt
	results_gpu/phase3_e2e_cpu_normal_n1000_run4.txt
	results_gpu/phase3_e2e_cpu_normal_n1000_run5.txt
	results_gpu/phase3_e2e_cpu_normal_n512_run1.txt
	results_gpu/phase3_e2e_cpu_normal_n512_run2.txt
	results_gpu/phase3_e2e_cpu_normal_n512_run3.txt
	results_gpu/phase3_e2e_cpu_normal_n512_run4.txt
	results_gpu/phase3_e2e_cpu_normal_n512_run5.txt
	results_gpu/phase3_e2e_cublas_normal_n1000_run1.txt
	results_gpu/phase3_e2e_cublas_normal_n1000_run2.txt
	results_gpu/phase3_e2e_cublas_normal_n1000_run3.txt
	results_gpu/phase3_e2e_cublas_normal_n1000_run4.txt
	results_gpu/phase3_e2e_cublas_normal_n1000_run5.txt
	results_gpu/phase3_e2e_cublas_normal_n512_run1.txt
	results_gpu/phase3_e2e_cublas_normal_n512_run2.txt
	results_gpu/phase3_e2e_cublas_normal_n512_run3.txt
	results_gpu/phase3_e2e_cublas_normal_n512_run4.txt
	results_gpu/phase3_e2e_cublas_normal_n512_run5.txt
	results_gpu/phase3_e2e_cublas_tuv_n1000_run1.txt
	results_gpu/phase3_e2e_cublas_tuv_n1000_run2.txt
	results_gpu/phase3_e2e_cublas_tuv_n1000_run3.txt
	results_gpu/phase3_e2e_cublas_tuv_n1000_run4.txt
	results_gpu/phase3_e2e_cublas_tuv_n1000_run5.txt
	results_gpu/phase3_e2e_cublas_tuv_n512_run1.txt
	results_gpu/phase3_e2e_cublas_tuv_n512_run2.txt
	results_gpu/phase3_e2e_cublas_tuv_n512_run3.txt
	results_gpu/phase3_e2e_cublas_tuv_n512_run4.txt
	results_gpu/phase3_e2e_cublas_tuv_n512_run5.txt
	results_gpu/phase3_e2e_kernel_tuv_n1000_run1.txt
	results_gpu/phase3_e2e_kernel_tuv_n1000_run2.txt
	results_gpu/phase3_e2e_kernel_tuv_n1000_run3.txt
	results_gpu/phase3_e2e_kernel_tuv_n1000_run4.txt
	results_gpu/phase3_e2e_kernel_tuv_n1000_run5.txt
	results_gpu/phase3_e2e_kernel_tuv_n512_run1.txt
	results_gpu/phase3_e2e_kernel_tuv_n512_run2.txt
	results_gpu/phase3_e2e_kernel_tuv_n512_run3.txt
	results_gpu/phase3_e2e_kernel_tuv_n512_run4.txt
	results_gpu/phase3_e2e_kernel_tuv_n512_run5.txt
	results_gpu/phase3_scale_normal_n1000_run1.txt
	results_gpu/phase3_scale_normal_n1000_run2.txt
	results_gpu/phase3_scale_normal_n1000_run3.txt
	results_gpu/phase3_scale_normal_n1000_run4.txt
	results_gpu/phase3_scale_normal_n1000_run5.txt
	results_gpu/phase3_scale_normal_n256_run1.txt
	results_gpu/phase3_scale_normal_n256_run2.txt
	results_gpu/phase3_scale_normal_n256_run3.txt
	results_gpu/phase3_scale_normal_n256_run4.txt
	results_gpu/phase3_scale_normal_n256_run5.txt
	results_gpu/phase3_scale_normal_n512_run1.txt
	results_gpu/phase3_scale_normal_n512_run2.txt
	results_gpu/phase3_scale_normal_n512_run3.txt
	results_gpu/phase3_scale_normal_n512_run4.txt
	results_gpu/phase3_scale_normal_n512_run5.txt
	results_gpu/phase3_scale_tuv_n1000_run1.txt
	results_gpu/phase3_scale_tuv_n1000_run2.txt
	results_gpu/phase3_scale_tuv_n1000_run3.txt
	results_gpu/phase3_scale_tuv_n1000_run4.txt
	results_gpu/phase3_scale_tuv_n1000_run5.txt
	results_gpu/phase3_scale_tuv_n256_run1.txt
	results_gpu/phase3_scale_tuv_n256_run2.txt
	results_gpu/phase3_scale_tuv_n256_run3.txt
	results_gpu/phase3_scale_tuv_n256_run4.txt
	results_gpu/phase3_scale_tuv_n256_run5.txt
	results_gpu/phase3_scale_tuv_n512_run1.txt
	results_gpu/phase3_scale_tuv_n512_run2.txt
	results_gpu/phase3_scale_tuv_n512_run3.txt
	results_gpu/phase3_scale_tuv_n512_run4.txt
	results_gpu/phase3_scale_tuv_n512_run5.txt
	results_gpu/phase3_seed_normal_s20261408.txt
	results_gpu/phase3_seed_normal_s20261409.txt
	results_gpu/phase3_seed_normal_s20261410.txt
	results_gpu/phase3_seed_tuv_s20261408.txt
	results_gpu/phase3_seed_tuv_s20261409.txt
	results_gpu/phase3_seed_tuv_s20261410.txt
	results_gpu/phase3_special_normal.txt
	results_gpu/phase3_special_tuv.txt
	results_gpu/phase3_tuv_summary.md
	results_gpu/phase4_breakdown_deferred_best.txt
	results_gpu/phase4_breakdown_deferred_t1.txt
	results_gpu/phase4_breakdown_normal.txt
	results_gpu/phase4_breakdown_tuv.txt
	results_gpu/phase4_build.txt
	results_gpu/phase4_check_cublas_deferred_t4.txt
	results_gpu/phase4_check_deferred_t1.txt
	results_gpu/phase4_check_deferred_t4.txt
	results_gpu/phase4_check_kernel_deferred_t4.txt
	results_gpu/phase4_check_normal.txt
	results_gpu/phase4_check_tuv.txt
	results_gpu/phase4_compare_deferred_t1_n1000_run1.txt
	results_gpu/phase4_compare_deferred_t1_n1000_run2.txt
	results_gpu/phase4_compare_deferred_t1_n1000_run3.txt
	results_gpu/phase4_compare_deferred_t1_n1000_run4.txt
	results_gpu/phase4_compare_deferred_t1_n1000_run5.txt
	results_gpu/phase4_compare_deferred_t1_n256_run1.txt
	results_gpu/phase4_compare_deferred_t1_n256_run2.txt
	results_gpu/phase4_compare_deferred_t1_n256_run3.txt
	results_gpu/phase4_compare_deferred_t1_n256_run4.txt
	results_gpu/phase4_compare_deferred_t1_n256_run5.txt
	results_gpu/phase4_compare_deferred_t1_n512_run1.txt
	results_gpu/phase4_compare_deferred_t1_n512_run2.txt
	results_gpu/phase4_compare_deferred_t1_n512_run3.txt
	results_gpu/phase4_compare_deferred_t1_n512_run4.txt
	results_gpu/phase4_compare_deferred_t1_n512_run5.txt
	results_gpu/phase4_compare_deferred_t8_n1000_run1.txt
	results_gpu/phase4_compare_deferred_t8_n1000_run2.txt
	results_gpu/phase4_compare_deferred_t8_n1000_run3.txt
	results_gpu/phase4_compare_deferred_t8_n1000_run4.txt
	results_gpu/phase4_compare_deferred_t8_n1000_run5.txt
	results_gpu/phase4_compare_deferred_t8_n256_run1.txt
	results_gpu/phase4_compare_deferred_t8_n256_run2.txt
	results_gpu/phase4_compare_deferred_t8_n256_run3.txt
	results_gpu/phase4_compare_deferred_t8_n256_run4.txt
	results_gpu/phase4_compare_deferred_t8_n256_run5.txt
	results_gpu/phase4_compare_deferred_t8_n512_run1.txt
	results_gpu/phase4_compare_deferred_t8_n512_run2.txt
	results_gpu/phase4_compare_deferred_t8_n512_run3.txt
	results_gpu/phase4_compare_deferred_t8_n512_run4.txt
	results_gpu/phase4_compare_deferred_t8_n512_run5.txt
	results_gpu/phase4_compare_normal_n1000_run1.txt
	results_gpu/phase4_compare_normal_n1000_run2.txt
	results_gpu/phase4_compare_normal_n1000_run3.txt
	results_gpu/phase4_compare_normal_n1000_run4.txt
	results_gpu/phase4_compare_normal_n1000_run5.txt
	results_gpu/phase4_compare_normal_n256_run1.txt
	results_gpu/phase4_compare_normal_n256_run2.txt
	results_gpu/phase4_compare_normal_n256_run3.txt
	results_gpu/phase4_compare_normal_n256_run4.txt
	results_gpu/phase4_compare_normal_n256_run5.txt
	results_gpu/phase4_compare_normal_n512_run1.txt
	results_gpu/phase4_compare_normal_n512_run2.txt
	results_gpu/phase4_compare_normal_n512_run3.txt
	results_gpu/phase4_compare_normal_n512_run4.txt
	results_gpu/phase4_compare_normal_n512_run5.txt
	results_gpu/phase4_compare_tuv_n1000_run1.txt
	results_gpu/phase4_compare_tuv_n1000_run2.txt
	results_gpu/phase4_compare_tuv_n1000_run3.txt
	results_gpu/phase4_compare_tuv_n1000_run4.txt
	results_gpu/phase4_compare_tuv_n1000_run5.txt
	results_gpu/phase4_compare_tuv_n256_run1.txt
	results_gpu/phase4_compare_tuv_n256_run2.txt
	results_gpu/phase4_compare_tuv_n256_run3.txt
	results_gpu/phase4_compare_tuv_n256_run4.txt
	results_gpu/phase4_compare_tuv_n256_run5.txt
	results_gpu/phase4_compare_tuv_n512_run1.txt
	results_gpu/phase4_compare_tuv_n512_run2.txt
	results_gpu/phase4_compare_tuv_n512_run3.txt
	results_gpu/phase4_compare_tuv_n512_run4.txt
	results_gpu/phase4_compare_tuv_n512_run5.txt
	results_gpu/phase4_equiv_deferred_t1.txt
	results_gpu/phase4_equiv_deferred_t4.txt
	results_gpu/phase4_equiv_normal.txt
	results_gpu/phase4_equiv_tuv.txt
	results_gpu/phase4_gpu_cpu_normal_n1000_run1.txt
	results_gpu/phase4_gpu_cpu_normal_n1000_run2.txt
	results_gpu/phase4_gpu_cpu_normal_n1000_run3.txt
	results_gpu/phase4_gpu_cpu_normal_n1000_run4.txt
	results_gpu/phase4_gpu_cpu_normal_n1000_run5.txt
	results_gpu/phase4_gpu_cpu_normal_n512_run1.txt
	results_gpu/phase4_gpu_cpu_normal_n512_run2.txt
	results_gpu/phase4_gpu_cpu_normal_n512_run3.txt
	results_gpu/phase4_gpu_cpu_normal_n512_run4.txt
	results_gpu/phase4_gpu_cpu_normal_n512_run5.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n1000_run1.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n1000_run2.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n1000_run3.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n1000_run4.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n1000_run5.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n512_run1.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n512_run2.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n512_run3.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n512_run4.txt
	results_gpu/phase4_gpu_cublas_deferred_t8_n512_run5.txt
	results_gpu/phase4_gpu_cublas_tuv_n1000_run1.txt
	results_gpu/phase4_gpu_cublas_tuv_n1000_run2.txt
	results_gpu/phase4_gpu_cublas_tuv_n1000_run3.txt
	results_gpu/phase4_gpu_cublas_tuv_n1000_run4.txt
	results_gpu/phase4_gpu_cublas_tuv_n1000_run5.txt
	results_gpu/phase4_gpu_cublas_tuv_n512_run1.txt
	results_gpu/phase4_gpu_cublas_tuv_n512_run2.txt
	results_gpu/phase4_gpu_cublas_tuv_n512_run3.txt
	results_gpu/phase4_gpu_cublas_tuv_n512_run4.txt
	results_gpu/phase4_gpu_cublas_tuv_n512_run5.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n1000_run1.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n1000_run2.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n1000_run3.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n1000_run4.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n1000_run5.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n512_run1.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n512_run2.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n512_run3.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n512_run4.txt
	results_gpu/phase4_gpu_kernel_deferred_t8_n512_run5.txt
	results_gpu/phase4_replay_summary.md
	results_gpu/phase4_seed_deferred_t8_s20261408.txt
	results_gpu/phase4_seed_deferred_t8_s20261409.txt
	results_gpu/phase4_seed_deferred_t8_s20261410.txt
	results_gpu/phase4_seed_tuv_s20261408.txt
	results_gpu/phase4_seed_tuv_s20261409.txt
	results_gpu/phase4_seed_tuv_s20261410.txt
	results_gpu/phase4_special_deferred_t1.txt
	results_gpu/phase4_special_deferred_t4.txt
	results_gpu/phase4_special_normal.txt
	results_gpu/phase4_threads_t1_tile4_run1.txt
	results_gpu/phase4_threads_t1_tile4_run2.txt
	results_gpu/phase4_threads_t1_tile4_run3.txt
	results_gpu/phase4_threads_t1_tile4_run4.txt
	results_gpu/phase4_threads_t1_tile4_run5.txt
	results_gpu/phase4_threads_t2_tile4_run1.txt
	results_gpu/phase4_threads_t2_tile4_run2.txt
	results_gpu/phase4_threads_t2_tile4_run3.txt
	results_gpu/phase4_threads_t2_tile4_run4.txt
	results_gpu/phase4_threads_t2_tile4_run5.txt
	results_gpu/phase4_threads_t4_tile4_run1.txt
	results_gpu/phase4_threads_t4_tile4_run2.txt
	results_gpu/phase4_threads_t4_tile4_run3.txt
	results_gpu/phase4_threads_t4_tile4_run4.txt
	results_gpu/phase4_threads_t4_tile4_run5.txt
	results_gpu/phase4_threads_t8_tile4_run1.txt
	results_gpu/phase4_threads_t8_tile4_run2.txt
	results_gpu/phase4_threads_t8_tile4_run3.txt
	results_gpu/phase4_threads_t8_tile4_run4.txt
	results_gpu/phase4_threads_t8_tile4_run5.txt
	results_gpu/phase4_tile_t4_tile128_run1.txt
	results_gpu/phase4_tile_t4_tile128_run2.txt
	results_gpu/phase4_tile_t4_tile128_run3.txt
	results_gpu/phase4_tile_t4_tile16_run1.txt
	results_gpu/phase4_tile_t4_tile16_run2.txt
	results_gpu/phase4_tile_t4_tile16_run3.txt
	results_gpu/phase4_tile_t4_tile1_run1.txt
	results_gpu/phase4_tile_t4_tile1_run2.txt
	results_gpu/phase4_tile_t4_tile1_run3.txt
	results_gpu/phase4_tile_t4_tile32_run1.txt
	results_gpu/phase4_tile_t4_tile32_run2.txt
	results_gpu/phase4_tile_t4_tile32_run3.txt
	results_gpu/phase4_tile_t4_tile4_run1.txt
	results_gpu/phase4_tile_t4_tile4_run2.txt
	results_gpu/phase4_tile_t4_tile4_run3.txt
	results_gpu/phase4_tile_t4_tile64_run1.txt
	results_gpu/phase4_tile_t4_tile64_run2.txt
	results_gpu/phase4_tile_t4_tile64_run3.txt
	results_gpu/phase4_tile_t4_tile8_run1.txt
	results_gpu/phase4_tile_t4_tile8_run2.txt
	results_gpu/phase4_tile_t4_tile8_run3.txt

no changes added to commit (use "git add" and/or "git commit -a")

```
