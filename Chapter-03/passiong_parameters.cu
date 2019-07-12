#include "../book.h"
#include <iostream>
__global__ void add(int a, int b, int *c);

int main(void) {
  int c;
  int *dev_c;

  HANDLE_ERROR(cudaMalloc((void **)&dev_c, sizeof(int)));
  add<<<1, 1>>>(2, 7, dev_c);
  HANDLE_ERROR(cudaMemcpy(&c, dev_c, sizeof(int), cudaMemcpyDeviceToHost));
  printf("2 + 7 = %d \n", c);
  cudaFree(dev_c);
  return 0;
}
__global__ void add(int a, int b, int *c) { *c = a + b; }