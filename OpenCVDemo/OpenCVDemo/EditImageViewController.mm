//
//  EditImageViewController.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/5.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <iostream>
#import <algorithm>
#import <string>
#import <vector>

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/core/core.hpp>

#import "Scanner.h"

#import "EditImageViewController.h"

#import "EditImageView.h"

using namespace std;
using namespace cv;

@interface EditImageViewController () <EditImageViewDelegate>

@property (nonatomic, strong) EditImageView *editImageView;

@end

@implementation EditImageViewController

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    
    if(self)
    {
        self.image = image;
    }
    
    return self;
}

- (void)createUI
{
    CGRect rect = self.view.bounds;
    
    self.editImageView = [[EditImageView alloc] initWithFrame:rect image:self.image];
    self.editImageView.delegate = self;
    self.editImageView.backgroundColor = [UIColor whiteColor];
    self.editImageView.userInteractionEnabled = YES;
    self.editImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.editImageView];
    __weak typeof(self) weakSelf = self;
    self.editImageView.block = ^(NSArray * _Nonnull points) {
        NSLog(@"开始截图");
        
        vector<cv::Point> corners;//[points.count];
        
        for(NSInteger i = 0; i < points.count; i++)
        {
            NSValue *value = [points objectAtIndex:i];
            CGPoint pt1 = [value CGPointValue];
            cv::Point pt2 = cv::Point(pt1.x, pt1.y);
            
            corners.push_back(pt2);
        }
        
        cv::Mat imgMat = [weakSelf cropImage:weakSelf.image withPoints:corners];
        
        weakSelf.editImageView.previewImageView.hidden = NO;
        weakSelf.editImageView.previewImageView.image = MatToUIImage(imgMat);
    };
}

- (void)clickGoBackBtn:(UIButton *)button
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clickRotateBtn:(UIButton *)button
{
    [self detect:self.image];
    
    [self.editImageView setNeedsDisplay];
}

- (void)clickFinishBtn:(UIButton *)button
{
    self.editImageView.block([self.editImageView getCornersPoints]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"编辑图片";
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self createUI];
    
    self.editImageView.image = self.image;
    
    vector<cv::Point> points = [self detect:self.image];
    
    NSArray *array = [self pointsToNative:points withImage:self.image];
    
    if(array.count == 4)
    {
        [self.editImageView setCornersWithPoints:array];
    }
}

- (NSArray *)pointsToNative:(vector<cv::Point>)points withImage:(UIImage *)image
{
    CGPoint lt, rt, rb, lb;
    if(points.size() == 4)
    {
        lt = CGPointMake(points[0].x, points[0].y);
        rt = CGPointMake(points[1].x, points[1].y);
        rb = CGPointMake(points[2].x, points[2].y);
        lb = CGPointMake(points[3].x, points[3].y);
    }
    else
    {
        return nil;
    }
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGFloat imageRatio = image.size.width / image.size.height;
    CGFloat screenRatio = rect.size.width / rect.size.height;
    
    CGFloat ratio;
    
    if(imageRatio >= screenRatio)
    {
        ratio = image.size.width / rect.size.width;
    }
    else
    {
        ratio = image.size.height / rect.size.height;
    }
    
    lt.x /= ratio;
    lt.y /= ratio;
    
    rt.x /= ratio;
    rt.y /= ratio;
    
    rb.x /= ratio;
    rb.y /= ratio;
    
    lb.x /= ratio;
    lb.y /= ratio;
    
//    //测试代码
//    (lt.x /= ratio) -= 1;
//    (lt.y /= ratio) -= 1;
//
//    (rt.x /= ratio) += 3;
//    (rt.y /= ratio) -= 1;
//
//    (rb.x /= ratio) += 3;
//    (rb.y /= ratio) += 3;
//
//    (lb.x /= ratio) -= 1;
//    (lb.y /= ratio) += 3;
    
    NSArray *array = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:lt], [NSValue valueWithCGPoint:rt], [NSValue valueWithCGPoint:rb], [NSValue valueWithCGPoint:lb], nil];
    
    return array;
}

// 检测顶点
- (vector<cv::Point>)detect:(UIImage *)image
{
    Mat src;
    UIImageToMat(image, src);
    
    Mat bgrData = Mat::zeros(src.rows, src.cols, CV_8UC(3));
    
    cvtColor(src, bgrData, CV_RGBA2BGR);
    scanner::Scanner docScanner(bgrData);
    std::vector<cv::Point> scanPoints = docScanner.scanPoint();
    
    src.release();
    
    return scanPoints;
}

// 截图
- (cv::Mat)cropImage:(UIImage *)image withPoints:(vector<cv::Point>)points
{
    Mat srcBitmapMat, dstBitmapMat;
    UIImageToMat(image, srcBitmapMat);
    
    if(points.size() != 4)
    {
        return srcBitmapMat;
    }
    
    cv::Point leftTop = points[0];
    cv::Point rightTop = points[1];
    cv::Point rightBottom = points[2];
    cv::Point leftBottom = points[3];
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGFloat imageRatio = image.size.width / image.size.height;
    CGFloat screenRatio = rect.size.width / rect.size.height;
    
    CGFloat ratio;
    
    if(imageRatio >= screenRatio)
    {
        ratio = image.size.width / rect.size.width;
    }
    else
    {
        ratio = image.size.height / rect.size.height;
    }
    
    leftTop.x *= ratio;
    leftTop.y *= ratio;
    
    rightTop.x *= ratio;
    rightTop.y *= ratio;
    
    rightBottom.x *= ratio;
    rightBottom.y *= ratio;
    
    leftBottom.x *= ratio;
    leftBottom.y *= ratio;
    
    int newHeight = sqrt(pow(leftBottom.x-leftTop.x, 2)+pow(leftBottom.y-leftTop.y, 2))/2 + sqrt(pow(rightBottom.x-rightTop.x, 2) + pow(rightBottom.y-rightTop.y, 2))/2;
    int newWidth = sqrt(pow(rightTop.x-leftTop.x, 2)+pow(rightTop.y-leftTop.y, 2))/2 + sqrt(pow(rightBottom.x-leftBottom.x, 2) + pow(rightBottom.y-leftBottom.y, 2))/2;
    
    dstBitmapMat = Mat::zeros(newHeight, newWidth, srcBitmapMat.type());
    
    vector<Point2f> srcTriangle;
    vector<Point2f> dstTriangle;
    
    srcTriangle.push_back(Point2f(leftTop.x, leftTop.y));
    srcTriangle.push_back(Point2f(rightTop.x, rightTop.y));
    srcTriangle.push_back(Point2f(leftBottom.x, leftBottom.y));
    srcTriangle.push_back(Point2f(rightBottom.x, rightBottom.y));
    
    dstTriangle.push_back(Point2f(0, 0));
    dstTriangle.push_back(Point2f(newWidth, 0));
    dstTriangle.push_back(Point2f(0, newHeight));
    dstTriangle.push_back(Point2f(newWidth, newHeight));
    
    //获得透视转换矩阵
    Mat transform = getPerspectiveTransform(srcTriangle, dstTriangle);
    
    //透视变换，校正图片
    warpPerspective(srcBitmapMat, dstBitmapMat, transform, dstBitmapMat.size());
    
    srcBitmapMat.release();
    
    return dstBitmapMat;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
