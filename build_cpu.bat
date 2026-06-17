@echo off
setlocal

cl /O2 /EHsc /std:c++17 /utf-8 /DNOMINMAX ^
    main.cpp gkh.cpp bidiagonalization.cpp ^
    /Fe:main_cpu.exe

endlocal