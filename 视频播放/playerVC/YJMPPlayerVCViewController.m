//
//  YJMPPlayerVCViewController.m
//  视频播放
//
//  Created by YJExpand on 17/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import "YJMPPlayerVCViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface YJMPPlayerVCViewController ()

//@property (weak, nonatomic) IBOutlet UIView *videoView;
/// iOS9.0后已经废弃，推荐AVPlayer
@property (strong , nonatomic )MPMoviePlayerViewController *playerVC;
@end

@implementation YJMPPlayerVCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"MPPlayerViewController -> 使用";
    
    /// url
    NSURL *localURL = [YJManager getLocalVideoURL];
    
    self.playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:localURL];
    /*
     MPMoviePlayerViewController 简单粗暴，不需要写UI，但是自定义UI不行
     视频的操作都在 MPMoviePlayerViewController.moviePlayer
     具体可以参考《MPPlayerController -> 使用》
     */
    
//    [self.videoView addSubview:self.playerVC.moviePlayer.view];
//    self.playerVC.moviePlayer.view.frame = self.videoView.bounds;
//    [self.playerVC.moviePlayer play];
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    
    [self.playerVC.moviePlayer stop];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
}


- (IBAction)playBtnClick:(UIButton *)sender {
    [self.playerVC.moviePlayer play];
    [self presentViewController:self.playerVC animated:true completion:nil];
}

@end
