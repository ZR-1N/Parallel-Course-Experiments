OpenMP Static Adaptive Block-Level Parallelism
==============================================

Version:
SVD_PARALLEL_MODE = 1
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Strategy:
Each GKH iteration collects non-trivial active blocks into a task list.
If task_count < SVD_MIN_PARALLEL_TASKS, the task list is processed serially.
If task_count >= SVD_MIN_PARALLEL_TASKS, OpenMP schedule(static) is used.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 4202.94
total GKH iteration time(ms): 22870.8

Large case profile:
iters=1425
cleanup_ms=4274.858
zero_ms=19.891
split_ms=25.786
block_ms=18489.663
final_ms=53.742
total_ms=22870.283
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Comparison:
Range-limited serial GKH time was about 20027.8 ms in the representative run.
Naive OpenMP static GKH time was about 26809.7 ms.
Adaptive static is faster than naive static because it avoids OpenMP parallel-region overhead when only one block task exists.
However, it is still slower than the range-limited serial version because the available block-level parallelism is very limited.

Observation:
Previous block profiling showed that among 1425 iterations, 1410 iterations have only one non-trivial block.
Therefore, most iterations cannot benefit from block-level OpenMP parallelism.
This version confirms that reducing scheduling overhead helps, but the algorithmic parallelism remains the main limitation.
