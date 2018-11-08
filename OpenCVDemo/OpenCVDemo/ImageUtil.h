//
//  ImageUtil.h
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/8.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgcodecs/imgcodecs_c.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageUtil : NSObject

//方差算法计算图片清晰度
+ (CGFloat)clarityOfImageWithVariance:(UIImage *)image;

//梯度算法计算图片清晰度
+ (double)clarityOfImageWithGradient:(UIImage *)image;

//旋转图片
+ (UIImage *)rotateImage:(UIImage *)image rotation:(UIImageOrientation)orientation;

// 修正图片方向
+ (UIImage *)fixImageOrientation:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
