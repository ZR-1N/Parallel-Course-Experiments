Pthread Static Adaptive Block-Level Scheduling
==============================================

Version:
SVD_PARALLEL_MODE = 5
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Strategy:
Each GKH iteration collects non-trivial active blocks into a task list.
If task_count < SVD_MIN_PARALLEL_TASKS, the task list is processed serially.
If task_count >= SVD_MIN_PARALLEL_TASKS, Pthread static scheduling is used.

Static scheduling:
Task i is assigned to thread i % thread_count.
This creates a fixed task assignment and is used as a comparison against the dynamic atomic task queue.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3701.33
total GKH iteration time(ms): 23063.5

Comparison:
Pthread dynamic adaptive GKH time was about 22864.2 ms.
Pthread static adaptive GKH time is about 23063.5 ms in this representative run.

Observation:
Static scheduling is slightly slower than dynamic scheduling in this run.
Dynamic scheduling can reduce load imbalance by allowing threads to fetch new block tasks after finishing their current ones.
However, the difference is limited because previous block profiling showed that most GKH iterations contain only one non-trivial block.
Therefore, the amount of exploitable block-level parallelism is small.

Data-race handling:
B updates inside one_block_step use range-limited functions:
apply_right_cols_range
apply_left_rows_range

Each active block only updates its own B subrange.
U and V updates are on disjoint column ranges for different active blocks.
Therefore, no global lock is used in the block-parallel phase.
