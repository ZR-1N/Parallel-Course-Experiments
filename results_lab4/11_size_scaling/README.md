# 11_size_scaling

## 本阶段目标

本目录记录最终 MPI 实现版本在不同问题规模下的性能表现，用于分析矩阵规模变化对 MPI 并行收益的影响。

本阶段重点回答以下问题：

1. 小规模矩阵下 MPI 并行是否值得；
2. 随着矩阵规模增大，MPI 任务池版本是否开始获得收益；
3. 当前最终版本在不同 n 下的加速比变化；
4. MPI 固定开销、master 端合并/回放开销与局部计算量之间的关系。

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

其中，local B + rotation logs 用于减少 U/V 子块传输，master_work 用于在任务池较浅时让 master 直接处理部分局部 block，从而降低远程任务发送和通信开销。

## 固定实验条件

| 参数          | serial_simd | mpi_pool  |
| ----------- | ----------- | --------- |
| mode        | bench       | bench     |
| seed        | 20260408    | 20260408  |
| repeat      | 1           | 1         |
| profile     | 1           | 1         |
| np          | 1           | 4         |
| sweep_cap   | -           | 8         |
| master_work | 0           | 1         |
| 平台          | qsub 队列环境   | qsub 队列环境 |

说明：

* 每个规模下均测试 serial_simd 与最终 mpi_pool 版本。
* serial_simd 作为串行/SIMD 基线。
* mpi_pool 使用最终优化版本：任务池 + changed iteration + local B + rotation logs + master_work + 内存访问优化。
* 本阶段主要关注 GKH 迭代阶段的规模扩展效果，同时也记录端到端总耗时。

## 结果文件

建议本目录保存以下文件：

| 文件                                 | 内容                               |
| ---------------------------------- | -------------------------------- |
| qsub_size_n64_serial_test.o        | n=64, serial_simd 标准输出           |
| qsub_size_n64_serial_test.e        | n=64, serial_simd profiling 输出   |
| qsub_size_n64_mpi_np4_mw1_test.o   | n=64, mpi_pool 标准输出              |
| qsub_size_n64_mpi_np4_mw1_test.e   | n=64, mpi_pool profiling 输出      |
| qsub_size_n256_serial_test.o       | n=256, serial_simd 标准输出          |
| qsub_size_n256_serial_test.e       | n=256, serial_simd profiling 输出  |
| qsub_size_n256_mpi_np4_mw1_test.o  | n=256, mpi_pool 标准输出             |
| qsub_size_n256_mpi_np4_mw1_test.e  | n=256, mpi_pool profiling 输出     |
| qsub_size_n512_serial_test.o       | n=512, serial_simd 标准输出          |
| qsub_size_n512_serial_test.e       | n=512, serial_simd profiling 输出  |
| qsub_size_n512_mpi_np4_mw1_test.o  | n=512, mpi_pool 标准输出             |
| qsub_size_n512_mpi_np4_mw1_test.e  | n=512, mpi_pool profiling 输出     |
| qsub_size_n1000_serial_test.o      | n=1000, serial_simd 标准输出         |
| qsub_size_n1000_serial_test.e      | n=1000, serial_simd profiling 输出 |
| qsub_size_n1000_mpi_np4_mw1_test.o | n=1000, mpi_pool 标准输出            |
| qsub_size_n1000_mpi_np4_mw1_test.e | n=1000, mpi_pool profiling 输出    |

## 正确性结果

所有测试均通过正确性检查：

|    n | serial_simd passed | mpi_pool passed |
| ---: | ------------------ | --------------- |
|   64 | 1/1                | 1/1             |
|  256 | 1/1                | 1/1             |
|  512 | 1/1                | 1/1             |
| 1000 | 1/1                | 1/1             |

各组测试的重构误差、U/V 正交性误差、对角结构误差、奇异值非负性与降序性均满足设定阈值。

## 主结果表

|    n | impl         | np | master_work | bidiag_ms |  gkh_ms | total_ms | GKH speedup vs serial | total speedup vs serial | tasks_sent | tasks_done | max_queue_size |
| ---: | ------------ | -: | ----------: | --------: | ------: | -------: | --------------------: | ----------------------: | ---------: | ---------: | -------------: |
|   64 | serial_simd  |  1 |           0 |  0.769991 | 4.95899 | 5.728981 |                 1.00x |                   1.00x |          - |          - |              - |
|   64 | mpi_pool_log |  4 |           1 |  0.756792 | 5.83220 | 6.588992 |                 0.85x |                   0.87x |          0 |         63 |              1 |
|  256 | serial_simd  |  1 |           0 |   53.1103 | 404.956 | 458.0663 |                 1.00x |                   1.00x |          - |          - |              - |
|  256 | mpi_pool_log |  4 |           1 |   52.1786 | 469.375 | 521.5536 |                 0.86x |                   0.88x |          3 |        254 |              2 |
|  512 | serial_simd  |  1 |           0 |   442.940 | 6706.49 |  7149.43 |                 1.00x |                   1.00x |          - |          - |              - |
|  512 | mpi_pool_log |  4 |           1 |   448.135 | 4366.27 | 4814.405 |                 1.54x |                   1.49x |          3 |        509 |              2 |
| 1000 | serial_simd  |  1 |           0 |   4342.09 | 20912.2 | 25254.29 |                 1.00x |                   1.00x |          - |          - |              - |
| 1000 | mpi_pool_log |  4 |           1 |   3894.22 | 15133.3 | 19027.52 |                 1.38x |                   1.33x |         14 |        994 |              2 |

注：

* total_ms = bidiag_ms + gkh_ms
* GKH speedup vs serial = serial_gkh_ms / mpi_gkh_ms
* total speedup vs serial = serial_total_ms / mpi_total_ms
* speedup 小于 1 表示 MPI 版本慢于 serial_simd

## MPI profiling 明细

|    n | dispatch_ms | worker_compute_ms | master_compute_ms | merge_ms | total_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size |
| ---: | ----------: | ----------------: | ----------------: | -------: | -------: | ---------: | ---------: | -----------: | -------------: |
|   64 |           0 |                 0 |           3.06034 | 0.863314 |  5.73659 |          0 |         63 |           63 |              1 |
|  256 |    0.021458 |          0.033855 |           222.858 |  232.812 |  469.240 |          3 |        254 |          254 |              2 |
|  512 |    0.022173 |          0.030041 |           1140.34 |  3099.36 |  4366.13 |          3 |        509 |          509 |              2 |
| 1000 |    0.946760 |          4.626990 |           6754.94 |  7644.74 |  15133.2 |         14 |        994 |          994 |              2 |

## 结果分析

### 1. 小规模 n=64 下 MPI 版本慢于 serial

n=64 时：

| impl         |  gkh_ms | total_ms |
| ------------ | ------: | -------: |
| serial_simd  | 4.95899 | 5.728981 |
| mpi_pool_log | 5.83220 | 6.588992 |

MPI 版本 GKH speedup 为 0.85x，总体 speedup 为 0.87x，说明 MPI 版本在该规模下不划算。

原因是：

* 矩阵规模太小；
* GKH 阶段本身只有约 5 ms；
* MPI 任务池、profile、调度和 master_work 的固定开销占比高；
* max_queue_size=1，任务池几乎没有可并行性；
* tasks_sent=0，说明任务基本由 master 本地完成，worker 没有实际参与。

因此，n=64 更适合做正确性和机制验证，不适合作为性能加速的主结论。

### 2. n=256 下 MPI 版本仍然慢于 serial

n=256 时：

| impl         |  gkh_ms | total_ms |
| ------------ | ------: | -------: |
| serial_simd  | 404.956 | 458.0663 |
| mpi_pool_log | 469.375 | 521.5536 |

MPI 版本 GKH speedup 为 0.86x，总体 speedup 为 0.88x，仍慢于 serial_simd。

profiling 显示：

| 指标                |      数值 |
| ----------------- | ------: |
| master_compute_ms | 222.858 |
| merge_ms          | 232.812 |
| tasks_sent        |       3 |
| tasks_done        |     254 |
| max_queue_size    |       2 |

虽然 max_queue_size 已经从 1 增加到 2，但可并行任务仍然很少，大部分任务还是由 master 本地完成。同时 merge/replay 开销已经接近 master 计算开销。因此，在 n=256 下，MPI 固定开销和 master 端合并开销仍然抵消了并行收益。

### 3. n=512 开始体现 MPI 优化收益

n=512 时：

| impl         |  gkh_ms | total_ms |
| ------------ | ------: | -------: |
| serial_simd  | 6706.49 |  7149.43 |
| mpi_pool_log | 4366.27 | 4814.405 |

MPI 版本 GKH speedup 达到 1.54x，总体 speedup 达到 1.49x，是本组实验中相对提升最大的规模。

profiling 显示：

| 指标                |      数值 |
| ----------------- | ------: |
| master_compute_ms | 1140.34 |
| merge_ms          | 3099.36 |
| tasks_sent        |       3 |
| tasks_done        |     509 |
| max_queue_size    |       2 |

虽然远程任务发送仍然很少，但随着问题规模增大，单个局部 block 的计算量和串行版本的 GKH 迭代成本显著增加。此时 local B + rotation logs、master_work 和内存访问优化开始体现效果。

因此，n=512 可以视为当前 MPI 版本从“固定开销主导”转向“计算量足够大、优化开始收益”的转折点。

### 4. n=1000 下 MPI 版本继续优于 serial，但加速比低于 n=512

n=1000 时：

| impl         |  gkh_ms | total_ms |
| ------------ | ------: | -------: |
| serial_simd  | 20912.2 | 25254.29 |
| mpi_pool_log | 15133.3 | 19027.52 |

MPI 版本 GKH speedup 为 1.38x，总体 speedup 为 1.33x，仍然明显优于 serial_simd。

但相比 n=512，n=1000 的相对加速比略低。profiling 显示：

| 指标                |      数值 |
| ----------------- | ------: |
| master_compute_ms | 6754.94 |
| merge_ms          | 7644.74 |
| tasks_sent        |      14 |
| tasks_done        |     994 |
| max_queue_size    |       2 |

可以看出，n=1000 下虽然计算量更大，但 master 端的局部计算与 merge/replay 成本也同步增加。尤其是 rotation logs 回放和局部 B 合并仍然是主要瓶颈，限制了进一步加速。

### 5. 任务池深度始终较浅

不同规模下 max_queue_size 为：

|    n | max_queue_size |
| ---: | -------------: |
|   64 |              1 |
|  256 |              2 |
|  512 |              2 |
| 1000 |              2 |

这说明本 SVD GKH 迭代过程中的活动块并行度有限。即使问题规模增大，同时存在的非平凡 block 数量也没有显著增加。因此，当前 MPI 版本不能依赖大量 worker 获得线性加速。

这一点与 np_scaling 实验结论一致：单纯增加 MPI 进程数并不能保证更好性能，任务池深度和 master 端合并/回放开销才是主要限制因素。

## 阶段结论

本阶段实验表明，最终 MPI 版本在不同规模下呈现明显的规模依赖性：

1. n=64 和 n=256 下，MPI 版本慢于 serial_simd，主要原因是问题规模较小，MPI 固定开销和 master 端 merge/replay 开销占比过高。
2. n=512 时，MPI 版本开始显著优于 serial_simd，GKH 阶段达到约 1.54x 加速，总体达到约 1.49x 加速。
3. n=1000 时，MPI 版本仍然优于 serial_simd，GKH 阶段达到约 1.38x 加速，总体达到约 1.33x 加速。
4. 随着规模增大，MPI 优化开始体现收益，但加速比并不单调增加，原因是 master_compute_ms 和 merge_ms 也随规模显著增加。
5. max_queue_size 始终不超过 2，说明该 SVD 任务的 MPI 并行度主要受算法分块结构限制，而不是单纯受矩阵规模控制。

因此，当前 MPI 版本适合中大规模矩阵，但不适合小规模矩阵。报告中应强调：该算法的 MPI 加速不是简单的规模越大、进程越多越好，而是受到活动块数量、通信粒度、master_work 策略和日志回放开销共同影响。

## 可写入报告的结论表述

在不同问题规模实验中，最终 MPI 版本表现出明显的规模阈值特征。对于 n=64 和 n=256 的小规模矩阵，MPI 固定开销和 master 端合并/日志回放开销较高，导致 mpi_pool 版本慢于 serial_simd。随着规模增大到 n=512，局部 block 计算量增加，local B + rotation logs、master_work 和内存访问优化开始发挥作用，GKH 阶段达到约 1.54 倍加速。进一步增大到 n=1000 后，MPI 版本仍保持优势，但由于 master 端 merge/replay 成本同步增加，加速比没有继续提升。该现象说明，本 SVD 分解任务的 MPI 并行收益不仅取决于矩阵规模，还受到活动块数量和 master 端串行开销的显著限制。

## 后续计划

后续实验将继续补充：

1. 不同节点布局测试
   固定 n=1000、np=4、sweep_cap=8、master_work=1，对比 1 node × 4 ppn、2 nodes × 2 ppn、4 nodes × 1 ppn。

2. MPI + OpenMP 混合并行探索
   尝试在 rotation replay 或局部矩阵更新中引入 OpenMP。

3. MPI 不同通信方法探索
   比较阻塞通信与非阻塞通信版本的调度开销。

4. 与 SIMD、Pthread、OpenMP 实验结果统一比较
   分析共享内存并行与分布式 MPI 并行在该 SVD 算法中的适用场景。
