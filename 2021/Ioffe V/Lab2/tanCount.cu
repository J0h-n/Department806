// System includes
#include <assert.h>
#include <stdio.h>
#include<math.h>
#include <time.h>
#include <chrono>
#include <stdio.h>
#include <stdlib.h>

// CUDA runtime
#include <cuda_runtime.h>

// Helper functions and utilities to work with CUDA
#include <helper_cuda.h>
#include <helper_functions.h>

#include "device_launch_parameters.h"

//���������� �������
#define N 1024
//���������� ������
#define BL 97

//��� ����������� �� GPU

__global__ void staticReverse(long* d, long n)
{
    __shared__ long s[N];
    long global_t = threadIdx.x + 1024 * blockIdx.x;
    int t = threadIdx.x;
    
    if (global_t >= n)
        return;

    //int tr = N - t - 1;
    s[t] = d[global_t];
    __syncthreads();
    d[n - global_t - 1] = s[t];
}

int main(int argc, char* argv)
{
    const long n = 100000;
    long a[n], d[n];

    for (long i = 0; i < n; i++) {
        a[i] = i + 1;
        d[i] = 0;
    }

    ////---���������� �� ����������---
    printf("[Reverse computing Using CUDA] - Starting...\n");

    cudaStream_t stream;

    //// ��������� ������ �� ����������



    long* d_d;
    checkCudaErrors(cudaMalloc(&d_d, n * sizeof(long)));


    //// ��������� ������ �� ���������� � ������������� ���� �������
    checkCudaErrors(cudaMemcpy(d_d, a, n*sizeof(long), cudaMemcpyHostToDevice));

    checkCudaErrors(cudaDeviceSynchronize());

    //// �������� ������� � ������ ��� �������
    cudaEvent_t start, stop;
    checkCudaErrors(cudaEventCreate(&start));
    checkCudaErrors(cudaEventCreate(&stop));

    checkCudaErrors(cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking));


    printf("Computing result using CUDA Kernel...\n");

    //// ������ ������ �������
    checkCudaErrors(cudaEventRecord(start, stream));

    //// ���������� ���� �� ���������� � �������� ���������� ���� �������

    staticReverse << <BL, N >> > (d_d, n);


    checkCudaErrors(cudaStreamSynchronize(stream));

    //// ������ ��������� �������
    checkCudaErrors(cudaEventRecord(stop, stream));

    //// ������������� � �������� ������������ �������
    checkCudaErrors(cudaEventSynchronize(stop));

    //// ������ � ����� ������������������

    float m_sec_total = 0.0f;
    checkCudaErrors(cudaEventElapsedTime(&m_sec_total, start, stop));

    float mc_sec_total = m_sec_total * 1000;
    printf(
        "Time GPU = %.10f microsec\n",
        mc_sec_total);

    //// ����������� ����������� � GPU �� CPU
    checkCudaErrors(
        cudaMemcpy(d, d_d, n * sizeof(long), cudaMemcpyDeviceToHost));

    checkCudaErrors(cudaStreamSynchronize(stream));


    ////---���������� �� ����������---



    // �������� ����� �������
    auto begin = std::chrono::high_resolution_clock::now();

    long r[n];

    for (long i = 0; i < n; i++)
    {
        r[i] = a[n - i - 1];
    }
    
    //// ������������� ������ � ������� ����� ����������
    auto end = std::chrono::high_resolution_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin);

    printf(
        "Time CPU = %.10f microsec\n",
        elapsed.count() * 1e-3);

    ////�������� ��������

    for (long i = 0; i < n; i++)
    {
        if (d[i] != r[i])
        {
          /* printf("Error: d[%d]!=r[%d] (%d, %d) \n", i, i, d[i], r[i]);*/
        }
    }

    //// ������������ ������
    checkCudaErrors(cudaFree(d_d));
    checkCudaErrors(cudaEventDestroy(start));
    checkCudaErrors(cudaEventDestroy(stop));

    cudaDeviceReset();

    return 0;
}
