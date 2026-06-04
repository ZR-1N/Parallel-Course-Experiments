# 08_nonblocking

## 本阶段目标

本目录记录 MPI 非阻塞通信探索实验结果，用于比较当前阻塞通信版本与非阻塞结果接收版本在 SVD GKH 迭代任务中的性能差异。

本阶段重点回答以下问题：

1. 使用 MPI 非阻塞通信是否能进一步降低 master-worker 通信等待；
2. 在最终版本中，通信是否仍然是主要瓶颈；
3. master_work 开启和关闭时，非阻塞通信的效果是否不同；
4. 当前 SVD GKH 任务是否适合通过非阻塞通信继续优化。

## 当前非阻塞版本说明

本阶段没有替换已有稳定的 mpi_pool 主线，而是新增 `mpi_nonblocking` 分支进行探索。

当前非阻塞版本采用的是轻量探索方案：

| 项目         | 说明                                                                       |
| ---------- | ------------------------------------------------------------------------ |
| impl 名称    | mpi_nonblocking                                                          |
| 基础版本       | mpi_pool + changed iteration + local B + rotation logs                   |
| 非阻塞部分      | master 对 worker 返回的 MPIResultHeader 使用 MPI_Irecv                         |
| 检查方式       | MPI_Test / MPI_Waitany                                                   |
| payload 接收 | header 完成后，后续 compute_ms、child blocks、rotation logs、local B 仍使用 MPI_Recv |
| worker 侧   | 复用原 worker_loop_until_split_or_cap                                       |
| send 侧     | 任务发送仍主要使用阻塞 MPI_Send                                                     |
| 目的         | 探索非阻塞结果头接收是否能减少 master 等待                                                |

因此，本版本不是完全异步化的 MPI 实现，而是对结果接收路径进行非阻塞化探索。这样做的优点是风险较低，不影响已有稳定主线；缺点是非阻塞优化空间有限。

## 固定实验条件

| 参数          | 取值            |
| ----------- | ------------- |
| mode        | bench         |
| n           | 1000          |
| seed        | 20260408      |
| repeat      | 1             |
| sweep_cap   | 8             |
| profile     | 1             |
| np          | 4             |
| OMP_THREADS | 2             |
| PBS 资源      | nodes=1:ppn=8 |
| 平台          | qsub 队列环境     |

本阶段比较两类配置：

1. master_work=1：最终主线配置，远程任务较少；
2. master_work=0：通信更频繁，用于观察非阻塞通信在高远程任务数下是否更有效。

## 结果文件

建议本目录保存以下文件：

| 文件                                   | 内容                                          |
| ------------------------------------ | ------------------------------------------- |
| qsub_blocking_np4_omp2_mw1_test.o    | mpi_pool, master_work=1 标准输出                |
| qsub_blocking_np4_omp2_mw1_test.e    | mpi_pool, master_work=1 profiling 输出        |
| qsub_nonblocking_np4_omp2_mw1_test.o | mpi_nonblocking, master_work=1 标准输出         |
| qsub_nonblocking_np4_omp2_mw1_test.e | mpi_nonblocking, master_work=1 profiling 输出 |
| qsub_blocking_np4_omp2_mw0_test.o    | mpi_pool, master_work=0 标准输出                |
| qsub_blocking_np4_omp2_mw0_test.e    | mpi_pool, master_work=0 profiling 输出        |
| qsub_nonblocking_np4_omp2_mw0_test.o | mpi_nonblocking, master_work=0 标准输出         |
| qsub_nonblocking_np4_omp2_mw0_test.e | mpi_nonblocking, master_work=0 profiling 输出 |

## 正确性结果

所有测试均通过正确性检查：

| impl            | master_work | passed |
| --------------- | ----------: | ------ |
| mpi_pool        |           1 | 1/1    |
| mpi_nonblocking |           1 | 1/1    |
| mpi_pool        |           0 | 1/1    |
| mpi_nonblocking |           0 | 1/1    |

各组测试的重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性均满足设定阈值。

## 主结果表

| impl            | master_work | bidiag_ms |  gkh_ms | total_ms | GKH speedup vs blocking | total speedup vs blocking | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size |
| --------------- | ----------: | --------: | ------: | -------: | ----------------------: | ------------------------: | ----------: | ----------------: | ----------------: | -------: | ---------: | ---------: | -----------: | -------------: |
| mpi_pool        |           1 |   4002.11 | 11718.8 | 15720.91 |                   1.00x |                     1.00x |    0.994205 |           4.87781 |           4992.19 |  6168.94 |         14 |        994 |          994 |              2 |
| mpi_nonblocking |           1 |   4442.64 | 13782.2 | 18224.84 |                   0.85x |                     0.86x |    0.499249 |           1.31845 |           7541.46 |  5570.31 |         10 |        994 |          994 |              2 |
| mpi_pool        |           0 |   4478.97 | 17080.2 | 21559.17 |                   1.00x |                     1.00x |     1704.63 |           6728.54 |                 0 |  5874.49 |        994 |        994 |          994 |              2 |
| mpi_nonblocking |           0 |   4037.37 | 17458.2 | 21495.57 |                   0.98x |                     1.00x |     1763.62 |           6981.64 |                 0 |  5869.34 |        994 |        994 |          994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* 对于 master_work=1，blocking 基线为 mpi_pool, master_work=1
* 对于 master_work=0，blocking 基线为 mpi_pool, master_work=0
* GKH speedup vs blocking = blocking gkh_ms / current gkh_ms
* total speedup vs blocking = blocking total_ms / current total_ms
* speedup 小于 1 表示 nonblocking 慢于 blocking

## 结果分析

### 1. master_work=1 时，nonblocking 版本慢于 blocking 主线

在最终主线配置 master_work=1 下：

| impl            |  gkh_ms | total_ms |
| --------------- | ------: | -------: |
| mpi_pool        | 11718.8 | 15720.91 |
| mpi_nonblocking | 13782.2 | 18224.84 |

nonblocking 的 GKH 阶段约为 blocking 的 0.85x，即慢于 blocking 版本。

从 profiling 看：

| 指标                | mpi_pool | mpi_nonblocking |
| ----------------- | -------: | --------------: |
| dispatch_ms       | 0.994205 |        0.499249 |
| worker_compute_ms |  4.87781 |         1.31845 |
| master_compute_ms |  4992.19 |         7541.46 |
| merge_ms          |  6168.94 |         5570.31 |
| tasks_sent        |       14 |              10 |

nonblocking 确实降低了 dispatch_ms，并且 tasks_sent 从 14 变为 10，说明调度行为发生了一些变化。但是总时间反而增加，主要原因是 master_compute_ms 明显上升，从 4992.19 ms 增加到 7541.46 ms。

这说明在 master_work=1 的最终版本中，远程通信已经不是主要瓶颈。当前主要开销来自 master 本地处理任务、局部 B 合并和 rotation logs 回放。非阻塞结果头接收无法有效降低这些开销。

### 2. master_work=0 时，nonblocking 与 blocking 接近但没有优势

关闭 master_work 后，远程任务数显著增加：

| impl            | tasks_sent | tasks_done |
| --------------- | ---------: | ---------: |
| mpi_pool        |        994 |        994 |
| mpi_nonblocking |        994 |        994 |

此时通信更频繁，更适合观察非阻塞通信是否有用。

结果为：

| impl            |  gkh_ms | total_ms |
| --------------- | ------: | -------: |
| mpi_pool        | 17080.2 | 21559.17 |
| mpi_nonblocking | 17458.2 | 21495.57 |

从 GKH 阶段看，nonblocking 略慢：

| 指标                      |    数值 |
| ----------------------- | ----: |
| GKH speedup vs blocking | 0.98x |

从端到端时间看，两者几乎相同，nonblocking 因 bidiag_ms 较低导致 total_ms 略低，但这部分不属于 MPI GKH 通信优化本身。因此本阶段主要结论应基于 GKH 阶段：nonblocking 在通信较频繁配置下也没有明显优于 blocking。

profiling 显示：

| 指标                | mpi_pool | mpi_nonblocking |
| ----------------- | -------: | --------------: |
| dispatch_ms       |  1704.63 |         1763.62 |
| worker_compute_ms |  6728.54 |         6981.64 |
| merge_ms          |  5874.49 |         5869.34 |
| tasks_sent        |      994 |             994 |

可以看出，nonblocking 的 merge_ms 与 blocking 几乎相同，dispatch_ms 反而略高。因此当前轻量级非阻塞实现没有带来有效收益。

### 3. 当前非阻塞实现的收益有限

本阶段实现的是轻量级非阻塞结果头接收，即：

* 使用 MPI_Irecv 预先接收 worker 返回的 MPIResultHeader；
* 使用 MPI_Test 或 MPI_Waitany 判断哪个 worker 已完成；
* 但后续 payload 数据仍然使用 MPI_Recv 接收；
* 任务发送仍主要使用 MPI_Send；
* worker 侧实现保持不变。

因此，该版本只能减少 master 在等待 result header 时的阻塞，不会减少以下开销：

| 开销                   | 是否被当前 nonblocking 优化 |
| -------------------- | -------------------- |
| local B payload 接收   | 否                    |
| rotation logs 接收     | 否                    |
| local B merge        | 否                    |
| rotation logs replay | 否                    |
| master 本地 block 计算   | 否                    |
| worker 实际计算          | 否                    |

这解释了为什么 nonblocking 版本正确性通过，但性能没有明显提升。

### 4. 当前最终版本中通信已经不是主瓶颈

在 master_work=1 下：

| impl            | tasks_sent | dispatch_ms |
| --------------- | ---------: | ----------: |
| mpi_pool        |         14 |    0.994205 |
| mpi_nonblocking |         10 |    0.499249 |

远程任务数本身已经很少，dispatch_ms 也只有约 1 ms 或更低。相比之下：

| 指标                |              数值范围 |
| ----------------- | ----------------: |
| master_compute_ms | 4992.19 到 7541.46 |
| merge_ms          | 5570.31 到 6168.94 |
| gkh_ms            | 11718.8 到 13782.2 |

因此，优化 dispatch 或 result header 等待，对总性能影响非常有限。最终版本的瓶颈仍然集中在 master 端计算和 rotation logs 回放上。

### 5. nonblocking 探索仍然有实验意义

虽然当前 nonblocking 版本没有超过 blocking 主线，但它仍然有价值：

1. 验证了 MPI_Irecv、MPI_Test、MPI_Waitany 可以正确接入当前任务池框架；
2. 说明当前最终版本的瓶颈已经不在简单阻塞等待通信；
3. 对比 master_work=0 和 master_work=1，证明减少任务数量比改通信方式更重要；
4. 为报告中的“MPI 不同编程方法探索”提供实测依据。

因此，报告中不应把 nonblocking 写成失败，而应写成：

非阻塞通信探索表明，在当前 SVD GKH 实现中，通信等待并非主要性能瓶颈。相比继续优化结果头接收，减少任务数量、降低 merge/replay 成本、优化 master 端计算更重要。

## 与最终主线的关系

当前最终主线仍建议使用：

| 项             | 取值                                 |
| ------------- | ---------------------------------- |
| impl          | mpi_pool                           |
| communication | blocking MPI_Send / MPI_Recv       |
| sweep_cap     | 8                                  |
| master_work   | 1                                  |
| OpenMP        | 可选，推荐 OMP_THREADS=2 做单节点混合         |
| 多节点最优         | np=4, 4 nodes × 1 ppn              |
| 单节点混合最优       | np=4, OMP_THREADS=2, nodes=1:ppn=8 |

nonblocking 版本作为探索项保留，不作为最终性能主版本。

## 阶段结论

本阶段实现并测试了基于 MPI_Irecv、MPI_Test 和 MPI_Waitany 的非阻塞结果接收版本。所有测试均通过正确性检查，说明该非阻塞通信机制可以正确接入当前主从式任务池框架。

性能方面，在 master_work=1 的最终配置下，nonblocking 版本 GKH 耗时为 13782.2 ms，慢于 blocking 主线的 11718.8 ms。profiling 显示，nonblocking 虽然降低了 dispatch_ms，但 master_compute_ms 明显上升，总体性能下降。在 master_work=0 的通信频繁配置下，nonblocking 版本与 blocking 版本接近，但 GKH 阶段仍略慢。

因此，本阶段的主要结论是：

1. 当前轻量级 nonblocking 实现正确，但未提升最终主线性能；
2. 最终版本中 tasks_sent 已经很少，通信等待不是主要瓶颈；
3. master_compute_ms 和 merge_ms 才是当前主要性能限制；
4. 对本 SVD GKH 任务而言，master_work、changed iteration、local B + rotation logs 和 OpenMP 行级并行比非阻塞结果头接收更有效；
5. nonblocking 版本适合作为 MPI 不同通信方法的进阶探索，而不适合作为最终主版本。

## 可写入报告的结论表述

为了探索不同 MPI 编程方法，本实验在任务池版本基础上实现了一个非阻塞通信分支。该版本使用 MPI_Irecv 预先挂起 worker 返回结果头的接收，并通过 MPI_Test / MPI_Waitany 检查完成情况。实验结果表明，非阻塞版本能够保证正确性，但在当前最终实现中没有带来进一步加速。在 master_work=1 的最终配置下，远程任务数已经很少，dispatch_ms 只占很小比例，主要耗时集中在 master 端局部计算和 rotation logs 回放。因此，非阻塞结果头接收无法显著改善总性能。在 master_work=0 的通信较频繁配置下，nonblocking 与 blocking 性能接近但仍未优于后者。该结果说明，对于本 SVD GKH 任务，优化任务粒度和 master 端计算比单纯替换阻塞通信为非阻塞通信更关键。

## 后续可改进方向

如果后续继续改进 nonblocking 版本，可以考虑：

1. 将 payload 数据也改为 MPI_Irecv；
2. 对任务发送使用 MPI_Isend，减少 master 发送时阻塞；
3. 使用 persistent communication 减少重复创建 request 的开销；
4. 在 worker 端也实现非阻塞接收任务；
5. 更细致地区分等待时间、payload 接收时间、merge 时间和 replay 时间；
6. 与 master_work=0 的高通信频率配置结合，进一步观察通信隐藏效果。

不过，在当前实验报告中，轻量 nonblocking 探索已经足以说明 MPI 非阻塞通信方法的实现与局限。
