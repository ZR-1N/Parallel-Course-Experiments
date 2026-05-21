OpenMP Guided with Parallel Cleanup
===================================

Version:
SVD_PARALLEL_MODE = 3
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2
SVD_PARALLEL_CLEANUP = 1
SVD_CLEANUP_MIN_ELEMENTS = 4096

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Parallel points:
1. Block-level GKH iteration:
   OpenMP guided scheduling over non-trivial active blocks.

2. Cleanup scan:
   OpenMP parallel for over rows in cleanup_bidiagonal_auto.
   Small matrices are processed serially to avoid OpenMP runtime overhead.
   Large matrices use OpenMP because cleanup_bidiagonal scans the full matrix.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3207.98
total GKH iteration time(ms): 22022

Large case profile:
iters=1425
cleanup_ms=1323.644
zero_ms=27.370
split_ms=26.941
block_ms=20592.261
final_ms=45.689
total_ms=22021.373
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
parallel_mode=3
num_threads=8
min_parallel_tasks=2
parallel_cleanup=1
avg_nontrivial_blocks_per_iter=1.012

Comparison:
OpenMP guided adaptive without parallel cleanup had cleanup_ms about 3686 ms
and total GKH time about 22304 ms in the representative run.
With parallel cleanup, cleanup_ms is reduced to about 1324 ms and total GKH time
is about 22022 ms.

Observation:
The cleanup scan is a regular matrix-wide loop and benefits from OpenMP parallelism.
However, total GKH time improves only moderately because the dominant block-step
phase still has limited block-level parallelism.
