# 01_gkh_neon_attempt

## 版本说明

- 尝试使用 ARM NEON 优化 gkh.cpp 中的 Givens 行/列旋转。
- apply_left_rows 使用 2-lane double NEON。
- apply_right_cols 对相邻两列使用 2-lane double NEON。
- bidiagonalization.cpp 保持原始实现。
- 编译选项：-O2
- 随机种子：20260409

## 运行命令

bash test.sh 1 1 1 -O O2 -s 20260409

## 实验结果

- 通过样例数：5 / 5
- 总上二对角化耗时：7225.14 ms
- 总 GKH 迭代耗时：35229.1 ms

## 与 baseline 对比

当前 baseline 结果为：

- 总上二对角化耗时：10342.5 ms
- 总 GKH 迭代耗时：41470.2 ms

本版本相对 baseline：

- 上二对角化阶段耗时有所下降，但本版本并未修改 bidiagonalization.cpp，因此该变化主要反映服务器运行波动。
- GKH 阶段耗时由 41470.2 ms 降至 35229.1 ms，但该收益不如后续 02_gkh_left_unroll 稳定。

## 分析

该版本保持了正确性，说明 NEON 改写后的 Givens 行/列旋转没有破坏 SVD 分解结果。

不过，显式 NEON 对 GKH 旋转的收益并不稳定。可能原因包括：

- ARM NEON 对 double 的向量宽度仅为 2，单条向量指令只能处理两个双精度元素。
- apply_right_cols 每次仅处理相邻两列，单次计算粒度较小，load/store 与 lane 操作开销可能抵消 SIMD 收益。
- -O2 下编译器对简单标量循环已有较好的优化能力。
- 服务器为共享环境，运行耗时存在较明显波动。

因此，本版本作为显式 NEON 尝试记录保留，但不作为最终采用的 GKH 优化方案。
