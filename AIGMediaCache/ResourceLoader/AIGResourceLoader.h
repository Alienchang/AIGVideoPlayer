//
//  AIGResoureLoader.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIGMediaCacheWorker.h"
#import "AIGMediaDownloader.h"

@import AVFoundation;
@protocol AIGResourceLoaderDelegate;

@interface AIGResourceLoader : NSObject
@property (nonatomic, strong) AIGMediaDownloader *mediaDownloader;
@property (nonatomic, strong) AIGMediaCacheWorker *cacheWorker;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, weak) id<AIGResourceLoaderDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

- (void)addRequest:(AVAssetResourceLoadingRequest *)request;
- (void)removeRequest:(AVAssetResourceLoadingRequest *)request;

- (void)cancel;
- (void)asyncLoadArobablyStart:(long long)startOffset size:(long long)size;
@end

@protocol AIGResourceLoaderDelegate <NSObject>
- (void)resourceLoaderData:(NSData *)data;
- (void)resourceLoader:(AIGResourceLoader *)resourceLoader didFailWithError:(NSError *)error;

@end
