//
//  ContourDetectionViewController.m
//  OpenCVDemo
//
//  Created by Meide Pan on 2018/10/25.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <math.h>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/core/core.hpp>
#import <opencv2/highgui/highgui.hpp>

//#import "ScanAndCrop.hpp"

#import <iostream>

#import "ContourDetectionViewController.h"

using namespace std;
using namespace cv;

RNG rng(12345);

cv::Point2f center1(0, 0);

//求四个顶点的坐标
// 类函数，Point2f为一个类对象
cv::Point2f computeIntersect1(cv::Vec4i a, cv::Vec4i b);

//确定四个点的中心线
void sortCorners1(std::vector<cv::Point2f>& corners, cv::Point2f center);

#define max_corners 4
#define C CV_PI /3
int Otsu(cv::Mat& src);

@interface ContourDetectionViewController ()

@property (nonatomic, strong) UIImageView *cropImageView;

@end

@implementation ContourDetectionViewController

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
    
    CGRect rect = self.view.bounds;
    
    self.cropImageView = [[UIImageView alloc] initWithFrame:rect];
    self.cropImageView.backgroundColor = [UIColor whiteColor];
    self.cropImageView.userInteractionEnabled = YES;
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFit;
//    self.cropImageView.image = self.image;
    [self.view addSubview:self.cropImageView];
    
    Mat src;
    UIImageToMat(self.image, src);
    Mat gray,dst,norm,scal;
    cvtColor(src, gray, CV_BGR2GRAY);
    vector<Point2f> corners;
    double qualityLevel = 0.01;
    double minDistance = 10;
    int blockSize = 3;
    double k = 0.04;
    Mat copy = src.clone();
    goodFeaturesToTrack(gray, corners, 33, qualityLevel, minDistance, Mat(), blockSize, false, k);
    cv::Size winSize = cv::Size(5, 5);
    cv::Size zeroZone = cv::Size(-1, -1);
    TermCriteria criteria = TermCriteria(CV_TERMCRIT_EPS + CV_TERMCRIT_ITER, 40, 0.001);
    
    /// Calculate the refined corner locations
    cornerSubPix(gray, corners, winSize, zeroZone, criteria);
    
    cvtColor(src, src, CV_RGBA2BGR);
    
    /// Write them down
    for (int i = 0; i < corners.size(); i++)
    {
        circle(src, corners[i], 4, Scalar(0, 255, 0), 2, 8);
    }
    
    self.cropImageView.image = MatToUIImage(src);

    
//    Mat src;
//    UIImageToMat(self.image, src);
//    Mat ret =  scan(src);
//    self.cropImageView.image = MatToUIImage(ret);
}

- (void)getCorners
{
    /***********************寻找轮廓*****************************************************************************************/
    int hull_flag;//用于找最大面积那个凸包（矩形度后）
    
    Mat srcImage = Mat::zeros(600, 800, CV_8UC3);
    Mat srcImage0;// = imread("2.jpg", 0);
    UIImageToMat(self.image, srcImage0);
    resize(srcImage0, srcImage, srcImage.size());
//    srcImage = srcImage > 200;//二值化
    cvtColor(srcImage, srcImage, CV_BGR2GRAY);
    Mat element = getStructuringElement(MORPH_RECT, cv::Size(5, 5));
    morphologyEx(srcImage, srcImage, MORPH_CLOSE, element);//闭运算滤波
    
    vector<vector<cv::Point>> contours;
    findContours(srcImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);//找轮廓
    vector<vector<cv::Point>> hull(contours.size());//用于存放凸包
    Mat drawing(srcImage.size(), CV_8UC1, cv::Scalar(0));
    int i = 0;
    vector<float> length(contours.size());
    vector<float> Area_contours(contours.size()), Area_hull(contours.size()), Area_ratio(contours.size());
    float max = 0.0;
    for(i = 0; i < contours.size(); i++)
    {
        //把所有的轮廓画出来
        length[i] = arcLength(contours[i], true);
        if (length[i] >200 && length[i] <2000)
        {//滤除小轮廓
            convexHull(Mat(contours[i]), hull[i], false);//把凸包找出来
            Area_contours[i] = contourArea(contours[i]);//轮廓面积
            
            Area_hull[i] = contourArea(hull[i]); //最小外接矩形面积，这里用的凸包
            Area_ratio[i] = Area_contours[i] / Area_hull[i];//矩形度
            
        }
    }
    
    for (i = 0; i < contours.size(); i++)
    {
        if (Area_ratio[i]>0.9)
        {
            //drawContours(drawing, contours, i, Scalar(255, 255, 255), 1);
            
            if (max < Area_hull[i])
            {
                max = Area_hull[i];
                hull_flag = i;
            }
        }
    }
    
    Scalar color = Scalar(rng.uniform(0, 255), rng.uniform(0, 255), rng.uniform(0, 255));
    drawContours(drawing, hull[hull_flag], i, color, 3);
    
    /******************************************************************************************/
    
    //hough检测直线
    std::vector<cv::Vec4i> lines;
    cv::HoughLinesP(drawing, lines, 1, CV_PI / 180, 70, 30, 10);
    //1像素分辨能力  1度的角度分辨能力        >70可以检测成连线       30是最小线长
    //在直线L上的点（且点与点之间距离小于maxLineGap=10的）连成线段，然后这些点全部删除，并且记录该线段的参数，就是起始点和终止点
    
    
    
    ////needed for visualization only//这里是将检测的线调整到延长至全屏，即射线的效果，其实可以不必这么做
    //for (unsigned int i = 0; i<lines.size(); i++)
    //{
    //  cv::Vec4i v = lines[i];
    //  lines[i][0] = 0;
    //  lines[i][1] = ((float)v[1] - v[3]) / (v[0] - v[2])* -v[0] + v[1];
    //  lines[i][2] = srcImage.cols;
    //  lines[i][3] = ((float)v[1] - v[3]) / (v[0] - v[2])*(srcImage.cols - v[2]) + v[3];
    
    //}
    
    std::vector<cv::Point2f> corners;//线的交点存储
    for (unsigned int i = 0; i<lines.size(); i++)
    {
        for (unsigned int j = i + 1; j<lines.size(); j++)
        {
            cv::Point2f pt = computeIntersect1(lines[i], lines[j]);
            if (pt.x >= 0 && pt.y >= 0)
            {
                corners.push_back(pt);
            }
        }
    }
    
    std::vector<cv::Point2f> approx;
    cv::approxPolyDP(cv::Mat(corners), approx, cv::arcLength(cv::Mat(corners), true)*0.02, true);
    
    
    //检测是否是四边形，很多图片检测不到
    //if (approx.size() != 4)
    //{
    //  std::cout << "The object is not quadrilateral（四边形）!" << std::endl;
    //  return -1;
    //}
    
    //get mass center
    for (unsigned int i = 0; i < corners.size(); i++)
    {
        center1 += corners[i];
    }
    center1 *= (1. / corners.size());
    
    sortCorners1(corners, center1);//确定四个点的中心线
    
    cv::Mat dst = srcImage.clone();
    
    //Draw Lines
    for (unsigned int i = 0; i<lines.size(); i++)
    {
        cv::Vec4i v = lines[i];
        cv::line(dst, cv::Point(v[0], v[1]), cv::Point(v[2], v[3]), CV_RGB(0, 255, 0));    //目标版块画绿线
    }
    
    //draw corner points
    cv::circle(dst, corners[0], 3, CV_RGB(255, 0, 0), 2);
    cv::circle(dst, corners[1], 3, CV_RGB(0, 255, 0), 2);
    cv::circle(dst, corners[2], 3, CV_RGB(0, 0, 255), 2);
    cv::circle(dst, corners[3], 3, CV_RGB(255, 255, 255), 2);
    
    //draw mass center  集合中心
    cv::circle(dst, center1, 3, CV_RGB(255, 255, 0), 2);
    
    cv::Mat quad = cv::Mat::zeros(600, 800, CV_8UC3);//设定校正过的图片从320*240变为300*220
    
    //corners of the destination image
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, 0));//(220,0)
    quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));//(220,300)
    quad_pts.push_back(cv::Point2f(0, quad.rows));
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);   //求源坐标系（已畸变的）与目标坐标系的转换矩阵
    
    // Apply perspective transformation透视转换
    cv::warpPerspective(srcImage, quad, transmtx, quad.size());
    
    /*cv::namedWindow("src", 0);
     cv::imshow("src", src);
     
     cv::namedWindow("image", 0);
     cv::imshow("image", dst);*/
    
//    cv::namedWindow("透视变换后", 0);
//    cv::imshow("透视变换后", quad);
    self.cropImageView.image = MatToUIImage(quad);
}

//- (void)test
//{
//    Mat src;
//    UIImageToMat([UIImage imageNamed:@"diaopaizuoxie"], src);
//
//    Mat dst = Mat::zeros(src.size(),CV_8UC3);//创建同等大小的画布
//
//    int threshold = Otsu(src);//最大类间方差阈值分割
//    cout << "threshold = %d"<< threshold << endl;
//
//    cv::threshold(src, dst, threshold, 255, CV_THRESH_BINARY);
//
//    CvRect roi = cvRect(30, 30,120,120);//去除复杂背景
//
//    Mat img1 = Mat::zeros(dst.size(),CV_8UC3);//创建同等大小的画布
//
//    for(int y = 0; y < img1.rows; y++)
//    {
//        for(int x = 0; x < img1.cols; x++)
//        {
//            CvScalar cs = (255);
//            cvSet2D(&img1, y, x, cs);
//        }
//    }
//    CvRect roi1 = cvRect(30, 30, 120, 120);
//
//    dst = dst(roi);
//    img1 = img1(roi1);
//    dst.copyTo(img1);
////    dst.release();
////    img1.release();
//
//    Mat edge = Mat::zeros(img1.size(),CV_8UC3);//canny边缘检测
//    int edgeThresh = 1;
//    Canny(img1, edge, edgeThresh, edgeThresh * 3, 3);
//
//    int count = 0;
//    for (int yy = 0; yy < edge.rows; yy++)//统计边缘图像中共有多少个黑色像素点
//    {
//        for (int xx = 0; xx < edge.cols; xx++)
//        {
//            //CvScalar ss = (255);
//            double ds = cvGet2D(&edge, yy, xx).val[0];
//            if (ds == 0)
//                count++;
//        }
//    }
//    int dianshu_threshold = (176*144-count)/ 4;//将白色像素点数的四分之一作为hough变换的阈值
//    IplImage* houghtu = cvCreateImage(cvGetSize(&edge), IPL_DEPTH_8U, 1);//hough直线变换
//    CvMemStorage*storage = cvCreateMemStorage();
//    CvSeq*lines = 0;
//    int i,j,k,m,n;
//    while (true)//循环找出合适的阈值，使检测到的直线的数量在8-12之间
//    {
//        lines = cvHoughLines2(&edge, storage, CV_HOUGH_STANDARD, 1, CV_PI / 180, dianshu_threshold, 0, 0);
//        int line_number = lines->total;
//        if (line_number <8)
//        {
//            dianshu_threshold = dianshu_threshold - 2;
//        }
//        else if (line_number > 12)
//        {
//            dianshu_threshold = dianshu_threshold +1;
//        }
//        else
//        {
//            printf("line_number=%d\n", line_number);
//            break;
//        }
//    }
//
//    int A = 10;
//    double B = CV_PI / 10;
//
//    while (1)
//    {
//        for (i = 0; i <lines->total; i++)//将多条非常相像的直线剔除
//        {
//            for (j = 0; j < lines->total; j++)
//            {
//                if (j != i)
//                {
//                    float*line1 = (float*)cvGetSeqElem(lines, i);
//                    float*line2 = (float*)cvGetSeqElem(lines, j);
//                    float rho1 = line1[0];
//                    float threta1 = line1[1];
//                    float rho2 = line2[0];
//                    float threta2 = line2[1];
//                    if (abs(rho1 - rho2) < A && abs(threta1 - threta2) < B)
//                        cvSeqRemove(lines, j);
//                }
//            }
//        }
//        if (lines->total > 4)//剔除一圈后如何直线的数量大于4，则改变A和B，继续删除相似的直线
//        {
//            A = A + 1;
//            B = B + CV_PI / 180;
//        }
//        else
//        {
//            printf("lines->total=%d\n", lines->total);
//            break;
//        }
//    }
//
//
//
//
//    for (k= 0; k < lines->total; k++)//画出直线
//    {
//        float*line = (float*)cvGetSeqElem(lines, k);
//        float rho = line[0];//r=line[0]
//        float threta = line[1];//threta=line[1]
//        CvPoint pt1, pt2;
//        double a = cos(threta), b = sin(threta);
//        double x0 = a*rho;
//        double y0 = b*rho;
//        pt1.x = cvRound(x0 + 100 * (-b));//定义直线的终点和起点，直线上每一个点应该满足直线方程r=xcos(threta)+ysin(threta);
//        pt1.y = cvRound(y0 + 100 * (a));
//        pt2.x = cvRound(x0 - 1200 * (-b));
//        pt2.y = cvRound(y0 - 1200 * (a));
//        cvLine(houghtu, pt1, pt2, CV_RGB(0, 255, 255), 1, 8);
//    }
//    int num = 0;
//    CvPoint arr[8] = { { 0, 0 } };
//    for (m = 0; m < lines->total; m++)//画出直线的交点
//    {
//        for (n = 0; n < lines->total; n++)
//        {
//            if (n!= m)
//            {
//                float*Line1 = (float*)cvGetSeqElem(lines,m);
//                float*Line2 = (float*)cvGetSeqElem(lines,n);
//                float Rho1 = Line1[0];
//                float Threta1 = Line1[1];
//                float Rho2 =Line2[0];
//                float Threta2 = Line2[1];
//                if (abs(Threta1 - Threta2) > C)
//                {
//                    double a1 = cos(Threta1), b1 = sin(Threta1);
//                    double a2 = cos(Threta2), b2 = sin(Threta2);
//                    CvPoint pt;
//                    pt.x = (Rho2*b1 - Rho1*b2) / (a2*b1 - a1*b2);//直线交点公式
//                    pt.y = (Rho1 - a1*pt.x) / b1;
//                    cvCircle(houghtu, pt, 3, CV_RGB(255, 255, 0));
//                    arr[num++] = pt;//将点的坐标保存在一个数组中
//                }
//            }
//
//        }
//    }
//
//    CvPoint arr1[8] = { { 0, 0 } };//将重复的角点剔除
//    int num1 = 0;
//    for (int r = 0; r < 8; r++)
//    {
//        int s = 0;
//        for (; s < num1; s++)
//        {
//            if (abs(arr[r].x - arr1[s].x) <= 2 && abs(arr[r].y - arr1[s].y) <= 2)
//                break;
//        }
//        if (s == num1)
//        {
//            arr1[num1] = arr[r];
//            num1++;
//        }
//
//    }
//
//    for (int w = 0; w < 4; w++)
//    {
//        CvPoint ps;
//        ps = arr1[w];
//        cvCircle(&src, ps, 3, CV_RGB(255,0,0));
//    }
//
//    src.release();
//    dst.release();
//}
//
//int Otsu(cv::Mat& src)
//{
//    int height = src.rows;
//    int width = src.cols;
//
//    //histogram
//    float histogram[256] = { 0 };
//    for (int i = 0; i < height; i++)
//    {
//        unsigned char* p = (unsigned char*)src.data + src.cols * i;
//        for (int j = 0; j < width; j++)
//        {
//            histogram[*p++]++;
//        }
//    }
//    //normalize histogram
//    int size = height * width;
//    for (int i = 0; i < 256; i++)
//    {
//        histogram[i] = histogram[i] / size;
//    }
//
//    //average pixel value
//    float avgValue = 0;
//    for (int i = 0; i < 256; i++)
//    {
//        avgValue += i * histogram[i];  //整幅图像的平均灰度
//    }
//
//    int threshold = 0;
//    float maxVariance = 0;
//    float w = 0, u = 0;
//    for (int i = 0; i < 256; i++)
//    {
//        w += histogram[i];  //假设当前灰度i为阈值, 0~i 灰度的像素(假设像素值在此范围的像素叫做前景像素) 所占整幅图像的比例
//        u += i * histogram[i];  // 灰度i 之前的像素(0~i)的平均灰度值： 前景像素的平均灰度值
//
//        float t = avgValue * w - u;
//        float variance = t * t / (w * (1 - w));
//        if (variance > maxVariance)
//        {
//            maxVariance = variance;
//            threshold = i;
//        }
//    }
//
//    return threshold;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

#pragma mark - C++

//求四个顶点的坐标
// 类函数，Point2f为一个类对象
cv::Point2f computeIntersect1(cv::Vec4i a, cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3], x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1 * x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3 * x4)) / d;
        pt.y = ((x1*y2 - y1 * x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3 * x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}
//确定四个点的中心线
void sortCorners1(std::vector<cv::Point2f>& corners, cv::Point2f center)
{
    std::vector<cv::Point2f> top, bot;
    
    for (unsigned int i = 0; i< corners.size(); i++)
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
