GKH Profiling Instrumentation Baseline
======================================

Branch:
svd-lab3-pthread-openmp

Purpose:
This version adds profiling instrumentation to gkh_svd_from_bidiagonal.
No Pthread or OpenMP parallel algorithm has been added yet.

Command:
bash test.sh 1 1 1 -O O2 -s 20260409

Seed:
20260409

Correctness:
PASS: 5 / 5

Measured total result:
total bidiagonalization time(ms): 3621.56
total GKH iteration time(ms): 42973.9

Large case profile: random 1000x1000
m=1000
n=1000
converged=yes
iters=1425
cleanup_ms=3887.145
zero_ms=21.613
split_ms=23.751
block_ms=38970.746
final_ms=65.883
total_ms=42973.276
total_blocks=640529
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Performance observation:
This profiling version is slightly slower than the previous SIMD serial baseline.
This is expected because the algorithm has not been optimized in this step.
The additional cost comes from timer calls, statistic updates, stderr output, and normal server-side runtime fluctuation.

Important findings:
1. The dominant cost is one_block_step.
   In the 1000x1000 case, block_ms is 38970.746 ms out of total_ms 42973.276 ms.

2. cleanup_bidiagonal is also non-negligible.
   In the 1000x1000 case, cleanup_ms is 3887.145 ms.

3. The observed block-level parallelism is limited for this random 1000x1000 case.
   avg_nontrivial_blocks_per_iter is only 1.012.
   This means most GKH iterations contain only about one non-trivial active block.
   Therefore, simple block-level parallelism may have limited speedup and may even suffer from scheduling overhead.

4. These data will be used later to explain the performance of OpenMP and Pthread versions.
