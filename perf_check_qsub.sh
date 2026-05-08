#!/bin/sh
#PBS -N perf_check
#PBS -e perf_check.e
#PBS -o perf_check.o

echo "Host: $(hostname)"
echo "Date: $(date)"
echo "PATH: $PATH"
echo

echo "which perf:"
which perf || true
echo

echo "ls /usr/bin/perf:"
ls -l /usr/bin/perf || true
echo

echo "find possible perf:"
find /usr -name perf 2>/dev/null | head -20 || true
echo

echo "kernel:"
uname -a
