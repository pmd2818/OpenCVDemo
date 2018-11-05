//
//  EditImageViewController.m
//  OpenCVDemo
//
//  Created by Meide Pan on 2018/11/5.
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

using namespace std;
using namespace cv;

@interface EditImageViewController ()

@property (nonatomic, strong) UIImageView *editImageView;

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
    
    self.editImageView = [[UIImageView alloc] initWithFrame:rect];
    self.editImageView.backgroundColor = [UIColor whiteColor];
    self.editImageView.userInteractionEnabled = YES;
    self.editImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.editImageView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"编辑图片";
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self createUI];
    
    Mat src, srcImage;
    UIImageToMat(self.image, src);
    srcImage = src.clone();
    Mat bgrData = Mat::zeros(srcImage.rows, srcImage.cols, CV_8UC(3));
    
    cvtColor(srcImage, bgrData, CV_RGBA2BGR);
    scanner::Scanner docScanner(bgrData);
    std::vector<cv::Point> scanPoints = docScanner.scanPoint();
    
    if(scanPoints.size() == 4)
    {
        for(int i = 0; i < 4; ++i)
        {
            if(i == 3)
            {
                line(src, scanPoints[i], scanPoints[0], Scalar(0,0,255), 4, LINE_8);
            }
            else
            {
                line(src, scanPoints[i], scanPoints[i+1], Scalar(0,0,255), 4, LINE_8);
            }
        }
    }
    
    vector<cv::Point> points =scanPoints;
    
    if(points.size() != 4)
    {
        return;
    }
    cv::Point leftTop = points[0];
    cv::Point rightTop = points[1];
    cv::Point rightBottom = points[2];
    cv::Point leftBottom = points[3];
    
    Mat srcBitmapMat;
    srcBitmapMat = src.clone();
    
    Mat dstBitmapMat;
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
    
    Mat transform = getPerspectiveTransform(srcTriangle, dstTriangle);
    warpPerspective(srcBitmapMat, dstBitmapMat, transform, dstBitmapMat.size());
    
    self.editImageView.image = MatToUIImage(dstBitmapMat);
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
