//
//  EditImageView.h
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/5.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//定义block
typedef void(^Block)(NSArray *points);

@protocol EditImageViewDelegate <NSObject>

- (void)clickGoBackBtn:(UIButton *)button;
- (void)clickRotateBtn:(UIButton *)button;
- (void)clickFinishBtn:(UIButton *)button;

@end

@interface EditImageView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *originImageView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, copy)   Block block;

@property (nonatomic, weak)   id<EditImageViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;

- (void)setCornersWithPoints:(NSArray *)points;

- (NSArray *)getCornersPoints;

@end

NS_ASSUME_NONNULL_END
