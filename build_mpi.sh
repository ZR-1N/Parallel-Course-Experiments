#!/bin/sh
set -e

PROJECT_DIR=/home/${USER}/svd
cd ${PROJECT_DIR}

echo "[build_mpi] building main ..."

mpic++ -O2 -std=c++17 -fopenmp -pthread \
    main.cpp gkh.cpp gkh_mpi.cpp bidiagonalization.cpp \
    -o main

echo "[build_mpi] build done: ${PROJECT_DIR}/main"