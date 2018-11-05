//
//  ProgressView.h
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/23.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressView : UIView

/**
 *  进度条高度  height: 5~100
 */
@property (nonatomic) CGFloat progressHeight;

/**
 *  进度值  maxValue:  <= YSProgressView.width
 */
@property (nonatomic) CGFloat progressValue;

/**
 *   动态进度条颜色  Dynamic progress
 */
@property (nonatomic, strong) UIColor *trackTintColor;
/**
 *  静态背景颜色    static progress
 */
@property (nonatomic, strong) UIColor *progressTintColor;

@end

NS_ASSUME_NONNULL_END
