//
// Created by ZhiquanWang on 2018/7/9.
//
#ifndef _SH_PNGMASTER_
#define _SH_PNGMASTER_

#include "svpng.inc"

#include <cstring>
#include <iostream>

using namespace std;

class pngmaster {
public:
  unsigned int height;          // the height of image
  unsigned int width;           // the width of image
  unsigned char *data;          // the pointer to image data
  unsigned int size;            // The number of bytes allocated for image data
  const unsigned int dimension; // the demension of colors

public:
  pngmaster(unsigned int _h, unsigned int _w) : dimension(4) {
    height = _h;
    width = _w;
    size = _h * _w * 4;
    data = new unsigned char[size];
    memset(data, 0, size);
  }

  void set_pixel(int _x, int _y, int _r, int _g, int _b, int _a = 255) {
    _y = height - _y - 1;
    data[(_y * width + _x) * 4] = (unsigned char)std::min(_r, 255);
    data[(_y * width + _x) * 4 + 1] = (unsigned char)std::min(_g, 255);
    data[(_y * width + _x) * 4 + 2] = (unsigned char)std::min(_b, 255);
    data[(_y * width + _x) * 4 + 3] = (unsigned char)std::min(_a, 255);
  }
  unsigned int size_bytes() { return sizeof(unsigned char) * size; }
  void output(const char *_name) {
    FILE *fp = fopen(_name, "wb");
    svpng(fp, width, height, data, 1);
    fclose(fp);
  }
};

#endif
