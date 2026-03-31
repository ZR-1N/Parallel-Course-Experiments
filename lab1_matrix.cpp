#include <iostream>
#include <windows.h> 
#include <iomanip> // 用于对齐输出

using namespace std;

const int MAX_N = 4096; // 最大开辟的空间
const int ITERATIONS = 1000; // 适当减少轮数，因为要测很多组

// 使用全局变量，大小固定为最大规模，避免每次循环重新分配内存的开销
double b[MAX_N][MAX_N];
double a[MAX_N];
double sum_res[MAX_N];

void init(int n) {
    for (int i = 0; i < n; i++) {
        a[i] = 1.0;
        for (int j = 0; j < n; j++) {
            b[i][j] = i + j; 
        }
    }
}

void trivial_algorithm(int n) {
    for (int i = 0; i < n; i++) {
        sum_res[i] = 0.0;
        for (int j = 0; j < n; j++) {
            sum_res[i] += b[j][i] * a[j];
        }
    }
}

void optimized_algorithm(int n) {
    for (int i = 0; i < n; i++) {
        sum_res[i] = 0.0;
    }
    for (int j = 0; j < n; j++) {
        for (int i = 0; i < n; i++) {
            sum_res[i] += b[j][i] * a[j];
        }
    }
}

int main() {
    long long head, tail, freq;
    QueryPerformanceFrequency((LARGE_INTEGER*)&freq);

    cout << "矩阵规模(N)\t平凡算法(ms)\t优化算法(ms)\t加速比" << endl;
    cout << "--------------------------------------------------------" << endl;

    // 测试不同的大小规模
    int sizes[] = {16,32,64, 128, 256, 512, 1024, 1536, 2048, 4096};
    
    for (int n : sizes) {
        init(n);

        // 测试平凡算法
        QueryPerformanceCounter((LARGE_INTEGER*)&head);
        for(int k = 0; k < ITERATIONS; k++) { 
            trivial_algorithm(n);
        }
        QueryPerformanceCounter((LARGE_INTEGER*)&tail);
        double time_trivial = (tail - head) * 1000.0 / freq;

        // 测试优化算法
        QueryPerformanceCounter((LARGE_INTEGER*)&head);
        for(int k = 0; k < ITERATIONS; k++) {
            optimized_algorithm(n);
        }
        QueryPerformanceCounter((LARGE_INTEGER*)&tail);
        double time_optimized = (tail - head) * 1000.0 / freq;

        // 打印结果 (制表符对齐)
        cout << n << "x" << n << "\t\t" 
             << fixed << setprecision(2) << time_trivial << "\t\t" 
             << time_optimized << "\t\t" 
             << time_trivial / time_optimized << "x" << endl;
    }

    // 防优化校验和
    double check_sum = 0;
    for(int i = 0; i < sizes[9]; i++) { check_sum += sum_res[i]; }
    cout << "\n[防止编译器优化] 校验和: " << check_sum << endl;

    return 0;
}