//
//  SaoMiaoViewController.m
//  OpenCVDemo
//
//  Created by Meide Pan on 2018/10/31.
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

#import "SaoMiaoViewController.h"

using namespace std;
using namespace cv;

cv::Point2f computeIntersect11(cv::Vec4i a,cv::Vec4i b)
{
    int x1 = a[0],y1 = a[1],x2 = a[2],y2 = a[3],x3 = b[0],y3 = b[1],x4 = b[2],y4 = b[3];
    
    if (float d = ((float)(x1 - x2)*(y3 - y4)-(y1 - y2)*(x3 - x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4))/d;
        pt.y = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4))/d;
        return pt;
    }
    else
        return cv::Point2f(-1,-1);
}

void sortCorners11(std::vector<cv::Point2f>& corners,cv::Point2f center)
{
    std::vector<cv::Point2f> top,bot;
    
    for (unsigned int i =0;i< corners.size();i++)
    {
        if (corners[i].y<center.y)
        {
            top.push_back(corners[i]);
        }
        else
        {
            bot.push_back(corners[i]);
        }
    }
    cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
    cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
    cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
    cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
    
    corners.clear();
    //注意以下存放顺序是顺时针，当时这里出错了，如果想任意顺序下文开辟的四边形矩阵注意对应
    corners.push_back(tl);
    corners.push_back(tr);
    corners.push_back(br);
    corners.push_back(bl);
    
}

Mat saomiao(cv::Mat image)
{
    cv::Mat src;
    
    src = image.clone();
    
    cv::Mat bw;
    cv::cvtColor(src,bw,CV_BGR2GRAY);
    
    cv::blur(bw,bw,cv::Size(3,3));
    
    cv::Canny(bw,bw,100,100,3);
    
    std::vector<cv::Vec4i> lines;
    cv::HoughLinesP(bw,lines,1,CV_PI/180,70,30,10);
    //1像素分辨能力  1度的角度分辨能力        >70可以检测成连线        30是最小线长
    //在直线L上的点（且点与点之间距离小于maxLineGap=10的）连成线段，然后这些点全部删除，并且记录该线段的参数，就是起始点和终止点
    
    //needed for visualization only//这里是将检测的线调整到延长至全屏，即射线的效果，其实可以不必这么做
    for (unsigned int i = 0;i<lines.size();i++)
    {
        cv::Vec4i v = lines[i];
        lines[i][0] = 0;
        lines[i][1] = ((float)v[1] - v[3])/(v[0] - v[2])* -v[0] + v[1];
        lines[i][2] = src.cols;
        lines[i][3] = ((float)v[1] - v[3])/(v[0] - v[2])*(src.cols - v[2]) + v[3];
    }
    std::vector<cv::Point2f> corners;//线的交点存储
    for (unsigned int i = 0;i<lines.size();i++)
    {
        for (unsigned int j=i+1;j<lines.size();j++)
        {
            cv::Point2f pt = computeIntersect11(lines[i],lines[j]);
            if (pt.x >= 0 && pt.y >=0)
            {
                corners.push_back(pt);
            }
        }
    }
    
    std::vector<cv::Point2f> approx;
    cv::approxPolyDP(cv::Mat(corners),approx,cv::arcLength(cv::Mat(corners),true)*0.02,true);
    
    if (approx.size()!=4)
    {
        std::cout<<"The object is not quadrilateral（四边形）!"<<std::endl;
    }
    
    Point2f center = Point2f(0,0);
    
    //get mass center
    for (unsigned int i = 0;i < corners.size();i++)
    {
        center += corners[i];
    }
    center *=(1./corners.size());
    sortCorners11(corners,center);
    cv::Mat dst = src.clone();
    //Draw Lines
    for (unsigned int i = 0;i<lines.size();i++)
    {
        cv::Vec4i v = lines[i];
        cv::line(dst,cv::Point(v[0],v[1]),cv::Point(v[2],v[3]),CV_RGB(0,255,0));    //目标版块画绿线
    }
    //draw corner points
    cv::circle(dst,corners[0],3,CV_RGB(255,0,0),2);
    cv::circle(dst,corners[1],3,CV_RGB(0,255,0),2);
    cv::circle(dst,corners[2],3,CV_RGB(0,0,255),2);
    cv::circle(dst,corners[3],3,CV_RGB(255,255,255),2);
    //draw mass center
    cv::circle(dst,center,3,CV_RGB(255,255,0),2);
    
//    return dst;
    cv::Mat quad = cv::Mat::zeros(image.rows,image.cols,CV_8UC3);//设定校正过的图片从320*240变为300*220
    //corners of the destination image
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0,0));
    quad_pts.push_back(cv::Point2f(quad.cols,0));//(220,0)
    quad_pts.push_back(cv::Point2f(quad.cols,quad.rows));//(220,300)
    quad_pts.push_back(cv::Point2f(0,quad.rows));
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners,quad_pts);    //求源坐标系（已畸变的）与目标坐标系的转换矩阵
    
    // Apply perspective transformation透视转换
    cv::warpPerspective(src,quad,transmtx,quad.size());
    
    return quad;
}


@interface SaoMiaoViewController ()

@property (nonatomic, strong) UIImageView *cropImageView;

@end

@implementation SaoMiaoViewController

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
    
    self.cropImageView = [[UIImageView alloc] initWithFrame:rect];
    self.cropImageView.backgroundColor = [UIColor whiteColor];
    self.cropImageView.userInteractionEnabled = YES;
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.cropImageView];
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
//    cvtColor(src, src, COLOR_RGBA2BGR);
    if (scanPoints.size() == 4) {
        for (int i = 0; i < 4; ++i) {
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
    
    self.cropImageView.image = MatToUIImage(dstBitmapMat);
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
