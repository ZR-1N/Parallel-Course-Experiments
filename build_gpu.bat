@echo off
setlocal

nvcc -O2 -arch=sm_89 -std=c++17 ^
    -Xcompiler /utf-8 ^
    -Xcompiler /EHsc ^
    -Xcompiler /DNOMINMAX ^
    -DUSE_CUDA_BIDIAG ^
    main.cpp gkh.cpp bidiagonalization.cpp bidiagonalization_gpu.cu ^
    -I"%CUDA_PATH%\include" ^
    -L"%CUDA_PATH%\lib\x64" ^
    -lcublas ^
    -o main_gpu.exe

endlocal