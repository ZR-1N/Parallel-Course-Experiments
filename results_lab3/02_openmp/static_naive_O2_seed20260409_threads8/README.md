OpenMP Static Naive Block-Level Parallelism
===========================================

Version:
SVD_PARALLEL_MODE = 1
SVD_NUM_THREADS = 8

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Strategy:
Each GKH iteration collects non-trivial active blocks into a task list.
Then OpenMP schedule(static) is applied directly to the task list.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 4332.02
total GKH iteration time(ms): 26809.7

Large case profile:
iters=1425
cleanup_ms=3925.037
zero_ms=17.753
split_ms=23.189
block_ms=22783.637
final_ms=53.732
total_ms=26808.690
total_blocks=640529
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Observation:
This naive OpenMP static version is slower than the range-limited serial version.
The main reason is that most GKH iterations contain only one non-trivial active block.
The OpenMP parallel-for region is still entered in every iteration, so scheduling and synchronization overhead dominate when the task count is small.

This version is kept as a negative-control experiment for OpenMP scheduling overhead.
