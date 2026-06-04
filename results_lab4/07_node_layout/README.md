# 07_node_layout

## 本阶段目标

本目录记录最终 MPI 实现版本在不同 PBS 节点布局下的性能表现，用于分析 MPI 进程分布方式对 SVD GKH 迭代性能的影响。

本阶段重点回答以下问题：

1. 相同 np 下，不同节点布局是否影响性能；
2. 单节点多进程与多节点少进程相比，哪种布局更适合当前 MPI 实现；
3. 当前最终版本的主要瓶颈是网络通信、节点内资源竞争，还是 master 端合并与 rotation logs 回放；
4. PBS 节点布局变化是否会改变最终最优配置。

## 当前最终 MPI 版本说明

本阶段测试使用当前最终候选 MPI 版本，其主要特征如下：

| 项目          | 说明                                                                            |
| ----------- | ----------------------------------------------------------------------------- |
| 调度方式        | 主从式任务池                                                                        |
| 通信方式        | local B + rotation logs                                                       |
| 局部迭代        | changed iteration                                                             |
| sweep_cap   | 8                                                                             |
| master_work | 1                                                                             |
| np          | 4                                                                             |
| 内存访问优化      | apply_right_cols、apply_right_cols_range、gkh_extract_block、gkh_merge_block 已优化 |
| profiling   | 开启                                                                            |

该版本通过 local B + rotation logs 避免频繁传输 U/V 子块，通过 master_work 在任务池较浅时让 master 直接处理大部分局部 block，从而减少远程任务发送次数。

## 固定实验条件

| 参数          | 取值        |
| ----------- | --------- |
| mode        | bench     |
| impl        | mpi_pool  |
| n           | 1000      |
| seed        | 20260408  |
| repeat      | 1         |
| np          | 4         |
| sweep_cap   | 8         |
| master_work | 1         |
| profile     | 1         |
| 平台          | qsub 队列环境 |

说明：

* 本阶段只改变 PBS 节点布局，不改变算法实现和运行参数。
* `ppn` 表示每个节点分配的 MPI 进程槽位，不是 OpenMP 线程数。
* 本实验中 OpenMP 线程数保持为 1，因此这里讨论的是 MPI 进程布局，而不是多线程布局。

## PBS 节点布局

| 布局名称            | PBS 配置        | 实际含义                            |
| --------------- | ------------- | ------------------------------- |
| 1 node × 4 ppn  | nodes=1:ppn=4 | 4 个 MPI 进程位于同一个计算节点             |
| 2 nodes × 2 ppn | nodes=2:ppn=2 | 4 个 MPI 进程分布在 2 个节点上，每个节点 2 个进程 |
| 4 nodes × 1 ppn | nodes=4:ppn=1 | 4 个 MPI 进程分布在 4 个节点上，每个节点 1 个进程 |

## 结果文件

建议本目录保存以下文件：

| 文件                            | 内容                           |
| ----------------------------- | ---------------------------- |
| qsub_layout_1node_4ppn_test.o | 1 node × 4 ppn 标准输出          |
| qsub_layout_1node_4ppn_test.e | 1 node × 4 ppn profiling 输出  |
| qsub_layout_2node_2ppn_test.o | 2 nodes × 2 ppn 标准输出         |
| qsub_layout_2node_2ppn_test.e | 2 nodes × 2 ppn profiling 输出 |
| qsub_layout_4node_1ppn_test.o | 4 nodes × 1 ppn 标准输出         |
| qsub_layout_4node_1ppn_test.e | 4 nodes × 1 ppn profiling 输出 |

## 正确性结果

所有节点布局测试均通过正确性检查：

| 节点布局            | passed |
| --------------- | ------ |
| 1 node × 4 ppn  | 1/1    |
| 2 nodes × 2 ppn | 1/1    |
| 4 nodes × 1 ppn | 1/1    |

各组测试的重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性均满足设定阈值。

## 主结果表

| 节点布局            | nodes | ppn | np | bidiag_ms |  gkh_ms | total_ms | relative GKH speedup vs 1node | relative total speedup vs 1node | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size |
| --------------- | ----: | --: | -: | --------: | ------: | -------: | ----------------------------: | ------------------------------: | ----------: | ----------------: | ----------------: | -------: | ---------: | ---------: | -----------: | -------------: |
| 1 node × 4 ppn  |     1 |   4 |  4 |   3322.31 | 15863.9 | 19186.21 |                         1.00x |                           1.00x |    0.998259 |           8.32248 |           7146.44 |  8026.02 |         14 |        994 |          994 |              2 |
| 2 nodes × 2 ppn |     2 |   2 |  4 |   3019.70 | 13035.0 | 16054.70 |                         1.22x |                           1.20x |     1.63174 |           3.76153 |           5857.84 |  6583.50 |         14 |        994 |          994 |              2 |
| 4 nodes × 1 ppn |     4 |   1 |  4 |   3348.15 | 11314.7 | 14662.85 |                         1.40x |                           1.31x |     1.12414 |           1.45316 |           3559.94 |  7156.59 |         14 |        994 |          994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* relative GKH speedup vs 1node = 1node_gkh_ms / current_gkh_ms
* relative total speedup vs 1node = 1node_total_ms / current_total_ms
* 这里的 speedup 只用于比较不同节点布局，不是相对 serial_simd 的加速比

## 结果分析

### 1. 多节点布局在本次实验中反而更快

实验结果显示：

| 节点布局            |  gkh_ms |
| --------------- | ------: |
| 1 node × 4 ppn  | 15863.9 |
| 2 nodes × 2 ppn | 13035.0 |
| 4 nodes × 1 ppn | 11314.7 |

与最初预期不同，多节点布局没有变慢，反而表现更好。其中 4 nodes × 1 ppn 的 GKH 阶段耗时最低，为 11314.7 ms，相比 1 node × 4 ppn 达到约 1.40x 的相对加速。

端到端耗时也呈现类似趋势：

| 节点布局            | total_ms |
| --------------- | -------: |
| 1 node × 4 ppn  | 19186.21 |
| 2 nodes × 2 ppn | 16054.70 |
| 4 nodes × 1 ppn | 14662.85 |

4 nodes × 1 ppn 相比 1 node × 4 ppn 端到端达到约 1.31x 的相对加速。

### 2. 当前最终版本的远程任务很少，跨节点通信没有成为主瓶颈

三组节点布局中，tasks_sent 均为 14：

| 节点布局            | tasks_sent | tasks_done |
| --------------- | ---------: | ---------: |
| 1 node × 4 ppn  |         14 |        994 |
| 2 nodes × 2 ppn |         14 |        994 |
| 4 nodes × 1 ppn |         14 |        994 |

这说明当前最终版本中，大部分任务由 master 本地处理，worker 只处理少量远程任务。由于远程任务数量很少，即使采用多节点布局，跨节点通信次数也较少，网络通信开销没有成为主导瓶颈。

这一点也可以从 dispatch_ms 看出：

| 节点布局            | dispatch_ms |
| --------------- | ----------: |
| 1 node × 4 ppn  |    0.998259 |
| 2 nodes × 2 ppn |     1.63174 |
| 4 nodes × 1 ppn |     1.12414 |

dispatch_ms 在三组中都很小，说明远程任务发送的总开销很低。因此，多节点布局并没有因为网络通信而明显退化。

### 3. 单节点多进程可能受到资源竞争影响

1 node × 4 ppn 中，4 个 MPI 进程共享同一节点的 CPU、cache、内存带宽等资源。虽然当前版本中 worker 计算量不大，但 master 端仍需要执行大量局部 block 计算、local B 合并和 rotation logs 回放。

对比 master_compute_ms：

| 节点布局            | master_compute_ms |
| --------------- | ----------------: |
| 1 node × 4 ppn  |           7146.44 |
| 2 nodes × 2 ppn |           5857.84 |
| 4 nodes × 1 ppn |           3559.94 |

4 nodes × 1 ppn 下 master_compute_ms 明显低于单节点布局。这可能说明在多节点少进程布局下，master 所在节点受到的资源竞争更少，能够更高效地完成本地计算任务。

### 4. merge/replay 仍然是主要瓶颈之一

虽然 4 nodes × 1 ppn 的 master_compute_ms 显著下降，但 merge_ms 仍然较高：

| 节点布局            | merge_ms |
| --------------- | -------: |
| 1 node × 4 ppn  |  8026.02 |
| 2 nodes × 2 ppn |  6583.50 |
| 4 nodes × 1 ppn |  7156.59 |

这说明当前版本的性能仍然受到 master 端合并 local B 和回放 rotation logs 的限制。即使改变节点布局，merge/replay 仍然是重要瓶颈。

### 5. 节点布局实验结果需要谨慎解释

虽然本次实验中 4 nodes × 1 ppn 最快，但不能简单得出“多节点一定更快”的结论。原因包括：

1. qsub 队列环境可能存在运行波动；
2. 不同节点当时负载可能不同；
3. 当前最终版本的远程任务数很少，因此该结论依赖于当前 master_work 策略；
4. 如果未来改成更多任务远程分发，跨节点通信开销可能重新变成瓶颈。

因此，本阶段更稳妥的结论是：

在当前最终 MPI 版本中，由于远程任务发送次数很少，跨节点通信开销没有成为主导；相反，多节点少进程布局可能减少单节点资源竞争，因此在本次测试中表现更好。

## 阶段结论

本阶段比较了相同 np=4 下三种 PBS 节点布局的性能。实验表明：

1. 1 node × 4 ppn 的 GKH 耗时为 15863.9 ms；
2. 2 nodes × 2 ppn 的 GKH 耗时下降到 13035.0 ms；
3. 4 nodes × 1 ppn 的 GKH 耗时进一步下降到 11314.7 ms；
4. 当前最终版本中 tasks_sent 始终只有 14，说明远程通信次数很少；
5. 多节点布局没有明显放大通信开销，反而可能通过减少单节点资源竞争提升性能；
6. 4 nodes × 1 ppn 是当前观测到的最优节点布局。

因此，在最终报告中，当前最优配置可以更新为：

| 参数            | 当前最优取值                  |
| ------------- | ----------------------- |
| impl          | mpi_pool                |
| n             | 1000                    |
| np            | 4                       |
| 节点布局          | 4 nodes × 1 ppn         |
| sweep_cap     | 8                       |
| master_work   | 1                       |
| communication | local B + rotation logs |
| gkh_ms        | 11314.7                 |
| total_ms      | 14662.85                |

## 可写入报告的结论表述

节点布局实验表明，在当前最终 MPI 版本中，多节点布局并未因为跨节点通信而退化，反而表现优于单节点布局。原因在于 master_work 策略使远程任务发送次数显著减少，tasks_sent 仅为 14，因此跨节点通信不是主要瓶颈。相比之下，master 端局部计算和 rotation logs 回放更影响总耗时。多节点少进程布局可能降低单节点 CPU、cache 和内存带宽竞争，因此 4 nodes × 1 ppn 在本次测试中取得最优性能。不过，由于 qsub 环境存在波动，该结论应限定在当前实现和当前实验条件下，不宜泛化为所有 MPI 程序均适合多节点布局。

## 后续计划

后续实验建议继续补充：

1. MPI + OpenMP 混合并行
   尝试在 rotation replay 或局部矩阵更新中引入 OpenMP，观察线程数对 master 端瓶颈的影响。

2. MPI 不同通信方法对比
   尝试实现非阻塞通信版本，比较 MPI_Send/MPI_Recv 与 MPI_Isend/MPI_Irecv 的差异。

3. MPI 策略演化总结
   整理 blocking baseline、task pool、changed iteration、B+logs、master_work、node layout 的优化链条。

4. 与 SIMD、Pthread、OpenMP 实验统一比较
   分析共享内存并行与分布式 MPI 在该 SVD 算法中的适用场景。
