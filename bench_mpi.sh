#!/bin/sh
set -e

PROJECT_DIR=/home/${USER}/svd
cd ${PROJECT_DIR}

# ===== 当前本地快速 bench 参数 =====
NP=2
MODE=bench
IMPL=mpi_blocking
N=64
SEED=20260408
REPEAT=1
SWEEP_CAP=1
PROFILE=1
MASTER_WORK=0
OMP_THREADS=1
# ================================

echo "[bench_mpi] local bench begin"
echo "[bench_mpi] NP=${NP} MODE=${MODE} IMPL=${IMPL} N=${N} SEED=${SEED}"

mpiexec -np ${NP} ./main \
    --mode ${MODE} \
    --impl ${IMPL} \
    --n ${N} \
    --seed ${SEED} \
    --repeat ${REPEAT} \
    --sweep-cap ${SWEEP_CAP} \
    --profile ${PROFILE} \
    --master-work ${MASTER_WORK} \
    --omp-threads ${OMP_THREADS}

echo "[bench_mpi] local bench done"