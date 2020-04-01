//
//  YJMPPlayerCViewController.m
//  视频播放
//
//  Created by YJExpand on 17/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import "YJMPPlayerCViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface YJMPPlayerCViewController ()
/// 如果使用临时变量保存，则会出现黑屏，使用必须使用全局变量缓存(iOS9.0后，已弃用)
@property (strong ,nonatomic) MPMoviePlayerController *playerController;

@property (weak, nonatomic) IBOutlet UIView *videoView;
@end

@implementation YJMPPlayerCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"MPPlayerController -> 使用";
    
    /// 初始化
    NSURL *localUrl = [YJManager getLocalVideoURL];
    
    self.playerController = [[MPMoviePlayerController alloc] initWithContentURL:localUrl];
    // 播放控件的样式
    self.playerController.controlStyle = MPMovieControlStyleDefault;
    // 是否自动播放
    self.playerController.shouldAutoplay = NO;
    // 播放模式
    self.playerController.repeatMode = MPMovieRepeatModeOne;
    /*----------还有视频时间、大小等等。。自行查看头文件---------*/
    
    // 重点
    [self.videoView addSubview:self.playerController.view];
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    
    [self.playerController stop];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.playerController.view.frame = self.videoView.bounds;
}

- (IBAction)operationClick:(UISegmentedControl *)sender {
    
    switch (sender.selectedSegmentIndex) {
        case 0: // 播放
            [self.playerController prepareToPlay];
            [self.playerController play];
            break;
        case 1: // 暂停
            [self.playerController pause];
            break;
        case 2: // 停止
            [self.playerController stop];
            break;
        default:
            break;
    }
    
}


@end
