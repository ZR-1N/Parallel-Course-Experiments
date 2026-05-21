OpenMP Guided + Parallel Cleanup Thread Scaling: Threads = 4
============================================================

Version:
SVD_PARALLEL_MODE = 3
SVD_NUM_THREADS = 4
SVD_MIN_PARALLEL_TASKS = 2
SVD_PARALLEL_CLEANUP = 1
SVD_CLEANUP_MIN_ELEMENTS = 4096

Command:
bash test.sh 1 1 4 -O O2 -s 20260409

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 4672.28
total GKH iteration time(ms): 22201.4

Large case profile:
m=1000
n=1000
converged=yes
iters=1425
cleanup_ms=1043.352
zero_ms=21.586
split_ms=25.623
block_ms=21061.011
final_ms=44.008
total_ms=22200.770
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
parallel_mode=3
num_threads=4
min_parallel_tasks=2
parallel_cleanup=1
avg_nontrivial_blocks_per_iter=1.012

Comparison:
threads=1 total GKH iteration time(ms): 28169.9
threads=2 total GKH iteration time(ms): 23681.8
threads=4 total GKH iteration time(ms): 22201.4

threads=1 cleanup_ms: 3470.756
threads=2 cleanup_ms: 2650.825
threads=4 cleanup_ms: 1043.352

Observation:
Compared with 1 and 2 threads, 4 threads further reduce cleanup_ms and total GKH iteration time.
The cleanup scan benefits clearly from row-level OpenMP parallelism.
However, block_ms does not decrease proportionally, because the block-level GKH phase is limited by the number of non-trivial active blocks.
