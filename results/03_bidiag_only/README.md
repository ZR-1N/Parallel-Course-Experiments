# 03_bidiag_only

版本说明：
- gkh.cpp 恢复为原始版本
- 仅保留 bidiagonalization.cpp 中 Householder 变换的 SIMD/连续访问优化
- 用于评估上二对角化阶段优化的单独贡献
- 编译选项：-O2
- 随机种子：20260409

运行命令：
bash test.sh 1 1 1 -O O2 -s 20260409

实验结果：
- 通过样例数：5 / 5
- 总上二对角化耗时(ms)：3716.3
- 总 GKH 迭代耗时(ms)：42036.2
- 1000x1000 重构误差：1.86375e-10
- 1000x1000 relative recon error：3.22033e-13

分析：
- 相比 baseline，上二对角化阶段耗时明显下降，说明 Householder 部分的连续访问与 NEON 辅助函数优化有效。
- GKH 阶段耗时本次较高，可能受共享服务器运行波动影响；此外，Householder 阶段改变了浮点累加顺序，可能使后续 GKH 收敛过程产生轻微波动。
- 本版本主要用于消融实验，证明 bidiagonalization.cpp 的优化本身有效。
