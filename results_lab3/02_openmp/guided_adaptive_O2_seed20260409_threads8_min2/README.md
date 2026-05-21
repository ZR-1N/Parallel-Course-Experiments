OpenMP Guided Adaptive Block-Level Parallelism
==============================================

Version:
SVD_PARALLEL_MODE = 3
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Strategy:
Each GKH iteration collects non-trivial active blocks into a task list.
If task_count < SVD_MIN_PARALLEL_TASKS, the task list is processed serially.
If task_count >= SVD_MIN_PARALLEL_TASKS, OpenMP schedule(guided, 1) is used.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3445.86
total GKH iteration time(ms): 22303.8

Large case profile:
iters=1425
cleanup_ms=3686.257
zero_ms=17.056
split_ms=23.369
block_ms=18513.414
final_ms=58.095
total_ms=22303.232
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Comparison:
OpenMP static adaptive GKH time was about 22870.8 ms.
OpenMP dynamic(1) adaptive GKH time was about 22323.4 ms.
OpenMP guided adaptive GKH time is about 22303.8 ms in this representative run.

Guided is slightly faster than dynamic(1) in this run, but the difference is very small.
Because most GKH iterations contain only one non-trivial active block, different OpenMP scheduling strategies have limited room to improve performance.
