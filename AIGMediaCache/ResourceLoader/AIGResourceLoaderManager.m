//
//  AIGResourceLoaderManager.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//
#import "AIGResourceLoaderManager.h"

static NSString *kCacheScheme = @"__ALTMediaCache___:";

@interface AIGResourceLoaderManager () <AIGResourceLoaderDelegate>



@end

@implementation AIGResourceLoaderManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _loaders = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)cleanCache {
    [self.loaders removeAllObjects];
}

- (void)cancelLoaders {
    [self.loaders enumerateKeysAndObjectsUsingBlock:^(id<NSCoding>  _Nonnull key, AIGResourceLoader * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [self.loaders removeAllObjects];
}

- (void)asyncLoadAt:(long long)startOffset size:(long long)size videourl:(NSString *)videoUrl {
    AIGResourceLoader *resourceLoader = [self resourceLoaderWithVideoUrl:videoUrl];
    [resourceLoader asyncLoadArobablyStart:startOffset size:size];
}
- (AIGResourceLoader *)resourceLoaderWithVideoUrl:(NSString *)videoUrl {
    NSString *key = nil;
    if(![videoUrl hasPrefix:kCacheScheme]){
        key = [NSString stringWithFormat:@"%@%@",kCacheScheme,videoUrl];
    } else {
        key = videoUrl;
    }
    AIGResourceLoader *resourceLoader = self.loaders[key];
    return resourceLoader;
}
#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest  {
    NSURL *resourceURL = [loadingRequest.request URL];
    if ([resourceURL.absoluteString hasPrefix:kCacheScheme]) {
        AIGResourceLoader *loader = [self loaderForRequest:loadingRequest];
        if (!loader) {
            NSURL *originURL = nil;
            NSString *originStr = [resourceURL absoluteString];
            originStr = [originStr stringByReplacingOccurrencesOfString:kCacheScheme withString:@""];
            originURL = [NSURL URLWithString:originStr];
            loader = [[AIGResourceLoader alloc] initWithURL:originURL];
            loader.delegate = self;
            NSString *key = [self keyForResourceLoaderWithURL:resourceURL];
            self.loaders[key] = loader;
        }
        [loader addRequest:loadingRequest];
        return YES;
    }
    
    return NO;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    AIGResourceLoader *loader = [self loaderForRequest:loadingRequest];
    [loader removeRequest:loadingRequest];
}

#pragma mark - AIGResourceLoaderDelegate
- (void)resourceLoaderData:(NSData *)data {
    if ([self.delegate respondsToSelector:@selector(resourceLoaderManagerLoadData:)]) {
        [self.delegate resourceLoaderManagerLoadData:data];
    }
}
- (void)resourceLoader:(AIGResourceLoader *)resourceLoader didFailWithError:(NSError *)error {
    [resourceLoader cancel];
    if ([self.delegate respondsToSelector:@selector(resourceLoaderManagerLoadURL:didFailWithError:)]) {
        [self.delegate resourceLoaderManagerLoadURL:resourceLoader.url didFailWithError:error];
    }
}

#pragma mark - Helper
- (NSString *)keyForResourceLoaderWithURL:(NSURL *)requestURL {
    if([[requestURL absoluteString] hasPrefix:kCacheScheme]){
        NSString *s = requestURL.absoluteString;
        return s;
    } else {

    }
    return nil;
}

- (AIGResourceLoader *)loaderForRequest:(AVAssetResourceLoadingRequest *)request {
    NSString *requestKey = [self keyForResourceLoaderWithURL:request.request.URL];
    AIGResourceLoader *loader = self.loaders[requestKey];
    return loader;
}

@end

@implementation AIGResourceLoaderManager (Convenient)

+ (NSURL *)assetURLWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }

    NSURL *assetURL = [NSURL URLWithString:[kCacheScheme stringByAppendingString:[url absoluteString]]];
    return assetURL;
}

- (AVPlayerItem *)playerItemWithURL:(NSURL *)url {
    NSURL *assetURL = [AIGResourceLoaderManager assetURLWithURL:url];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    /// https://www.jianshu.com/p/be0c20e339c4
    [urlAsset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    if ([playerItem respondsToSelector:@selector(setCanUseNetworkResourcesForLiveStreamingWhilePaused:)]) {
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
    }
    return playerItem;
}

@end
