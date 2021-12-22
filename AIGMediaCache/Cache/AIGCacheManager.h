//
//  AIGCacheManager.h
//  AIGVideoPlayer
//  Created by Alienchang on 2019/3/25.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIGCacheConfiguration.h"

extern NSString *AIGCacheManagerDidUpdateCacheNotification;
extern NSString *AIGCacheManagerDidFinishCacheNotification;

extern NSString *AIGCacheConfigurationKey;
extern NSString *AIGCacheFinishedErrorKey;

@interface AIGCacheManager : NSObject

+ (void)setCacheDirectory:(NSString *)cacheDirectory;
+ (NSString *)cacheDirectory;
+ (NSArray <NSString *>*)cachedFiles;
+ (NSArray <NSString *>*)cachedUrls;

/**
 How often trigger `AIGCacheManagerDidUpdateCacheNotification` notification

 @param interval Minimum interval
 */
+ (void)setCacheUpdateNotifyInterval:(NSTimeInterval)interval;
+ (NSTimeInterval)cacheUpdateNotifyInterval;

+ (NSString *)cachedFilePathForURL:(NSURL *)url;
+ (AIGCacheConfiguration *)cacheConfigurationForURL:(NSURL *)url;


/**
 Calculate cached files size

 @param error If error not empty, calculate failed
 @return files size, respresent by `byte`, if error occurs, return -1
 */
+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error;
+ (void)cleanAllCacheWithError:(NSError **)error;
+ (void)cleanCacheForURL:(NSURL *)url error:(NSError **)error;


/**
 Useful when you upload a local file to the server

 @param filePath local file path
 @param url remote resource url
 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information.
 */
+ (BOOL)addCacheFile:(NSString *)filePath forURL:(NSURL *)url error:(NSError **)error;

@end
