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
#define BL 98

//��� ����������� �� GPU

__global__ void staticReverse(unsigned int* data_d, unsigned int* result_d, unsigned int n)
{
    __shared__ unsigned int s[N];
    unsigned int global_t = threadIdx.x + 1024 * blockIdx.x;
   // printf("%d", sizeof(double));
    int t = threadIdx.x;
    
    if (global_t >= n)
        return;

    //int tr = N - t - 1;
    s[t] = data_d[global_t];
    __syncthreads();
    result_d[n - global_t - 1] = s[t];
}

int main(int argc, char* argv)
{
    size_t free, total;
    printf("\n");
    cudaMemGetInfo(&free, &total);
    printf("%d KB free of total %d KB\n", free / 1024, total / 1024);

    const unsigned int n = 100000;
    unsigned int *data = new unsigned int[n];
    unsigned int* result = new unsigned int[n];

    for (unsigned int i = 0; i < n; i++) {
        data[i] = i + 1;
        result[i] = 0;
    }

    ////---���������� �� ����������---
    printf("[Reverse computing Using CUDA] - Starting...\n");

    cudaStream_t stream;

    //// ��������� ������ �� ����������



    unsigned int* data_d;
    checkCudaErrors(cudaMalloc(&data_d, n * sizeof(unsigned int)));

    unsigned int* result_d;
    checkCudaErrors(cudaMalloc(&result_d, n * sizeof(unsigned int)));


    //// ��������� ������ �� ���������� � ������������� ���� �������
    checkCudaErrors(cudaMemcpy(data_d, data, n*sizeof(unsigned int), cudaMemcpyHostToDevice));

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

    staticReverse << <BL, N >> > (data_d, result_d, n);


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
        cudaMemcpy(result, result_d, n * sizeof(unsigned int), cudaMemcpyDeviceToHost));

    checkCudaErrors(cudaStreamSynchronize(stream));


    ////---���������� �� ����������---



    // �������� ����� �������
    auto begin = std::chrono::high_resolution_clock::now();

    unsigned int cpu_result[n];

    for (unsigned int i = 0; i < n; i++)
    {
        cpu_result[i] = data[n - i - 1];
    }
    
    //// ������������� ������ � ������� ����� ����������
    auto end = std::chrono::high_resolution_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin);

    printf(
        "Time CPU = %.10f microsec\n",
        elapsed.count() * 1e-3);

    ////�������� ��������

    for (unsigned int i = 0; i < n; i++)
    {
        //if (result[i] != cpu_result[i])
        if(i % 11111 == 0)
        {
           printf("d[%d] == r[%d] (%d, %d) \n", i, i, result[i], cpu_result[i]);
        }
    }

    //// ������������ ������
    checkCudaErrors(cudaFree(data_d));
    checkCudaErrors(cudaEventDestroy(start));
    checkCudaErrors(cudaEventDestroy(stop));

    cudaDeviceReset();

    return 0;
}
