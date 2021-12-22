//
//  AIGResourceLoaderManager.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "AIGResourceLoader.h"

@import AVFoundation;
@protocol AIGResourceLoaderManagerDelegate;

@interface AIGResourceLoaderManager : NSObject <AVAssetResourceLoaderDelegate>
@property (nonatomic, strong) NSMutableDictionary<id<NSCoding>, AIGResourceLoader *> *loaders;
@property (nonatomic, weak) id<AIGResourceLoaderManagerDelegate> delegate;
- (void)asyncLoadAt:(long long)startOffset size:(long long)size videourl:(NSString *)videoUrl;
/**
 Normally you no need to call this method to clean cache. Cache cleaned after AVPlayer delloc.
 If you have a singleton AVPlayer then you need call this method to clean cache at suitable time.
 */
- (void)cleanCache;

/**
 Cancel all downloading loaders.
 */
- (void)cancelLoaders;

- (AIGResourceLoader *)resourceLoaderWithVideoUrl:(NSString *)videoUrl;

@end

@protocol AIGResourceLoaderManagerDelegate <NSObject>
- (void)resourceLoaderManagerLoadData:(NSData *)data;
- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error;


@end

@interface AIGResourceLoaderManager (Convenient)

+ (NSURL *)assetURLWithURL:(NSURL *)url;
- (AVPlayerItem *)playerItemWithURL:(NSURL *)url;

@end
