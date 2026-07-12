# 1. 修改前状态

Start state was recorded before edits. Actual branch remained `svd-lab5-gpu`; actual HEAD during this run was `9f5acfd`. The user context mentioned `c08f9d7`, but the repository reported `9f5acfd` and initially `git status` was clean, so no branch/history operation was performed. No reset, clean, checkout, branch switch, or commit was executed.

# 2. 数学等价性

Normal GKH maintains `A = U B V^T`. For a left update `B <- L B`, correctness requires `U <- U L^T`. With `UT = U^T`, this is `UT <- L UT`, implemented by applying the same left-row rotation to rows `r0,r1` of `UT`. For a right update `B <- B R`, normal accumulation is `V <- V R`. With `VT = V^T`, this is `VT <- R^T VT`; because `apply_left_rows(c,s)` applies `[c s; -s c]`, the TUV path uses `apply_left_rows(VT, c0, c1, c, -s)`. B updates are unchanged.

# 3. 代码修改

- `gkh.h`: added `GKHLayout`, `GKHOptions`, `transpose_in_ms`, and `transpose_out_ms`; `gkh_svd_from_bidiagonal` now accepts options with defaults preserving old calls.
- `gkh.cpp`: added direct transpose helper, normal/TUV/U-V-skip accumulation routing, TUV input/output transposes, and separate mode2 transpose timing. GKH convergence math and B bulge chasing are unchanged.
- `main.cpp`: added `--gkh-layout normal|tuv`, `--gkh-uv-update 0|1`, B-only validation/logging, TUV profile fields, and `--mode gkh-special-check`.

# 4. 正确性
Build succeeded; output is saved in `phase3_build.txt`. The build log lists compilation of `main.cpp`, `gkh.cpp`, `bidiagonalization.cpp`, and `bidiagonalization_gpu.cu`, with no build failure.

| file | PASS count | FAIL count |
|---|---|---|
| phase3_check_cpu_normal.txt | 5/5 | 0 |
| phase3_check_cpu_tuv.txt | 5/5 | 0 |
| phase3_check_kernel_tuv.txt | 5/5 | 0 |
| phase3_check_cublas_tuv.txt | 5/5 | 0 |

| file | case | converged | zero_chase_calls | pass | rel_recon |
|---|---|---|---|---|---|
| phase3_special_normal.txt | zero_diagonal_chase | 1 | 1 | 1 | 8.663e-16 |
| phase3_special_normal.txt | already_diagonal | 1 | 0 | 1 | 0.000e+00 |
| phase3_special_normal.txt | two_active_blocks | 1 | 0 | 1 | 3.383e-16 |
| phase3_special_tuv.txt | zero_diagonal_chase | 1 | 1 | 1 | 8.663e-16 |
| phase3_special_tuv.txt | already_diagonal | 1 | 0 | 1 | 0.000e+00 |
| phase3_special_tuv.txt | two_active_blocks | 1 | 0 | 1 | 3.383e-16 |

# 5. B-only消融
| version | mean gkh_ms | median | min | max | stddev | CV | outer_iter | block_steps | rotations | deflations |
|---|---|---|---|---|---|---|---|---|---|---|
| normal_full | 6568.108 | 6501.790 | 6480.680 | 6772.780 | 124.685 | 1.90% | 1434 | 1441 | 1558190 | 997 |
| normal_bonly | 2630.070 | 2629.670 | 2583.720 | 2703.200 | 47.465 | 1.80% | 1434 | 1441 | 1558190 | 997 |
| tuv_full | 4149.114 | 4021.130 | 3933.670 | 4501.190 | 239.778 | 5.78% | 1434 | 1441 | 1558190 | 997 |

UV contribution ratio by medians: `59.55%`. TUV GKH speedup over normal by medians: `1.617x`. B-only is a diagnostic ablation only; it skips U/V accumulation and is not a valid SVD output.

# 6. normal与TUV规模对比
| n | normal GKH med | TUV GKH med | GKH speedup | normal total med | TUV total med | E2E speedup | normal iter | TUV iter | normal rotations | TUV rotations | TUV rel_recon |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 256 | 131.512 | 83.791 | 1.570 | 149.958 | 101.892 | 1.472 | 386 | 386 | 108190 | 108190 | 3.302e-13 |
| 512 | 4580.880 | 1802.010 | 2.542 | 4749.770 | 1988.150 | 2.389 | 750 | 750 | 420100 | 420100 | 3.602e-13 |
| 1000 | 6455.610 | 4022.170 | 1.605 | 8304.450 | 5922.420 | 1.402 | 1434 | 1434 | 1558190 | 1558190 | 3.518e-13 |

# 7. 本地异构端到端结果
| n | impl/layout | bidiag med | GKH med | total med | speedup vs cpu normal | GKH vs cublas normal | iterations | rotations | rel_recon |
|---|---|---|---|---|---|---|---|---|---|
| 512 | cpu+normal | 176.590 | 4457.580 | 4632.400 | 1.000 | 1.000 | 750 | 420100 | 3.602e-13 |
| 512 | gpu_cublas+normal | 106.999 | 4120.230 | 4221.170 | 1.097 | 1.000 | 750 | 420632 | 3.791e-13 |
| 512 | gpu_cublas+tuv | 107.300 | 1824.590 | 1931.890 | 2.398 | 2.258 | 750 | 420632 | 3.791e-13 |
| 512 | gpu_kernel+tuv | 103.102 | 1849.160 | 1947.120 | 2.379 | 2.228 | 750 | 420100 | 3.604e-13 |
| 1000 | cpu+normal | 1989.320 | 7081.160 | 9056.020 | 1.000 | 1.000 | 1434 | 1558190 | 3.518e-13 |
| 1000 | gpu_cublas+normal | 252.160 | 6952.080 | 7206.270 | 1.257 | 1.000 | 1434 | 1558190 | 3.521e-13 |
| 1000 | gpu_cublas+tuv | 244.630 | 4191.030 | 4437.240 | 2.041 | 1.659 | 1434 | 1558190 | 3.521e-13 |
| 1000 | gpu_kernel+tuv | 295.439 | 4130.850 | 4420.410 | 2.049 | 1.683 | 1434 | 1558190 | 3.521e-13 |

# 8. 多seed稳健性
| seed | normal gkh_ms | TUV gkh_ms | speedup | normal iter | TUV iter | normal rotations | TUV rotations | normal steps | TUV steps |
|---|---|---|---|---|---|---|---|---|---|
| 20261408 | 7343.280 | 4290.260 | 1.712 | 1434 | 1434 | 1558190 | 1558190 | 1441 | 1441 |
| 20261409 | 7155.860 | 4476.570 | 1.599 | 1430 | 1430 | 1554058 | 1554058 | 1433 | 1433 |
| 20261410 | 8131.940 | 4334.240 | 1.876 | 1435 | 1435 | 1560130 | 1560130 | 1442 | 1442 |

# 9. 转置开销与摊销
| layout | gkh_ms | cleanup_ms | block_step_ms | finalize_ms | transpose_in_ms | transpose_out_ms | tuv_extra_ms | profiled_total_ms |
|---|---|---|---|---|---|---|---|---|
| normal | 7160.940 | 1314.350 | 5800.180 | 11.422 | 0 | 0 | 0 | 7155.390 |
| tuv | 4311.970 | 1290.990 | 2968.280 | 10.554 | 5.196 | 5.440 | 10.636 | 4307.670 |

For the TUV mode2 run, transpose extra was `10.636` ms, `0.25%` of measured TUV GKH time. The normal/TUV block-step comparison shows how much of the original row-major column-update cost is removed from the dominant rotation loop.

# 10. 工作量等价性
| scope | n | normal iter | TUV iter | normal steps | TUV steps | normal rotations | TUV rotations | normal deflations | TUV deflations |
|---|---|---|---|---|---|---|---|---|---|
| ablation first run | 1000 | 1434 | 1434 | 1441 | 1441 | 1558190 | 1558190 | 997 | 997 |
| scale n=256 first run | 256 | 386 | 386 | 386 | 386 | 108190 | 108190 | 255 | 255 |
| scale n=512 first run | 512 | 750 | 750 | 757 | 757 | 420100 | 420100 | 509 | 509 |
| scale n=1000 first run | 1000 | 1434 | 1434 | 1441 | 1441 | 1558190 | 1558190 | 997 | 997 |

# 11. 与前序实验的融合
Phase 2 showed almost one nontrivial active block per iteration, so block-level multithreading/MPI scheduling cannot create much parallel work. The dominant cost is the ordered stream of Givens rotations, and in row-major storage the old U/V column updates are cache-unfriendly strided writes. TUV converts those accumulations into contiguous row updates, matching the SIMD lesson that continuous memory access matters. The rotation-log idea from earlier MPI analysis also separates B advancement from later U/V accumulation; this phase keeps the same iteration path but changes only the local memory layout. Once GPU Householder reduces bidiagonalization time, this mostly sequential GKH stage becomes the endpoint bottleneck, and TUV attacks its largest memory-access cost without changing convergence.

# 12. 与同类TUV思路的区别
This implementation was derived from the matrix equivalence above and the local code paths, not copied from another source. Its experimental framing combines Phase1 low-disturbance GPU timing, Phase2 multi-seed workload profiling, B-only ablation, explicit zero-diagonal special-path checks, transpose-cost accounting, independent-process median statistics, and CPU/GPU end-to-end combinations.

# 13. 限制
- No OpenMP TUV is implemented.
- No hardware cache counters were collected.
- Windows/WDDM background activity can still affect timing.
- B-only is not a valid SVD output and exists only for performance attribution.

# 14. 原始日志索引
- `phase3_ablation_normal_bonly_run1.txt`
- `phase3_ablation_normal_bonly_run2.txt`
- `phase3_ablation_normal_bonly_run3.txt`
- `phase3_ablation_normal_bonly_run4.txt`
- `phase3_ablation_normal_bonly_run5.txt`
- `phase3_ablation_normal_full_run1.txt`
- `phase3_ablation_normal_full_run2.txt`
- `phase3_ablation_normal_full_run3.txt`
- `phase3_ablation_normal_full_run4.txt`
- `phase3_ablation_normal_full_run5.txt`
- `phase3_ablation_tuv_full_run1.txt`
- `phase3_ablation_tuv_full_run2.txt`
- `phase3_ablation_tuv_full_run3.txt`
- `phase3_ablation_tuv_full_run4.txt`
- `phase3_ablation_tuv_full_run5.txt`
- `phase3_breakdown_normal_n1000.txt`
- `phase3_breakdown_tuv_n1000.txt`
- `phase3_build.txt`
- `phase3_check_cpu_normal.txt`
- `phase3_check_cpu_tuv.txt`
- `phase3_check_cublas_tuv.txt`
- `phase3_check_kernel_tuv.txt`
- `phase3_e2e_cpu_normal_n1000_run1.txt`
- `phase3_e2e_cpu_normal_n1000_run2.txt`
- `phase3_e2e_cpu_normal_n1000_run3.txt`
- `phase3_e2e_cpu_normal_n1000_run4.txt`
- `phase3_e2e_cpu_normal_n1000_run5.txt`
- `phase3_e2e_cpu_normal_n512_run1.txt`
- `phase3_e2e_cpu_normal_n512_run2.txt`
- `phase3_e2e_cpu_normal_n512_run3.txt`
- `phase3_e2e_cpu_normal_n512_run4.txt`
- `phase3_e2e_cpu_normal_n512_run5.txt`
- `phase3_e2e_cublas_normal_n1000_run1.txt`
- `phase3_e2e_cublas_normal_n1000_run2.txt`
- `phase3_e2e_cublas_normal_n1000_run3.txt`
- `phase3_e2e_cublas_normal_n1000_run4.txt`
- `phase3_e2e_cublas_normal_n1000_run5.txt`
- `phase3_e2e_cublas_normal_n512_run1.txt`
- `phase3_e2e_cublas_normal_n512_run2.txt`
- `phase3_e2e_cublas_normal_n512_run3.txt`
- `phase3_e2e_cublas_normal_n512_run4.txt`
- `phase3_e2e_cublas_normal_n512_run5.txt`
- `phase3_e2e_cublas_tuv_n1000_run1.txt`
- `phase3_e2e_cublas_tuv_n1000_run2.txt`
- `phase3_e2e_cublas_tuv_n1000_run3.txt`
- `phase3_e2e_cublas_tuv_n1000_run4.txt`
- `phase3_e2e_cublas_tuv_n1000_run5.txt`
- `phase3_e2e_cublas_tuv_n512_run1.txt`
- `phase3_e2e_cublas_tuv_n512_run2.txt`
- `phase3_e2e_cublas_tuv_n512_run3.txt`
- `phase3_e2e_cublas_tuv_n512_run4.txt`
- `phase3_e2e_cublas_tuv_n512_run5.txt`
- `phase3_e2e_kernel_tuv_n1000_run1.txt`
- `phase3_e2e_kernel_tuv_n1000_run2.txt`
- `phase3_e2e_kernel_tuv_n1000_run3.txt`
- `phase3_e2e_kernel_tuv_n1000_run4.txt`
- `phase3_e2e_kernel_tuv_n1000_run5.txt`
- `phase3_e2e_kernel_tuv_n512_run1.txt`
- `phase3_e2e_kernel_tuv_n512_run2.txt`
- `phase3_e2e_kernel_tuv_n512_run3.txt`
- `phase3_e2e_kernel_tuv_n512_run4.txt`
- `phase3_e2e_kernel_tuv_n512_run5.txt`
- `phase3_scale_normal_n1000_run1.txt`
- `phase3_scale_normal_n1000_run2.txt`
- `phase3_scale_normal_n1000_run3.txt`
- `phase3_scale_normal_n1000_run4.txt`
- `phase3_scale_normal_n1000_run5.txt`
- `phase3_scale_normal_n256_run1.txt`
- `phase3_scale_normal_n256_run2.txt`
- `phase3_scale_normal_n256_run3.txt`
- `phase3_scale_normal_n256_run4.txt`
- `phase3_scale_normal_n256_run5.txt`
- `phase3_scale_normal_n512_run1.txt`
- `phase3_scale_normal_n512_run2.txt`
- `phase3_scale_normal_n512_run3.txt`
- `phase3_scale_normal_n512_run4.txt`
- `phase3_scale_normal_n512_run5.txt`
- `phase3_scale_tuv_n1000_run1.txt`
- `phase3_scale_tuv_n1000_run2.txt`
- `phase3_scale_tuv_n1000_run3.txt`
- `phase3_scale_tuv_n1000_run4.txt`
- `phase3_scale_tuv_n1000_run5.txt`
- `phase3_scale_tuv_n256_run1.txt`
- `phase3_scale_tuv_n256_run2.txt`
- `phase3_scale_tuv_n256_run3.txt`
- `phase3_scale_tuv_n256_run4.txt`
- `phase3_scale_tuv_n256_run5.txt`
- `phase3_scale_tuv_n512_run1.txt`
- `phase3_scale_tuv_n512_run2.txt`
- `phase3_scale_tuv_n512_run3.txt`
- `phase3_scale_tuv_n512_run4.txt`
- `phase3_scale_tuv_n512_run5.txt`
- `phase3_seed_normal_s20261408.txt`
- `phase3_seed_normal_s20261409.txt`
- `phase3_seed_normal_s20261410.txt`
- `phase3_seed_tuv_s20261408.txt`
- `phase3_seed_tuv_s20261409.txt`
- `phase3_seed_tuv_s20261410.txt`
- `phase3_special_normal.txt`
- `phase3_special_tuv.txt`
- `phase3_tuv_summary.md`

# 15. 最终Git状态
`git diff --stat`:

```text
gkh.cpp      | 202 +++++++++++++++++++++++++++++++++---------
 gkh.h        |  17 +++-
 main.cpp     | 285 +++++++++++++++++++++++++++++++++++++++++++++++++++--------
 main_gpu.exe | Bin 529920 -> 539136 bytes
 4 files changed, 425 insertions(+), 79 deletions(-)
```

`git status`:

```text
On branch svd-lab5-gpu
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
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

no changes added to commit (use "git add" and/or "git commit -a")

```
