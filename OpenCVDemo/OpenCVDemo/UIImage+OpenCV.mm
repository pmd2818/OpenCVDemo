//
//  UIImage+OpenCV.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/16.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import "UIImage+OpenCV.h"

//static void ProviderReleaseDataNOP(void *info,const void *data,size_t size)
//{
//    // Do not release memory
//    return;
//}

@implementation UIImage (OpenCV)

- (cv::Mat)CVMat
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
    
    CGFloat cols = self.size.width;
    
    CGFloat rows = self.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                     // Width of bitmap
                                                    rows,                    // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (cv::Mat)CVGrayscaleMat
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGFloat cols = self.size.width;
    
    CGFloat rows = self.size.height;
    
    cv::Mat cvMat = cv::Mat(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                     // Width of bitmap
                                                    rows,                    // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNone |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    
    CGContextRelease(contextRef);
    
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    return [[UIImage alloc] initWithCVMat:cvMat];
}

- (id)initWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider =CGDataProviderCreateWithCFData((CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                    // Width
                                        cvMat.rows,                                    // Height
                                        8,                                             // Bits per component
                                        8 * cvMat.elemSize(),                          // Bits per pixel
                                        cvMat.step[0],                                 // Bytes per row
                                        colorSpace,                                    // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                      // CGDataProviderRef
                                        NULL,                                          // Decode
                                        false,                                         // Should interpolate
                                        kCGRenderingIntentDefault);                    // Intent
    
    self = [self initWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    
    CGDataProviderRelease(provider);
    
    CGColorSpaceRelease(colorSpace);
    
    return self;
}

/// UIImage类型转换为IPlImage类型
- (IplImage*)convertToIplImage:(UIImage*)image
{
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplImage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, iplImage->depth, iplImage->widthStep, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    IplImage *ret = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, ret, CV_RGB2BGR);
    cvReleaseImage(&iplImage);
    return ret;
}

/// IplImage类型转换为UIImage类型
- (UIImage*)convertToUIImage:(IplImage*)image
{
    cvCvtColor(image, image, CV_BGR2RGB);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width, image->height, image->depth, image->depth * image->nChannels, image->widthStep, colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}

@end
