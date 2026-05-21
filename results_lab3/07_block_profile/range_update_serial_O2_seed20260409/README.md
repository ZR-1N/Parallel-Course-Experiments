Range-Limited B Update Serial Test
==================================

Branch:
svd-lab3-pthread-openmp

Version:
SVD_PARALLEL_MODE = 0
SVD_NUM_THREADS = 8
OpenMP/Pthread parallelism is not enabled in this run.

Main change:
B updates inside one_block_step are changed from full-matrix row/column updates to range-limited block-local updates.

Changed calls:
apply_right_cols(B, ...) -> apply_right_cols_range(B, ..., l, r)
apply_left_rows(B, ...)  -> apply_left_rows_range(B, ..., l, r)

Purpose:
This change prepares the code for lock-free block-level parallelism.
Different active blocks are independent only if B updates are restricted to the current block range.
Otherwise, the original full-row/full-column update functions may write outside the current active block.

Correctness:
PASS: 5 / 5

Representative result:
total bidiagonalization time(ms): 3583.45
total GKH iteration time(ms): 20027.8

Large case profile: random 1000x1000
iters=1425
cleanup_ms=3885.463
zero_ms=15.374
split_ms=20.802
block_ms=16050.633
final_ms=51.302
total_ms=20027.249
total_blocks=640529
nontrivial_blocks=1442
max_block_size=1000
avg_nontrivial_blocks_per_iter=1.012

Observation:
Although this run is still serial, the GKH time is significantly reduced.
The reason is that range-limited B updates avoid unnecessary accesses to B entries outside the current active block.
This is both a correctness preparation for later parallel block processing and a useful serial optimization.
