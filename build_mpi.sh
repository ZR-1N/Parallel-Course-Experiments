#!/bin/sh
set -e

PROJECT_DIR=/home/${USER}/svd
cd ${PROJECT_DIR}

CXX=${CXX:-mpic++}
OPT_FLAGS=${OPT_FLAGS:--O2}
EXTRA_FLAGS=${EXTRA_FLAGS:-}

echo "[build_mpi] building main ..."
echo "[build_mpi] CXX=${CXX}"
echo "[build_mpi] OPT_FLAGS=${OPT_FLAGS}"
echo "[build_mpi] EXTRA_FLAGS=${EXTRA_FLAGS}"

${CXX} ${OPT_FLAGS} -std=c++17 -fopenmp -pthread ${EXTRA_FLAGS} \
    main.cpp gkh.cpp gkh_mpi.cpp bidiagonalization.cpp \
    -o main

echo "[build_mpi] build done: ${PROJECT_DIR}/main"