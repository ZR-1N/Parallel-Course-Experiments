OpenMP Dynamic(1) Adaptive Block-Level Parallelism
==================================================

Version:
SVD_PARALLEL_MODE = 2
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Strategy:
Each GKH iteration collects non-trivial active blocks into a task list.
If task_count < SVD_MIN_PARALLEL_TASKS, the task list is processed serially.
If task_count >= SVD_MIN_PARALLEL_TASKS, OpenMP schedule(dynamic, 1) is used.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3485.97
total GKH iteration time(ms): 22323.4

Large case profile:
iters=1425
cleanup_ms=4046.101
zero_ms=18.342
split_ms=23.188
block_ms=18172.778
final_ms=57.511
total_ms=22322.916
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Comparison:
OpenMP static adaptive GKH time was about 22870.8 ms.
OpenMP dynamic(1) adaptive GKH time is about 22323.4 ms in this representative run.
Dynamic(1) is slightly faster than static in this test, likely because it handles the few multi-block iterations more flexibly.

However, it is still slower than the range-limited serial representative result, whose GKH time was about 20027.8 ms.
The reason is that available block-level parallelism is very limited.
Most GKH iterations contain only one non-trivial block, so dynamic scheduling can only help in a small number of iterations.
