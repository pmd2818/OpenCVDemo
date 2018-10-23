//
//  CropImageViewController.m
//  OpenCVDemo
//
//  Created by boljonggo on 2018/10/18.
//  Copyright © 2018 boljonggo. All rights reserved.
//

#import "CropImageViewController.h"

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
}

- (void)createUI
{
    CGRect rect = self.view.bounds;
    
    self.cropImageView = [[UIImageView alloc] initWithFrame:rect];
    self.cropImageView.backgroundColor = [UIColor whiteColor];
    self.cropImageView.userInteractionEnabled = YES;
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.cropImageView.image = self.image;
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
