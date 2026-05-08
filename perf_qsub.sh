#!/bin/sh
#PBS -N perf_svd
#PBS -e perf.e
#PBS -o perf.o

SETUP_LOG="/tmp/perf_setup_${USER}.log"

mkdir -p /home/${USER} > "$SETUP_LOG" 2>&1
scp master_ubss1:/home/${USER}/svd/main /home/${USER}/main >> "$SETUP_LOG" 2>&1
scp -r master_ubss1:/home/${USER}/svd/files/ /home/${USER}/ >> "$SETUP_LOG" 2>&1

echo "===== /usr/bin/perf stat: SVD main ====="
echo "Host: $(hostname)"
echo "Date: $(date)"
echo "Seed: ${SVD_SEED}"
echo

if [ -n "$SVD_SEED" ]; then
    /usr/bin/perf stat -r 3 \
        -e cycles,instructions,branches,branch-misses,cache-references,cache-misses,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses,dTLB-loads,dTLB-load-misses \
        /home/${USER}/main "$SVD_SEED"
else
    /usr/bin/perf stat -r 3 \
        -e cycles,instructions,branches,branch-misses,cache-references,cache-misses,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses,dTLB-loads,dTLB-load-misses \
        /home/${USER}/main
fi

rm -f /home/${USER}/main >> "$SETUP_LOG" 2>&1
rm -rf /home/${USER}/files/ >> "$SETUP_LOG" 2>&1
