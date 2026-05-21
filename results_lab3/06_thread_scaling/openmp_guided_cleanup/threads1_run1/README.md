OpenMP Guided + Parallel Cleanup Thread Scaling: Threads = 1
============================================================

Version:
SVD_PARALLEL_MODE = 3
SVD_NUM_THREADS = 1
SVD_MIN_PARALLEL_TASKS = 2
SVD_PARALLEL_CLEANUP = 1
SVD_CLEANUP_MIN_ELEMENTS = 4096

Command:
bash test.sh 1 1 1 -O O2 -s 20260409

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3398.66
total GKH iteration time(ms): 28169.9

Large case profile:
m=1000
n=1000
converged=yes
iters=1425
cleanup_ms=3470.756
zero_ms=18.093
split_ms=21.720
block_ms=24597.032
final_ms=56.575
total_ms=28169.208
total_blocks=640527
nontrivial_blocks=1442
max_block_size=1000
parallel_mode=3
num_threads=1
min_parallel_tasks=2
parallel_cleanup=1
avg_nontrivial_blocks_per_iter=1.012

Observation:
This run is the 1-thread baseline for the combined OpenMP guided block scheduling and parallel cleanup version.
Although SVD_PARALLEL_CLEANUP is enabled, num_threads=1 means the cleanup scan effectively runs with one OpenMP worker.
The measured cleanup_ms is therefore close to the previous serial cleanup level.
