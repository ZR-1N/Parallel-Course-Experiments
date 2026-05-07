# 04_final

版本说明：
- 在 GKH 阶段保留 apply_left_rows 的行指针访问与 4 路循环展开优化。
- 在 bidiagonalization.cpp 中优化 Householder 变换的两个 TODO。
- 使用 ARM NEON 辅助函数优化连续点积与连续 scaled-add。
- 将左 Householder 中 w = v^T * B_sub 的计算从按列访问改为按行连续访问，提升 cache locality。
- 优化 B/U/V 更新中的连续行访问。
- 编译选项：-O2
- 随机种子：20260409

运行命令：
bash test.sh 1 1 1 -O O2 -s 20260409

代表性实验结果：
- 通过样例数：5 / 5
- 总上二对角化耗时(ms)：3229.01
- 总 GKH 迭代耗时(ms)：29923.4
- 1000x1000 重构误差：1.86375e-10
- 1000x1000 relative recon error：3.22033e-13

分析摘要：
- Householder 上二对角化阶段取得明显加速，主要来自连续内存访问、减少列式访问带来的 cache 不友好，以及 NEON 对连续点积/向量更新的加速。
- GKH 阶段保留行旋转的指针访问与循环展开优化，收益相对较小但正确性稳定。
- 显式 NEON 直接优化 GKH Givens 旋转的尝试未稳定取得收益，因此最终未采用。
