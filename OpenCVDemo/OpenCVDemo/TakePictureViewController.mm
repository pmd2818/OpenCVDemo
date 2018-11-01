//
//  TakePictureViewController.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/23.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgcodecs/imgcodecs_c.h>

#import "TakePictureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "CropImageViewController.h"
#import "EditImageViewController.h"
#import "SaoMiaoViewController.h"

#import "ProgressView.h"

using namespace std;
using namespace cv;

#define KScreenWidth  [UIScreen mainScreen].bounds.size.width
#define KScreenHeight  [UIScreen mainScreen].bounds.size.height

/**
 * 抓取视频帧数据流拍照片
 */

@interface TakePictureViewController () <UIAlertViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic, strong) AVCaptureDevice *device;

//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property(nonatomic, strong) AVCaptureDeviceInput *input;

//视频输出流
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property(nonatomic, strong)AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;

//图像预览层，实时显示捕获的图像
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

// ------------- UI --------------
//拍照按钮
@property (nonatomic, strong) UIButton *photoButton;

//闪光灯按钮
@property (nonatomic, strong) UIButton *flashButton;

//聚焦
@property (nonatomic, strong) UIView *focusView;

//是否开启闪光灯
@property (nonatomic, assign) BOOL isflashOn;

//进度条
@property (nonatomic, strong) ProgressView *progressView;

@property (nonatomic, strong) UIImage *image;

@end

@implementation TakePictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if([self checkCameraPermission])
    {
        [self customCamera];
        
        [self createUI];
        
        [self focusAtPoint:self.view.center];
    }
}

//状态栏隐藏
- (BOOL)prefersStatusBarHidden
{
    [super prefersStatusBarHidden];
    
    return YES; //YES:隐藏；NO:显示
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
    
    if(!self.session.running)
    {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if(self.session.running)
    {
        [self.session stopRunning];
    }
}

- (void)customCamera
{
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc] init];
    
    if([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080])
    {
        [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
    }
    
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //使用设备初始化输入
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    
    if([self.session canAddInput:self.input])
    {
        [self.session addInput:self.input];
    }
    
    dispatch_queue_t videoQueue = dispatch_queue_create("com.videoQueue", DISPATCH_QUEUE_SERIAL);
    
    // 视频输出
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [self.videoOutput setSampleBufferDelegate:self queue:videoQueue];
    if([self.session canAddOutput:self.videoOutput])
    {
        [self.session addOutput:self.videoOutput];
        _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    
    //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    //开始启动
    [self.session startRunning];
    
    //修改设备的属性，先加锁
    if([self.device lockForConfiguration:nil])
    {
        //闪光灯自动
        if([self.device isFlashModeSupported:AVCaptureFlashModeAuto])
        {
            [self.device setFlashMode:AVCaptureFlashModeOn];
        }
        
        //自动白平衡
        if([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
        {
            [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        
        //解锁
        [self.device unlockForConfiguration];
    }
}

- (void)createUI
{
    self.focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
    self.focusView.layer.borderWidth = 1.0;
    self.focusView.layer.borderColor = [UIColor greenColor].CGColor;
    self.focusView.center = self.view.center;
    [self.view addSubview:self.focusView];
    self.focusView.hidden = YES;
    
    //添加对焦手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
    //返回
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setTitle:@"返回" forState:UIControlStateNormal];
    leftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [leftButton sizeToFit];
    leftButton.center = CGPointMake((KScreenWidth - 60)/2.0/2.0, KScreenHeight-70);
    [leftButton addTarget:self action:@selector(closeCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:leftButton];
    
    //拍照
    self.photoButton = [UIButton new];
    self.photoButton.frame = CGRectMake(KScreenWidth/2.0-30, KScreenHeight-100, 60, 60);
    [self.photoButton setImage:[UIImage imageNamed:@"takePhoto"] forState:UIControlStateNormal];
    [self.photoButton addTarget:self action:@selector(shoot) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.photoButton];
    
    //闪光灯
    self.flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.flashButton setTitle:@"闪光灯关" forState:UIControlStateNormal];
    self.flashButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.flashButton sizeToFit];
    self.flashButton.center = CGPointMake(KScreenWidth - (KScreenWidth - 60)/2.0/2.0, KScreenHeight-70);
    [self.flashButton addTarget:self action:@selector(flashOnOrOff) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: self.flashButton];
    
    //清晰度
    UIView *clarityView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, KScreenWidth, 50.0f)];
    clarityView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:clarityView];
    
    //进度条
    self.progressView = [[ProgressView alloc] initWithFrame:CGRectMake(10, 15, KScreenWidth-20, 20)];
//    self.progressView.progressTintColor = [UIColor redColor];
//    self.progressView.trackTintColor = [UIColor cyanColor];
//    self.progressView.transform = CGAffineTransformMakeScale(1.0, 5.0);
    [clarityView addSubview:self.progressView];
}

- (NSInteger)getRandomNumber:(NSInteger)from to:(NSInteger)to
{
    NSInteger ret = (int)(from + (arc4random() % (to - from + 1)));
    
    return ret;
}

- (void)focusGesture:(UITapGestureRecognizer*)gesture
{
    CGPoint point = [gesture locationInView:gesture.view];
    
    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point
{
    CGSize size = self.view.bounds.size;
    
    // focusPoint 函数后面Point取值范围是取景框左上角（0，0）到取景框右下角（1，1）之间,按这个来但位置就是不对，只能按上面的写法才可以。前面是点击位置的y/PreviewLayer的高度，后面是1-点击位置的x/PreviewLayer的宽度
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1 - point.x/size.width );
    
    if([self.device lockForConfiguration:nil])
    {
        if([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ])
        {
            [self.device setExposurePointOfInterest:focusPoint];
            //曝光量调节
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        _focusView.center = point;
        _focusView.hidden = NO;
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                weakSelf.focusView.hidden = YES;
            }];
        }];
    }
}

#pragma mark - 关闭相机
- (void)closeCamera
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark- 拍照
- (void)shoot
{
    //保存照片到相册
//    [self loadImageFinished:self.image];
    
    //跳转到照片预览裁剪页面
    SaoMiaoViewController *vc = [[SaoMiaoViewController alloc] initWithImage:self.image];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 闪光灯开关
- (void)flashOnOrOff
{
    if([self.device lockForConfiguration:nil])
    {
        if(self.isflashOn)
        {
            if([self.device isFlashModeSupported:AVCaptureFlashModeOff])
            {
                [self.device setFlashMode:AVCaptureFlashModeOff];
                self.isflashOn = NO;
                [self.flashButton setTitle:@"闪光灯关" forState:UIControlStateNormal];
            }
        }
        else
        {
            if([self.device isFlashModeSupported:AVCaptureFlashModeOn])
            {
                [self.device setFlashMode:AVCaptureFlashModeOn];
                self.isflashOn = YES;
                [self.flashButton setTitle:@"闪光灯开" forState:UIControlStateNormal];
            }
        }
        
        [self.device unlockForConfiguration];
    }
}

#pragma mark- 检测相机权限
- (BOOL)checkCameraPermission
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if(authStatus == AVAuthorizationStatusDenied)
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"请打开相机权限" message:@"设置-隐私-相机" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = 100;
        [alertView show];
        return NO;
    }
    else
    {
        return YES;
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0 && alertView.tag == 100)
    {
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        
        if([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    if(buttonIndex == 1 && alertView.tag == 100)
    {
        [self closeCamera];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self.videoConnection == connection)
    {
        NSLog(@"采集到视频");
        
        self.image = [self getImageBySampleBufferref:sampleBuffer];
        
        CGFloat value = [self clarityOfImageWithVariance:self.image];
        
        NSLog(@"\n---------------------\n清晰度 = %f\n---------------------\n\n\n", value);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progressValue = value/100*(KScreenWidth-20);
        });
    }
}

// 丢失帧会调用
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self.videoConnection == connection)
    {
        NSLog(@"采集到视频-丢失帧");
    }
}

// 将视频帧数据转换成图片
- (UIImage *)getImageBySampleBufferref:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    
    NSLog(@"%@", image);
    
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    
    return image;
}

- (void)loadImageFinished:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

//方差算法计算图片清晰度
- (CGFloat)clarityOfImageWithVariance:(UIImage *)image
{
    Mat imageGrey;
    CGFloat varianceValue = 0.0;
    
    Mat imageSource;
    UIImageToMat(image, imageSource);
    cvtColor(imageSource, imageGrey, CV_RGB2GRAY);
    
    // -------------------方差方法-------------------
    Mat meanValueImage;
    Mat meanStdValueImage;
    
    //求灰度图像的标准差
    meanStdDev(imageGrey, meanValueImage, meanStdValueImage);
    varianceValue = meanStdValueImage.at<double>(0, 0);
    // -------------------方差方法-------------------
    
    return varianceValue;
}

//梯度算法计算图片清晰度
- (double)clarityOfImageWithGradient:(UIImage *)image
{
    Mat imageGrey;
    double gradientValue = 0.0;
    
    Mat imageSource;
    UIImageToMat(image, imageSource);
    cvtColor(imageSource, imageGrey, CV_RGB2GRAY);
    
    // -------------------梯度方法-------------------
    Mat imageSobel;
    //Laplacian(imageGrey, imageSobel, CV_16U); // Laplacian梯度方法
    
    Sobel(imageGrey, imageSobel, CV_16U, 1, 1); // Tenengrad梯度方法
    
    //图像的平均灰度
    gradientValue = mean(imageSobel)[0];
    // -------------------梯度方法-------------------
    
    return gradientValue;
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
