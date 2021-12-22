//
//  AIGCacheSessionManager.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/25.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AIGCacheSessionManager : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;

+ (instancetype)shared;

@end
