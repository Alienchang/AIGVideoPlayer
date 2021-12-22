//
//  AIGCacheConfiguration.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIGContentInfo.h"

@interface AIGCacheConfiguration : NSObject <NSCopying>

+ (NSString *)configurationFilePathForFilePath:(NSString *)filePath;

+ (instancetype)configurationWithFilePath:(NSString *)filePath;

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, strong) AIGContentInfo *contentInfo;
@property (nonatomic, strong) NSURL *url;

- (NSArray<NSValue *> *)cacheFragments;

/**
 *  cached progress
 */
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) long long downloadedBytes;
@property (nonatomic, readonly) float downloadSpeed; // kb/s

#pragma mark - update API

- (void)save;
- (void)addCacheFragment:(NSRange)fragment;

/**
 *  Record the download speed
 */
- (void)addDownloadedBytes:(long long)bytes spent:(NSTimeInterval)time;

@end

@interface AIGCacheConfiguration (AIGConvenient)

+ (BOOL)createAndSaveDownloadedConfigurationForURL:(NSURL *)url error:(NSError **)error;

@end
