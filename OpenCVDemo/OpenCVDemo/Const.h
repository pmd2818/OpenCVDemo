//
//  Const.h
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/28.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#ifndef Const_h
#define Const_h

#define KScreenWidth  [UIScreen mainScreen].bounds.size.width
#define KScreenHeight  [UIScreen mainScreen].bounds.size.height

#define COLOR_WITH_HEX(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0 green:((float)((hexValue & 0xFF00) >> 8)) / 255.0 blue:((float)(hexValue & 0xFF)) / 255.0 alpha:1.0f]

#define STATUSBAT_HEIGHT [[UIApplication sharedApplication] statusBarFrame].size.height
#define TOPVIEW_HEIGHT ((STATUSBAT_HEIGHT) + 72.0f)
#define BOTTOMVIEW_HEIGHT 100.0f

#define STATUSBAT_HEIGHT [[UIApplication sharedApplication] statusBarFrame].size.height
#define TOPVIEW_HEIGHT ((STATUSBAT_HEIGHT) + 72.0f)
#define BOTTOMVIEW_HEIGHT 100.0f
#define IMAGEVIEW_WIDTH ([[UIScreen mainScreen] bounds].size.width)

#define COLOR_WITH_HEX(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0 green:((float)((hexValue & 0xFF00) >> 8)) / 255.0 blue:((float)(hexValue & 0xFF)) / 255.0 alpha:1.0f]

#define HORIZONTAL_FIT(x)  ((CGFloat)(x) / 375.0f * ([[UIScreen mainScreen] bounds].size.width)) //水平方向相对值
#define VERTICAL_FIT(y) ((CGFloat)(y) / 375.0f * ([[UIScreen mainScreen] bounds].size.width)) //竖直方向相对值

#define ANCHOR_SIZE 20.0f
#define ANCHOR_BORDER_WIDTH 0.5f
#define ANCHOR_ALPHA 0.7f
#define ANCHOR_BORDER_COLOR (0X3C70FF)

#define MARGIN_LEFT 30.0f
#define MARGIN_RIGHT 30.0f
#define MARGIN_TOP 34.0f
#define BUTTON_SIZE_WIDTH 32.0f
#define MARGIN_IMAGE 45.0f

#endif /* Const_h */
