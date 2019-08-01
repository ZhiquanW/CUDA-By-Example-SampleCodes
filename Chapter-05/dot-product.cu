#include "../book.h"
#include <cmath>
#include <stdio.h>
const int N = 33 * 1024;
const int threadsPerBlock = 256;
const int blocksPerGrid = min(32, (N + threadsPerBlock - 1) / threadsPerBlock);
__global__ void dot(float *, float *, float *);
int main() {
  float *a, *b, *partial_c;
  float *dev_a, *dev_b, *dev_partial_c;
  a = new float[N];
  b = new float[N];
  partial_c = new float[blocksPerGrid];
  printf("%d %d\n", blocksPerGrid, threadsPerBlock);
  HANDLE_ERROR(cudaMalloc((void **)&dev_a, N * sizeof(float)));
  HANDLE_ERROR(cudaMalloc((void **)&dev_b, N * sizeof(float)));
  HANDLE_ERROR(
      cudaMalloc((void **)&dev_partial_c, blocksPerGrid * sizeof(float)));
  for (int i = 0; i < N; ++i) {
    a[i] = i;
    b[i] = 0;
  }
  HANDLE_ERROR(cudaMemcpy(dev_a, a, N * sizeof(float), cudaMemcpyHostToDevice));
  HANDLE_ERROR(cudaMemcpy(dev_b, b, N * sizeof(float), cudaMemcpyHostToDevice));
  dot<<<blocksPerGrid, threadsPerBlock>>>(dev_a, dev_b, dev_partial_c);
  HANDLE_ERROR(cudaMemcpy(partial_c, dev_partial_c,
                          blocksPerGrid * sizeof(float),
                          cudaMemcpyDeviceToHost));

  float final_result = 0;
  for (int i = 0; i < blocksPerGrid; ++i) {
    final_result += partial_c[i];
  }
  printf("Final Result: %.6f\n", final_result);
  cudaFree(dev_a);
  cudaFree(dev_b);
  cudaFree(dev_partial_c);
  free(a);
  free(b);
  free(partial_c);
}
__global__ void dot(float *a, float *b, float *c) {
  __shared__ float cache[threadsPerBlock];
  int tid = blockDim.x * blockIdx.x + threadIdx.x;
  int cacheIndex = threadIdx.x;

  float tmp = 0;
  while (tid < N) {
    tmp += a[tid] * b[tid];

    tid += gridDim.x * blockDim.x;
  }
  cache[cacheIndex] = tmp;

  __syncthreads();
  int tmp_len = blockDim.x / 2;
  while (tmp_len != 0) {
    if (cacheIndex < tmp_len) {
      cache[cacheIndex] += cache[cacheIndex + tmp_len];
    }
    __syncthreads();
    tmp_len /= 2;
  }
  if (cacheIndex == 0) {
    c[blockIdx.x] = cache[0];
  }
}
