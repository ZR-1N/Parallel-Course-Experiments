# 14_final

## 本阶段目标

本目录记录 MPI 实验当前最终候选版本的主要性能结果，用于总结本次 MPI 实验中各阶段优化后的最终表现。

本阶段重点记录：

1. serial_simd 串行/SIMD 基线；
2. mpi_pool 最终版本在不同进程数下的性能；
3. master_work 对最终版本的影响；
4. 不同节点布局对最终版本性能的影响；
5. 当前最终最优配置及其相对串行基线的加速比。

## 当前最终 MPI 版本说明

当前最终 MPI 版本包含以下优化：

| 优化项                     | 说明                                                                                   |
| ----------------------- | ------------------------------------------------------------------------------------ |
| 主从式任务池                  | master 维护活动 block 队列，worker 获取局部任务                                                   |
| changed iteration       | worker 或 master 在局部 block 内连续迭代，直到达到 sweep_cap、局部收敛或发生再次分裂                           |
| sweep_cap=8             | 控制单次局部任务的最大连续迭代次数                                                                    |
| local B + rotation logs | worker 只传输局部 B 与 Givens 旋转日志，避免传输 U/V 子块                                             |
| master_work             | master 在任务池较浅时参与局部 block 计算，减少远程任务发送                                                 |
| 内存访问优化                  | 优化 apply_right_cols、apply_right_cols_range、gkh_extract_block、gkh_merge_block 的连续内存访问 |

其中，local B + rotation logs 和 master_work 是本阶段最终性能提升的关键。

## 固定实验条件

| 参数        | 取值          |
| --------- | ----------- |
| mode      | bench       |
| n         | 1000        |
| seed      | 20260408    |
| repeat    | 1           |
| sweep_cap | 8           |
| profile   | 1           |
| MPI impl  | mpi_pool    |
| 串行基线      | serial_simd |
| 主要测试平台    | qsub 队列环境   |

说明：

* serial_simd 使用 np=1。
* mpi_pool 使用最终优化版本。
* 除节点布局实验外，默认对比使用单节点运行。
* 由于 qsub 环境存在一定波动，性能结论以整体趋势和 profiling 指标共同判断。

## 结果文件建议

建议本目录保存以下结果文件：

| 文件                                        | 内容                                                          |
| ----------------------------------------- | ----------------------------------------------------------- |
| qsub_final_serial_n1000_np1_test.o        | serial_simd, np=1 标准输出                                      |
| qsub_final_serial_n1000_np1_test.e        | serial_simd, np=1 profiling 输出                              |
| qsub_final_log_n1000_np2_mw0_test.o       | mpi_pool, np=2, master_work=0 标准输出                          |
| qsub_final_log_n1000_np2_mw0_test.e       | mpi_pool, np=2, master_work=0 profiling 输出                  |
| qsub_final_log_n1000_np2_mw1_test.o       | mpi_pool, np=2, master_work=1 标准输出                          |
| qsub_final_log_n1000_np2_mw1_test.e       | mpi_pool, np=2, master_work=1 profiling 输出                  |
| qsub_final_log_n1000_np4_mw0_test.o       | mpi_pool, np=4, master_work=0 标准输出                          |
| qsub_final_log_n1000_np4_mw0_test.e       | mpi_pool, np=4, master_work=0 profiling 输出                  |
| qsub_final_log_n1000_np4_mw1_1node_test.o | mpi_pool, np=4, master_work=1, 1 node × 4 ppn 标准输出          |
| qsub_final_log_n1000_np4_mw1_1node_test.e | mpi_pool, np=4, master_work=1, 1 node × 4 ppn profiling 输出  |
| qsub_final_log_n1000_np4_mw1_2node_test.o | mpi_pool, np=4, master_work=1, 2 nodes × 2 ppn 标准输出         |
| qsub_final_log_n1000_np4_mw1_2node_test.e | mpi_pool, np=4, master_work=1, 2 nodes × 2 ppn profiling 输出 |
| qsub_final_log_n1000_np4_mw1_4node_test.o | mpi_pool, np=4, master_work=1, 4 nodes × 1 ppn 标准输出         |
| qsub_final_log_n1000_np4_mw1_4node_test.e | mpi_pool, np=4, master_work=1, 4 nodes × 1 ppn profiling 输出 |
| qsub_final_log_n1000_np8_mw1_test.o       | mpi_pool, np=8, master_work=1 标准输出                          |
| qsub_final_log_n1000_np8_mw1_test.e       | mpi_pool, np=8, master_work=1 profiling 输出                  |

## 正确性结果

所有最终测试均通过正确性检查：

| 配置                                             | passed |
| ---------------------------------------------- | ------ |
| serial_simd, np=1                              | 1/1    |
| mpi_pool, np=2, master_work=0                  | 1/1    |
| mpi_pool, np=2, master_work=1                  | 1/1    |
| mpi_pool, np=4, master_work=0                  | 1/1    |
| mpi_pool, np=4, master_work=1, 1 node × 4 ppn  | 1/1    |
| mpi_pool, np=4, master_work=1, 2 nodes × 2 ppn | 1/1    |
| mpi_pool, np=4, master_work=1, 4 nodes × 1 ppn | 1/1    |
| mpi_pool, np=8, master_work=1                  | 1/1    |

各组测试均满足重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性要求。

## 主结果表：最终版本与串行基线对比

以下表格沿用 serial_simd 的基线结果：

* serial_gkh_ms = 21197.7 ms
* serial_total_ms = 25579.97 ms

| impl         | np | master_work | 节点布局            | bidiag_ms |  gkh_ms | total_ms | GKH speedup vs serial | total speedup vs serial | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | max_queue_size |
| ------------ | -: | ----------: | --------------- | --------: | ------: | -------: | --------------------: | ----------------------: | ----------: | ----------------: | ----------------: | -------: | ---------: | ---------: | -------------: |
| serial_simd  |  1 |           0 | 1 node × 1 ppn  |   4382.27 | 21197.7 | 25579.97 |                 1.00x |                   1.00x |           - |                 - |                 - |        - |          - |          - |              - |
| mpi_pool_log |  2 |           0 | 1 node × 2 ppn  |   3620.16 | 21980.2 | 25600.36 |                 0.96x |                   1.00x |     1999.63 |           6272.53 |                 0 |  10814.2 |        994 |        994 |              3 |
| mpi_pool_log |  2 |           1 | 1 node × 2 ppn  |   3721.44 | 18686.7 | 22408.14 |                 1.13x |                   1.14x |       1.106 |             3.221 |           5866.72 |  12089.0 |         14 |        994 |              2 |
| mpi_pool_log |  4 |           0 | 1 node × 4 ppn  |   3551.61 | 19281.5 | 22833.11 |                 1.10x |                   1.12x |     2010.30 |           6862.28 |                 0 |  7536.55 |        994 |        994 |              2 |
| mpi_pool_log |  4 |           1 | 1 node × 4 ppn  |   3322.31 | 15863.9 | 19186.21 |                 1.34x |                   1.33x |       0.998 |             8.322 |           7146.44 |  8026.02 |         14 |        994 |              2 |
| mpi_pool_log |  4 |           1 | 2 nodes × 2 ppn |   3019.70 | 13035.0 | 16054.70 |                 1.63x |                   1.59x |       1.632 |             3.762 |           5857.84 |  6583.50 |         14 |        994 |              2 |
| mpi_pool_log |  4 |           1 | 4 nodes × 1 ppn |   3348.15 | 11314.7 | 14662.85 |                 1.87x |                   1.74x |       1.124 |             1.453 |           3559.94 |  7156.59 |         14 |        994 |              2 |
| mpi_pool_log |  8 |           1 | 1 node × 8 ppn  |   3498.14 | 19627.3 | 23125.44 |                 1.08x |                   1.11x |       0.819 |            51.383 |           11480.8 |   7481.2 |         14 |        994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* GKH speedup vs serial = serial_gkh_ms / current_gkh_ms
* total speedup vs serial = serial_total_ms / current_total_ms
* speedup 小于 1 表示慢于 serial_simd

## 当前最终最优配置

根据目前所有最终测试数据，当前最优配置为：

| 参数                      | 取值                      |
| ----------------------- | ----------------------- |
| impl                    | mpi_pool                |
| 通信策略                    | local B + rotation logs |
| np                      | 4                       |
| 节点布局                    | 4 nodes × 1 ppn         |
| sweep_cap               | 8                       |
| master_work             | 1                       |
| n                       | 1000                    |
| gkh_ms                  | 11314.7                 |
| total_ms                | 14662.85                |
| GKH speedup vs serial   | 1.87x                   |
| total speedup vs serial | 1.74x                   |

相对 serial_simd：

* GKH 阶段从 21197.7 ms 降至 11314.7 ms；
* GKH 阶段耗时下降约 46.6%；
* 总耗时从 25579.97 ms 降至 14662.85 ms；
* 总耗时下降约 42.7%。

## 结果分析

### 1. master_work 是最终版本的重要优化

对比 np=4 单节点下 master_work 开关：

| 配置            |  gkh_ms | tasks_sent | dispatch_ms |
| ------------- | ------: | ---------: | ----------: |
| master_work=0 | 19281.5 |        994 |     2010.30 |
| master_work=1 | 15863.9 |         14 |       0.998 |

开启 master_work 后，远程任务发送次数从 994 降至 14，dispatch_ms 也从 2010.30 ms 降至约 1 ms。这说明在当前 SVD GKH 任务中，任务池较浅，频繁远程发送小任务不划算。master 直接处理大部分局部 block 可以显著减少通信和调度开销。

### 2. 单纯增加 np 不一定提升性能

np=8 的 GKH 耗时为 19627.3 ms，明显慢于 np=4 的单节点和多节点结果。其 profiling 显示：

| 指标                |      数值 |
| ----------------- | ------: |
| tasks_sent        |      14 |
| tasks_done        |     994 |
| max_queue_size    |       2 |
| worker_compute_ms |  51.383 |
| master_compute_ms | 11480.8 |

虽然进程数增加到 8，但 tasks_sent 仍然只有 14，max_queue_size 仍为 2，说明新增 worker 很难获得足够任务。该结果表明，本 SVD 任务的 MPI 可扩展性主要受活动块数量限制，而不是单纯受进程数限制。

### 3. 多节点布局在当前实验中表现更好

节点布局实验结果为：

| 节点布局            |  gkh_ms | total_ms |
| --------------- | ------: | -------: |
| 1 node × 4 ppn  | 15863.9 | 19186.21 |
| 2 nodes × 2 ppn | 13035.0 | 16054.70 |
| 4 nodes × 1 ppn | 11314.7 | 14662.85 |

与最初预期不同，多节点布局反而更快。可能原因包括：

1. 当前最终版本的远程任务数很少
   tasks_sent 始终只有 14，因此跨节点通信次数较少，网络通信开销没有成为主导瓶颈。

2. 单节点多进程可能存在资源竞争
   单节点 4 进程共享同一节点的 CPU、cache 和内存带宽，而 4 nodes × 1 ppn 可以让每个进程使用相对独立的节点资源。

3. master 端本地计算和 merge/replay 占比较高
   当前版本的主要瓶颈是 master_compute_ms 和 merge_ms，多节点布局可能减少了部分资源争用，使 master 端工作更快完成。

4. qsub 环境存在运行波动
   不同节点当时负载、硬件状态和调度环境可能影响结果。因此该结论应表述为“当前实验观测中多节点布局更优”，而不应绝对化为“多节点一定更快”。

### 4. 当前主要瓶颈仍然是 master 端工作

以当前最优配置 4 nodes × 1 ppn 为例：

| 指标                |      数值 |
| ----------------- | ------: |
| master_compute_ms | 3559.94 |
| merge_ms          | 7156.59 |
| worker_compute_ms |   1.453 |
| tasks_sent        |      14 |
| tasks_done        |     994 |
| max_queue_size    |       2 |

可以看出，绝大部分耗时仍集中在 master 端的局部计算、局部 B 合并和 rotation logs 回放。worker 只承担少量辅助任务。因此，当前 MPI 加速并不是典型的线性并行加速，而是通过减少远程通信、优化任务粒度、降低内存访问开销，并利用多节点资源缓解部分资源竞争所获得的综合收益。

## 阶段结论

当前最终 MPI 版本在 n=1000 下取得了明显优于 serial_simd 的性能。最优配置为 np=4, sweep_cap=8, master_work=1, 4 nodes × 1 ppn，GKH 阶段达到约 1.87x 加速，端到端达到约 1.74x 加速。

但实验同时表明：

1. 该 SVD GKH 任务的 MPI 加速不是随进程数单调增加；
2. max_queue_size 始终较小，说明活动块并行度有限；
3. 频繁远程发送任务不适合该任务结构，master_work 对性能非常关键；
4. 当前版本中 worker 计算量较少，主要瓶颈仍在 master 端 merge/replay；
5. 多节点布局在当前实验中表现更好，可能与减少单节点资源竞争有关，但仍需结合 qsub 环境波动谨慎分析。

因此，报告中应避免宣称“MPI 实现获得线性加速”，更准确的表述是：

通过任务池调度、changed iteration、local B + rotation logs、master_work 和内存访问优化，最终 MPI 版本在中大规模矩阵上取得了有效加速；但由于 GKH 活动块数量有限、master 合并/日志回放成本较高，其扩展性仍受到明显限制。

## 后续计划

后续仍可补充以下探索：

1. MPI + OpenMP 混合并行
   尝试在单条 rotation 的行更新或局部矩阵操作中引入 OpenMP。

2. 非阻塞通信探索
   对比当前阻塞通信与 MPI_Isend / MPI_Irecv 版本的调度开销。

3. 不同 MPI 策略总结
   整理 blocking baseline、task pool、changed iteration、B+logs、master_work 的优化演化链。

4. 与 SIMD、Pthread、OpenMP 实验统一比较
   分析共享内存并行与分布式 MPI 在该 SVD 算法中的适用场景。
