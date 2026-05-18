SIMD Serial Baseline Result
===========================

Branch:
svd-lab3-pthread-openmp

Base version:
This Lab3 branch is created from svd-simd.
The current result is used as the SIMD-optimized serial baseline before adding Pthread and OpenMP parallelization.

Command:
bash test.sh 1 1 1 -O O2 -s 20260409

Compile option:
-O2

Seed:
20260409

Job information:
Submitted job with ID: 18972.master_ubss1
Execution node: master_ubss2

Correctness summary:
PASS: 5 / 5

Test cases:
1. Fixed 5x5
2. Random 8x8
3. Near-rank-deficient 10x8
4. Random 10x8
5. Random 1000x1000

Large case result: random 1000x1000
converged: yes
||A-U*S*V^T||_F: 1.86375e-10
relative reconstruction error: 3.22033e-13
||U^T U-I||_F: 2.16109e-13
||V^T V-I||_F: 2.09013e-13
diagonal structure error: 0
descending order error: 0
nonnegative diagonal: yes
time bidiagonalization(ms): 3243.15
time gkh iteration(ms): 40575.5
result: PASS

Total timing:
total bidiagonalization time(ms): 3243.2
total GKH iteration time(ms): 40575.6

Notes:
1. This run verifies that the Lab3 branch starts from a correct SIMD-optimized serial baseline.
2. No Pthread or OpenMP parallelization has been added in this run.
3. The test.sh third argument is kept as 1 for this baseline run. Later multi-thread experiments will control the internal Pthread/OpenMP thread count separately.
4. The GKH stage is still the dominant cost, so Lab3 optimization will focus on gkh_svd_from_bidiagonal and the processing of non-trivial active blocks.
