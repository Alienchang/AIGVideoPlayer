//
//  AIGCacheAction.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AIGCacheAtionType) {
    AIGCacheAtionTypeLocal = 0,
    AIGCacheAtionTypeRemote
};

@interface AIGCacheAction : NSObject

- (instancetype)initWithActionType:(AIGCacheAtionType)actionType range:(NSRange)range;

@property (nonatomic) AIGCacheAtionType actionType;
@property (nonatomic) NSRange range;

@end
