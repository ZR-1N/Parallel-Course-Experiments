#!/bin/sh
#PBS -N svd_mpi
#PBS -e test.e
#PBS -o test.o
#PBS -l nodes=1:ppn=2

set -e

PROJECT_DIR=/home/${USER}/svd
BIN_NAME=main

# 提交作业的主机与目录
SUBMIT_HOST=${PBS_O_HOST}
SUBMIT_DIR=${PBS_O_WORKDIR}

# ===== 本轮队列测试参数 =====
NP=4
MODE=bench
IMPL=mpi_pool
N=1000
SEED=20260408
REPEAT=1
SWEEP_CAP=8
PROFILE=1
MASTER_WORK=1
OMP_THREADS=1
# ===========================

NODES=$(cat $PBS_NODEFILE | sort | uniq)

echo "[qsub_mpi] submit_host=${SUBMIT_HOST}"
echo "[qsub_mpi] submit_dir=${SUBMIT_DIR}"
echo "[qsub_mpi] nodes=${NODES}"
echo "[qsub_mpi] np=${NP} mode=${MODE} impl=${IMPL} n=${N}"

# 从提交节点把 main 拷到各执行节点
for node in $NODES; do
    ssh $node "mkdir -p /home/${USER}/files/lab4_mpi"
    scp ${SUBMIT_HOST}:${SUBMIT_DIR}/${BIN_NAME} ${node}:/home/${USER}/${BIN_NAME} 1>&2
done

# 运行 MPI 程序
/usr/local/bin/mpiexec -np ${NP} -machinefile $PBS_NODEFILE /home/${USER}/${BIN_NAME} \
    --mode ${MODE} \
    --impl ${IMPL} \
    --n ${N} \
    --seed ${SEED} \
    --repeat ${REPEAT} \
    --sweep-cap ${SWEEP_CAP} \
    --profile ${PROFILE} \
    --master-work ${MASTER_WORK} \
    --omp-threads ${OMP_THREADS}

# 如果程序后续往 files 下写输出，再统一拷回提交目录
scp -r /home/${USER}/files/ ${SUBMIT_HOST}:${SUBMIT_DIR}/ 2>&1