//
//  YJManager.h
//  视频播放
//
//  Created by YJExpand on 17/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YJManager : NSObject

+ (NSURL *)getLocalVideoURL;


+ (NSURL *)getWebVideoURL;
@end

NS_ASSUME_NONNULL_END
