
#ifndef __SOBELFILTER_KERNELS_H_
#define __SOBELFILTER_KERNELS_H_

typedef unsigned char Pixel;

// ������������ ��������� ������� �����������
enum SobelDisplayMode
{
    SOBELDISPLAY_IMAGE = 0,
    SOBELDISPLAY_SOBELTEX = 1
};

//������������ � ������ ������ �����
extern enum SobelDisplayMode g_SobelDisplayMode;

extern "C" void sobelFilter(Pixel *odata, int iw, int ih, enum SobelDisplayMode mode);
extern "C" void setupTexture(int iw, int ih, Pixel *data);
extern "C" void deleteTexture(void);
extern "C" void initFilter(void);

#endif

