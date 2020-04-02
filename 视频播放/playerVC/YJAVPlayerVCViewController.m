//
//  YJAVPlayerVCViewController.m
//  视频播放
//
//  Created by YJExpand on 17/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import "YJAVPlayerVCViewController.h"
#import <AVKit/AVKit.h>

@interface YJAVPlayerVCViewController ()<AVPlayerViewControllerDelegate>

@end

@implementation YJAVPlayerVCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"YJAVPlayerViewController -> 使用";
    
    
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    
    
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
}


- (IBAction)playBtnClick:(UIButton *)sender {
    /// url
    NSURL *localURL = [YJManager getLocalVideoURL];
    
    AVPlayerViewController *playVC = [[AVPlayerViewController alloc] init];
    
    /// 基本操作都是player , 可参考YJAVPlayerViewController（AVPlayer的使用）
    playVC.player = [AVPlayer playerWithURL:localURL];
    
    // 具体使用参考<AVPlayerViewControllerDelegate>
    playVC.delegate = self;
    
    [playVC.player play];
    
    /*
     可以使用控制器的方式使用，也可以[self.view addSubview:playVC.view],
     设置playVC.view.frame就好了
     */
    [self presentViewController:playVC animated:YES completion:nil];
}

@end
