# 03_mpi_blocking

## 当前阶段
Round 1：MPI blocking stub / smoke test

## 本轮目标
- 打通 main.cpp 的 MPI 入口
- 打通 build_mpi.sh / bench_mpi.sh / qsub_mpi.sh
- 验证 serial_simd 与 mpi_blocking 路径都能正常运行
- 验证 qsub 输出进入 test.o / test.e

## 本轮修改后的状态
- serial_simd: 正常
- mpi_blocking: 当前仍为 stub
- 说明：tasks_sent=0, tasks_done=0，表示 MPI 调用链已通，但还未进入真正的任务分发与结果合并

## 结果文件
- check_serial_np1.txt
- check_mpi_stub_np2.txt
- bench_local_stub_np2_n64.txt
- qsub_jobid.txt
- qsub_bench_stub_test.o
- qsub_bench_stub_test.e

## 结论
第 1 轮已完成：
- 编译成功
- 本地 check 成功
- 本地 bench 成功
- qsub 提交流程成功

## 下一轮
实现真实 mpi_blocking baseline：
- root 分发 block
- worker 执行一次 block step
- worker 回传结果
- root 合并结果
