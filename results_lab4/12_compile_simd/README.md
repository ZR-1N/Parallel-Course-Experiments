# 12_compile_simd

## 本阶段目标

本目录记录编译优化与 SIMD/体系结构相关优化探索实验结果，用于分析在最终 MPI + OpenMP 版本基础上，不同编译优化等级对 SVD GKH 迭代性能的影响。

本阶段重点回答以下问题：

1. `-O3` 是否比当前主线使用的 `-O2` 更适合本程序；
2. 编译优化是否能进一步加速局部 Givens rotation、local B 合并和 rotation logs 回放；
3. 底层 SIMD/内存访问优化与 MPI、OpenMP 混合并行是否能形成互补；
4. 当前性能瓶颈是否仍然集中在 master 端计算与 merge/replay。

## 当前实现背景

在前面实验中，最终 MPI 版本已经包含：

| 优化项                     | 说明                                                          |
| ----------------------- | ----------------------------------------------------------- |
| MPI task pool           | master-worker 任务池调度                                         |
| changed iteration       | 局部 block 内连续迭代，减少频繁返回                                       |
| sweep_cap=8             | 控制局部任务粒度                                                    |
| local B + rotation logs | 减少 U/V 子块通信                                                 |
| master_work=1           | master 在任务池较浅时参与计算                                          |
| MPI + OpenMP            | rotation logs replay 中单条 rotation 的行循环并行化                   |
| 内存访问优化                  | 优化 apply_right_cols、gkh_extract_block、gkh_merge_block 等局部循环 |

本阶段不改变算法逻辑，只改变编译优化等级，用于观察编译器优化对最终版本的影响。

## 编译设置

本阶段使用 `mpic++` 编译，满足 MPI 实验手册要求。

| 配置           | 编译选项                               |
| ------------ | ---------------------------------- |
| O2 baseline  | `-O2 -std=c++17 -fopenmp -pthread` |
| O3 optimized | `-O3 -std=c++17 -fopenmp -pthread` |

本阶段没有使用 `-march=native`。原因是 qsub 任务可能被调度到不同计算节点，如果编译节点和运行节点 CPU 指令集不完全一致，`-march=native` 可能带来非法指令或平台相关不可复现问题。因此，本阶段主要比较稳定可移植的 `-O2` 与 `-O3`。

## 固定实验条件

| 参数          | 取值            |
| ----------- | ------------- |
| mode        | bench         |
| impl        | mpi_pool      |
| n           | 1000          |
| seed        | 20260408      |
| repeat      | 1             |
| np          | 4             |
| OMP_THREADS | 2             |
| sweep_cap   | 8             |
| master_work | 1             |
| profile     | 1             |
| PBS 资源      | nodes=1:ppn=8 |
| 平台          | qsub 队列环境     |

说明：

* 本阶段使用前面 MPI+OpenMP 实验中的单节点混合并行配置；
* 固定 `np=4, OMP_THREADS=2`，只改变编译优化等级；
* 主要关注 GKH 迭代阶段，同时记录端到端总耗时。

## 结果文件

建议本目录保存以下文件：

| 文件                      | 内容                 |
| ----------------------- | ------------------ |
| qsub_o2_np4_omp2_test.o | `-O2` 标准输出         |
| qsub_o2_np4_omp2_test.e | `-O2` profiling 输出 |
| qsub_o3_np4_omp2_test.o | `-O3` 标准输出         |
| qsub_o3_np4_omp2_test.e | `-O3` profiling 输出 |

## 正确性结果

两组测试均通过正确性检查：

| 编译选项 | passed |
| ---- | ------ |
| -O2  | 1/1    |
| -O3  | 1/1    |

两组测试的重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性均满足设定阈值。

## 主结果表

| 编译选项 | bidiag_ms |  gkh_ms | total_ms | GKH speedup vs O2 | total speedup vs O2 | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size |
| ---- | --------: | ------: | -------: | ----------------: | ------------------: | ----------: | ----------------: | ----------------: | -------: | ---------: | ---------: | -----------: | -------------: |
| -O2  |   3383.88 | 16206.5 | 19590.38 |             1.00x |               1.00x |    0.761747 |           5.82194 |           8539.08 |  6890.51 |         14 |        994 |          994 |              2 |
| -O3  |   3768.37 | 13194.9 | 16963.27 |             1.23x |               1.15x |    0.840187 |           4.83370 |           6438.59 |  6034.76 |         14 |        994 |          994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* GKH speedup vs O2 = O2 gkh_ms / O3 gkh_ms
* total speedup vs O2 = O2 total_ms / O3 total_ms

## 结果分析

### 1. -O3 显著加速 GKH 迭代阶段

从 GKH 阶段看：

| 编译选项 |  gkh_ms |
| ---- | ------: |
| -O2  | 16206.5 |
| -O3  | 13194.9 |

`-O3` 将 GKH 耗时从 16206.5 ms 降至 13194.9 ms，达到约 1.23x 加速，GKH 阶段耗时下降约 18.6%。

这说明当前程序中的局部循环、内存访问和 rotation replay 仍然能从更激进的编译优化中受益。

### 2. -O3 降低了 master_compute_ms 和 merge_ms

profiling 显示：

| 指标                |     -O2 |     -O3 |        变化 |
| ----------------- | ------: | ------: | --------: |
| master_compute_ms | 8539.08 | 6438.59 | 下降约 24.6% |
| merge_ms          | 6890.51 | 6034.76 | 下降约 12.4% |
| worker_compute_ms | 5.82194 | 4.83370 | 下降约 17.0% |

这与前面对瓶颈的判断一致：当前最终版本主要耗时集中在 master 端局部计算和 merge/replay。`-O3` 对局部循环优化、内联和自动向量化更激进，因此能明显降低 master 端计算时间，并对 merge/replay 有一定收益。

### 3. -O3 对 bidiagonalization 阶段没有带来收益

从上二对角化阶段看：

| 编译选项 | bidiag_ms |
| ---- | --------: |
| -O2  |   3383.88 |
| -O3  |   3768.37 |

`-O3` 下 bidiagonalization 耗时反而略高。这可能来自运行波动，也可能与更激进优化导致的代码膨胀、cache 行为变化有关。

但是本实验的 MPI 优化重点是 GKH 迭代阶段，且端到端总时间仍然下降：

| 编译选项 | total_ms |
| ---- | -------: |
| -O2  | 19590.38 |
| -O3  | 16963.27 |

因此，综合来看，`-O3` 对最终混合并行版本仍然是有利的。

### 4. 任务结构没有发生变化

两组实验中任务调度指标完全一致：

| 指标             | -O2 | -O3 |
| -------------- | --: | --: |
| tasks_sent     |  14 |  14 |
| tasks_done     | 994 | 994 |
| queue_rounds   | 994 | 994 |
| max_queue_size |   2 |   2 |

这说明编译优化没有改变算法流程、任务池结构或收敛行为。性能提升主要来自单个任务内部执行效率提高，而不是任务数量减少。

### 5. -O3 与已有 SIMD/内存优化形成互补

当前代码中已经进行了若干底层优化：

| 优化            | 说明                                              |
| ------------- | ----------------------------------------------- |
| 手动展开          | apply_left_rows、apply_left_rows_range 中对循环进行展开  |
| 连续内存访问        | apply_right_cols、apply_right_cols_range 使用行指针访问 |
| 局部 block 连续复制 | gkh_extract_block、gkh_merge_block 优化局部 B 拷贝     |
| OpenMP 行级并行   | gkh_replay_rotations_hybrid 对单条 rotation 的行循环并行 |
| 编译器优化         | -O3 增强循环优化、内联和可能的自动向量化                          |

`-O3` 的收益说明，底层循环仍然是性能敏感部分。MPI 负责任务级并行，OpenMP 负责单条 rotation 的行级并行，而编译器优化和 SIMD/内存访问优化进一步提升单核局部循环效率。

因此，本阶段可以作为“MPI + OpenMP + SIMD/编译优化结合”的证据。

## 与前面实验的关系

本阶段结果补充了前面 MPI+OpenMP 实验：

| 实验           | 主要优化层次            |
| ------------ | ----------------- |
| mpi_pool     | MPI 任务级并行         |
| master_work  | 减少远程任务发送          |
| MPI+OpenMP   | master 端行级多线程     |
| compile_simd | 编译器局部循环优化与潜在自动向量化 |

它说明最终版本的性能提升来自多层次优化，而不是单一 MPI 调度策略。

## 阶段结论

本阶段比较了 `-O2` 与 `-O3` 对最终 MPI+OpenMP 版本的影响。实验结果表明：

1. 两组编译选项均能保证正确性；
2. `-O3` 将 GKH 阶段耗时从 16206.5 ms 降至 13194.9 ms，达到约 1.23x 加速；
3. `-O3` 将端到端总耗时从 19590.38 ms 降至 16963.27 ms，达到约 1.15x 加速；
4. `-O3` 主要降低 master_compute_ms 和 merge_ms，说明局部计算与 rotation replay 能从更激进的编译优化中受益；
5. 任务数量和任务池结构不变，说明性能提升来自单任务内部执行效率提高；
6. `-O3` 与已有内存访问优化、OpenMP 行级并行和 MPI 任务池调度形成互补。

因此，最终报告中可以将 `-O3` 作为编译优化和 SIMD/体系结构相关探索的一部分。但为了保证与前面主线实验可比，前面的历史数据仍保留 `-O2` 结果；最终性能总结中可以补充说明，使用 `-O3` 后最终混合并行版本仍可进一步提升。

## 可写入报告的结论表述

为了探索编译优化与 SIMD/体系结构相关优化对最终 MPI 版本的影响，本实验在相同运行参数下比较了 `-O2` 与 `-O3`。实验结果表明，`-O3` 对 GKH 迭代阶段有明显加速效果，将 GKH 耗时从 16206.5 ms 降至 13194.9 ms，达到约 1.23 倍加速。profiling 显示，`-O3` 主要降低了 master_compute_ms 和 merge_ms，说明当前程序中的 Givens rotation、local B 合并和 rotation logs 回放等局部循环仍然能从更激进的编译优化和潜在自动向量化中受益。与此同时，tasks_sent、tasks_done 和 max_queue_size 均保持不变，说明编译优化没有改变算法流程，而是提高了单个任务内部执行效率。因此，编译优化可以作为 MPI 任务级并行和 OpenMP 行级并行之外的底层补充优化。

## 后续可选探索

后续如果继续深入体系结构相关优化，可以考虑：

1. 使用 `-fopt-info-vec-optimized` 和 `-fopt-info-vec-missed` 生成向量化报告；
2. 在确认计算节点 CPU 架构一致后，小规模尝试 `-march=native`；
3. 对 `gkh_replay_rotations_hybrid` 中的行循环进一步分析 cache 行为；
4. 对 `Matrix::at`、局部 block 拷贝和 rotation replay 继续减少索引开销；
5. 比较不同 OpenMP 线程绑定策略，如 OMP_PROC_BIND 和 OMP_PLACES。

当前阶段 `-O2` 与 `-O3` 的对比已经足以支撑报告中的编译优化与 SIMD/体系结构相关探索部分。
