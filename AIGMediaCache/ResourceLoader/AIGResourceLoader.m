//
//  AIGResoureLoader.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import "AIGResourceLoader.h"
#import "AIGResourceLoadingRequestWorker.h"
#import "AIGMediaDownloaderStatus.h"
NSString * const MCResourceLoaderErrorDomain = @"LSFilePlayerResourceLoaderErrorDomain";

@interface AIGResourceLoader () <AIGResourceLoadingRequestWorkerDelegate>

@property (nonatomic, strong, readwrite) NSURL *url;

@property (nonatomic, strong) NSMutableArray<AIGResourceLoadingRequestWorker *> *pendingRequestWorkers;

@property (nonatomic, getter=isCancelled) BOOL cancelled;

@end

@implementation AIGResourceLoader


- (void)dealloc {
    [_mediaDownloader cancel];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        _cacheWorker = [[AIGMediaCacheWorker alloc] initWithURL:url];
        _mediaDownloader = [[AIGMediaDownloader alloc] initWithURL:url cacheWorker:_cacheWorker];
        _pendingRequestWorkers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use - initWithURL: instead");
    return nil;
}

- (void)addRequest:(AVAssetResourceLoadingRequest *)request {
    if (self.pendingRequestWorkers.count > 0) {
        [self startNoCacheWorkerWithRequest:request];
    } else {
        [self startWorkerWithRequest:request];
    }
}

- (void)removeRequest:(AVAssetResourceLoadingRequest *)request {
    __block AIGResourceLoadingRequestWorker *requestWorker = nil;
    [self.pendingRequestWorkers enumerateObjectsUsingBlock:^(AIGResourceLoadingRequestWorker *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.request == request) {
            requestWorker = obj;
            *stop = YES;
        }
    }];
    if (requestWorker) {
        [requestWorker finish];
        [self.pendingRequestWorkers removeObject:requestWorker];
    }
}

- (void)cancel {
    [self.mediaDownloader cancel];
    [self.pendingRequestWorkers removeAllObjects];
    [[AIGMediaDownloaderStatus shared] removeURL:self.url];
}

- (void)asyncLoadArobablyStart:(long long)startOffset size:(long long)size {
    [self.mediaDownloader asyncDownloadStartOffset:startOffset size:size];
}
#pragma mark - AIGResourceLoadingRequestWorkerDelegate

- (void)resourceLoadingRequestWorker:(AIGResourceLoadingRequestWorker *)requestWorker didCompleteWithError:(NSError *)error {
    [self removeRequest:requestWorker.request];
    if (error && [self.delegate respondsToSelector:@selector(resourceLoader:didFailWithError:)]) {
        [self.delegate resourceLoader:self didFailWithError:error];
    }
    if (self.pendingRequestWorkers.count == 0) {
        [[AIGMediaDownloaderStatus shared] removeURL:self.url];
    }
}

- (void)resourceLoadingData:(NSData *)data {
    if ([self.delegate respondsToSelector:@selector(resourceLoaderData:)]) {
        [self.delegate resourceLoaderData:data];
    }
}

#pragma mark - Helper

- (void)startNoCacheWorkerWithRequest:(AVAssetResourceLoadingRequest *)request {
    [[AIGMediaDownloaderStatus shared] addURL:self.url];
    AIGMediaDownloader *mediaDownloader = [[AIGMediaDownloader alloc] initWithURL:self.url cacheWorker:self.cacheWorker];
    AIGResourceLoadingRequestWorker *requestWorker = [[AIGResourceLoadingRequestWorker alloc] initWithMediaDownloader:mediaDownloader
                                                                                               resourceLoadingRequest:request];
    [self.pendingRequestWorkers addObject:requestWorker];
    requestWorker.delegate = self;
    [requestWorker startWork];
}

- (void)startWorkerWithRequest:(AVAssetResourceLoadingRequest *)request {
    [[AIGMediaDownloaderStatus shared] addURL:self.url];
    AIGResourceLoadingRequestWorker *requestWorker = [[AIGResourceLoadingRequestWorker alloc] initWithMediaDownloader:self.mediaDownloader
                                                                                             resourceLoadingRequest:request];
    [self.pendingRequestWorkers addObject:requestWorker];
    requestWorker.delegate = self;
    [requestWorker startWork];
    
}

- (NSError *)loaderCancelledError {
    NSError *error = [[NSError alloc] initWithDomain:MCResourceLoaderErrorDomain
                                                code:-3
                                            userInfo:@{NSLocalizedDescriptionKey:@"Resource loader cancelled"}];
    return error;
}

@end
