OpenMP Guided + Parallel Cleanup Thread Scaling
===============================================

Version:
SVD_PARALLEL_MODE = 3
SVD_MIN_PARALLEL_TASKS = 2
SVD_PARALLEL_CLEANUP = 1
SVD_CLEANUP_MIN_ELEMENTS = 4096

Seed:
20260409

Optimization:
-O2

Commands:
threads=1: bash test.sh 1 1 1 -O O2 -s 20260409
threads=2: bash test.sh 1 1 2 -O O2 -s 20260409
threads=4: bash test.sh 1 1 4 -O O2 -s 20260409
threads=8: bash test.sh 1 1 8 -O O2 -s 20260409

Raw representative results:
threads,total_bidiagonalization_ms,total_gkh_ms,cleanup_ms,block_ms,total_ms,pass
1,3398.66,28169.9,3470.756,24597.032,28169.208,5/5
2,3795.10,23681.8,2650.825,20900.275,23681.139,5/5
4,4672.28,22201.4,1043.352,21061.011,22200.770,5/5
8,3084.93,20839.2,1098.780,19619.461,20838.633,5/5

Speedup relative to 1 thread:
threads,total_gkh_speedup
1,1.000
2,1.190
4,1.269
8,1.352

Observation:
This experiment evaluates thread scaling for the combined OpenMP guided block scheduling and parallel cleanup version.
From 1 to 8 threads, total GKH time decreases from 28169.9 ms to 20839.2 ms, giving about 1.35x speedup in this representative run.

The cleanup scan benefits clearly from row-level OpenMP parallelism:
cleanup_ms decreases from 3470.756 ms at 1 thread to about 1.1 seconds at 8 threads.
However, the improvement is not linear, and the 4-thread and 8-thread cleanup times are close.

The block-step phase remains the dominant cost:
threads=8 still spends 19619.461 ms in block_ms.
This is consistent with the previous block evolution profiling, where most GKH iterations contain only one non-trivial active block.
Therefore, increasing threads mainly helps the regular matrix-wide cleanup scan, while the block-level GKH iteration remains limited by algorithmic parallelism.
