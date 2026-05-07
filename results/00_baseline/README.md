# 00_baseline

版本说明：
- 原始 SVD 串行框架
- 未进行 SIMD/循环展开/指针访问优化
- 编译选项：-O2
- 随机种子：20260409

运行命令：
bash test.sh 1 1 1 -O O2 -s 20260409

关注指标：
- time bidiagonalization(ms)
- time gkh iteration(ms)
- 通过样例数
- 重构误差、正交误差
