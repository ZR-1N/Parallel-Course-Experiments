@echo off
setlocal

if not exist results_gpu mkdir results_gpu

echo Running GPU SVD bidiagonalization benchmark...

for %%N in (128 256 512 1000 1500) do (
    echo === n=%%N cpu ===
    main_gpu.exe 20260408 --impl cpu --mode bench --n %%N --repeat 3 --full-svd 0 --verify 1 > results_gpu\bench_cpu_n%%N.txt

    echo === n=%%N gpu_kernel ===
    main_gpu.exe 20260408 --impl gpu_kernel --mode bench --n %%N --repeat 3 --full-svd 0 --verify 1 > results_gpu\bench_gpu_kernel_n%%N.txt

    echo === n=%%N gpu_cublas ===
    main_gpu.exe 20260408 --impl gpu_cublas --mode bench --n %%N --repeat 3 --full-svd 0 --verify 1 > results_gpu\bench_gpu_cublas_n%%N.txt
)

echo Done.
echo Summary lines:
findstr /C:"[bench-summary]" results_gpu\bench_*.txt

endlocal