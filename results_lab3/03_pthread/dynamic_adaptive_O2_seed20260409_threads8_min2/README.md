Pthread Dynamic Adaptive Block-Level Parallelism
================================================

Version:
SVD_PARALLEL_MODE = 4
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Strategy:
Each GKH iteration collects non-trivial active blocks into a task list.
If task_count < SVD_MIN_PARALLEL_TASKS, the task list is processed serially.
If task_count >= SVD_MIN_PARALLEL_TASKS, Pthread dynamic scheduling is used.

Scheduling:
The implementation uses an atomic task index.
Each worker repeatedly fetches one task index and processes the corresponding active block.
The main thread also participates as a worker, so 8 threads means 7 pthread workers plus the main thread.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3672.62
total GKH iteration time(ms): 22864.2

Large case profile:
iters=1425
cleanup_ms=4018.557
zero_ms=17.971
split_ms=22.469
block_ms=18744.203
final_ms=56.026
total_ms=22863.731
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Data-race handling:
B updates inside one_block_step use range-limited functions:
apply_right_cols_range
apply_left_rows_range

Thus, each block only updates its own B subrange.
For U and V, different active blocks operate on disjoint column ranges.
Therefore, the final implementation avoids global locks in the block-parallel phase.

Comparison:
OpenMP adaptive static GKH time was about 22870.8 ms.
OpenMP adaptive dynamic(1) GKH time was about 22323.4 ms.
OpenMP adaptive guided GKH time was about 22303.8 ms.
Pthread dynamic adaptive GKH time is about 22864.2 ms in this representative run.

Observation:
Pthread dynamic scheduling has similar performance to OpenMP adaptive block-level scheduling.
The reason is that available block-level parallelism is very limited: most GKH iterations contain only one non-trivial active block.
Dynamic scheduling improves load balancing only in a small number of multi-block iterations.
