//
//  AIGMediaCacheWorker.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIGCacheConfiguration.h"

@class AIGCacheAction;

@interface AIGMediaCacheWorker : NSObject
@property (nonatomic ,readonly) long long currentLoadEndOffset;
- (instancetype)initWithURL:(NSURL *)url;

@property (nonatomic, strong, readonly) AIGCacheConfiguration *cacheConfiguration;
@property (nonatomic, strong, readonly) NSError *setupError; // Create fileHandler error, can't save/use cache

- (void)cacheData:(NSData *)data forRange:(NSRange)range error:(NSError **)error;
- (NSArray<AIGCacheAction *> *)cachedDataActionsForRange:(NSRange)range;
- (NSData *)cachedDataForRange:(NSRange)range error:(NSError **)error;

- (void)setContentInfo:(AIGContentInfo *)contentInfo error:(NSError **)error;

- (void)save;

- (void)startWritting;
- (void)finishWritting;

@end
