//
//  MagnifyGlassView.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/27.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import "MagnifyGlassView.h"

#define MagnifierViewSize 90.0f
#define kMagnifyingGlassDefaultOffset -70.0f

@interface MagnifyGlassView ()

@property (nonatomic, assign) CGPoint touchPointOffset;

@end

@implementation MagnifyGlassView

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        self.magnification = 1.5f;
        self.frame = CGRectMake(0, 0, MagnifierViewSize, MagnifierViewSize);
        self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.layer.borderWidth = 1.0f;
        self.layer.cornerRadius = self.frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.touchPointOffset = CGPointMake(0, kMagnifyingGlassDefaultOffset);
    }
    
    return self;
}

- (void)setTouchPoint:(CGPoint)point
{
    point.y = point.y + [UIApplication sharedApplication].statusBarFrame.size.height+72;
    
    _touchPoint = point;
    
    self.center = CGPointMake(point.x+self.touchPointOffset.x, point.y+self.touchPointOffset.y);//跟随touchmove 不断得到中心点
}

- (void)drawRect:(CGRect)rect
{
    //绘制放大镜效果部分
    CGContextRef context = UIGraphicsGetCurrentContext();//获取的是当前view的图形上下文
    CGContextTranslateCTM(context, MagnifierViewSize/2, MagnifierViewSize/2);//重新设置坐标系原点
    CGContextScaleCTM(context, self.magnification, self.magnification);//通过调用CGContextScaleCTM函数来指定x, y缩放因子 这里我们是扩大1.5倍
    CGContextTranslateCTM(context, -self.touchPoint.x, -self.touchPoint.y);
    [self.magnifyView.layer renderInContext:context];//直接在一个 Core Graphics 上下文中绘制放大后的图像,实现放大镜效果
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
