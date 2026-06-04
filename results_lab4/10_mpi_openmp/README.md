# 10_mpi_openmp

## 本阶段目标

本目录记录 MPI 与 OpenMP 混合并行实验结果，用于分析在最终 MPI 版本基础上，引入多线程是否能够进一步优化 SVD GKH 迭代阶段性能。

本阶段重点回答以下问题：

1. MPI 与 OpenMP 混合并行是否能够进一步提升当前最终 MPI 版本性能；
2. 当前瓶颈中的 master_compute_ms 和 merge_ms 是否能通过 OpenMP 降低；
3. 在相同单节点资源约束下，更多 MPI 进程与更多 OpenMP 线程之间如何权衡；
4. OpenMP 与已有 SIMD/内存访问优化能否形成互补。

## 当前实现说明

在前一阶段 MPI 最终版本中，主要瓶颈集中在 master 端：

| 瓶颈                | 说明                               |
| ----------------- | -------------------------------- |
| master_compute_ms | master 本地处理局部 block 的计算时间        |
| merge_ms          | 合并 local B 与回放 rotation logs 的时间 |
| max_queue_size 较小 | 任务池深度不足，worker 很难被充分喂满           |
| tasks_sent 较少     | master_work 后远程任务发送次数大幅减少        |

因此，本阶段主要对 master 端 rotation logs 回放过程进行 OpenMP 并行化。

需要注意的是，rotation logs 之间存在顺序依赖，不能并行处理不同的 Givens rotation。但是对于单条 Givens rotation，对矩阵不同行的两列更新相互独立，因此可以对单条 rotation 内部的行循环使用 OpenMP 并行。

## 当前 MPI + OpenMP 优化内容

本阶段在最终 MPI 版本基础上加入以下 OpenMP 支持：

| 优化项                             | 说明                                  |
| ------------------------------- | ----------------------------------- |
| gkh_replay_rotations_hybrid     | 新增混合并行版本的 rotation logs 回放函数        |
| apply_right_cols_parallel       | 对单条 Givens rotation 的行循环使用 OpenMP   |
| accumulate_left_into_U_parallel | 对 U 的列旋转更新使用 OpenMP                 |
| omp_threads 参数                  | 通过命令行 `--omp-threads` 控制 OpenMP 线程数 |
| OMP_NUM_THREADS                 | qsub 脚本中设置 OpenMP 线程数环境变量           |
| SVD_HYBRID_MIN_ROWS             | 设置 OpenMP 启用的最小行数阈值，避免小矩阵线程开销过大     |

本阶段不是完全独立的 OpenMP 版本，而是在当前 MPI 任务池版本、local B + rotation logs 通信优化、master_work 机制和内存访问优化基础上加入 OpenMP 行级并行。

## 编译设置

当前 build_mpi.sh 使用 mpic++ 编译，满足 MPI 实验手册要求。

| 项       | 当前设置     |
| ------- | -------- |
| 编译器     | mpic++   |
| C++ 标准  | C++17    |
| 优化等级    | -O2      |
| OpenMP  | -fopenmp |
| pthread | -pthread |

当前编译命令使用 -O2，是为了保持与前面实验结果的可比性。后续若单独研究编译优化，可以再比较 -O2、-O3 和 -march=native 的差异。

## 固定实验条件

| 参数          | 取值            |
| ----------- | ------------- |
| mode        | bench         |
| impl        | mpi_pool      |
| n           | 1000          |
| seed        | 20260408      |
| repeat      | 1             |
| sweep_cap   | 8             |
| master_work | 1             |
| profile     | 1             |
| PBS 资源      | nodes=1:ppn=8 |
| 平台          | qsub 队列环境     |

说明：

* 本阶段统一使用单节点 nodes=1:ppn=8，以便比较 MPI 进程数与 OpenMP 线程数的组合。
* ppn 表示每个节点可用的进程槽位或资源槽位，不是 OpenMP 线程数本身。
* OpenMP 线程数通过 OMP_THREADS 和 OMP_NUM_THREADS 控制。
* 本阶段不使用 nodes=4:ppn=1，因为每个节点只有 1 个 slot 时再开启 OpenMP 线程不适合作为规范的混合并行测试。

## 测试配置

| 配置名称                   | NP | OMP_THREADS | 说明                              |
| ---------------------- | -: | ----------: | ------------------------------- |
| MPI-only baseline      |  4 |           1 | 单节点纯 MPI 基线                     |
| MPI + OpenMP           |  4 |           2 | 4 个 MPI 进程，每个进程最多 2 个 OpenMP 线程 |
| Less MPI + More OpenMP |  2 |           4 | 2 个 MPI 进程，每个进程最多 4 个 OpenMP 线程 |

三组配置均在 nodes=1:ppn=8 下运行，符合实验手册中每个计算节点申请线程数不超过 8 的要求。

## 结果文件

建议本目录保存以下文件：

| 文件                          | 内容                               |
| --------------------------- | -------------------------------- |
| qsub_hybrid_np4_omp1_test.o | NP=4, OMP_THREADS=1 标准输出         |
| qsub_hybrid_np4_omp1_test.e | NP=4, OMP_THREADS=1 profiling 输出 |
| qsub_hybrid_np4_omp2_test.o | NP=4, OMP_THREADS=2 标准输出         |
| qsub_hybrid_np4_omp2_test.e | NP=4, OMP_THREADS=2 profiling 输出 |
| qsub_hybrid_np2_omp4_test.o | NP=2, OMP_THREADS=4 标准输出         |
| qsub_hybrid_np2_omp4_test.e | NP=2, OMP_THREADS=4 profiling 输出 |

## 正确性结果

所有测试均通过正确性检查：

| 配置                  | passed |
| ------------------- | ------ |
| NP=4, OMP_THREADS=1 | 1/1    |
| NP=4, OMP_THREADS=2 | 1/1    |
| NP=2, OMP_THREADS=4 | 1/1    |

各组测试的重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性均满足设定阈值。

## 主结果表

| 配置                     | NP | OMP_THREADS | bidiag_ms |  gkh_ms | total_ms | GKH speedup vs MPI-only | total speedup vs MPI-only | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size |
| ---------------------- | -: | ----------: | --------: | ------: | -------: | ----------------------: | ------------------------: | ----------: | ----------------: | ----------------: | -------: | ---------: | ---------: | -----------: | -------------: |
| MPI-only baseline      |  4 |           1 |   4011.44 | 15656.3 | 19667.74 |                   1.00x |                     1.00x |    0.769377 |           4.45342 |           7957.23 |  6857.70 |         14 |        994 |          994 |              2 |
| MPI + OpenMP           |  4 |           2 |   3965.78 | 11709.0 | 15674.78 |                   1.34x |                     1.25x |    0.926256 |           4.43912 |           5638.62 |  5476.05 |         14 |        994 |          994 |              2 |
| Less MPI + More OpenMP |  2 |           4 |   4444.91 | 12305.5 | 16750.41 |                   1.27x |                     1.17x |     1.04856 |           3.50332 |           5563.75 |  6051.11 |         14 |        994 |          994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* GKH speedup vs MPI-only = MPI-only gkh_ms / current gkh_ms
* total speedup vs MPI-only = MPI-only total_ms / current total_ms
* MPI-only baseline 指 NP=4, OMP_THREADS=1

## 结果分析

### 1. MPI + OpenMP 明显优于 MPI-only

在单节点 nodes=1:ppn=8 条件下，NP=4, OMP_THREADS=2 的混合并行版本明显优于 NP=4, OMP_THREADS=1 的 MPI-only 基线。

| 配置                  |  gkh_ms | total_ms |
| ------------------- | ------: | -------: |
| NP=4, OMP_THREADS=1 | 15656.3 | 19667.74 |
| NP=4, OMP_THREADS=2 | 11709.0 | 15674.78 |

GKH 阶段加速比为：

| 指标                        |    数值 |
| ------------------------- | ----: |
| GKH speedup vs MPI-only   | 1.34x |
| total speedup vs MPI-only | 1.25x |

这说明在当前最终 MPI 版本中，master 端 rotation replay 和局部更新确实存在可由 OpenMP 利用的行级并行性。

### 2. OpenMP 有效降低 master_compute_ms 和 merge_ms

对比 NP=4, OMP_THREADS=1 与 NP=4, OMP_THREADS=2：

| 指标                |   OMP=1 |   OMP=2 |        变化 |
| ----------------- | ------: | ------: | --------: |
| master_compute_ms | 7957.23 | 5638.62 | 下降约 29.1% |
| merge_ms          | 6857.70 | 5476.05 | 下降约 20.1% |
| gkh_ms            | 15656.3 | 11709.0 | 下降约 25.2% |

可以看出，OpenMP 不仅降低了 master 端局部计算时间，也降低了 merge/replay 时间。这与实现逻辑一致：rotation logs 回放时，单条 Givens rotation 内部对不同行的列更新可以并行执行。

### 3. NP=4, OMP_THREADS=2 是本阶段最优组合

NP=2, OMP_THREADS=4 也明显优于 MPI-only baseline：

| 配置                  |  gkh_ms | total_ms |
| ------------------- | ------: | -------: |
| NP=4, OMP_THREADS=1 | 15656.3 | 19667.74 |
| NP=2, OMP_THREADS=4 | 12305.5 | 16750.41 |

但它仍略慢于 NP=4, OMP_THREADS=2：

| 配置                  |  gkh_ms | total_ms |
| ------------------- | ------: | -------: |
| NP=4, OMP_THREADS=2 | 11709.0 | 15674.78 |
| NP=2, OMP_THREADS=4 | 12305.5 | 16750.41 |

从 profiling 看：

| 配置          | master_compute_ms | merge_ms |
| ----------- | ----------------: | -------: |
| NP=4, OMP=2 |           5638.62 |  5476.05 |
| NP=2, OMP=4 |           5563.75 |  6051.11 |

两者 master_compute_ms 接近，但 NP=2, OMP=4 的 merge_ms 更高，且 bidiag_ms 也更高。因此，当前单节点 8 ppn 资源约束下，NP=4, OMP_THREADS=2 是更均衡的组合。

### 4. 任务调度结构没有发生变化

三组实验中：

| 配置          | tasks_sent | tasks_done | max_queue_size |
| ----------- | ---------: | ---------: | -------------: |
| NP=4, OMP=1 |         14 |        994 |              2 |
| NP=4, OMP=2 |         14 |        994 |              2 |
| NP=2, OMP=4 |         14 |        994 |              2 |

这说明引入 OpenMP 后，任务池结构没有发生变化。性能提升主要来自单个任务内部的计算与回放加速，而不是任务调度数量变化。

因此，本阶段可以明确说明：

OpenMP 的作用不是增加任务池并行度，而是在已有 MPI 任务池结构内，优化 master 端局部 block 计算和 rotation logs 回放的行级并行。

### 5. MPI + OpenMP 与已有 SIMD/内存优化互补

当前版本中已有若干 SIMD/内存访问相关优化：

| 优化          | 位置                                                     |
| ----------- | ------------------------------------------------------ |
| 手动循环展开      | apply_left_rows, apply_left_rows_range                 |
| 连续内存访问      | apply_right_cols, apply_right_cols_range               |
| 按行连续复制      | gkh_extract_block, gkh_merge_block                     |
| 编译器优化       | -O2 -fopenmp                                           |
| OpenMP 行级并行 | apply_right_cols_parallel, gkh_replay_rotations_hybrid |

本阶段的 MPI+OpenMP 并不是取代前面的 SIMD/内存访问优化，而是在其基础上进一步引入线程并行。实验结果表明，这种组合对 master 端瓶颈是有效的。

## 与多节点最优结果的关系

在 node_layout 实验中，当前观测到的多节点最优配置为：

| 配置                           |  gkh_ms | total_ms |
| ---------------------------- | ------: | -------: |
| NP=4, OMP=1, 4 nodes × 1 ppn | 11314.7 | 14662.85 |

本阶段最优单节点混合并行配置为：

| 配置                          |  gkh_ms | total_ms |
| --------------------------- | ------: | -------: |
| NP=4, OMP=2, 1 node × 8 ppn | 11709.0 | 15674.78 |

可以看出，单节点 MPI+OpenMP 的 GKH 阶段性能已经接近多节点最优版本，但端到端时间仍略慢。两者说明了不同优化方向：

| 优化方向       | 作用                                    |
| ---------- | ------------------------------------- |
| 多节点布局      | 可能减少单节点资源竞争                           |
| MPI+OpenMP | 在单节点内加速 master 端局部计算和 rotation replay |

因此，MPI+OpenMP 是对多节点布局实验的有效补充。

## 阶段结论

本阶段实验表明，在当前最终 MPI 版本基础上加入 OpenMP 行级并行可以进一步提升性能。

主要结论如下：

1. NP=4, OMP_THREADS=2 相比 NP=4, OMP_THREADS=1，GKH 阶段达到约 1.34x 加速，端到端达到约 1.25x 加速。
2. OpenMP 主要降低 master_compute_ms 和 merge_ms，说明 rotation logs 回放和局部列更新中的行级并行有效。
3. NP=2, OMP_THREADS=4 也优于 MPI-only baseline，但略慢于 NP=4, OMP_THREADS=2。
4. tasks_sent、tasks_done 和 max_queue_size 基本不变，说明 OpenMP 没有改变任务池结构，而是优化单个任务内部执行。
5. 当前最优单节点混合并行配置为 NP=4, OMP_THREADS=2, nodes=1:ppn=8。
6. MPI+OpenMP 与已有 SIMD/内存访问优化是互补关系，可以作为本实验“与多线程结合”和“体系结构相关优化”的重要结果。

## 可写入报告的结论表述

在 MPI 最终版本中，性能瓶颈主要集中在 master 端的局部 block 计算和 rotation logs 回放。由于不同 rotation log 之间存在顺序依赖，不能直接并行处理整个 logs 序列；但单条 Givens rotation 对矩阵不同行的列更新相互独立，因此可以使用 OpenMP 对行循环进行并行化。实验结果表明，在单节点 nodes=1:ppn=8 条件下，NP=4, OMP_THREADS=2 相比 NP=4, OMP_THREADS=1 将 GKH 阶段耗时从 15656.3 ms 降至 11709.0 ms，达到约 1.34 倍加速。这说明 MPI 与 OpenMP 的混合并行能够有效缓解 master 端瓶颈。与此同时，NP=2, OMP_THREADS=4 虽然也取得提升，但整体略慢于 NP=4, OMP_THREADS=2，说明当前资源约束下适度增加 MPI 进程并配合少量 OpenMP 线程更为均衡。

## 后续计划

后续可以继续补充：

1. 非阻塞通信探索
   对比当前阻塞通信与 MPI_Isend / MPI_Irecv 是否能进一步降低 dispatch 或等待开销。

2. 编译优化与 SIMD 选项探索
   比较 -O2、-O3、-march=native 对当前 MPI+OpenMP 版本的影响。

3. MPI 策略演化总结
   整理 blocking baseline、task pool、changed iteration、B+logs、master_work、MPI+OpenMP 的优化链条。

4. 与 Pthread / OpenMP 实验统一比较
   对比共享内存并行、多进程 MPI 和混合并行在该 SVD 任务上的适用场景。
