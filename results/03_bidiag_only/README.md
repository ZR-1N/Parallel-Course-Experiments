# 03_bidiag_only

## 版本说明

- gkh.cpp 恢复为原始版本。
- 仅保留 bidiagonalization.cpp 中 Householder 变换的 SIMD/连续访问优化。
- 用于评估上二对角化阶段优化的单独贡献。
- 编译选项：-O2
- 随机种子：20260409

## 运行命令

bash test.sh 1 1 1 -O O2 -s 20260409

## 实验结果

- 通过样例数：5 / 5
- 总上二对角化耗时：3716.3 ms
- 总 GKH 迭代耗时：42036.2 ms
- 1000x1000 重构误差：1.86375e-10
- 1000x1000 relative recon error：3.22033e-13

## 与 baseline 对比

当前 baseline 结果为：

- 总上二对角化耗时：10342.5 ms
- 总 GKH 迭代耗时：41470.2 ms

本版本相对 baseline：

- 上二对角化阶段耗时由 10342.5 ms 降至 3716.3 ms。
- 上二对角化阶段加速比约为 2.78x。
- GKH 阶段耗时基本不作为本版本的主要评价对象，因为本版本没有优化 gkh.cpp，且 GKH 时间受运行波动与数值收敛路径影响较明显。

## 分析

本版本说明 bidiagonalization.cpp 中 Householder 部分的优化是有效的。

优化收益主要来自：

- 使用 ARM NEON 辅助函数优化连续点积与连续 scaled-add。
- 将左 Householder 中 w = v^T * B_sub 的计算从按列访问改为按行连续访问。
- 减少行主序矩阵下不友好的列式访问，提高 cache locality。
- 对 B、U、V 更新中的连续行片段使用统一的向量化辅助函数。

由于 Householder 阶段改变了部分浮点累加顺序，生成的上二对角矩阵在数值上可能与原始版本存在微小差异。尽管最终正确性通过，但后续 GKH 迭代耗时可能随收敛路径产生一定波动。
