# 01_gkh_neon_attempt

版本说明：
- 尝试使用 ARM NEON 优化 gkh.cpp 中的 Givens 行/列旋转
- apply_left_rows 使用 2-lane double NEON
- apply_right_cols 对相邻两列使用 2-lane double NEON
- 编译选项：-O2
- 随机种子：20260409

实验结果：
- 通过样例数：5 / 5
- 总上二对角化耗时(ms)：7225.14
- 总 GKH 迭代耗时(ms)：35229.1

分析：
- 相比 baseline 的 GKH 30658.7 ms，本版本未取得加速，反而变慢。
- 可能原因包括 NEON 双精度向量宽度仅为 2、列旋转粒度过小、向量 lane 操作开销较高，以及 -O2 下编译器对标量循环已有较好优化。
