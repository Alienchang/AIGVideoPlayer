//
//  AIGCacheSessionManager.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/25.
//  Copyright © 2019年 Alienchang. All rights reserved.
//


#import "AIGCacheSessionManager.h"

@interface AIGCacheSessionManager ()

@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation AIGCacheSessionManager

+ (instancetype)shared {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.name = @"com.AIGMediaCache.download";
        _downloadQueue = queue;
    }
    return self;
}

@end
