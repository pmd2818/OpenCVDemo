//
//  MagnifyGlassView.h
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/27.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MagnifyGlassView : UIView

@property (nonatomic, strong) UIView *magnifyView;
@property (nonatomic, assign) CGPoint touchPoint;
@property (nonatomic, assign) CGFloat magnification;

@end

NS_ASSUME_NONNULL_END
