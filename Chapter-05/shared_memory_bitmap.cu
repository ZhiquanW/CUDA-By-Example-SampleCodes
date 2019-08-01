#include "../common/book.h"
#include "../common/cpu_bitmap.h"
#include "pngmaster.h"
#define DIM 1024
#define PI 3.1415926535897932f
struct cuComplex {
    float r;
    float i;
    __device__ cuComplex(float a, float b) : r(a), i(b) {}
    __device__ float magnitude2(void) { return r * r + i * i; }
    __device__ cuComplex operator*(const cuComplex &a) { return cuComplex(r * a.r - i * a.i, i * a.r + r * a.i); }
    __device__ cuComplex operator+(const cuComplex &a) { return cuComplex(r + a.r, i + a.i); }
};

__global__ void kernel(unsigned char *ptr) {
    // map from threadIdx/BlockIdx to pixel position
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int offset = x + y * gridDim.x * blockDim.x;

    __shared__ float cache[16][16];
    // now calculate the value at that position
    const float period = 128.0f;
    cache[threadIdx.x][threadIdx.y] =
        255 * (sinf(x * 2.0f * PI / period) + 1.0f) * (sinf(y * 2.0f * PI / period) + 1.0f) / 4.0f;
    __syncthreads();
    ptr[offset * 4 + 0] = 0;
    ptr[offset * 4 + 1] = cache[15 - threadIdx.x][15 - threadIdx.y];
    ptr[offset * 4 + 2] = 0;
    ptr[offset * 4 + 3] = 255;
}
int main(void) {
    pngmaster bitmap(DIM, DIM);
    unsigned char *dev_bitmap;
    HANDLE_ERROR(cudaMalloc((void **)&dev_bitmap, sizeof(unsigned char) * bitmap.height * bitmap.width * 4));
    dim3 grids(DIM / 16, DIM / 16);
    dim3 threads(16, 16);
    kernel<<<grids, threads>>>(dev_bitmap);
    HANDLE_ERROR(cudaMemcpy(bitmap.data, dev_bitmap, sizeof(unsigned char) * bitmap.height * bitmap.width * 4,
                            cudaMemcpyDeviceToHost));
    bitmap.output("1234.png");
    cudaFree(dev_bitmap);
}
