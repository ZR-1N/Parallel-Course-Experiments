#02_simd_mpi_compare

## 本阶段目标

本目录记录 SIMD-only 与 MPI+SIMD 的对比实验，用于回应实验手册中“合并之前 SIMD 实验内容”以及“探索只运行 SIMD 和 MPI+SIMD 的性能差异”的要求。

本阶段重点回答以下问题：

1. 前序 SIMD 实验的优化是否已经合并到本次 MPI 实验代码中；
2. 只运行 SIMD 优化版本与在 SIMD 基础上加入 MPI 后，性能有何差异；
3. MPI 是否会削弱 SIMD 的效果；
4. 在不同问题规模下，MPI+SIMD 是否比 SIMD-only 更有优势；
5. MPI、SIMD、OpenMP 分别在当前 SVD 实现中承担什么层次的优化作用。

## 与实验手册要求的对应关系

实验手册要求继续将 SIMD 实验代码合并到 MPI 实验中，并比较“只运行 SIMD”和“MPI+SIMD”的性能差异。

本实验中的对应关系如下：

| 手册要求            | 本实验对应实现                                                   |
| --------------- | --------------------------------------------------------- |
| 合并 SIMD 实验代码    | 当前 `gkh.cpp` 保留前序 SIMD/内存访问优化，并被 serial_simd 与 MPI 版本共同调用 |
| 只运行 SIMD        | `impl=serial_simd, np=1`                                  |
| MPI+SIMD        | `impl=mpi_pool, np=4`，在保留 SIMD/内存优化的基础上加入 MPI 任务池         |
| MPI+SIMD+OpenMP | `impl=mpi_pool, np=4, OMP_THREADS=2`，进一步加入 OpenMP 行级并行    |
| 正确性验证           | 所有配置均通过重构误差、正交性误差、对角结构与奇异值顺序检查                            |

需要说明的是，本文中的“SIMD”不仅指显式 intrinsic，也包括前序 SIMD 实验中保留下来的局部循环展开、连续内存访问和编译器可自动向量化的局部热点循环。MPI 版本并没有放弃这些优化，而是在同一套局部 GKH 计算函数基础上增加任务级并行。

## 当前 SIMD 合并方式

当前代码中 SIMD/内存访问优化主要体现在以下位置：

| 优化位置                          | 说明                                 |
| ----------------------------- | ---------------------------------- |
| `apply_left_rows`             | 对两行 Givens rotation 进行手动展开，改善连续行访问 |
| `apply_left_rows_range`       | 对局部列范围内的行更新进行手动展开                  |
| `apply_right_cols`            | 使用行指针和连续行偏移减少 `at()` 调用开销          |
| `apply_right_cols_range`      | 优化局部右乘列旋转的内存访问                     |
| `gkh_extract_block`           | 按行连续复制 local B，减少局部块提取开销           |
| `gkh_merge_block`             | 按行连续写回 local B，减少合并开销              |
| `-O2 / -O3` 编译选项              | 允许编译器进一步做循环优化、内联和自动向量化             |
| `gkh_replay_rotations_hybrid` | 在 SIMD/内存优化基础上加入 OpenMP 行级并行       |

因此，MPI+SIMD 不是将两个完全独立版本简单拼接，而是：

* SIMD/内存优化负责进程内部局部矩阵更新；
* MPI 负责任务池级别的多进程并行；
* OpenMP 可进一步优化 master 端 replay 中单条 rotation 的行循环。

## 固定实验说明

本阶段主要汇总此前 `13_size_scaling` 与 `12_final` 中已经得到的结果，不重新跑实验。

| 配置                | 含义                                                                |
| ----------------- | ----------------------------------------------------------------- |
| serial_simd       | 只运行 SIMD/内存访问优化后的单进程版本                                            |
| mpi_pool          | 在 SIMD/内存访问优化基础上加入 MPI 任务池、changed iteration、B+logs 和 master_work |
| mpi_pool + OpenMP | 在 MPI+SIMD 基础上继续加入 OpenMP 行级并行                                    |

## 结果文件建议

建议本目录保存以下文件：

| 文件                          | 内容                                        |
| --------------------------- | ----------------------------------------- |
| README.md                   | 本阶段说明与数据分析                                |
| qsub_simd_only_n64_test.o   | 可复制自 size_scaling 中 n=64 serial_simd 结果   |
| qsub_mpi_simd_n64_test.o    | 可复制自 size_scaling 中 n=64 mpi_pool 结果      |
| qsub_simd_only_n256_test.o  | 可复制自 size_scaling 中 n=256 serial_simd 结果  |
| qsub_mpi_simd_n256_test.o   | 可复制自 size_scaling 中 n=256 mpi_pool 结果     |
| qsub_simd_only_n512_test.o  | 可复制自 size_scaling 中 n=512 serial_simd 结果  |
| qsub_mpi_simd_n512_test.o   | 可复制自 size_scaling 中 n=512 mpi_pool 结果     |
| qsub_simd_only_n1000_test.o | 可复制自 size_scaling 中 n=1000 serial_simd 结果 |
| qsub_mpi_simd_n1000_test.o  | 可复制自 size_scaling 中 n=1000 mpi_pool 结果    |

如果不复制原始输出文件，也可以在报告中说明本节数据来自 `results_lab4/13_size_scaling` 和 `results_lab4/12_final`。

## 正确性结果

不同规模下，serial_simd 和 mpi_pool 均通过正确性检查：

|    n | serial_simd passed | mpi_pool passed |
| ---: | ------------------ | --------------- |
|   64 | 1/1                | 1/1             |
|  256 | 1/1                | 1/1             |
|  512 | 1/1                | 1/1             |
| 1000 | 1/1                | 1/1             |

说明在合并 SIMD 与 MPI 后，SVD 结果的数值正确性仍然能够保持。

## 主结果表：不同规模下 SIMD-only 与 MPI+SIMD 对比

以下数据来自 size_scaling 实验。serial_simd 表示只运行 SIMD/内存优化后的单进程版本；mpi_pool 表示在 SIMD/内存优化基础上加入 MPI 任务池、changed iteration、B+logs 和 master_work。

|    n | SIMD-only gkh_ms | MPI+SIMD gkh_ms | GKH speedup | SIMD-only total_ms | MPI+SIMD total_ms | total speedup | 结论                           |
| ---: | ---------------: | --------------: | ----------: | -----------------: | ----------------: | ------------: | ---------------------------- |
|   64 |          4.95899 |         5.83220 |       0.85x |            5.72898 |           6.58899 |         0.87x | 小规模下 MPI 开销大于收益              |
|  256 |          404.956 |         469.375 |       0.86x |            458.066 |           521.554 |         0.88x | 中小规模仍未摊薄 MPI 开销              |
|  512 |          6706.49 |         4366.27 |       1.54x |            7149.43 |           4814.41 |         1.49x | 中大规模开始体现 MPI+SIMD 优势         |
| 1000 |          20912.2 |         15133.3 |       1.38x |           25254.29 |          19027.52 |         1.33x | 大规模下 MPI+SIMD 明显优于 SIMD-only |

注：

* `total_ms = bidiag_ms + gkh_ms`
* `GKH speedup = SIMD-only gkh_ms / MPI+SIMD gkh_ms`
* `total speedup = SIMD-only total_ms / MPI+SIMD total_ms`
* speedup 小于 1 表示 MPI+SIMD 慢于 SIMD-only

## 结果分析

### 1. 小规模下 MPI+SIMD 慢于 SIMD-only

在 n=64 和 n=256 时，MPI+SIMD 均慢于 SIMD-only。

|   n | SIMD-only gkh_ms | MPI+SIMD gkh_ms | GKH speedup |
| --: | ---------------: | --------------: | ----------: |
|  64 |          4.95899 |         5.83220 |       0.85x |
| 256 |          404.956 |         469.375 |       0.86x |

原因主要有三点：

1. 小规模矩阵中 GKH 局部计算量有限；
2. MPI 需要额外的进程启动、任务分发、结果回收和合并；
3. 当前 SVD GKH 的活动 block 并行度较低，任务池不能充分喂满所有 worker。

因此，小规模下 MPI 的固定开销难以被计算收益摊薄，导致 MPI+SIMD 反而比 SIMD-only 慢。

### 2. 中大规模下 MPI+SIMD 开始获得加速

在 n=512 和 n=1000 时，MPI+SIMD 明显优于 SIMD-only。

|    n | SIMD-only gkh_ms | MPI+SIMD gkh_ms | GKH speedup |
| ---: | ---------------: | --------------: | ----------: |
|  512 |          6706.49 |         4366.27 |       1.54x |
| 1000 |          20912.2 |         15133.3 |       1.38x |

这说明随着矩阵规模增大，局部 GKH 计算、local B 合并和 rotation replay 的计算量显著增加，MPI 任务级并行和 master_work 策略开始能够覆盖部分额外通信和调度开销。

其中 n=512 的 GKH 加速比达到约 1.54x，说明该规模下 MPI+SIMD 的收益较明显。

### 3. MPI 不会“破坏” SIMD，但可能引入额外开销

从代码结构看，MPI 版本仍然调用相同的局部 GKH 更新函数和优化后的内存访问函数。因此，MPI 并没有取消 SIMD/内存访问优化。

但是 MPI 会引入新的开销：

| MPI 引入的开销 | 说明                                    |
| --------- | ------------------------------------- |
| 任务分发      | master 向 worker 发送 local B 或任务信息      |
| 结果回收      | worker 返回 local B、rotation logs 或其他结果 |
| 合并开销      | master 合并 local B                     |
| replay 开销 | master 回放 rotation logs 更新 U/V        |
| 调度开销      | 维护任务池、空闲 worker、队列轮次                  |
| 负载不均      | max_queue_size 较小，worker 难以充分利用       |

因此，MPI 不是让 SIMD 效果变差，而是在 SIMD 之上增加了任务级并行，同时也增加了通信与调度成本。是否更快取决于计算量能否覆盖这些额外开销。

### 4. SIMD 与 MPI 的作用层次不同

当前实现中，SIMD 与 MPI 的关系可以理解为：

| 优化层次        | 作用                                     |
| ----------- | -------------------------------------- |
| SIMD/内存访问优化 | 加速单进程内部局部矩阵更新                          |
| MPI         | 将活动 block 任务分发到不同进程，进行任务级并行            |
| OpenMP      | 在 master 端 replay 中对单条 rotation 的行循环并行 |
| 编译优化        | 对局部热点循环进一步内联、向量化和优化                    |

因此，SIMD 和 MPI 并不是互相替代的关系，而是不同层次的优化。SIMD 负责局部细粒度计算，MPI 负责粗粒度任务并行。

### 5. MPI+SIMD 的收益受到任务池深度限制

尽管 n=512 和 n=1000 下 MPI+SIMD 获得加速，但其加速并非线性。这与前面 profiling 的结论一致：

| 指标                | 现象                               |
| ----------------- | -------------------------------- |
| max_queue_size    | 通常只有 1 到 3                       |
| tasks_sent        | master_work 后远程任务数量显著减少          |
| master_compute_ms | master 端局部计算仍然占比较高               |
| merge_ms          | local B 合并和 rotation logs 回放仍然较重 |

因此，MPI+SIMD 的加速受到 SVD GKH 算法结构限制。即使保留 SIMD 优化，MPI 也不能简单通过增加进程数获得线性加速。

## 与 MPI+SIMD+OpenMP 的关系

前面的 MPI+OpenMP 实验进一步表明，在 MPI+SIMD 基础上加入 OpenMP 可以继续提升单节点性能。

代表性结果如下：

| 配置              |    n | np | OMP_THREADS |  gkh_ms | total_ms |
| --------------- | ---: | -: | ----------: | ------: | -------: |
| MPI+SIMD        | 1000 |  4 |           1 | 15656.3 | 19667.74 |
| MPI+SIMD+OpenMP | 1000 |  4 |           2 | 11709.0 | 15674.78 |

这说明当前瓶颈中仍有一部分可以通过线程级并行缓解，尤其是 master 端局部计算和 rotation logs replay。

## 与编译优化的关系

compile_simd 实验中，`-O3` 相比 `-O2` 对最终混合版本也有明显提升：

| 编译选项 |  gkh_ms | total_ms |
| ---- | ------: | -------: |
| -O2  | 16206.5 | 19590.38 |
| -O3  | 13194.9 | 16963.27 |

这进一步说明局部循环仍然是性能敏感部分。MPI 负责更高层任务并行，而 SIMD/编译优化仍然会影响每个任务内部的执行效率。

## 阶段结论

本阶段对比了 SIMD-only 与 MPI+SIMD 在不同问题规模下的性能。实验结果表明：

1. 当前 MPI 版本已经合并前序 SIMD/内存访问优化，并非从未优化串行代码重新开始；
2. 在 n=64 和 n=256 的小规模问题上，MPI+SIMD 慢于 SIMD-only，说明 MPI 通信、调度和合并开销无法被小规模计算摊薄；
3. 在 n=512 和 n=1000 的中大规模问题上，MPI+SIMD 明显优于 SIMD-only，GKH 阶段分别达到约 1.54x 和 1.38x 加速；
4. MPI 并不会破坏 SIMD 优化，而是在 SIMD 优化基础上引入任务级并行；
5. MPI+SIMD 的收益受任务池深度、master 端合并和 rotation replay 开销限制，因此加速不是线性的；
6. 在 MPI+SIMD 基础上继续加入 OpenMP 和更高编译优化等级，仍然可以进一步改善 master 端瓶颈。



为了验证 SIMD 实验内容是否成功合并到 MPI 实验中，本文比较了 `serial_simd` 与 `mpi_pool` 两条路径。其中 `serial_simd` 表示只运行保留 SIMD/内存访问优化的单进程版本，`mpi_pool` 表示在同一局部计算代码基础上加入 MPI 任务池、changed iteration、local B + rotation logs 和 master_work。实验结果表明，小规模矩阵下 MPI+SIMD 会因为通信、任务调度和结果合并开销而慢于 SIMD-only；但当矩阵规模增大到 n=512 和 n=1000 后，MPI+SIMD 开始获得明显加速。n=1000 时，SIMD-only 的 GKH 阶段耗时为 20912.2 ms，而 MPI+SIMD 降至 15133.3 ms，达到约 1.38 倍加速。这说明 MPI 并没有削弱 SIMD 的局部优化效果，而是在其基础上引入了更高层次的任务级并行；是否加速主要取决于问题规模是否足以摊薄 MPI 通信和调度开销。


