OpenMP Guided + Parallel Cleanup Thread Scaling: Threads = 8
============================================================

Version:
SVD_PARALLEL_MODE = 3
SVD_NUM_THREADS = 8
SVD_MIN_PARALLEL_TASKS = 2
SVD_PARALLEL_CLEANUP = 1
SVD_CLEANUP_MIN_ELEMENTS = 4096

Command:
bash test.sh 1 1 8 -O O2 -s 20260409

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3084.93
total GKH iteration time(ms): 20839.2

Large case profile:
m=1000
n=1000
converged=yes
iters=1425
cleanup_ms=1098.780
zero_ms=29.940
split_ms=29.105
block_ms=19619.461
final_ms=55.951
total_ms=20838.633
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
parallel_mode=3
num_threads=8
min_parallel_tasks=2
parallel_cleanup=1
avg_nontrivial_blocks_per_iter=1.012

Comparison:
threads=1 total GKH iteration time(ms): 28169.9
threads=2 total GKH iteration time(ms): 23681.8
threads=4 total GKH iteration time(ms): 22201.4
threads=8 total GKH iteration time(ms): 20839.2

threads=1 cleanup_ms: 3470.756
threads=2 cleanup_ms: 2650.825
threads=4 cleanup_ms: 1043.352
threads=8 cleanup_ms: 1098.780

Observation:
The 8-thread run gives the best total GKH time among the representative 1/2/4/8 thread-scaling runs.
Compared with 1 thread, total GKH time decreases from 28169.9 ms to 20839.2 ms.
The cleanup scan benefits strongly from threading, decreasing from 3470.756 ms at 1 thread to around 1.1 seconds at 8 threads.

The cleanup time of 8 threads is close to the 4-thread value rather than much lower, suggesting that the cleanup scan begins to saturate after several threads.
The block-step phase remains the dominant cost and is limited by the number of non-trivial active blocks.
