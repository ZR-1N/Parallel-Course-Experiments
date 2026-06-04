# 05_sweep_cap

## 本轮目标
比较 `mpi_pool_changed_iteration` 在不同 `sweep_cap` 下的性能与调度行为，分析任务粒度对 MPI 调度开销的影响。

## 固定实验条件
- impl = `mpi_pool`
- 模式 = `bench`
- n = `64`
- np = `2`
- repeat = `1`
- 平台 = qsub 队列环境
- 其余参数保持一致，仅改变 `sweep_cap`

## 实验结果

| sweep_cap | gkh_ms | dispatch_ms | worker_compute_ms | merge_ms | total_ms | tasks_sent | tasks_done | queue_rounds | max_queue_size | passed |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 56.6521 | 4.8995 | 23.1247 | 1.02067 | 56.5295 | 165 | 165 | 165 | 1 | 1/1 |
| 2 | 38.2872 | 2.99025 | 15.1525 | 0.609159 | 38.1744 | 98 | 98 | 98 | 1 | 1/1 |
| 4 | 10.0579 | 1.95718 | 3.90339 | 0.381231 | 9.9659 | 64 | 64 | 64 | 1 | 1/1 |
| 8 | 10.0358 | 1.87159 | 3.97635 | 0.369072 | 9.94754 | 63 | 63 | 63 | 1 | 1/1 |

## 结果文件
- `qsub_cap1_test.o`
- `qsub_cap1_test.e`
- `qsub_cap2_test.o`
- `qsub_cap2_test.e`
- `qsub_cap4_test.o`
- `qsub_cap4_test.e`
- `qsub_cap8_test.o`
- `qsub_cap8_test.e`

## 现象分析
1. 当 `sweep_cap=1` 时，任务最碎，worker 每做一步就把 block 返回给 root，导致：
   - `tasks_done=165`
   - `queue_rounds=165`
   - 调度与通信次数最多
   - 整体耗时最高

2. 当 `sweep_cap` 从 1 提高到 2 时：
   - `tasks_done` 从 165 降到 98
   - `queue_rounds` 从 165 降到 98
   - `gkh_ms` 从 56.65 ms 降到 38.29 ms
   说明适度增大任务粒度后，调度开销明显下降。

3. 当 `sweep_cap` 提高到 4 时：
   - `tasks_done` 进一步降到 64
   - `queue_rounds` 降到 64
   - `gkh_ms` 大幅降低到约 10.06 ms
   说明 changed iteration 已经显著发挥作用。

4. 当 `sweep_cap` 从 4 增加到 8 时：
   - 性能仅从 10.06 ms 提升到 10.04 ms
   - 提升极小，说明在当前规模下已经进入平台区

## 结论
- 在当前实验条件（`np=2, n=64`）下，`sweep_cap=4` 和 `8` 明显优于 `1` 和 `2`
- `sweep_cap=8` 略优于 `4`，但差距非常小
- 为了在后续更大规模或更多进程下保持更稳妥的任务粒度与负载均衡折中，后续实验默认采用：

**默认 sweep_cap = 4**

## 当前进度
- `mpi_blocking_baseline`：已完成
- `mpi_pool_step_queue`：已完成
- `mpi_pool_changed_iteration`：已完成
- `sweep_cap` 对比实验：已完成

## 下一步
进入 `06_np_scaling`：
- 固定 `impl=mpi_pool`
- 固定 `sweep_cap=4`
- 比较不同进程数（如 2, 4, 8, 16）下的性能变化
