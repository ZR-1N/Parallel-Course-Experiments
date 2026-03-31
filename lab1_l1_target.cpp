#include <iostream>
#include <windows.h>

using namespace std;

// 【L1 打靶配置】
const int N = 256;          
const int ITERATIONS = 10000; 

double b[N][N];
double a[N];
double sum_res[N];

void init() {
    for (int i = 0; i < N; i++) {
        a[i] = 1.0;
        for (int j = 0; j < N; j++) {
            b[i][j] = i + j; 
        }
    }
}

void trivial_algorithm() {
    for (int i = 0; i < N; i++) {
        sum_res[i] = 0.0;
        for (int j = 0; j < N; j++) {
            sum_res[i] += b[j][i] * a[j];
        }
    }
}

void optimized_algorithm() {
    for (int i = 0; i < N; i++) {
        sum_res[i] = 0.0;
    }
    for (int j = 0; j < N; j++) {
        for (int i = 0; i < N; i++) {
            sum_res[i] += b[j][i] * a[j];
        }
    }
}

int main() {
    cout << "正在初始化矩阵 (N=256, 针对 L1 Cache 测试)..." << endl;
    init();

    long long head, tail, freq;
    QueryPerformanceFrequency((LARGE_INTEGER*)&freq); 

    cout << "\n开始测试【平凡算法】(按列跨行), 共 " << ITERATIONS << " 轮..." << endl;
    QueryPerformanceCounter((LARGE_INTEGER*)&head);
    for(int k = 0; k < ITERATIONS; k++) { 
        trivial_algorithm();
    }
    QueryPerformanceCounter((LARGE_INTEGER*)&tail);
    cout << "平凡算法耗时: " << (tail - head) * 1000.0 / freq << " ms" << endl;

    cout << "\n开始测试【Cache优化算法】(按行顺序), 共 " << ITERATIONS << " 轮..." << endl;
    QueryPerformanceCounter((LARGE_INTEGER*)&head);
    for(int k = 0; k < ITERATIONS; k++) {
        optimized_algorithm();
    }
    QueryPerformanceCounter((LARGE_INTEGER*)&tail);
    cout << "优化算法耗时: " << (tail - head) * 1000.0 / freq << " ms" << endl;

    double check_sum = 0;
    for(int i = 0; i < N; i++) {
        check_sum += sum_res[i];
    }
    cout << "\n[防止编译器优化] 结果校验和: " << check_sum << endl;

    return 0;
}