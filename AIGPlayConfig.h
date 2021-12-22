//
//  AIGPlayConfig.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/13.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIGPlayConfig : NSObject
/// 最大视频预加载个数
@property (nonatomic ,assign) NSInteger macCacheCount;
/// 视频缓存时间
@property(nonatomic, assign)  CGFloat   cacheTime;
/// 视频缓存路径
@property (nonatomic ,copy)   NSString  *cachePath;
/// 播放重连时间，单位s
@property (nonatomic ,assign) CGFloat   connectRetryInterval;
/// 重连重试次数
@property (nonatomic ,assign) NSInteger connectRetryCount;
@end

NS_ASSUME_NONNULL_END
