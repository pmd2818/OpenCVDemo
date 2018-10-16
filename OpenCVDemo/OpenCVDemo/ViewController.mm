//
//  ViewController.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/16.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgcodecs/imgcodecs_c.h>
#import <opencv2/core/core.hpp>
#import <opencv2/features2d/features2d.hpp>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/calib3d/calib3d.hpp>

#import "UIImage+OpenCV.h"

#import "ViewController.h"

using namespace std;
using namespace cv;

@interface ViewController ()<CvVideoCameraDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) CvVideoCamera *videoCamera;

@property (nonatomic, strong) UIImageView *cropImageView;//截图图片显示
@property (nonatomic, strong) UIImageView *leftTopImageView;//左上角图片
@property (nonatomic, strong) UIImageView *preImageView;//预览页面图片

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor blackColor];
    [self createUI];
    
    UIImage *image = [UIImage imageNamed:@"diaopaizuoxie"];
    
    [self xuanzhuanjietu:image];
}

- (void)xuanzhuanjietu:(UIImage *)image
{
    self.leftTopImageView.image = image;
    
    Mat srcImg;
    UIImageToMat(image, srcImg);
    
    //    Mat dstImg = srcImg.clone();
    
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
    
    float angle = box.angle;
    
    if(box.size.width > box.size.height)
    {
        if(angle<0)
        {
            angle -= 90;
        }
    }
    
    UIImageToMat(image, srcImg);
    
    cv::Point2f center(srcImg.cols / 2, srcImg.rows / 2);
    cv::Mat rot = cv::getRotationMatrix2D(center, angle, 1);
    cv::Rect bbox = cv::RotatedRect(center, srcImg.size(), angle).boundingRect();
    
    rot.at<double>(0, 2) += bbox.width / 2.0 - center.x;
    rot.at<double>(1, 2) += bbox.height / 2.0 - center.y;
    
    cv::Mat dst;
    cv::warpAffine(srcImg, dst, rot, bbox.size());
    
    //    rectangle(srcImg, cv::Point(bounding_rect.x, bounding_rect.y), cv::Point(bounding_rect.x + bounding_rect.width, bounding_rect.y + bounding_rect.height), Scalar(0, 255, 0), 2, 8);
    //
    //    Mat src_mat;
    //    UIImageToMat(image, src_mat);
    //    Mat crop = src_mat(bounding_rect);
    
    [self crop:dst];
    //    self.imgView.image = MatToUIImage(dst);
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

- (double)variance:(Mat)imageSource//(UIImage *)image
{
    Mat imageGrey;
    double meanValue = 0.0;
    
    //    Mat imageSource;
    //    UIImageToMat(image, imageSource);
    cvtColor(imageSource, imageGrey, CV_RGB2GRAY);
    
    //    // -------------------方差方法-------------------
    //    Mat meanValueImage;
    //    Mat meanStdValueImage;
    //
    //    //求灰度图像的标准差
    //    meanStdDev(imageGrey, meanValueImage, meanStdValueImage);
    //    meanValue = meanStdValueImage.at<double>(0, 0);
    //    // -------------------方差方法-------------------
    
    // -------------------梯度方法-------------------
    Mat imageSobel;
    //    Laplacian(imageGrey, imageSobel, CV_16U); // Laplacian梯度方法
    
    Sobel(imageGrey, imageSobel, CV_16U, 1, 1); // Tenengrad梯度方法
    
    //图像的平均灰度
    meanValue = mean(imageSobel)[0];
    // -------------------梯度方法-------------------
    
    return meanValue;
}

#pragma mark - CvVideoCameraDelegate
- (void)processImage:(cv::Mat &)image
{
    double clearValue = [self variance:image];
    
    cout << "clear = "<< clearValue << endl;
    if(clearValue < 2.0f)
    {
        return;
    }
    
    Mat gray;
    Mat mat_image_src = image;
    
    cvtColor(mat_image_src, gray, CV_BGR2GRAY);
    threshold(gray, gray, 200, 255, THRESH_BINARY_INV); //Threshold the gray
    
    int largest_area = 0;
    int largest_contour_index = 0;
    
    cv::Rect bounding_rect;
    vector<vector<cv::Point>> contours; // Vector for storing contour
    vector<Vec4i> hierarchy;
    
    findContours(gray, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    
    // iterate through each contour.
    for(int i = 0; i < contours.size(); i++)
    {
        //  Find the area of contour
        double a = contourArea(contours[i], false);
        if(a > largest_area)
        {
            largest_area = a;
            //            cout<<i<<" area  "<<a<<endl;
            
            // Store the index of largest contour
            largest_contour_index = i;
            
            // Find the bounding rectangle for biggest contour
            bounding_rect = boundingRect(contours[i]);
        }
    }
    
    Scalar color(255, 255, 255);  // color of the contour in the
    //Draw the contour and rectangle
    drawContours(mat_image_src, contours, largest_contour_index, color, CV_FILLED, 8, hierarchy);
    rectangle(mat_image_src, bounding_rect, Scalar(0, 255, 0), 2, 8, 0);
    
    self.cropImageView.image = MatToUIImage(mat_image_src);
}

- (void)createUI
{
    CGRect rect = self.view.bounds;
    rect.origin.y = 55;
    rect.size.height -= rect.origin.y*2;
    
    //显示截取完毕的图片
    self.cropImageView = [[UIImageView alloc] initWithFrame:rect];
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.cropImageView.userInteractionEnabled = YES;
    [self.view addSubview:self.cropImageView];
    
    //左上角图片
    self.leftTopImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 90, 120)];
    self.leftTopImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.leftTopImageView];
    self.leftTopImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(preView:)];
    [self.leftTopImageView addGestureRecognizer:tap];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setTitle:@"拍吊牌" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [startButton setBackgroundColor:[UIColor orangeColor]];
    startButton.frame = CGRectMake(50, 600, 100, 35);
    [startButton addTarget:self action:@selector(startPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn setBackgroundColor:[UIColor orangeColor]];
    closeBtn.frame = CGRectMake(225, 600, 100, 35);
    [closeBtn addTarget:self action:@selector(closePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.cropImageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation=AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    // 拍照
    UIButton *shootButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shootButton setImage:[UIImage imageNamed:@"takePicture"] forState:UIControlStateNormal];
    [shootButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [shootButton setBackgroundColor:[UIColor clearColor]];
    shootButton.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-35)/2, [UIScreen mainScreen].bounds.size.height-45, 35, 35);
    [shootButton addTarget:self action:@selector(shoot:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shootButton];
    
    // 打开相册
    UIButton *albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [albumButton setImage:[UIImage imageNamed:@"openAlbum"] forState:UIControlStateNormal];
    [albumButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [albumButton setBackgroundColor:[UIColor clearColor]];
    albumButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-45, [UIScreen mainScreen].bounds.size.height-35, 25, 25);
    [albumButton addTarget:self action:@selector(openAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:albumButton];
}

//拍照
- (void)shoot:(UIButton *)button
{
    // 创建UIImagePickerController实例
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    // 设置代理
    imagePickerController.delegate = self;
    // 是否显示裁剪框编辑（默认为NO），等于YES的时候，照片拍摄完成可以进行裁剪
    imagePickerController.allowsEditing = YES;
    // 设置照片来源为相机
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    // 设置进入相机时使用前置或后置摄像头
    imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    // 展示选取照片控制器
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

//相册
- (void)openAlbum:(UIButton *)button
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.allowsEditing = YES;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:^{
        NSLog(@"打开相册");
    }];
}

- (void)preView:(UITapGestureRecognizer *)tap
{
    self.preImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.preImageView.backgroundColor = [UIColor whiteColor];
    self.preImageView.userInteractionEnabled = YES;
    self.preImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.preImageView.image = self.leftTopImageView.image;
    [self.view addSubview:self.preImageView];
    [self.view bringSubviewToFront:self.preImageView];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePreView:)];
    [self.preImageView addGestureRecognizer:tap1];
}

- (void)closePreView:(UITapGestureRecognizer *)tap
{
    [self.preImageView removeFromSuperview];
}

- (void)startPressed:(UIButton *)button
{
    [self.videoCamera start];
}

- (void)closePressed:(UIButton *)button
{
    [self.videoCamera stop];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"取消");
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"%@", info);
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.leftTopImageView.image = image;
    //    [self xuanzhuanjietu:image];
    Mat srcImg, canny_output;
    int thresh = 100;
    UIImageToMat(image, srcImg);
    cvtColor(srcImg, srcImg, CV_BGR2GRAY);
    blur(srcImg, srcImg, cv::Size(3, 3));
    //    Canny(srcImg, srcImg, thresh, thresh*2, 3);
    //    Sobel(srcImg, srcImg, CV_8U, 0, 1, 3, 1, 1, BORDER_DEFAULT);
    Mat erodeStruct = getStructuringElement(MORPH_RECT,cv::Size(5,5));
    erode(srcImg, srcImg, erodeStruct);
    self.cropImageView.image = MatToUIImage(srcImg);
    
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"选照片");
    }];
}

- (void)loadImageFinished:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
