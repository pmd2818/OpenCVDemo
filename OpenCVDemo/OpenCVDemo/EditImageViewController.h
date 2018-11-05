//
//  EditImageViewController.h
//  OpenCVDemo
//
//  Created by Meide Pan on 2018/11/5.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditImageViewController : UIViewController

- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, strong) UIImage *image;

@end

NS_ASSUME_NONNULL_END
