//
//  EditImageView.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/5.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import "ImageUtil.h"

#import "EditImageView.h"
#import "ProgressView.h"
#import "MagnifyGlassView.h"

@interface EditImageView ()
{
    MagnifyGlassView *magGlassView;
    UIView *view;
}

//进度条
@property (nonatomic, strong) ProgressView *progressView;

//清晰度值
@property (nonatomic, strong) UILabel *clarityValueLabel;

@property (nonatomic, assign) CGPoint ltPoint;
@property (nonatomic, assign) CGPoint rtPoint;
@property (nonatomic, assign) CGPoint rbPoint;
@property (nonatomic, assign) CGPoint lbPoint;

@property (nonatomic, assign) CGPoint leftPoint;
@property (nonatomic, assign) CGPoint topPoint;
@property (nonatomic, assign) CGPoint rightPoint;
@property (nonatomic, assign) CGPoint bottomPoint;

@property (nonatomic, strong) UIView *ltCircle;
@property (nonatomic, strong) UIView *rtCircle;
@property (nonatomic, strong) UIView *rbCircle;
@property (nonatomic, strong) UIView *lbCircle;

@property (nonatomic, strong) UIView *leftCircle;
@property (nonatomic, strong) UIView *topCircle;
@property (nonatomic, strong) UIView *rightCircle;
@property (nonatomic, strong) UIView *bottomCircle;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@end

@implementation EditImageView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        self.image = image;
        
        [self createUI];
        
        float value = [ImageUtil clarityOfImageWithVariance:self.image];
        
        self.progressView.progressValue = value/100*(self.progressView.bounds.size.width);
        
        NSString *valueString = [NSString stringWithFormat:@"%d%@", (int)value, @"%"];
        self.clarityValueLabel.text = valueString;
    }
    
    return self;
}

// 限制拖动范围
- (CGPoint)convertPoint:(CGPoint)point withRect:(CGRect)rect
{
    if(point.x < rect.origin.x)
    {
        point.x = rect.origin.x;
    }
    else if(point.x > rect.size.width)
    {
        point.x = rect.size.width;
    }
    
    if(point.y < rect.origin.y)
    {
        point.y = rect.origin.y;
    }
    else if(point.y > rect.size.height)
    {
        point.y = rect.size.height;
    }
    
    return point;
}

// 获取距离拖拽点最近的角点
- (UIView *)closetToPoint:(CGPoint)point withViews:(NSArray<UIView *> *)array
{
    UIView *cornerView = nil;
    CGFloat distance = -0.1f;
    
    for(UIView *view in array)
    {
        CGFloat dis = sqrt(pow((view.center.x - point.x), 2) + pow((view.center.y - point.y), 2));
        
        if(distance < 0)
        {
            distance = dis;
        }
        
        if(dis <= distance)
        {
            distance = dis;
            cornerView = view;
        }
    }
    
    return cornerView;
}

// 拖拽手势
- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    CGFloat x, y;
    CGPoint point = CGPointZero;
    CGRect rect = self.originImageView.bounds;
    
    //获取手指按在图片上的位置  以图片左上角为原点
    CGPoint translation = [recognizer translationInView:self.originImageView];
    
    NSArray <UIView *> *viewArray = [NSArray arrayWithObjects:self.ltCircle, self.rtCircle, self.rbCircle, self.lbCircle, nil];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"recognizer.state=开始拖动");
            
            CGPoint location = [recognizer locationInView:self.originImageView];
            view = [self closetToPoint:location withViews:viewArray];
            
            x = view.center.x + translation.x;
            y = view.center.y + translation.y;
            point = CGPointMake(x, y);
            
            if(!magGlassView)
            {
                magGlassView = [[MagnifyGlassView alloc] init];
                magGlassView.magnifyView = self;
                [self.superview addSubview:magGlassView];
            }
            magGlassView.touchPoint = point;
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            x = view.center.x + translation.x;
            y = view.center.y + translation.y;
            point = CGPointMake(x, y);
            switch(view.tag)
            {
                case 10001:
                    point = [self convertPoint:point withRect:rect];
                    self.ltPoint = point;
                    break;
                case 10002:
                    point = [self convertPoint:point withRect:rect];
                    self.rtPoint = point;
                    break;
                case 10003:
                    point = [self convertPoint:point withRect:rect];
                    self.rbPoint = point;
                    break;
                case 10004:
                    point = [self convertPoint:point withRect:rect];
                    self.lbPoint = point;
                    break;
                    
                default:
                    break;
            }
            
            NSLog(@"recognizer.state=拖动中");
            point.x += self.originImageView.frame.origin.x;
            magGlassView.touchPoint = point;//将本身的touch信息传递给放大镜,设置放大镜的中心点
            [magGlassView setNeedsDisplay];
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"recognizer.state=结束拖动");
            [magGlassView removeFromSuperview];
            magGlassView = nil;
            
            break;
        }
        default:
            break;
    }
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.originImageView];
    
    [self setNeedsDisplay];
}

- (void)createUI
{
    CGRect rect = self.bounds;
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, TOPVIEW_HEIGHT)];
    topView.backgroundColor = [UIColor whiteColor];
    [self addSubview:topView];
    
    UILabel *clarityLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, STATUSBAT_HEIGHT+15.0f, 50.0f, 20.0f)];
    clarityLabel.text = @"清晰度";
    clarityLabel.textColor = COLOR_WITH_HEX(0X3C70FF);
    clarityLabel.font = [UIFont systemFontOfSize:14.0f];
    clarityLabel.textAlignment = NSTextAlignmentCenter;
    [topView addSubview:clarityLabel];
    
    UILabel *markLabel = [[UILabel alloc] initWithFrame:CGRectMake((rect.size.width-64.0f-15.0f)/2+15.0f, STATUSBAT_HEIGHT+15.0f, 75.0f, 20.0f)];
    markLabel.text = @"50（达标）";
    markLabel.textColor = COLOR_WITH_HEX(0X222222);
    markLabel.font = [UIFont systemFontOfSize:14.0f];
    markLabel.textAlignment = NSTextAlignmentCenter;
    [topView addSubview:markLabel];
    
    self.progressView = [[ProgressView alloc] initWithFrame:CGRectMake(15.0f, STATUSBAT_HEIGHT+45.0f, rect.size.width-15.0f-64.0f, 12.0f)];
    self.progressView.trackTintColor = COLOR_WITH_HEX(0X4C65FD);
    [topView addSubview:self.progressView];
    
    self.clarityValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width-15.0f-32.0f, STATUSBAT_HEIGHT+41.0f, 32.0f, 20.0f)];
    self.clarityValueLabel.text = @"";
    self.clarityValueLabel.textColor = COLOR_WITH_HEX(0X222222);
    self.clarityValueLabel.font = [UIFont systemFontOfSize:14.0f];
    self.clarityValueLabel.textAlignment = NSTextAlignmentCenter;
    [topView addSubview:self.clarityValueLabel];
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, rect.size.height-BOTTOMVIEW_HEIGHT, rect.size.width, BOTTOMVIEW_HEIGHT)];
    bottomView.backgroundColor = [UIColor whiteColor];
    [self addSubview:bottomView];
    
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake((rect.size.width-140.0f)/2, 10.0f, 140.0f, 17.0f)];
    tipLabel.text = @"可随意拖拽锚点调整图片";
    tipLabel.textColor = COLOR_WITH_HEX(0X222222);
    tipLabel.font = [UIFont systemFontOfSize:12.0f];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [bottomView addSubview:tipLabel];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setFrame:CGRectMake(MARGIN_LEFT, MARGIN_TOP, BUTTON_SIZE_WIDTH, BUTTON_SIZE_WIDTH)];
    [backBtn setImage:[UIImage imageNamed:@"返回"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:backBtn];
    
    UIButton *rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rotateBtn setFrame:CGRectMake((rect.size.width-32)/2, MARGIN_TOP, BUTTON_SIZE_WIDTH, BUTTON_SIZE_WIDTH)];
    [rotateBtn setImage:[UIImage imageNamed:@"翻转"] forState:UIControlStateNormal];
    [rotateBtn addTarget:self action:@selector(rotateButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:rotateBtn];
    
    UIButton *cropBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cropBtn setFrame:CGRectMake(rect.size.width - 32 - MARGIN_RIGHT, MARGIN_TOP, BUTTON_SIZE_WIDTH, BUTTON_SIZE_WIDTH)];
    [cropBtn setImage:[UIImage imageNamed:@"完成"] forState:UIControlStateNormal];
    [cropBtn addTarget:self action:@selector(cropButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:cropBtn];
    
    //原图
    rect = self.bounds;
    rect.origin.x = MARGIN_IMAGE;
    rect.origin.y = topView.frame.size.height;
    rect.size.width = rect.size.width - 2 * MARGIN_IMAGE;
    rect.size.height = rect.size.height - topView.frame.size.height - bottomView.frame.size.height;
    self.originImageView = [[UIImageView alloc] initWithFrame:rect];
    self.originImageView.image = self.image;
    self.originImageView.backgroundColor = COLOR_WITH_HEX(0X222222);
    self.originImageView.userInteractionEnabled = YES;
    self.originImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.originImageView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.originImageView addGestureRecognizer:panGesture];
    
    //预览图片
    self.previewImageView = [[UIImageView alloc] initWithFrame:rect];
    self.previewImageView.backgroundColor = [UIColor whiteColor];
    self.previewImageView.userInteractionEnabled = YES;
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewImageView.hidden = YES;
    [self addSubview:self.previewImageView];
    
    _shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.lineWidth = 1.f;//锚点连线线宽
    self.shapeLayer.strokeColor = COLOR_WITH_HEX(ANCHOR_BORDER_COLOR).CGColor;//锚点连线颜色
    self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
    [self.originImageView.layer addSublayer:self.shapeLayer];
    
    //左上角
    self.ltCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    self.ltCircle.tag = 10001;
    self.ltCircle.backgroundColor = [UIColor whiteColor];
    self.ltCircle.alpha = ANCHOR_ALPHA;
    self.ltCircle.layer.masksToBounds = YES;
    self.ltCircle.layer.borderColor = COLOR_WITH_HEX(ANCHOR_BORDER_COLOR).CGColor;
    self.ltCircle.layer.borderWidth = ANCHOR_BORDER_WIDTH;
    self.ltCircle.layer.cornerRadius = ANCHOR_SIZE/2;
//    [self.shapeLayer addSublayer:self.ltCircle.layer];
    [self.originImageView addSubview:self.ltCircle];
    
    UIPanGestureRecognizer *ltPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.ltCircle addGestureRecognizer:ltPan];
    
    //右上角
    self.rtCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    self.rtCircle.tag = 10002;
    self.rtCircle.backgroundColor = [UIColor whiteColor];
    self.rtCircle.alpha = ANCHOR_ALPHA;
    self.rtCircle.layer.masksToBounds = YES;
    self.rtCircle.layer.borderColor = COLOR_WITH_HEX(ANCHOR_BORDER_COLOR).CGColor;
    self.rtCircle.layer.borderWidth = ANCHOR_BORDER_WIDTH;
    self.rtCircle.layer.cornerRadius = ANCHOR_SIZE/2;
    [self.originImageView addSubview:self.rtCircle];
    
    UIPanGestureRecognizer *rtPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.rtCircle addGestureRecognizer:rtPan];
    
    //右下角
    self.rbCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    self.rbCircle.tag = 10003;
    self.rbCircle.backgroundColor = [UIColor whiteColor];
    self.rbCircle.alpha = ANCHOR_ALPHA;
    self.rbCircle.layer.masksToBounds = YES;
    self.rbCircle.layer.borderColor = COLOR_WITH_HEX(ANCHOR_BORDER_COLOR).CGColor;
    self.rbCircle.layer.borderWidth = ANCHOR_BORDER_WIDTH;
    self.rbCircle.layer.cornerRadius = ANCHOR_SIZE/2;
    [self.originImageView addSubview:self.rbCircle];
    
    UIPanGestureRecognizer *rbPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.rbCircle addGestureRecognizer:rbPan];
    
    //左下角
    self.lbCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    self.lbCircle.tag = 10004;
    self.lbCircle.backgroundColor = [UIColor whiteColor];
    self.lbCircle.alpha = ANCHOR_ALPHA;
    self.lbCircle.layer.masksToBounds = YES;
    self.lbCircle.layer.borderColor = COLOR_WITH_HEX(ANCHOR_BORDER_COLOR).CGColor;
    self.lbCircle.layer.borderWidth = ANCHOR_BORDER_WIDTH;
    self.lbCircle.layer.cornerRadius = ANCHOR_SIZE/2;
    [self.originImageView addSubview:self.lbCircle];
    
    UIPanGestureRecognizer *lbPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.lbCircle addGestureRecognizer:lbPan];
    
    //左边中点
    self.leftCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    
    //顶边中点
    self.topCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    
    //右边中点
    self.rightCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
    
    //底边中点
    self.bottomCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ANCHOR_SIZE, ANCHOR_SIZE)];
}

- (void)backButtonClicked:(UIButton *)button
{
    if([self.delegate respondsToSelector:@selector(clickGoBackBtn:)])
    {
        [self.delegate clickGoBackBtn:button];
    }
}

- (void)rotateButtonClicked:(UIButton *)button
{
    //TODO:调整图片方向
    if(!self.previewImageView.hidden)
    {
        UIImage *image = [ImageUtil rotateImage:self.previewImageView.image rotation:UIImageOrientationLeft];
        self.previewImageView.image = image;
    }
    else
    {
        UIImage *image = [ImageUtil rotateImage:self.originImageView.image rotation:UIImageOrientationLeft];
        self.originImageView.image = image;
    }
    
    if([self.delegate respondsToSelector:@selector(clickRotateBtn:)])
    {
        [self.delegate clickRotateBtn:button];
    }
}

- (void)cropButtonClicked:(UIButton *)button
{
    if([self.delegate respondsToSelector:@selector(clickFinishBtn:)])
    {
        [self.delegate clickFinishBtn:button];
    }
}

//获取四边中点point
- (void)getLineCenter
{
    self.leftPoint = CGPointMake((self.lbPoint.x-self.ltPoint.x)/2, (self.lbPoint.y-self.ltPoint.y)/2);
    self.topPoint = CGPointMake((self.rtPoint.x-self.ltPoint.x)/2, (self.rtPoint.y-self.ltPoint.y)/2);
    self.rightPoint = CGPointMake((self.rbPoint.x-self.rtPoint.x)/2, (self.rbPoint.y-self.rtPoint.y)/2);
    self.bottomPoint = CGPointMake((self.rbPoint.x-self.lbPoint.x)/2, (self.rbPoint.y-self.lbPoint.y)/2);
}

//设置截图区域顶点
- (void)setCornersWithPoints:(NSArray *)points
{
    //取出左上点
    NSValue *value = [points objectAtIndex:0];
    self.ltPoint = [value CGPointValue];
    
    //取出右上点
    value = [points objectAtIndex:1];
    self.rtPoint = [value CGPointValue];
    
    //取出右下点
    value = [points objectAtIndex:2];
    self.rbPoint = [value CGPointValue];
    
    //取出左下点
    value = [points objectAtIndex:3];
    self.lbPoint = [value CGPointValue];
}

//获取截图区域顶点
- (NSArray *)getCornersPoints
{
    NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:self.ltPoint], [NSValue valueWithCGPoint:self.rtPoint], [NSValue valueWithCGPoint:self.rbPoint], [NSValue valueWithCGPoint:self.lbPoint], nil];
    
    return array;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)drawRect:(CGRect)rect
{
    //1.创建UIBezierPath对象
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    //2.设置相关属性
    [COLOR_WITH_HEX(ANCHOR_BORDER_COLOR) set];//线条颜色
//    linePath.lineWidth = 1.0f;//线条宽度
    linePath.lineCapStyle = kCGLineCapRound;//线条拐角样式
//    linePath.lineJoinStyle = kCGLineCapRound;//线条终点样式
    //3.通过moveToPoint:设置起点
    [linePath moveToPoint:self.ltPoint];
    //4.添加line为subPaths
    [linePath addLineToPoint:self.rtPoint];
    [linePath addLineToPoint:self.rbPoint];
    [linePath addLineToPoint:self.lbPoint];
    [linePath closePath];
    //5.开始绘制
//    [linePath stroke];
    self.shapeLayer.path = linePath.CGPath;
    
    self.ltCircle.center = self.ltPoint;
    self.rtCircle.center = self.rtPoint;
    self.rbCircle.center = self.rbPoint;
    self.lbCircle.center = self.lbPoint;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
