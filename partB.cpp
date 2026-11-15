#include <iostream>
#include <vector>
#include <omp.h>
#include "assignment2.h"
#include <algorithm>

void kernel(int r0, int r1, int c0, int c1, int b, double* A, double* B, double* C, int N, int K) {
    // Untiled ikj
    if (b == 0) {
        for (int i = r0; i < r1; i++) {
            for (int j = c0; j < c1; j++)
                C[i * N + j] = 0.0;
            for (int k = 0; k < K; k++) {
                double a = A[i * K + k];
                for (int j = c0; j < c1; j++)
                    C[i * N + j] += a * B[k * N + j];
            }
        }
        return;
    }

    // Tiled ikj 
    for (int i0 = r0; i0 < r1; i0 += b) {
        for (int j0 = c0; j0 < c1; j0 += b) {
            // zero the tile (i0, j0)
            for (int i = i0; i < i0 + b && i < r1; i++) {
                for (int j = j0; j < j0 + b && j < c1; j++) {
                    C[i * N + j] = 0.0;
                }
            }
            
            for (int k0 = 0; k0 < K; k0 += b) {
                for (int i = i0; i < i0 + b && i < r1; i++) {
                    for (int k = k0; k < k0 + b && k < K; k++) {
                        double a = A[i * K + k];
                        for (int j = j0; j < j0 + b && j < c1; j++) {
                            C[i * N + j] += a * B[k * N + j];
                        }
                    }
                }
            }
        }
    }
}

int main(int argc, char* argv[]) {
    if (argc < 7) {
        std::cout << argv[0] << " <M> <K> <N> <pr> <pc> <b>\n";
        return 1;
    }

    int m  = std::atoi(argv[1]);
    int k  = std::atoi(argv[2]);
    int n  = std::atoi(argv[3]);
    int pr = std::atoi(argv[4]);
    int pc = std::atoi(argv[5]);
    int b  = std::atoi(argv[6]);
    int p  = pr * pc;

    // generate arrays
    double* A = generate_matrix(m, k, 1);
    std:: cout << "A generated\n";
    double* B = generate_matrix(k, n, 2);
    std:: cout << "B generated\n";
    double* C = (double *)malloc((size_t)m * (size_t)n * sizeof(double));
    double* C_test = (double *)malloc((size_t)m * (size_t)n * sizeof(double));
    std::cout << "C generated\n";

    // get C_test array for comparisson
    kernel(0, m, 0, n, 0, A, B, C_test, n, k);

    double times[10];
    double elapsed_time = 0.0;

    // sequential 
    if (p == 0) {
        // warm up run
        kernel(0, m, 0, n, b, A, B, C, n, k);

        for (int i = 0; i < m * n; ++i) {
            if (C[i] != C_test[i]) {
                std::cerr << "Fail array computed incorrectly\n";
                return 1;
            }
        }

        // 10 runs
        for (int i = 0; i < 10; ++i) {
            double before = omp_get_wtime();
            kernel(0, m, 0, n, b, A, B, C, n, k);
            double after = omp_get_wtime() - before;
            times[i] = after;
            elapsed_time += after;
        }
    }
    else {
        // Set thread count
        omp_set_num_threads(p);

        // Warm-up run
        #pragma omp parallel for schedule(static)
        for (int rank = 0; rank < p; rank++) {
            if (pc == 1) {
                int blk = m / pr;
                int r0 = blk * rank;
                int r1 = (rank == pr - 1) ? m : r0 + blk;
                kernel(r0, r1, 0, n, b, A, B, C, n, k);
            } else {
                int bi = rank / pc;
                int bj = rank % pc;
                int blk = m / pr;
                int r0 = blk * bi;
                int r1 = (bi == pr - 1) ? m : r0 + blk;
                blk = n / pc;
                int c0 = blk * bj;
                int c1 = (bj == pc - 1) ? n : c0 + blk;
                kernel(r0, r1, c0, c1, b, A, B, C, n, k);
            }
        }

        // verification against sequential
        for (int i = 0; i < m * n; ++i) {
            if (C[i] != C_test[i]) {
                std::cerr << "Fail array computed incorrectly\n";
                return 1;
            }
        }
        // 10 times
        for (int rep = 0; rep < 10; rep++) {
            double before = omp_get_wtime();

            #pragma omp parallel for schedule(static)
            for (int rank = 0; rank < p; rank++) {
                if (pc == 1) {
                    int blk = m / pr;
                    int r0 = blk * rank;
                    int r1 = (rank == pr - 1) ? m : r0 + blk;
                    kernel(r0, r1, 0, n, b, A, B, C, n, k);
                } else {
                    int bi = rank / pc;
                    int bj = rank % pc;
                    int blk = m / pr;
                    int r0 = blk * bi;
                    int r1 = (bi == pr - 1) ? m : r0 + blk;
                    blk = n / pc;
                    int c0 = blk * bj;
                    int c1 = (bj == pc - 1) ? n : c0 + blk;
                    kernel(r0, r1, c0, c1, b, A, B, C, n, k);
                }
            }

            double after = omp_get_wtime() - before;
            times[rep] = after;
            elapsed_time += after;
        }
    }

    // gathering data
    std::sort(times, times + 10);
    double min = times[0];
    double max = times[9];
    double avg_t = elapsed_time / 10.0;
    double median = 0.5 * (times[4] + times[5]);
    double gflops = (2.0 * m * k * n / median) / 1e9;

    std::cout << "---------------------------------------------------\n";
    std::cout << "M=" << m << " K=" << k << " N=" << n << "\n";
    std::cout << "grid=" << pr << "x" << pc << " p=" << p << " b=" << b << "\n";
    std::cout << "median=" << median << " average time=" << avg_t << "\n";
    std::cout << "min=" << min << " max=" << max << "\n";
    std::cout << "rate=" << gflops << " GFLOP/s\n";
    std::cout << "---------------------------------------------------\n";  


    free(A);
    free(B);
    free(C);

    return 0;
}