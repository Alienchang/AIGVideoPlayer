//
//  AIGVideoPlayerListener.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/13.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#ifndef AIListener_h
#define AIListener_h
#import <UIKit/UIKit.h>
#import "AIGVideoPlayerEnum.h"

/// 正常播放视频写有
@protocol AIGPlayerDelegate <NSObject>
@optional
/// 播放事件回调，error信息可能有网络、鉴权、url不正确等等。。
- (void)playEvent:(AIG_ENUM_PLAYER_STATUS)event
            error:(NSError *)error;

/**
 播放进度回调

 @param progress 进度（百分比）
 @param currentTime 当前进度（时间）
 */
- (void)playProgress:(float)progress
         currentTime:(NSTimeInterval)currentTime;

/**
 视频缓存进度
 */
- (void)cacheProgress:(float)progress;

/**
 缓存结束
 */
- (void)cacheFinished;

/**
 视频缓存进度
 
 @param progress 进度
 @param finished 是否完成
 @param url 缓存的视频地址
 */
- (void)preloadProgress:(float)progress
               finished:(BOOL)finished
                    url:(NSString *)url
              cachePath:(NSString *)path;


/**
 当前接收到的视频数据
 */
- (void)playbackData:(NSData *)data;
@end


#endif /* AIListener_h */
