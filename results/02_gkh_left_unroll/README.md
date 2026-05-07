# 02_gkh_left_unroll

版本说明：
- 仅优化 gkh.cpp 中的 apply_left_rows
- 利用 Matrix 行主序连续存储，将 Matrix::at() 访问改为行指针访问
- 对行旋转循环进行 4 路手动展开
- apply_right_cols 保持原始实现
- 编译选项：-O2
- 随机种子：20260409

运行命令：
bash test.sh 1 1 1 -O O2 -s 20260409

实验结果：
- 通过样例数：5 / 5
- 总上二对角化耗时(ms)：7367.29
- 总 GKH 迭代耗时(ms)：29750.6

分析：
- 相比 baseline，本版本 GKH 迭代耗时有所下降。
- 主要原因是 apply_left_rows 中两行数据在行主序存储下连续访问，使用行指针减少了 Matrix::at() 的重复下标计算，4 路循环展开降低了循环控制开销并增加了编译器指令调度空间。
- apply_right_cols 保持原始实现，因为列旋转在行主序矩阵中局部性较差，简单展开或显式 SIMD 未稳定带来收益。
