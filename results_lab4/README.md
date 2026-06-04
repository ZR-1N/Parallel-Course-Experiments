# strategy_compare

## 本阶段目标

本目录用于总结本次 MPI 实验中不同 MPI 并行策略的设计、实现、性能表现与优化演化过程。

本阶段不是单独的一组全新性能测试，而是对前面各阶段实验结果进行汇总分析，重点回答以下问题：

1. 从最初的 MPI blocking baseline 到最终版本，分别做了哪些优化；
2. 不同 MPI 策略的任务分配方式、通信方式和计算粒度有什么区别；
3. 为什么初始 MPI 版本性能不一定好；
4. 哪些优化真正改善了性能；
5. 最终版本的瓶颈仍然在哪里；
6. 本 SVD GKH 迭代任务为什么不能简单获得线性加速。

## 总体优化路线

本实验围绕 Golub-Kahan SVD 迭代中的活动 block 进行 MPI 并行化。整体优化路线如下：

| 阶段 | 版本                         | 核心思想                                                   | 主要目的                    |
| -- | -------------------------- | ------------------------------------------------------ | ----------------------- |
| 0  | serial_simd                | 串行 GKH + SIMD/内存访问优化                                   | 提供正确性和性能基线              |
| 1  | mpi_blocking_baseline      | 阻塞式主从通信，一次任务执行一步 block iteration                       | 验证 MPI 正确性              |
| 2  | mpi_pool_step_queue        | 引入任务池，master 动态分发任务                                    | 改善静态分配不均                |
| 3  | mpi_pool_changed_iteration | worker 在局部 block 内连续迭代，直到 split、converge 或达到 sweep_cap | 增大任务粒度，减少频繁返回           |
| 4  | sweep_cap tuning           | 调整局部连续迭代步数                                             | 平衡通信次数与负载均衡             |
| 5  | local B + rotation logs    | 只传局部 B 和 Givens rotation logs，不再直接传 U/V 子块             | 降低通信数据量                 |
| 6  | master_work                | master 在任务池较浅时参与计算                                     | 减少远程发送次数，降低调度开销         |
| 7  | memory optimization        | 优化列旋转、局部 block 拷贝与合并的连续内存访问                            | 降低 merge/replay 和局部计算开销 |
| 8  | node_layout                | 比较不同 PBS 节点布局                                          | 分析节点资源竞争与跨节点通信影响        |
| 9  | MPI + OpenMP               | 对 rotation replay 中单条旋转的行循环并行化                         | 缓解 master 端瓶颈           |

## 当前最终候选版本

当前最终 MPI 版本具有以下特征：

| 项目            | 取值或说明                                                                     |
| ------------- | ------------------------------------------------------------------------- |
| MPI 实现        | mpi_pool                                                                  |
| 调度方式          | 主从式任务池                                                                    |
| 通信方式          | local B + rotation logs                                                   |
| 局部迭代策略        | changed iteration                                                         |
| sweep_cap     | 8                                                                         |
| master_work   | 1                                                                         |
| OpenMP 支持     | gkh_replay_rotations_hybrid 中对单条 rotation 的行循环并行                          |
| 内存访问优化        | apply_right_cols、apply_right_cols_range、gkh_extract_block、gkh_merge_block |
| 主要瓶颈          | master 端局部计算、local B 合并、rotation logs 回放                                  |
| 当前观测最优布局      | np=4, 4 nodes × 1 ppn                                                     |
| 当前观测最优单节点混合版本 | np=4, OMP_THREADS=2, nodes=1:ppn=8                                        |

## 结果来源说明

本 README 汇总的数据来自以下目录：

| 目录                            | 内容                       |
| ----------------------------- | ------------------------ |
| results_lab4/03_mpi_blocking  | 阻塞通信 baseline            |
| results_lab4/04_mpi_task_pool | 初始任务池与 changed iteration |
| results_lab4/05_sweep_cap     | sweep_cap 调优             |
| results_lab4/06_np_scaling    | 最终版本不同进程数扩展性             |
| results_lab4/07_node_layout   | 不同 PBS 节点布局              |
| results_lab4/10_mpi_openmp    | MPI + OpenMP 混合并行        |
| results_lab4/12_final         | 最终主结果                    |
| results_lab4/13_size_scaling  | 不同问题规模                   |

需要注意，不同阶段的结果不一定来自完全相同的代码版本和测试配置。因此，本目录中的策略对比主要用于说明优化演化趋势，不应把所有阶段的绝对时间直接视为严格公平的横向性能排名。严格公平的最终性能对比应以 12_final、06_np_scaling、07_node_layout、10_mpi_openmp 和 13_size_scaling 中最终代码版本的数据为准。

## 各阶段设计与分析

### 0. serial_simd 基线

serial_simd 是本实验的基本参考版本。该版本不使用 MPI，主要包含：

| 内容        | 说明                                  |
| --------- | ----------------------------------- |
| GKH 迭代    | 串行执行 block iteration                |
| SIMD/内存优化 | apply_left_rows 等函数中存在手动展开和连续内存访问优化 |
| 作用        | 提供正确性基准和性能基线                        |

在 n=1000 的最终基线中，serial_simd 的代表性结果为：

| impl        |    n | np | bidiag_ms |  gkh_ms | total_ms | passed |
| ----------- | ---: | -: | --------: | ------: | -------: | ------ |
| serial_simd | 1000 |  1 |   4382.27 | 21197.7 | 25579.97 | 1/1    |

serial_simd 的 GKH 阶段耗时作为后续 MPI 版本计算 speedup 的主要参考。

### 1. mpi_blocking_baseline

mpi_blocking_baseline 是第一个真正使用 MPI 的版本。它采用阻塞双边通信：

| 设计项  | 内容                       |
| ---- | ------------------------ |
| 通信方式 | MPI_Send / MPI_Recv      |
| 调度方式 | master 分发任务，worker 计算后返回 |
| 任务粒度 | 每次任务执行一次 block step      |
| 数据传输 | 早期版本传输 U/B/V 子块          |
| 作用   | 验证 MPI 主从通信和正确性          |

代表性小规模结果：

| 版本                    |  n | np |  gkh_ms | dispatch_ms | worker_compute_ms | merge_ms | tasks_sent | tasks_done | passed |
| --------------------- | -: | -: | ------: | ----------: | ----------------: | -------: | ---------: | ---------: | ------ |
| mpi_blocking_baseline | 64 |  2 | 47.2634 |     2.86031 |           1.66798 | 0.780106 |        102 |        102 | 1/1    |

该版本能够正确运行，但存在明显问题：

1. 每次只做一步 block iteration，任务粒度过细；
2. master 与 worker 频繁交互；
3. 如果传输 U/B/V 子块，通信数据量较大；
4. worker 的实际计算时间很少，通信和调度占比偏高。

因此，mpi_blocking_baseline 更适合作为正确性验证版本，而不是最终性能版本。

### 2. mpi_pool_step_queue

为改善固定分配和任务粒度问题，引入任务池版本。master 维护一个活动 block 队列，worker 完成任务后可以继续领取新任务。

| 设计项       | 内容                 |
| --------- | ------------------ |
| 调度方式      | master 维护 queue    |
| worker 行为 | 完成任务后返回结果并继续领取任务   |
| 优点        | 动态调度，适合 block 大小不均 |
| 缺点        | 如果每次只做一步，仍然频繁返回    |

代表性结果：

| 版本                  |  n | np |  gkh_ms | dispatch_ms | worker_compute_ms | merge_ms | tasks_sent | queue_rounds | max_queue_size | passed |
| ------------------- | -: | -: | ------: | ----------: | ----------------: | -------: | ---------: | -----------: | -------------: | ------ |
| mpi_pool_step_queue | 64 |  2 | 50.6351 |     3.36385 |           1.61839 |  1.16682 |        102 |          102 |              1 | 1/1    |

该版本相比 blocking baseline 结构更灵活，但对于 n=64 这样的小规模问题，任务池深度很浅，通信和调度开销仍然比较突出。因此还需要增大单次任务的计算粒度。

### 3. mpi_pool_changed_iteration

changed iteration 的思想是让 worker 或 master 在局部 block 内连续执行多步 GKH 迭代，直到满足以下条件之一：

1. 局部 block 收敛；
2. 局部 block 再次分裂；
3. 达到 sweep_cap 限制。

这样可以将“每一步返回一次”变成“连续多步后再返回一次”，从而减少 master-worker 交互次数。

| 设计项  | 内容                   |
| ---- | -------------------- |
| 局部循环 | worker 在 block 内连续迭代 |
| 控制参数 | sweep_cap            |
| 返回条件 | 收敛、分裂或达到 cap         |
| 目的   | 增大任务粒度，减少调度次数        |

代表性结果：

| 版本                         |  n | np | sweep_cap |  gkh_ms | tasks_sent | queue_rounds | max_queue_size | passed |
| -------------------------- | -: | -: | --------: | ------: | ---------: | -----------: | -------------: | ------ |
| mpi_pool_changed_iteration | 64 |  2 |         4 | 10.0579 |         64 |           64 |              1 | 1/1    |
| mpi_pool_changed_iteration | 64 |  2 |         8 | 10.0358 |         63 |           63 |              1 | 1/1    |

相比 step_queue 的约 50 ms，changed iteration 在 n=64 小规模下已明显减少耗时。其核心原因不是增加了更多并行度，而是减少了频繁返回和调度的开销。

### 4. sweep_cap 调优

sweep_cap 是 changed iteration 的关键参数。它控制每个局部任务最多连续执行多少次 GKH step。

| sweep_cap 较小  | sweep_cap 较大 |
| ------------- | ------------ |
| 返回更频繁，通信和调度更多 | 单个任务更粗，通信减少  |
| 负载均衡较好        | 可能导致单个任务过长   |
| 适合任务变化快的场景    | 适合通信开销明显的场景  |

代表性 n=64 结果：

| sweep_cap |  gkh_ms | tasks_sent | queue_rounds | passed |
| --------: | ------: | ---------: | -----------: | ------ |
|         1 | 56.6521 |        165 |          165 | 1/1    |
|         2 | 38.2872 |         98 |           98 | 1/1    |
|         4 | 10.0579 |         64 |           64 | 1/1    |
|         8 | 10.0358 |         63 |           63 | 1/1    |

代表性 n=1000, np=2 结果：

| sweep_cap |  gkh_ms | tasks_sent | max_queue_size | passed |
| --------: | ------: | ---------: | -------------: | ------ |
|         8 | 20849.1 |        994 |              3 | 1/1    |
|        16 | 21290.5 |        994 |              3 | 1/1    |
|        32 | 21923.6 |        994 |              3 | 1/1    |

综合小规模和大规模实验，sweep_cap=8 是一个相对稳妥的折中选择。它能有效减少任务返回次数，同时不会明显增加负载不均。

### 5. local B + rotation logs

早期 MPI 版本直接传输 U/B/V 子块，通信量较大。后续版本改为只传局部 B 和 rotation logs。

核心思想：

| 原始做法                            | 优化做法                              |
| ------------------------------- | --------------------------------- |
| worker 接收 U_sub、B_sub、V_sub     | worker 只接收 local B                |
| worker 返回更新后的 U_sub、B_sub、V_sub | worker 返回 local B 和 rotation logs |
| 通信数据量较大                         | 通信数据量下降                           |
| worker 直接更新 U/V 子块              | master 根据 logs 回放 U/V 更新          |

对于一个大小为 bs 的 block，早期版本每次任务需要传输的数据大致包括：

| 数据          | 规模        |
| ----------- | --------- |
| U(:, l:r)   | O(m · bs) |
| B(l:r, l:r) | O(bs²)    |
| V(:, l:r)   | O(n · bs) |

在 m≈n 时，U/V 子块传输开销约为 O(n · bs)。

优化后主要传输：

| 数据                 | 规模                     |
| ------------------ | ---------------------- |
| local B            | O(bs²)                 |
| rotation logs      | O(number_of_rotations) |
| split child blocks | O(number_of_children)  |

这样显著减少了 U/V 子块的远程传输，但代价是 master 端需要回放 rotation logs。因此，该版本将瓶颈从通信转移到 master 端 replay/merge。

### 6. master_work

由于本问题的任务池深度很浅，max_queue_size 通常只有 1 到 3。如果 master 只负责调度，worker 数量较多时也难以充分利用；如果每个小任务都远程发送，则通信与调度开销反而较大。

master_work 的策略是：

| 情况            | 处理方式                |
| ------------- | ------------------- |
| 任务池较浅         | master 保留任务并本地处理    |
| 队列中仍有可分发任务    | 分发给 worker          |
| master 本地处理完成 | 合并 B，回放 logs，更新任务队列 |

最终 n=1000 单节点 np=4 对比结果：

| 配置            |  gkh_ms | dispatch_ms | master_compute_ms | merge_ms | tasks_sent | tasks_done | passed |
| ------------- | ------: | ----------: | ----------------: | -------: | ---------: | ---------: | ------ |
| master_work=0 | 19281.5 |     2010.30 |                 0 |  7536.55 |        994 |        994 | 1/1    |
| master_work=1 | 15863.9 |       0.998 |           7146.44 |  8026.02 |         14 |        994 | 1/1    |

master_work 使 tasks_sent 从 994 降至 14，显著降低 dispatch_ms。虽然 master_compute_ms 增加，但减少远程调度后整体耗时明显下降。

这说明对于本 SVD GKH 任务，任务池深度不足时，master 参与计算比频繁远程分发更有效。

### 7. memory optimization

local B + logs 降低通信后，master 端 replay/merge 成为新瓶颈。因此进一步优化了以下函数：

| 函数                     | 优化内容                       |
| ---------------------- | -------------------------- |
| apply_right_cols       | 使用基指针和行偏移，减少 at() 调用       |
| apply_right_cols_range | 使用连续内存访问                   |
| gkh_extract_block      | 按行连续复制局部 B                 |
| gkh_merge_block        | 按行连续写回局部 B                 |
| Matrix::at const       | 改为返回 const double&，支持安全取地址 |

该优化属于体系结构相关优化，主要改善内存访问局部性和减少循环中的索引开销。

优化后，n=1000、np=4、master_work=1 的单节点结果达到约 15 秒级 GKH 时间，并且后续 MPI+OpenMP 版本可以进一步利用这些连续内存访问结构。

### 8. node_layout

节点布局实验固定 n=1000、np=4、sweep_cap=8、master_work=1，只改变 PBS 节点布局。

| 节点布局            |  gkh_ms | total_ms | master_compute_ms | merge_ms | tasks_sent | max_queue_size | passed |
| --------------- | ------: | -------: | ----------------: | -------: | ---------: | -------------: | ------ |
| 1 node × 4 ppn  | 15863.9 | 19186.21 |           7146.44 |  8026.02 |         14 |              2 | 1/1    |
| 2 nodes × 2 ppn | 13035.0 | 16054.70 |           5857.84 |  6583.50 |         14 |              2 | 1/1    |
| 4 nodes × 1 ppn | 11314.7 | 14662.85 |           3559.94 |  7156.59 |         14 |              2 | 1/1    |

本实验中，多节点布局反而更快。原因可能包括：

1. 当前最终版本 tasks_sent 很少，跨节点通信次数少；
2. 单节点多进程可能存在 CPU、cache、内存带宽资源竞争；
3. 多节点少进程可能缓解资源争用；
4. qsub 环境存在一定波动，因此结论应谨慎表述。

当前观测最优的纯 MPI 多节点配置为：

| 参数          | 取值              |
| ----------- | --------------- |
| impl        | mpi_pool        |
| n           | 1000            |
| np          | 4               |
| 节点布局        | 4 nodes × 1 ppn |
| sweep_cap   | 8               |
| master_work | 1               |
| gkh_ms      | 11314.7         |
| total_ms    | 14662.85        |

### 9. MPI + OpenMP

MPI+OpenMP 版本在最终 MPI 基础上，对 rotation logs 回放中的单条 Givens rotation 行循环进行 OpenMP 并行。

需要注意，rotation logs 之间存在顺序依赖，因此不能并行处理整个 logs 序列。但对于单条 rotation，对矩阵不同行的两列更新互不依赖，因此可以使用 OpenMP 并行。

单节点 nodes=1:ppn=8 实验结果：

| 配置                     | NP | OMP_THREADS |  gkh_ms | total_ms | master_compute_ms | merge_ms | tasks_sent | passed |
| ---------------------- | -: | ----------: | ------: | -------: | ----------------: | -------: | ---------: | ------ |
| MPI-only baseline      |  4 |           1 | 15656.3 | 19667.74 |           7957.23 |  6857.70 |         14 | 1/1    |
| MPI + OpenMP           |  4 |           2 | 11709.0 | 15674.78 |           5638.62 |  5476.05 |         14 | 1/1    |
| Less MPI + More OpenMP |  2 |           4 | 12305.5 | 16750.41 |           5563.75 |  6051.11 |         14 | 1/1    |

结果表明：

1. NP=4, OMP_THREADS=2 相比 NP=4, OMP_THREADS=1，GKH 阶段达到约 1.34x 加速；
2. OpenMP 同时降低了 master_compute_ms 和 merge_ms；
3. tasks_sent 和 max_queue_size 没有变化，说明 OpenMP 改善的是单个任务内部执行，而不是任务池结构；
4. NP=4, OMP_THREADS=2 是当前单节点混合并行中的最优组合。

## 策略演化代表性结果汇总

不同阶段的代表性结果如下。注意：不同阶段不完全来自同一代码版本和同一测试规模，因此该表主要反映优化趋势。

| 阶段                    | 代表配置                  |    n | np |  gkh_ms | 关键指标              | 主要结论                |
| --------------------- | --------------------- | ---: | -: | ------: | ----------------- | ------------------- |
| serial_simd           | np=1                  | 1000 |  1 | 21197.7 | baseline          | 串行/SIMD 基线          |
| mpi_blocking_baseline | blocking, step-only   |   64 |  2 | 47.2634 | tasks_sent=102    | 能正确运行，但通信频繁         |
| mpi_pool_step_queue   | task pool, step-only  |   64 |  2 | 50.6351 | queue_rounds=102  | 动态调度但粒度仍细           |
| changed_iteration     | cap=4/8               |   64 |  2 |  约 10.0 | tasks_sent 降低     | 增大任务粒度后明显改善         |
| sweep_cap tuning      | cap=8                 | 1000 |  2 | 20849.1 | tasks_sent=994    | cap=8 较稳，继续增大收益有限   |
| B+logs + master_work  | np=4, 1 node          | 1000 |  4 | 15863.9 | tasks_sent=14     | 大幅减少远程发送            |
| node_layout           | np=4, 4 nodes × 1 ppn | 1000 |  4 | 11314.7 | master_compute 降低 | 多节点布局在当前实验中最优       |
| MPI+OpenMP            | np=4, omp=2, 1 node   | 1000 |  4 | 11709.0 | merge_ms 降低       | 混合并行有效缓解 master 端瓶颈 |

## 通信复杂性与计算复杂性分析

### 1. 早期直接传 U/B/V 子块的通信开销

对于大小为 bs 的活动 block，若每次任务都传输 U/B/V 子块，则单次任务通信量大致为：

| 数据          | 规模        |
| ----------- | --------- |
| U(:, l:r)   | O(m · bs) |
| B(l:r, l:r) | O(bs²)    |
| V(:, l:r)   | O(n · bs) |

当 m≈n 时，U/V 子块通信约为 O(n · bs)，在大规模矩阵下开销较高。

### 2. local B + rotation logs 的通信开销

优化后，worker 只接收 local B，并返回 local B 与 rotation logs：

| 数据               | 规模                     |
| ---------------- | ---------------------- |
| local B          | O(bs²)                 |
| rotation logs    | O(number_of_rotations) |
| child block info | O(number_of_children)  |

该方法减少了 U/V 子块远程传输，但 master 需要回放 logs，因此 merge/replay 成为新的主要开销。

### 3. changed iteration 对通信次数的影响

如果每个任务只执行一步 GKH step，则通信次数接近迭代步数。changed iteration 让 worker 或 master 连续执行多步后再返回，可以减少任务发送次数和队列轮次。

但 sweep_cap 不宜无限增大：

| sweep_cap 太小 | sweep_cap 太大 |
| ------------ | ------------ |
| 通信次数多        | 单个任务可能过重     |
| 调度开销高        | 负载均衡可能变差     |
| worker 返回频繁  | 任务池响应变慢      |

实验中 sweep_cap=8 是较稳定的折中值。

### 4. master_work 对通信次数的影响

master_work 将大量原本要远程发送的小任务留在 master 本地执行。最终版本中 tasks_sent 从 994 降至 14，dispatch_ms 从约 2010 ms 降至约 1 ms，说明该优化显著减少远程通信次数。

代价是 master_compute_ms 增加，但对于当前任务池深度较浅的问题，这一代价小于频繁远程通信的代价。

### 5. OpenMP 对 master 端瓶颈的影响

MPI+OpenMP 不改变任务池深度，也不减少 tasks_sent。它主要优化：

| 目标                   | 方法                  |
| -------------------- | ------------------- |
| master 本地局部计算        | 单条 rotation 内部行循环并行 |
| rotation logs replay | 对每条 log 的行更新并行      |
| merge/replay 开销      | 利用 OpenMP 线程降低行循环时间 |

实验显示，NP=4, OMP_THREADS=2 相比 MPI-only baseline 将 GKH 耗时从 15656.3 ms 降至 11709.0 ms，说明 master 端行级并行是有效的。

## 当前瓶颈总结

虽然最终版本取得了明显加速，但仍存在以下限制：

| 瓶颈                 | 说明                                         |
| ------------------ | ------------------------------------------ |
| max_queue_size 较小  | 活动 block 并行度不足，通常只有 1 到 3                  |
| worker 利用率有限       | master_work 后 tasks_sent 很少，worker 只处理少量任务 |
| master 端串行部分仍重     | master_compute_ms 和 merge_ms 仍占主要比例        |
| rotation logs 顺序依赖 | 不同 Givens rotation 不能乱序并行                  |
| qsub 环境波动          | 不同节点负载会影响实验时间                              |
| 加速非线性              | np 增加不能保证性能提升                              |

因此，本实验的 MPI 加速不是典型线性扩展，而是通过多种策略减少通信、控制任务粒度、优化内存访问和缓解 master 端瓶颈后获得的综合收益。

## 最终结论

本次 MPI 实验从 blocking baseline 开始，逐步实现并比较了任务池调度、changed iteration、sweep_cap 调优、local B + rotation logs、master_work、节点布局优化和 MPI+OpenMP 混合并行。

主要结论如下：

1. 初始阻塞通信版本能够保证正确性，但任务粒度细、通信频繁，性能较差。
2. 任务池动态调度改善了任务分配方式，但如果每步都返回，仍然存在较高调度开销。
3. changed iteration 增大了局部任务粒度，是早期性能改善的关键。
4. sweep_cap=8 在本实验中是较稳定的折中值。
5. local B + rotation logs 显著降低了 U/V 子块通信量，但将瓶颈转移到 master 端 replay/merge。
6. master_work 对当前任务池较浅的 SVD GKH 任务非常有效，可以大幅减少远程任务发送次数。
7. 节点布局实验中，4 nodes × 1 ppn 在当前观测下表现最好，可能与减少单节点资源竞争有关。
8. MPI+OpenMP 能进一步降低 master_compute_ms 和 merge_ms，是有效的混合并行探索。
9. 由于 max_queue_size 始终较小，该算法无法通过简单增加进程数获得线性加速。
10. 最终版本在 n=1000 的中大规模矩阵上取得了明显优于 serial_simd 的性能，但扩展性仍受 master 端瓶颈限制。


本实验围绕 SVD 分解中的 Golub-Kahan 迭代进行了多种 MPI 并行策略探索。初始阻塞通信版本采用 master-worker 模型，可以保证正确性，但由于每次任务只执行一步 block iteration，通信与调度开销较高。随后引入任务池和 changed iteration，使 worker 或 master 能在局部 block 内连续迭代，减少频繁返回。进一步地，将通信数据从 U/B/V 子块优化为 local B + rotation logs，显著降低远程传输量。考虑到 GKH 迭代过程中活动 block 数量有限，实验又加入 master_work 策略，使 master 在任务池较浅时直接参与计算，避免大量小任务远程发送。最终，在内存访问优化、节点布局调整和 MPI+OpenMP 混合并行的配合下，MPI 版本在 n=1000 的大规模矩阵上取得了明显加速。

同时，实验也表明该 SVD 任务不是线性扩展型 MPI 问题。由于活动 block 数量有限，max_queue_size 始终较小，增加 MPI 进程数并不能保证性能提升。最终性能主要受 master 端局部计算、local B 合并和 rotation logs 回放影响。因此，本实验的主要收获不仅是得到一个较快的 MPI 版本，也包括对任务粒度、通信量、动态调度、master 端瓶颈和混合并行适用性的系统分析。
