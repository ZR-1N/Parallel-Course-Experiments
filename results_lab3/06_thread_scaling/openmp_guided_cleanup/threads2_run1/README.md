OpenMP Guided + Parallel Cleanup Thread Scaling: Threads = 2
============================================================

Version:
SVD_PARALLEL_MODE = 3
SVD_NUM_THREADS = 2
SVD_MIN_PARALLEL_TASKS = 2
SVD_PARALLEL_CLEANUP = 1
SVD_CLEANUP_MIN_ELEMENTS = 4096

Command:
bash test.sh 1 1 2 -O O2 -s 20260409

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3795.10
total GKH iteration time(ms): 23681.8

Large case profile:
m=1000
n=1000
converged=yes
iters=1425
cleanup_ms=2650.825
zero_ms=28.490
split_ms=34.337
block_ms=20900.275
final_ms=62.296
total_ms=23681.139
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
parallel_mode=3
num_threads=2
min_parallel_tasks=2
parallel_cleanup=1
avg_nontrivial_blocks_per_iter=1.012

Comparison with threads=1:
threads=1 total GKH iteration time(ms): 28169.9
threads=2 total GKH iteration time(ms): 23681.8

threads=1 cleanup_ms: 3470.756
threads=2 cleanup_ms: 2650.825

Observation:
Compared with the 1-thread baseline, 2 threads reduce both cleanup_ms and total GKH iteration time.
This shows that the final combined implementation can benefit from additional threads, especially in the matrix-wide cleanup scan.
The block-level GKH phase is still limited by the number of non-trivial active blocks, so the speedup is not expected to be linear.
