#include "../book.h"
#include "pngmaster.h"
#include <cmath>
__global__ void gen_image(unsigned char *data);

#define IMAGE_DIM 640
int main() {
  const unsigned int image_height = IMAGE_DIM;
  const unsigned int image_width = IMAGE_DIM;
  pngmaster png_image(image_height, image_width);
  unsigned char *d_image_data;
  HANDLE_ERROR(cudaMalloc((void **)&d_image_data, png_image.size_bytes()));

  dim3 block_size(16, 16);
  dim3 grid_size(IMAGE_DIM / block_size.x, IMAGE_DIM / block_size.y);
  gen_image<<<grid_size, block_size>>>(d_image_data);
  printf("%d \n", png_image.size_bytes());
  HANDLE_ERROR(cudaMemcpy(png_image.data, d_image_data, png_image.size_bytes(),
                          cudaMemcpyDeviceToHost));

  png_image.output("ripple.png");
  cudaFree(d_image_data);
}

__global__ void gen_image(unsigned char *data) {
  int col = blockDim.x * blockIdx.x + threadIdx.x;
  int row = blockDim.y * blockIdx.y + threadIdx.y;
  int offset = row * gridDim.x * blockDim.x + col;
  printf("%d \n", offset);
  float fx = col - IMAGE_DIM / 2;
  float fy = row - IMAGE_DIM / 2;
  float dis = sqrtf(fx * fx + fy * fy);

  unsigned char grey =
      (unsigned char)(128.0f + 127.0f * cos(dis / 10.0f - 12 / 7.0f) /
                                   (dis / 10.0f + 1.0f));
  data[offset * 4 + 0] = 64;
  data[offset * 4 + 1] = grey;
  data[offset * 4 + 2] = 128;
  data[offset * 4 + 3] = 255;
}