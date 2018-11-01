//
//  ContourDetectionViewController.h
//  OpenCVDemo
//
//  Created by Meide Pan on 2018/10/25.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContourDetectionViewController : UIViewController

- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, strong) UIImage *image;


@end

NS_ASSUME_NONNULL_END
