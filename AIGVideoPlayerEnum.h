//
//  AIGVideoPlayerEnum.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/13.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#ifndef AIEnum_h
#define AIEnum_h

/// 画面填充方式
typedef enum : NSUInteger {
    AIGVideoGravityResizeAspect,
    AIGVideoGravityResizeAspectFill,
    AIGVideoGravityResize,
} AIGVideoFillMode;

/// 视频清晰度选择
typedef NS_ENUM(NSInteger, AIG_ENUM_VIDEO_QUALITY) {
    PLAY_QUALITY_AUTO     = 0,          // 自适应
    PLAY_QUALITY_360_640  = 1,
    PLAY_QUALITY_540_960  = 2,
    PLAY_QUALITY_720_1280 = 3,
};

/// 当前播放器状态
typedef NS_ENUM(NSInteger, AIG_ENUM_PLAYER_STATUS) {
    AIG_ENUM_PLAYER_UNKNOW     = 0,
    AIG_ENUM_PLAYER_PREPARE,        /// 准备播放
    AIG_ENUM_PLAYER_BEGINPLAY,      /// 开始播放
    AIG_ENUM_PLAYER_PLAYING,        /// 播放中
    AIG_ENUM_PLAYER_PAUSE,          /// 暂停
    AIG_ENUM_PLAYER_SEEK_COMPLETED, /// seek完成
    AIG_ENUM_PLAYER_FINISHED,       /// 播放结束
    AIG_ENUM_PLAYER_FAILURE,        /// 播放失败
};


#endif /* AIEnum_h */
