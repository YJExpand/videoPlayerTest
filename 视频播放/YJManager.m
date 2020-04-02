//
//  YJManager.m
//  视频播放
//
//  Created by YJExpand on 17/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import "YJManager.h"

@implementation YJManager

/**
 获取本地视频
 1、[[NSBundle mainBundle] URLForResource:@"lol" withExtension:@"mp4"]
 使用该方法获取本地视频必须要在target->Build Phases -> copy bundle resources 添加素材路径
 否则该方法无法获取真实路径
 */
+ (NSURL *)getLocalVideoURL{
    
    NSURL *url;
    int x = arc4random() % 2;
    if (x == 0) {
        url = [[NSBundle mainBundle] URLForResource:@"lin" withExtension:@"mp4"];
    }else{
        url = [[NSBundle mainBundle] URLForResource:@"lol" withExtension:@"mp4"];
    }
    
    return url;
}


+ (NSURL *)getWebVideoURL{
    
    NSURL *url;
    int x = arc4random() % 2;
    if (x == 0) {
        url = [NSURL URLWithString:@"https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4"];
    }else{
        url = [NSURL URLWithString:@"http://flv2.bn.netease.com/videolib3/1606/23/RiTxE9164/SD/RiTxE9164-mobile.mp4"];
    }
    
    
    return url;
}
@end
