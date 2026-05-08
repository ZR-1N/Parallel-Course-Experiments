# 06_perf_testsh

## 实验说明

本目录记录使用 perf stat 包裹课程测试脚本的端到端 profiling 结果。

运行形式：

perf stat bash test.sh 1 1 1 -O O2 -s 20260409

需要注意的是，课程框架通过 test.sh 提交 qsub 任务，真正的 SVD 主程序运行在计算节点上。因此，在登录节点执行 perf stat bash test.sh 时，硬件计数器主要反映 test.sh、编译、qsub 提交、pssh/scp、输出收集和等待过程，而不能严格代表计算节点上 main 程序的微架构行为。

因此，本实验中的 cycles、instructions、branch-misses 等指标仅作为端到端脚本 profiling 的辅助参考。最终性能分析主要依据程序自身输出的 bidiagonalization / GKH 阶段耗时、消融实验、编译优化等级对比和汇编级分析。

## 测试版本

- baseline：原始版本
- gkh_left_unroll：仅优化 GKH 中 apply_left_rows
- bidiag_only：仅优化 bidiagonalization.cpp 中 Householder TODO
- final：综合采用 GKH left-row unroll 与 Householder SIMD 优化

## 程序阶段耗时

| 版本 | 通过情况 | Bidiagonalization(ms) | GKH(ms) | Total(ms) |
|---|---:|---:|---:|---:|
| baseline | 5 / 5 | 9057.39 | 37836.2 | 46893.59 |
| gkh_left_unroll | 5 / 5 | 8220.63 | 24383.3 | 32603.93 |
| bidiag_only | 5 / 5 | 3250.22 | 42664.0 | 45914.22 |
| final | 5 / 5 | 3140.39 | 24157.8 | 27298.19 |

## perf stat 端到端指标

| 版本 | task-clock(ms) | cycles | instructions | IPC | branch-misses | elapsed(s) | user(s) | sys(s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| baseline | 5427.84 | 12701362613 | 10720045368 | 0.84 | 115655385 | 65.4436 | 5.0041 | 0.4144 |
| gkh_left_unroll | 5393.99 | 12610208812 | 10764576353 | 0.85 | 116554868 | 45.3987 | 4.9556 | 0.4199 |
| bidiag_only | 5750.92 | 13532306885 | 11903096822 | 0.88 | 127715086 | 60.7548 | 5.3558 | 0.3856 |
| final | 5932.59 | 13916540358 | 11948456848 | 0.86 | 127711446 | 40.9400 | 5.4301 | 0.4864 |

## 分析

从程序自身输出的阶段耗时看，final 版本总耗时最低，为 27298.19 ms，相比 baseline 的 46893.59 ms 有明显下降。bidiag_only 版本显著降低了上二对角化阶段耗时，说明 Householder 部分的连续访问与 NEON 辅助函数优化有效；gkh_left_unroll 版本显著降低了 GKH 阶段耗时，说明 apply_left_rows 的行指针访问与循环展开对 Givens 行旋转有帮助。

从 perf stat 的端到端结果看，elapsed time 与程序内部计时并不完全一致。这是因为 perf 包裹的是 test.sh，而 test.sh 中包含编译、qsub 提交、文件传输、输出收集和等待计算节点任务完成等过程。task-clock 只有 5 到 6 秒，而 elapsed time 达到 40 到 65 秒，CPU utilized 较低，说明该 perf 结果包含大量等待时间。

因此，本实验不将 perf 的 cycles、instructions、branch-misses 等指标作为 main 程序的核心微架构证据，而将其作为端到端脚本 profiling 的辅助说明。真正用于评价 SIMD 优化效果的主要依据仍是 main 程序输出的 bidiagonalization 和 GKH 阶段耗时，以及不同版本间的消融实验对比。

## 结论

perf test.sh 结果主要说明：课程测试流程存在明显的端到端调度与等待开销，因此单次运行耗时会受到服务器调度、节点负载和文件传输影响。最终报告中应优先使用程序内部计时进行性能比较，并结合 perf 结果说明端到端测试环境存在波动。
