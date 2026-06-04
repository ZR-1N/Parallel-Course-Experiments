# 07_asm

## 实验目的

本实验用于从汇编层面观察 baseline 与 final 版本在 AArch64 平台上的代码生成差异，重点关注浮点与 SIMD/NEON 相关指令。

## 生成方式

final 版本汇编生成命令：

g++ -O2 -march=native -S bidiagonalization.cpp -o results/07_asm/bidiagonalization_final_O2.s  
g++ -O2 -march=native -S gkh.cpp -o results/07_asm/gkh_final_O2.s  

baseline 版本通过恢复原始 gkh.cpp 与 bidiagonalization.cpp 后生成对应汇编文件：

g++ -O2 -march=native -S bidiagonalization.cpp -o results/07_asm/bidiagonalization_baseline_O2.s  
g++ -O2 -march=native -S gkh.cpp -o results/07_asm/gkh_baseline_O2.s  

## 关注指令

- ldr q... / str q...：128-bit 向量寄存器加载和存储
- fmla v?.2d：双精度 2-lane 向量 fused multiply-add
- fmul / fadd：浮点乘法与加法
- d0、d1 等：64-bit 标量浮点寄存器视图
- v0.2d、v1.2d 等：NEON 双精度向量寄存器视图

## 指令统计

| 文件 | 匹配到的浮点/向量相关指令行数 |
|---|---:|
| bidiagonalization_baseline_vector_instr.txt | 8 |
| bidiagonalization_final_vector_instr.txt | 15 |
| gkh_baseline_vector_instr.txt | 15 |
| gkh_final_vector_instr.txt | 23 |

需要注意，指令行数并不是性能优劣的直接指标，它只用于辅助观察代码生成差异。最终性能仍以程序运行时间和消融实验为准。

## bidiagonalization.cpp 汇编观察

baseline 版本中主要观察到如下标量双精度浮点指令：

fadd d0, d8, d0  
fmul d1, d8, d1  

其中 d0、d1、d8 是 64-bit 标量 double 浮点寄存器视图。

final 版本中出现了更明显的 NEON 双精度向量指令，例如：

ldr q1, [x4], 16  
ldr q2, [x5], 16  
fmla v0.2d, v2.2d, v1.2d  

以及：

ldr q2, [x3], 16  
ldr q1, [x2]  
fmla v1.2d, v3.2d, v2.2d  
str q1, [x2], 16  

其中 q 寄存器表示 128-bit 向量寄存器，v?.2d 表示一个 NEON 向量中包含两个 double 元素。fmla v?.2d 指令说明编译器为 final 版本中的连续点积和 scaled-add 辅助函数生成了双精度向量 fused multiply-add 指令。

因此，汇编结果支持了本实验对 Householder 变换进行 SIMD 优化的实现：final 版本中的 bidiagonalization.cpp 确实进入了 AArch64/NEON 双精度向量执行路径。

## gkh.cpp 汇编观察

gkh.cpp 的 final 版本匹配到的浮点相关指令数量多于 baseline，但主要仍是 fmul d... 和 fadd d... 这类标量双精度浮点指令。

这与代码实现一致：GKH 阶段最终采用的是 apply_left_rows 的行指针访问与 4 路循环展开，而不是显式 NEON intrinsic。其优化收益主要来自减少 Matrix::at() 的重复下标计算、利用行主序连续访问以及增加编译器指令调度空间。

## 分析结论

汇编级分析表明，final 版本中的 Householder 优化确实生成了 AArch64/NEON 双精度向量指令，这是上二对角化阶段加速的重要底层依据。

同时，GKH 阶段的最终优化并非显式 NEON 向量化，而是偏向访存与循环结构优化。这也解释了实验中 GKH 显式 NEON 尝试未稳定取得收益，而 apply_left_rows 指针访问与循环展开更适合作为最终方案。

汇编分析主要用于说明代码生成特征，最终性能结论仍应以程序自身输出的 bidiagonalization / GKH 阶段耗时、消融实验和编译优化等级对比为主要依据。
