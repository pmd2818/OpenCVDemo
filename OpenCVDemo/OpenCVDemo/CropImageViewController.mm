//
//  CropImageViewController.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/18.
//  Copyright © 2018 boljonggo. All rights reserved.
//
#import <iostream>
#import <algorithm>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
//#import <opencv2/imgcodecs/imgcodecs_c.h>
#import <opencv2/core/core.hpp>

#include <cmath>
#include <cstdlib>
#include <random>

#import "CropImageViewController.h"

using namespace std;
using namespace cv;

Point2f center(0, 0);

int g_dst_hight;  //最终图像的高度
int g_dst_width; //最终图像的宽度

bool sort_corners(std::vector<cv::Point2f>& corners);
cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b);
bool IsBadLine(int a, int b);
bool x_sort(const Point2f & m1, const Point2f & m2);
void sortCorners(std::vector<cv::Point2f>& corners, cv::Point2f center);
void CalcDstSize(const vector<cv::Point2f>& corners);

//distance -- max distance to the random line for voting
//ngon     -- n-gon to be detected
//itmax    -- max iteration times
void ransacLines(std::vector<cv::Point>& input, std::vector<cv::Vec4d>& lines, double distance, unsigned int ngon, unsigned int itmax)
{
    if(!input.empty())
    {
        for(int i = 0; i < ngon; ++i)
        {
            unsigned int Mmax = 0;
            cv::Point imax;
            cv::Point jmax;
            cv::Vec4d line;
            size_t t1 , t2;
            
            std::random_device rd;     // only used once to initialise (seed) engine
            std::mt19937 rng(rd());    // random-number engine used (Mersenne-Twister in this case)
            std::uniform_int_distribution<int> uni(0,input.size()-1); // guaranteed unbiased // 概率相同
            
            unsigned int it = itmax;
            while(--it)
            {
                t1 = uni(rng);
                t2 = uni(rng);
                t2 = (t1 == t2 ? uni(rng): t2);
                unsigned int M = 0;
                cv::Point i = input[t1];
                cv::Point j = input[t2];
                for(auto a : input)
                {
                    double dis = fabs((j.x - i.x)*(a.y - i.y) - (j.y - i.y)*(a.x - i.x)) / sqrt((j.x - i.x)*(j.x - i.x) + (j.y - i.y)*(j.y - i.y));
                    
                    if(dis < distance)
                    {
                        ++M;
                    }
                }
                
                if(M > Mmax)
                {
                    Mmax = M;
                    imax = i;
                    jmax = j;
                }
            }
            
            line[0] = imax.x;
            line[1] = imax.y;
            line[2] = jmax.x;
            line[3] = jmax.y;
            lines.push_back(line);
            auto iter = input.begin();
            while(iter != input.end())
            {
                double dis = fabs((jmax.x - imax.x)*((*iter).y - imax.y) - (jmax.y - imax.y)*((*iter).x - imax.x)) / sqrt((jmax.x - imax.x)*(jmax.x - imax.x) + (jmax.y - imax.y)*(jmax.y - imax.y));
                
                if(dis < distance)
                {
                    iter = input.erase(iter);  //erase the dis within , then point to
                }
                //   the next element
                else
                {
                    ++iter;
                }
            }
        }
    }
    else
    {
        std::cout << "no input to ransacLines" << std::endl;
    }
}

int thresh = 50, N = 5;

double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

// returns sequence of squares detected on the image.
// the sequence is stored in the specified memory storage
void findSquares(const Mat& image, vector<vector<cv::Point>>& squares)
{
    squares.clear();
    
    // blur will enhance edge detection
    Mat timg(image);
    medianBlur(image, timg, 9);
    Mat gray0(timg.size(), CV_8U), gray;
    
    vector<vector<cv::Point>> contours;
    
    // find squares in every color plane of the image
    for(int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        for(int l = 0; l < N; l++)
        {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading
            if(l == 0)
            {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 5, thresh, 5);
                // dilate canny output to remove potential
                // holes between edge segments
                dilate(gray, gray, Mat(), cv::Point(-1,-1));
            }
            else
            {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                gray = gray0 >= (l+1)*255/N;
            }
            
            // find contours and store them all as a list
            findContours(gray, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
            
            vector<cv::Point> approx;
            
            // test each contour
            for(size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if(approx.size() == 4 && fabs(contourArea(Mat(approx))) > 1000 && isContourConvex(Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for(int j = 2; j < 5; j++)
                    {
                        // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence
                    if(maxCosine < 0.3)
                    {
                        squares.push_back(approx);
                    }
                }
            }
        }
    }
}

// the function draws all the squares in the image
Mat& drawSquares(Mat& image, const vector<vector<cv::Point>>& squares)
{
    for(size_t i = 0; i < squares.size(); i++)
    {
        const cv::Point *p = &squares[i][0];
        
        int n = (int)squares[i].size();
        //dont detect the border
        if(p-> x > 3 && p->y > 3)
        {
            polylines(image, &p, &n, 1, true, Scalar(0,0,255), 6, LINE_AA);
        }
    }
    
    return image;
}

@interface CropImageViewController ()

@property (nonatomic, strong) UIImageView *cropImageView;

@end

@implementation CropImageViewController

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    
    if(self)
    {
        self.image = image;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"crop";
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self createUI];
    
//    [self chulitupian:self.image];
    [self detectQuadrangle:self.image];
}

- (void)detectQuadrangle:(UIImage *)image
{
    Mat imgSrc;
    UIImageToMat(image, imgSrc);
    
    vector<vector<cv::Point>> squares;
    
    findSquares(imgSrc, squares);
    Mat ret = drawSquares(imgSrc, squares);
    
    self.cropImageView.image = MatToUIImage(ret);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
}

// 获取3点角度
- (CGFloat)getAngle:(cv::Point)pt1 pt2:(cv::Point)pt2 pt0:(cv::Point)pt0
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    CGFloat angle = (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
    return angle;
}

- (void)getQuadrangle:(UIImage *)image
{
    Mat src, gray, dst;
    
    UIImageToMat(image, src);
    
//    cvtColor(src, src, CV_RGBA2RGB);
//    
//    // MeanShift滤波，降噪
//    pyrMeanShiftFiltering(src, gray, 30, 10);
    
    // 彩色转灰度
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    //中值滤波
    medianBlur(gray, gray, 7);
    
    // 高斯滤波，降噪
    GaussianBlur(gray, gray, cv::Size(3,3), 2);
    
    //二值化
    threshold(gray, gray, 180, 255, THRESH_BINARY);//转为二值图片，阈值为180
    
    int threshold = 200;
    Canny(gray, gray, threshold, threshold*3, 3, false);
    
    //获取自定义核
    Mat element = getStructuringElement(MORPH_RECT, cv::Size(3, 3));
    //第一个参数MORPH_RECT表示矩形的卷积核，当然还可以选择椭圆形的、交叉型的
    //膨胀操作
    dilate(gray, gray, element, cv::Point(-1,-1), 3, BORDER_CONSTANT, Scalar(1));//实现过程中发现，适当的膨胀很重要
    
//    erode(gray, gray, element);
    
    vector<vector<cv::Point>> contours;
    vector<vector<cv::Point>> f_contours;
    
    //注意第5个参数为CV_RETR_EXTERNAL，只检索外框
    findContours(gray, f_contours, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE); //找轮廓
    
    //求出面积最大的轮廓
    int max_area = 0;
    int index;
    for(int i = 0; i < f_contours.size(); i++)
    {
        double tmparea = fabs(contourArea(f_contours[i]));
        if(tmparea > max_area)
        {
            index = i;
            max_area = tmparea;
        }
    }
    
    contours.push_back(f_contours[index]);
    
    Mat test = Mat::zeros(src.size(), CV_8UC3);
    
    for (int i = 0; i < contours.size(); i++) {
        drawContours(src, contours, i, Scalar(255,0,0), 6, LINE_8);
    }
    
    self.cropImageView.image = MatToUIImage(test);
    return;
}

- (void)pickQuadrangle:(UIImage *)image
{
    Mat src, gray, dst;
    UIImageToMat(image, src);
    
    //转化为灰度图
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    //中值滤波
    medianBlur(gray, gray, 7);
    
    //二值化
    threshold(gray, dst, 180, 255, THRESH_BINARY);//转为二值图片，阈值为180
    
    int thresh = 200, FACTOR = 2.5;
    //边缘检测
    Canny(dst, dst, thresh, thresh*FACTOR, 3, true);
    
    //提取轮廓
    vector<vector<cv::Point>> contours;//储存轮廓
    vector<Vec4i> hierarchy;
    findContours(dst, contours, hierarchy, RETR_CCOMP, CHAIN_APPROX_SIMPLE);//获取轮廓
    
    Mat linePic = Mat::zeros(dst.rows, dst.cols, CV_8UC4);
    for(int index = 0; index < contours.size(); index++)
    {
        drawContours(linePic, contours, index, Scalar(rand() & 255, rand() & 255, rand() & 255), 6, 8/*, hierarchy*/);
    }
    
    vector<vector<cv::Point>> polyContours(contours.size());
    int maxAreaIndex = 0;
    for(int i = 0; i < contours.size(); i++)
    {
        if(contourArea(contours[i]) > contourArea(contours[maxAreaIndex]))
        {
            maxAreaIndex = i;
        }
        approxPolyDP(contours[i], polyContours[i], 10, true);
    }
    
    Mat polyPic = Mat::zeros(src.size(), CV_8UC4);
    drawContours(polyPic, polyContours, maxAreaIndex, Scalar(0,0,255/*rand() & 255, rand() & 255, rand() & 255*/), 6);
    
    //检测该轮廓的凸包
    vector<int>  hull;
    //参数：clockwise=true，顺时针；clockwise=false，逆时针；
    //参数：returnPoints=true，返回凸包点；returnPoints=false，返回凸包索引；
    if(polyContours.size() > 0)
    {
        convexHull(polyContours[maxAreaIndex], hull, false, true);
    }
    
    //把点和多边形添加到原图中查看效果
    for(int i = 0; i < hull.size(); i++)
    {
        Scalar color = Scalar(rand() & 255, rand() & 255, rand() & 255);
        circle(polyPic, polyContours[maxAreaIndex][i], 10, color, 4);
    }
    Mat pic = Mat::zeros(src.size(), CV_8UC4);
    //图片融合
    addWeighted(polyPic, 1.0f, src, 1.0f, 0, pic);
    
    self.cropImageView.image = MatToUIImage(pic);
    return;
    
    Point2f srcPoints[4], dstPoints[4];
    dstPoints[0] = Point2f(0, 0);
    dstPoints[1] = Point2f(src.cols, 0);
    dstPoints[2] = Point2f(src.cols, src.rows);
    dstPoints[3] = Point2f(0, src.rows);
    
    for(int i = 0; i < 4; i++)
    {
        polyContours[maxAreaIndex][i] = Point2f(polyContours[maxAreaIndex][i].x * 4, polyContours[maxAreaIndex][i].y * 4); //恢复坐标到原图
    }
    //对四个点进行排序 分出左上 右上 右下 左下
    bool sorted = false;
    int n = 4;
    while (!sorted)
    {
        for(int i = 1; i < n; i++)
        {
            sorted = true;
            if(polyContours[maxAreaIndex][i-1].x > polyContours[maxAreaIndex][i].x)
            {
                swap(polyContours[maxAreaIndex][i-1], polyContours[maxAreaIndex][i]);
                sorted = false;
            }
        }
        n--;
    }
    
    if(polyContours[maxAreaIndex][0].y < polyContours[maxAreaIndex][1].y)
    {
        srcPoints[0] = polyContours[maxAreaIndex][0];
        srcPoints[3] = polyContours[maxAreaIndex][1];
    }
    else
    {
        srcPoints[0] = polyContours[maxAreaIndex][1];
        srcPoints[3] = polyContours[maxAreaIndex][0];
    }
    
    if(polyContours[maxAreaIndex][9].y < polyContours[maxAreaIndex][10].y)
    {
        srcPoints[1] = polyContours[maxAreaIndex][2];
        srcPoints[2] = polyContours[maxAreaIndex][3];
    }
    else
    {
        srcPoints[1] = polyContours[maxAreaIndex][3];
        srcPoints[2] = polyContours[maxAreaIndex][2];
    }
    
    Mat transMat = getPerspectiveTransform(srcPoints, dstPoints); //得到变换矩阵
    
    warpPerspective(src, dst, transMat, src.size()); //进行坐标变换
    
    self.cropImageView.image = MatToUIImage(dst);
}

//二值化+高斯滤波+膨胀+canny边缘提取
- (void)chulitupian:(UIImage *)image
{
    Mat src, gray, dst;
    UIImageToMat(image, src);
    
    //灰度图片
    cvtColor(src, gray, CV_RGBA2GRAY);
    
    //二值化
    threshold(gray, gray, 200, 255, CV_THRESH_BINARY);
    
    //高斯滤波
    GaussianBlur(gray, gray, cv::Size(5, 5), 0, 0);
    
    //获取自定义核
    Mat element = getStructuringElement(MORPH_RECT, cv::Size(3, 3));
    //第一个参数MORPH_RECT表示矩形的卷积核，当然还可以选择椭圆形的、交叉型的
    //膨胀操作
    dilate(gray, dst, element);//实现过程中发现，适当的膨胀很重要
    
//    [self getMaxContour:dst];
    [self get4Corners:dst];
//    [self test:dst];
}

- (void)test:(cv::Mat &)src
{
    vector<vector<cv::Point>> contours;
    vector<vector<cv::Point>> f_contours;
    
    //注意第5个参数为CV_RETR_EXTERNAL，只检索外框
    findContours(src, f_contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE); //找轮廓
    
    //求出面积最大的轮廓
    int max_area = 0;
    int index = 0;
    for(int i = 0; i < f_contours.size(); i++)
    {
        double tmparea = fabs(contourArea(f_contours[i]));
        if (tmparea > max_area)
        {
            index = i;
            max_area = tmparea;
        }
        
    }
    
    if(f_contours.size() > 0)
    {
        contours.push_back(f_contours[index]);
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"图片识别失败" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
        return;
    }
    
    /// 多边形逼近轮廓 + 获取矩形和圆形边界框
    vector<vector<cv::Point> > contours_poly( contours.size() );
    vector<cv::Rect> boundRect( contours.size() );
    vector<Point2f>center( contours.size() );
    vector<float>radius( contours.size() );
    
    for( int i = 0; i < contours.size(); i++ )
    { approxPolyDP( Mat(contours[i]), contours_poly[i], 3, true );
        boundRect[i] = boundingRect( Mat(contours_poly[i]) );
        minEnclosingCircle( contours_poly[i], center[i], radius[i] );
    }
    
    RNG rng(12345);
    
    /// 画多边形轮廓 + 包围的矩形框 + 圆形框
//    Mat drawing = Mat::zeros(src.size(), CV_8UC3 );
    Mat result;
    UIImageToMat(self.image, result);
    cvtColor(result, result, CV_RGBA2BGR);
    for( int i = 0; i< contours.size(); i++ )
    {
        Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        drawContours( result, contours_poly, i, color, 1, 8, vector<Vec4i>(), 0, cv::Point() );
        rectangle( result, boundRect[i].tl(), boundRect[i].br(), color, 2, 8, 0 );
//        circle( drawing, center[i], (int)radius[i], color, 2, 8, 0 );
    }
//    self.cropImageView.image = MatToUIImage(result);
}

- (void)get4Corners:(cv::Mat &)src
{
    vector<vector<cv::Point>> contours;
    vector<vector<cv::Point>> f_contours;
    
    //注意第5个参数为CV_RETR_EXTERNAL，只检索外框
    findContours(src, f_contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE); //找轮廓
    
    //求出面积最大的轮廓
    int max_area = 0;
    int index = 0;
    for(int i = 0; i < f_contours.size(); i++)
    {
        double tmparea = fabs(contourArea(f_contours[i]));
        if (tmparea > max_area)
        {
            index = i;
            max_area = tmparea;
        }
        
    }
    
    if(f_contours.size() > 0)
    {
        contours.push_back(f_contours[index]);
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"图片识别失败" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
        return;
    }
    
//    int max_x = 0, max_y = 0, min_x = 0, min_y = 0;
//    cv::Point corners[4];
    
    cv::Point leftPoint = contours[0][0];//cv::Point(0, 0);
    cv::Point bottomPoint = contours[0][0];//cv::Point(0, 0);
    cv::Point rightPoint = contours[0][0];//cv::Point(0, 0);
    cv::Point topPoint = contours[0][0];//cv::Point(0, 0);
    
    // 遍历轮廓中的点
    for(int i = 0; i<contours.size(); i++)//遍历每个轮廓
    {
        for(int j = 0; j<contours[i].size(); j++)//遍历轮廓中的所有点
        {
            cv::Point point = contours[i][j];
            // 左边顶点
            if(leftPoint.x > point.x)
            {
                leftPoint = point;
            }
            
            // 底部顶点
            if(bottomPoint.y > point.y)
            {
                bottomPoint = point;
            }
            
            // 右边顶点
            if(rightPoint.x < point.x)
            {
                rightPoint = point;
            }
            
            // 顶部顶点
            if(topPoint.y < point.y)
            {
                topPoint = point;
            }
            
//            cv::Point pointPre = contours[i][j];
//            cv::Point pointNext = contours[i][j + 1];
//            NSLog(@"x=====%d, y=====%d\n", pointPre.x, pointPre.y);
        }
    }
    
    NSLog(@"左边顶点：x=%d y=%d\n",leftPoint.x, leftPoint.y);
    NSLog(@"底部顶点：x=%d y=%d\n",bottomPoint.x, bottomPoint.y);
    NSLog(@"右边顶点：x=%d y=%d\n",rightPoint.x, rightPoint.y);
    NSLog(@"顶部顶点：x=%d y=%d\n",topPoint.x, topPoint.y);
    
//    cv::Point corners[4];
    
    Mat result;
    UIImageToMat(self.image, result);
    cvtColor(result, result, CV_RGBA2BGR);
    
    line(result, leftPoint, bottomPoint, Scalar(0, 255, 0), 5, LINE_8);
    line(result, bottomPoint, rightPoint, Scalar(0, 255, 0), 5, LINE_8);
    line(result, rightPoint, topPoint, Scalar(0, 255, 0), 5, LINE_8);
    line(result, topPoint, leftPoint, Scalar(0, 255, 0), 5, LINE_8);
    
    self.cropImageView.image = MatToUIImage(result);
}

//获取角点
- (void)getCorners:(cv::Mat &)src
{
    int thresh = 200;
    Mat dst, dst_norm,dst_norm_scaled;
    dst = Mat::zeros(src.size(), CV_32FC1);
    
    int blockSize = 2;
    int apertureSize = 3;
    double k = 0.04;
    
    // 检测角点
    cornerHarris(src, dst, blockSize, apertureSize, k, BORDER_DEFAULT);
    
    normalize(dst, dst_norm, 0, 255, NORM_MINMAX, CV_32FC1, Mat());
    convertScaleAbs(dst_norm, dst_norm_scaled);
    // 绘制角点
    for(int j = 0; j < dst_norm.rows; j++)
    {
        for(int i = 0; i < dst_norm.cols; i++)
        {
            if((int) dst_norm.at<float>(j,i) > thresh)
            {
                circle(dst_norm_scaled, cv::Point(i, j), 5, Scalar(0), 2, 8, 0);
                circle(src, cv::Point(i, j), 5,  Scalar(255,0,0), -1, 8, 0);
            }
        }
    }
    
    self.cropImageView.image = MatToUIImage(src);
}

- (void)getMaxContour:(Mat &)src
{
    vector<vector<cv::Point>> contours;
    vector<vector<cv::Point>> f_contours;
//    std::vector<cv::Point> approx2;
    //注意第5个参数为CV_RETR_EXTERNAL，只检索外框
    findContours(src, f_contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE); //找轮廓
    
    //求出面积最大的轮廓
    int max_area = 0;
    int index = 0;
    for(int i = 0; i < f_contours.size(); i++)
    {
        double tmparea = fabs(contourArea(f_contours[i]));
        if (tmparea > max_area)
        {
            index = i;
            max_area = tmparea;
        }
        
    }
    
    if(f_contours.size() > 0)
    {
        contours.push_back(f_contours[index]);
    }
    
    Mat img, dst;
    UIImageToMat(self.image, img);
    cvtColor(img, dst, CV_RGBA2BGR);
    for(int i = 0; i < contours.size(); i++)
    {
        //绘制轮廓的最小外结矩形
        RotatedRect rect = minAreaRect(contours[i]);
        Point2f P[4];
        rect.points(P);
        for(int j=0;j<=3;j++)
        {
            line(dst,P[j],P[(j+1)%4],Scalar(255,0,255),15,LINE_AA);
        }
    }
    
    self.cropImageView.image = MatToUIImage(dst);
    
//    Mat source = src.clone();
//
//    [self find4VerTex:contours source:source];
}

// 截图
- (void)crop:(Mat &)imageMat
{
    Mat srcImg = imageMat.clone();
    cvtColor(srcImg, srcImg, CV_BGR2GRAY);
    threshold(srcImg, srcImg, 150, 255, CV_THRESH_BINARY); //二值化
    
    vector<vector<cv::Point>> contours;
    vector<cv::Vec4i> hierarcy;
    int largest_area = 0;//最大轮廓面积
    int largest_contour_index = 0;//最大轮廓index
    cv::Rect bounding_rect;
    
    findContours(srcImg, contours, hierarcy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    
    RotatedRect box;
    for(int i=0; i<contours.size(); i++)
    {
        double a = contourArea(contours[i], false);
        if(a > largest_area)
        {
            largest_area = a;
            
            // Store the index of largest contour
            largest_contour_index = i;
            
            // Find the bounding rectangle for biggest contour
            bounding_rect = boundingRect(contours[i]);
            
            box = minAreaRect(Mat(contours[i]));
        }
    }
    
    rectangle(srcImg, cv::Point(bounding_rect.x, bounding_rect.y), cv::Point(bounding_rect.x + bounding_rect.width, bounding_rect.y + bounding_rect.height), Scalar(0, 255, 0), 2, 8);
    
    Mat crop = imageMat(bounding_rect);
    
    self.cropImageView.image = MatToUIImage(crop);
}

- (void)find4VerTex:(vector<vector<cv::Point> > &)contours source:(Mat &)src
{
    Mat source = src.clone();
    Mat img = src.clone();
    Mat bkup = src.clone();
    
    vector<cv::Point> tmp = contours[0];
    
    for (int line_type = 1; line_type <= 3; line_type++)
    {
        cout << "line_type: " << line_type << endl;
        Mat black = img.clone();
        black.setTo(0);
        drawContours(black, contours, 0, Scalar(255), line_type);  //注意线的厚度，不要选择太细的
        
        std::vector<Vec4i> lines;
        std::vector<cv::Point2f> corners;
        std::vector<cv::Point2f> approx;
        
        int para = 10;
        int flag = 0;
        int round = 0;
        for (; para < 300; para++)
        {
            cout << "round: " << ++round << endl;
            lines.clear();
            corners.clear();
            approx.clear();
            center = Point2f(0, 0);
            
            cv::HoughLinesP(black, lines, 1, CV_PI / 180, para, 30, 10);
            
            //过滤距离太近的直线
            std::set<int> ErasePt;
            for (int i = 0; i < lines.size(); i++)
            {
                for (int j = i + 1; j < lines.size(); j++)
                {
                    if (IsBadLine(abs(lines[i][0] - lines[j][0]), abs(lines[i][1] - lines[j][1])) && (IsBadLine(abs(lines[i][2] - lines[j][2]), abs(lines[i][3] - lines[j][3]))))
                    {
                        ErasePt.insert(j);//将该坏线加入集合
                    }
                }
            }
            
            int Num = lines.size();
            while (Num != 0)
            {
                std::set<int>::iterator j = ErasePt.find(Num);
                if (j != ErasePt.end())
                {
                    lines.erase(lines.begin() + Num - 1);
                }
                Num--;
            }
            if (lines.size() != 4)
            {
                continue;
            }
            
            //计算直线的交点，保存在图像范围内的部分
            for (int i = 0; i < lines.size(); i++)
            {
                for (int j = i + 1; j < lines.size(); j++)
                {
                    cv::Point2f pt = computeIntersect(lines[i], lines[j]);
                    if (pt.x >= 0 && pt.y >= 0 && pt.x <= src.cols && pt.y <= src.rows)             //保证交点在图像的范围之内
                        corners.push_back(pt);
                }
            }
            if (corners.size() != 4)
            {
                continue;
            }
#if 1
            bool IsGoodPoints = true;
            
            //保证点与点的距离足够大以排除错误点
            for (int i = 0; i < corners.size(); i++)
            {
                for (int j = i + 1; j < corners.size(); j++)
                {
                    int distance = sqrt((corners[i].x - corners[j].x)*(corners[i].x - corners[j].x) + (corners[i].y - corners[j].y)*(corners[i].y - corners[j].y));
                    if (distance < 5)
                    {
                        IsGoodPoints = false;
                    }
                }
            }
            
            if (!IsGoodPoints) continue;
#endif
            cv::approxPolyDP(cv::Mat(corners), approx, cv::arcLength(cv::Mat(corners), true) * 0.02, true);
            
            if (lines.size() == 4 && corners.size() == 4 && approx.size() == 4)
            {
                flag = 1;
                break;
            }
        }
        
        // Get mass center
        for (int i = 0; i < corners.size(); i++)
            center += corners[i];
        center *= (1. / corners.size());
        
        if (flag)
        {
            cout << "we found it!" << endl;
            cv::circle(bkup, corners[0], 3, CV_RGB(255, 0, 0), -1);
            cv::circle(bkup, corners[1], 3, CV_RGB(0, 255, 0), -1);
            cv::circle(bkup, corners[2], 3, CV_RGB(0, 0, 255), -1);
            cv::circle(bkup, corners[3], 3, CV_RGB(255, 255, 255), -1);
            cv::circle(bkup, center, 3, CV_RGB(255, 0, 255), -1);
            
            cout << "corners size" << corners.size() << endl;
            // cv::waitKey();
            
            // bool sort_flag = sort_corners(corners);
            // if (!sort_flag) cout << "fail to sort" << endl;
            
            sortCorners(corners, center);
            cout << "corners size" << corners.size() << endl;
            cout << "tl:" << corners[0] << endl;
            cout << "tr:" << corners[1] << endl;
            cout << "br:" << corners[2] << endl;
            cout << "bl:" << corners[3] << endl;
            
            CalcDstSize(corners);
            
            cv::Mat quad = cv::Mat::zeros(g_dst_hight, g_dst_width, CV_8UC3);
            std::vector<cv::Point2f> quad_pts;
            quad_pts.push_back(cv::Point2f(0, 0));
            quad_pts.push_back(cv::Point2f(quad.cols, 0));
            quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
            
            quad_pts.push_back(cv::Point2f(0, quad.rows));
            
            cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
            cv::warpPerspective(source, quad, transmtx, quad.size());
            
            /*如果需要二值化就解掉注释把*/
            /*
             Mat local,gray;
             cvtColor(quad, gray, CV_RGB2GRAY);
             int blockSize = 25;
             int constValue = 10;
             adaptiveThreshold(gray, local, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, blockSize, constValue);
             imshow("二值化", local);
             */
        }
    }
    
    self.cropImageView.image = MatToUIImage(bkup);
}

- (void)createUI
{
    CGRect rect = self.view.bounds;
    
    self.cropImageView = [[UIImageView alloc] initWithFrame:rect];
    self.cropImageView.backgroundColor = [UIColor whiteColor];
    self.cropImageView.userInteractionEnabled = YES;
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFit;
//    self.cropImageView.image = self.image;
    [self.view addSubview:self.cropImageView];
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

bool sort_corners(std::vector<cv::Point2f>& corners)
{
    std::vector<cv::Point2f> top, bot;
    cv::Point2f tmp_pt;
    std::vector<cv::Point2f> olddata = corners;
    
    if (corners.size() != 4)
    {
        return false;
    }
    
    for (size_t i = 0; i < corners.size(); i++)
    {
        for (size_t j = i + 1; j<corners.size(); j++)
        {
            if (corners[i].y < corners[j].y)
            {
                tmp_pt = corners[i];
                corners[i] = corners[j];
                corners[j] = tmp_pt;
            }
        }
    }
    top.push_back(corners[0]);
    top.push_back(corners[1]);
    bot.push_back(corners[2]);
    bot.push_back(corners[3]);
    if (top.size() == 2 && bot.size() == 2) {
        corners.clear();
        cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
        cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
        cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
        cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
        corners.push_back(tl);
        corners.push_back(tr);
        corners.push_back(br);
        corners.push_back(bl);
        return true;
    }
    else
    {
        corners = olddata;
        return false;
    }
}

cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3];
    int x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2) * (x3 - x4) - (x1 - x2) * (x3*y4 - y3*x4)) / d;
        pt.y = ((x1*y2 - y1*x2) * (y3 - y4) - (y1 - y2) * (x3*y4 - y3*x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

bool IsBadLine(int a, int b)
{
    if (a * a + b * b < 100)
    {
        return true;
    }
    else
    {
        return false;
    }
}

bool x_sort(const Point2f & m1, const Point2f & m2)
{
    return m1.x < m2.x;
}

//确定四个点的中心线
void sortCorners(std::vector<cv::Point2f>& corners, cv::Point2f center)
{
    std::vector<cv::Point2f> top, bot, dst;
    vector<Point2f> backup = corners;
    
    cv::sort(corners, dst, 0);  //注意先按x的大小给4个点排序
    
    for (int i = 0; i < corners.size(); i++)
    {
        if (corners[i].y < center.y && top.size() < 2)    //这里的小于2是为了避免三个顶点都在top的情况
            top.push_back(corners[i]);
        else
            bot.push_back(corners[i]);
    }
    corners.clear();
    
    if (top.size() == 2 && bot.size() == 2)
    {
        cout << "log" << endl;
        cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
        cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
        cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
        cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
        
        
        corners.push_back(tl);
        corners.push_back(tr);
        corners.push_back(br);
        corners.push_back(bl);
    }
    else
    {
        corners = backup;
    }
}

void CalcDstSize(const vector<cv::Point2f>& corners)
{
    int h1 = sqrt((corners[0].x - corners[3].x)*(corners[0].x - corners[3].x) + (corners[0].y - corners[3].y)*(corners[0].y - corners[3].y));
    int h2 = sqrt((corners[1].x - corners[2].x)*(corners[1].x - corners[2].x) + (corners[1].y - corners[2].y)*(corners[1].y - corners[2].y));
    g_dst_hight = MAX(h1, h2);
    
    int w1 = sqrt((corners[0].x - corners[1].x)*(corners[0].x - corners[1].x) + (corners[0].y - corners[1].y)*(corners[0].y - corners[1].y));
    int w2 = sqrt((corners[2].x - corners[3].x)*(corners[2].x - corners[3].x) + (corners[2].y - corners[3].y)*(corners[2].y - corners[3].y));
    g_dst_width = MAX(w1, w2);
}
