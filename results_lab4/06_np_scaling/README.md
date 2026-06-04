# 06_np_scaling

## 本阶段目标

本目录记录最终 MPI 实现版本在不同进程数下的性能变化，用于分析本 SVD 分解任务在 MPI 并行化下的可扩展性。

本阶段重点回答以下问题：

1. 增加 MPI 进程数是否能够带来稳定加速；
2. 当前任务池调度是否能够充分利用更多 worker；
3. master_work 对不同进程数下性能的影响；
4. MPI 并行化瓶颈主要来自计算、通信、任务池深度还是 master 端合并与 rotation logs 回放。

## 当前最终 MPI 版本说明

本阶段测试使用当前最终候选 MPI 版本，其主要特征如下：

| 项目          | 说明                                                                            |
| ----------- | ----------------------------------------------------------------------------- |
| 调度方式        | 主从式任务池                                                                        |
| 通信方式        | local B + rotation logs                                                       |
| 局部迭代        | changed iteration                                                             |
| sweep_cap   | 8                                                                             |
| master_work | 1                                                                             |
| 内存访问优化      | apply_right_cols、apply_right_cols_range、gkh_extract_block、gkh_merge_block 已优化 |
| profiling   | 开启                                                                            |

其中，local B + rotation logs 的设计避免在每次任务中传输 U/V 子块；master_work 允许 master 在任务池较浅时参与局部 block 计算，从而减少远程任务发送次数。

## 固定实验条件

| 参数          | 取值        |
| ----------- | --------- |
| mode        | bench     |
| n           | 1000      |
| seed        | 20260408  |
| repeat      | 1         |
| impl        | mpi_pool  |
| sweep_cap   | 8         |
| master_work | 1         |
| profile     | 1         |
| 平台          | qsub 队列环境 |

说明：

* np=1 时使用 serial_simd 作为串行/SIMD 基线。
* np=2、4、8 时使用最终 mpi_pool 版本。
* 本阶段主要关注 GKH 迭代阶段的并行效果；bidiagonalization 阶段仍主要由 root 进程完成。

## 结果文件

建议本目录保存以下文件：

| 文件                                 | 内容                                         |
| ---------------------------------- | ------------------------------------------ |
| qsub_final_n1000_np1_serial_test.o | serial_simd, np=1 标准输出                     |
| qsub_final_n1000_np1_serial_test.e | serial_simd, np=1 profiling 输出             |
| qsub_final_n1000_np2_mw1_test.o    | mpi_pool, np=2, master_work=1 标准输出         |
| qsub_final_n1000_np2_mw1_test.e    | mpi_pool, np=2, master_work=1 profiling 输出 |
| qsub_final_n1000_np4_mw1_test.o    | mpi_pool, np=4, master_work=1 标准输出         |
| qsub_final_n1000_np4_mw1_test.e    | mpi_pool, np=4, master_work=1 profiling 输出 |
| qsub_final_n1000_np8_mw1_test.o    | mpi_pool, np=8, master_work=1 标准输出         |
| qsub_final_n1000_np8_mw1_test.e    | mpi_pool, np=8, master_work=1 profiling 输出 |

## 正确性结果

所有测试均通过正确性检查：

| 配置                            | passed |
| ----------------------------- | ------ |
| serial_simd, np=1             | 1/1    |
| mpi_pool, np=2, master_work=1 | 1/1    |
| mpi_pool, np=4, master_work=1 | 1/1    |
| mpi_pool, np=8, master_work=1 | 1/1    |

各组测试的重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性均满足设定阈值。

## 主结果表

| impl         | np | master_work | bidiag_ms |  gkh_ms | total_ms | GKH speedup vs serial | total speedup vs serial | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size |
| ------------ | -: | ----------: | --------: | ------: | -------: | --------------------: | ----------------------: | ----------: | ----------------: | ----------------: | -------: | ---------: | ---------: | -----------: | -------------: |
| serial_simd  |  1 |           0 |   4382.27 | 21197.7 | 25579.97 |                 1.00x |                   1.00x |           - |                 - |                 - |        - |          - |          - |            - |              - |
| mpi_pool_log |  2 |           1 |   3721.44 | 18686.7 | 22408.14 |                 1.13x |                   1.14x |       1.106 |             3.221 |           5866.72 |  12089.0 |         14 |        994 |          994 |              2 |
| mpi_pool_log |  4 |           1 |   3705.44 | 15012.7 | 18718.14 |                 1.41x |                   1.37x |       0.960 |             4.700 |           6872.28 |  7415.12 |         14 |        994 |          994 |              2 |
| mpi_pool_log |  8 |           1 |   3498.14 | 19627.3 | 23125.44 |                 1.08x |                   1.11x |       0.819 |            51.383 |           11480.8 |   7481.2 |         14 |        994 |          994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* GKH speedup vs serial = serial_gkh_ms / current_gkh_ms
* total speedup vs serial = serial_total_ms / current_total_ms
* serial_gkh_ms = 21197.7 ms
* serial_total_ms = 25579.97 ms

## 结果分析

### 1. np=4 是当前最优进程数

从 GKH 阶段耗时看：

| np |  gkh_ms |
| -: | ------: |
|  1 | 21197.7 |
|  2 | 18686.7 |
|  4 | 15012.7 |
|  8 | 19627.3 |

其中 np=4 时取得最佳结果，GKH 阶段耗时为 15012.7 ms，相对 serial_simd 的 21197.7 ms 达到约 1.41x 加速。

端到端耗时方面：

| np | total_ms |
| -: | -------: |
|  1 | 25579.97 |
|  2 | 22408.14 |
|  4 | 18718.14 |
|  8 | 23125.44 |

np=4 时端到端总耗时为 18718.14 ms，相对 serial_simd 的 25579.97 ms 达到约 1.37x 加速。

因此，当前最终版本中，np=4 是最合适的进程数配置。

### 2. np=2 能取得一定加速，但幅度有限

np=2 时，GKH 阶段从 21197.7 ms 降至 18686.7 ms，达到约 1.13x 加速。说明 local B + rotation logs 和 master_work 已经能够减少一部分 MPI 通信与调度开销。

但是 profiling 显示：

| 指标                |      数值 |
| ----------------- | ------: |
| master_compute_ms | 5866.72 |
| merge_ms          | 12089.0 |
| tasks_sent        |      14 |
| tasks_done        |     994 |
| max_queue_size    |       2 |

可以看出，大部分耗时仍然集中在 master 端的局部计算和 merge/replay。worker 实际承担的任务较少，因此 np=2 的提升有限。

### 3. np=4 取得最佳性能

np=4 时：

| 指标                |      数值 |
| ----------------- | ------: |
| gkh_ms            | 15012.7 |
| dispatch_ms       |   0.960 |
| worker_compute_ms |   4.700 |
| master_compute_ms | 6872.28 |
| merge_ms          | 7415.12 |
| tasks_sent        |      14 |
| tasks_done        |     994 |
| max_queue_size    |       2 |

相比 np=2，np=4 的 merge_ms 明显下降：

| np | merge_ms |
| -: | -------: |
|  2 |  12089.0 |
|  4 |  7415.12 |

同时，总 GKH 时间也明显下降。因此，在当前任务结构下，np=4 能较好地平衡 master 本地计算、少量 worker 辅助计算和日志回放开销。

### 4. np=8 未继续加速

np=8 的 GKH 耗时为 19627.3 ms，反而比 np=4 更慢。profiling 显示：

| 指标                |      数值 |
| ----------------- | ------: |
| worker_compute_ms |  51.383 |
| master_compute_ms | 11480.8 |
| merge_ms          |  7481.2 |
| tasks_sent        |      14 |
| tasks_done        |     994 |
| max_queue_size    |       2 |

虽然进程数增加到 8，但 tasks_sent 仍然只有 14，max_queue_size 仍然为 2。这说明任务池中同时可供分配的非平凡 block 数量很少，额外 worker 难以获得足够任务。

同时，master_compute_ms 从 np=4 的 6872.28 ms 上升到 np=8 的 11480.8 ms，说明总耗时仍主要受 master 端串行工作影响。额外进程并没有有效降低瓶颈，反而可能带来等待和调度负担。

因此，np=8 不适合作为当前算法与实现下的最优配置。

## 关键结论

### 1. MPI 加速不是随进程数单调提升

本实验结果表明，在该 SVD GKH 迭代任务中，单纯增加 MPI 进程数不能保证性能提升。

根本原因是：

* GKH 迭代中的活动块数量有限；
* 任务池最大深度 max_queue_size 只有 2；
* 可并行任务不足以喂满更多 worker；
* master 端仍需承担日志回放和局部结果合并；
* 过多进程会增加等待与调度复杂度。

因此，当前实现下 np=4 优于 np=2 和 np=8。

### 2. master_work 与任务池深度密切相关

在最终版本中，master_work 不是简单地让 master 多做计算，而是在任务池较浅时减少远程任务发送次数。

从结果看：

| np | tasks_sent | tasks_done |
| -: | ---------: | ---------: |
|  2 |         14 |        994 |
|  4 |         14 |        994 |
|  8 |         14 |        994 |

可以看出，绝大部分任务最终由 master 本地完成，worker 只承担少量辅助任务。这种策略在任务池较浅时比频繁远程发送任务更高效。

### 3. 当前主要瓶颈是 master 端 merge/replay

最终版本虽然减少了远程通信，但 master 端仍然需要：

* merge local B；
* replay rotation logs；
* 维护任务池；
* 处理最终收敛检查。

因此，merge_ms 在各组中仍然较高：

| np | merge_ms |
| -: | -------: |
|  2 |  12089.0 |
|  4 |  7415.12 |
|  8 |   7481.2 |

这说明下一步若继续优化，应重点降低 rotation logs 回放成本，或进一步减少 master 端重复合并次数。

## 阶段结论

本阶段重新测试了最终 MPI 实现版本在 n=1000 下的进程数扩展性。实验表明：

1. np=2 相比 serial_simd 有一定提升，但提升有限；
2. np=4 取得最佳性能，GKH 阶段达到约 1.41x 加速，总体达到约 1.37x 加速；
3. np=8 未继续提升，说明该 SVD 任务的 MPI 扩展性受活动块数量和 master 端合并/回放开销限制；
4. 当前最优配置为 np=4, sweep_cap=8, master_work=1；
5. 最终报告中应强调该任务不是线性扩展型任务，优化重点在减少通信、控制任务粒度和降低 master 端串行开销。

## 后续计划

后续实验将继续补充：

1. 不同问题规模测试
   固定 np=4, sweep_cap=8, master_work=1，测试 n=256、512、1000。

2. 不同节点布局测试
   固定 np=4, n=1000，对比 1 node × 4 ppn、2 nodes × 2 ppn、4 nodes × 1 ppn。

3. MPI 与 OpenMP 混合并行探索
   尝试在 rotation replay 或局部矩阵更新中加入 OpenMP。

4. 非阻塞通信探索
   对比阻塞双边通信与 MPI_Isend / MPI_Irecv 的调度开销差异。

5. 与 SIMD、Pthread、OpenMP 实验结果统一比较
   分析共享内存并行与分布式 MPI 在该 SVD 算法中的适用场景。
