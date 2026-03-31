#include <iostream>
#include <windows.h>

using namespace std;

// 元素个数，取 2 的幂次。数据量不要太大，我们要保证数据全在 L1 Cache 里，只测 CPU 计算速度 [cite: 1055, 1058]
const int N = 65536; 
// 因为计算实在太快了，我们需要循环执行海量次，VTune 才能抓到足够的 CPU 时钟周期 [cite: 1059]
const int ITERATIONS = 100000; 

double a[N];

void init() {
    for (int i = 0; i < N; i++) {
        a[i] = 1.0;
    }
}

// 平凡算法：单路链式累加 [cite: 1065-1067]
double trivial_sum() {
    double sum = 0.0;
    for (int i = 0; i < N; i++) {
        sum += a[i]; // 存在严重的数据依赖，只能串行流水
    }
    return sum;
}

// 优化算法：2路展开累加 (利用超标量架构的指令级并行) 
double superscalar_sum() {
    double sum1 = 0.0;
    double sum2 = 0.0;
    // 每次循环步进 2，减少了循环条件判断的开销 (Loop Overhead) [cite: 1056]
    for (int i = 0; i < N; i += 2) {
        sum1 += a[i];
        sum2 += a[i+1];
    }
    return sum1 + sum2;
}

int main() {
    init();

    long long head, tail, freq;
    QueryPerformanceFrequency((LARGE_INTEGER*)&freq);

    double final_sum1 = 0, final_sum2 = 0;

    cout << "开始测试【平凡算法】(单路链式)..." << endl;
    QueryPerformanceCounter((LARGE_INTEGER*)&head);
    for(int k = 0; k < ITERATIONS; k++) { 
        final_sum1 += trivial_sum();
    }
    QueryPerformanceCounter((LARGE_INTEGER*)&tail);
    cout << "平凡算法耗时: " << (tail - head) * 1000.0 / freq << " ms" << endl;


    cout << "\n开始测试【优化算法】(2路超标量)..." << endl;
    QueryPerformanceCounter((LARGE_INTEGER*)&head);
    for(int k = 0; k < ITERATIONS; k++) {
        final_sum2 += superscalar_sum();
    }
    QueryPerformanceCounter((LARGE_INTEGER*)&tail);
    cout << "优化算法耗时: " << (tail - head) * 1000.0 / freq << " ms" << endl;

    cout << "\n[防优化校验] sum1: " << final_sum1 << " sum2: " << final_sum2 << endl;

    return 0;
}