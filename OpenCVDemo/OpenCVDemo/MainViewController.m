//
//  MainViewController.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/11/2.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import "MainViewController.h"

#import "TakePhotoViewController.h"
#import "TakePictureViewController.h"

@interface MainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIButton *shootButton;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"扫描吊牌";
    self.navigationController.navigationBar.hidden = NO;
    
    UIImage *image = [UIImage imageNamed:@"background"];
//    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    self.view.layer.contents = (__bridge id _Nullable)(image.CGImage);
    
    [self createUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
}

- (void)createUI
{
    CGRect rect = CGRectMake(([UIScreen mainScreen].bounds.size.width-80)/2, ([UIScreen mainScreen].bounds.size.height-80)/2, 80, 80);
    // 拍照
    _shootButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shootButton setImage:[UIImage imageNamed:@"shoot"] forState:UIControlStateNormal];
    [self.shootButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.shootButton setBackgroundColor:[UIColor clearColor]];
    self.shootButton.frame = rect;
    [self.shootButton addTarget:self action:@selector(shoot:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shootButton];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(action) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    rect.size = CGSizeMake(40, 40);
    rect.origin = CGPointMake(self.view.bounds.size.width - 50, rect.origin.y + 150);
    
    // 打开相册
    UIButton *albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [albumButton setImage:[UIImage imageNamed:@"album"] forState:UIControlStateNormal];
    [albumButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [albumButton setBackgroundColor:[UIColor clearColor]];
    albumButton.frame = rect;//CGRectMake([UIScreen mainScreen].bounds.size.width-45, [UIScreen mainScreen].bounds.size.height-35, 25, 25);
    [albumButton addTarget:self action:@selector(openAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:albumButton];
}

// 按钮动效
- (void)action
{
    // 创建圆形view
    UIView *circleView = [[UIView alloc] init];
    circleView.backgroundColor = [UIColor whiteColor];
    CGRect rect = self.shootButton.frame;
    rect.size.width *= 0.6f;
    rect.size.height *= 0.6f;
    circleView.frame = rect;
    circleView.center = self.shootButton.center;
    
    // 在按钮下面插入动效view
    [self.view insertSubview:circleView belowSubview:self.shootButton];
    circleView.layer.cornerRadius = circleView.frame.size.width * 0.5f;
    
    circleView.layer.masksToBounds = YES;
    
    // 执行动画
    [UIView animateWithDuration:1.0f delay:0.2f options:UIViewAnimationOptionLayoutSubviews animations:^{
        circleView.transform = CGAffineTransformMakeScale(3.0f, 3.0f);
        circleView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [circleView removeFromSuperview];
    }];
}

//拍照
- (void)shoot:(UIButton *)button
{
//    TakePhotoViewController *vc = [[TakePhotoViewController alloc] init];
    TakePictureViewController *vc = [[TakePictureViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
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
    
    //TODO: <调用图片剪切功能>
    
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
