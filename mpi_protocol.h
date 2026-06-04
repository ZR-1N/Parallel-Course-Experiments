#pragma once

constexpr int MPI_TAG_TASK = 100;
constexpr int MPI_TAG_RESULT = 101;
constexpr int MPI_TAG_STOP = 102;

struct MPITaskHeader
{
    int l;
    int r;
};

struct MPIResultHeader
{
    int l;
    int r;
    int converged;
    int split_count;
    int sweep_count;
};