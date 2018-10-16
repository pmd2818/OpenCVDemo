//
//  UIImage+OpenCV.h
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/16.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (OpenCV)

+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;

- (id)initWithCVMat:(const cv::Mat&)cvMat;


@property(nonatomic, readonly) cv::Mat CVMat;

@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end

NS_ASSUME_NONNULL_END
