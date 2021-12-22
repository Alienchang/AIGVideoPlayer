//
//  AIGMediaDownloader.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//


#import "AIGMediaDownloader.h"
#import "AIGContentInfo.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AIGCacheSessionManager.h"
#import "AIGMediaDownloaderStatus.h"
#import "AIGMediaCacheWorker.h"
#import "AIGCacheManager.h"
#import "AIGCacheAction.h"
#import "AIGURLSessionDelegateObject.h"
#import "AIGActionWorker.h"
#pragma mark - Class: AIGMediaDownloader

@interface AIGMediaDownloader () <AIGActionWorkerDelegate> {
    float _progress;
    long long _currentEndOffset;        // 当前请求数据的尾部
}

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) AIGActionWorker *actionWorker;
@property (nonatomic, assign) unsigned long long totalLength;
@property (nonatomic) BOOL downloadToEnd;

@end

@implementation AIGMediaDownloader

- (void)dealloc {
    [[AIGMediaDownloaderStatus shared] removeURL:self.url];
}

- (instancetype)initWithURL:(NSURL *)url cacheWorker:(AIGMediaCacheWorker *)cacheWorker {
    self = [super init];
    if (self) {
        _saveToCache = YES;
        _url = url;
        _cacheWorker = cacheWorker;
        _info = _cacheWorker.cacheConfiguration.contentInfo;
        [[AIGMediaDownloaderStatus shared] addURL:self.url];
    }
    return self;
}
- (void)asyncDownloadStartOffset:(long long)offset size:(long long)size {
    NSMutableArray *rangeActions = [NSMutableArray new];
    for (AIGCacheAction *action in self.actionWorker.actions) {
        if (action.range.location < offset && (action.range.location + action.range.length) > offset) {
            [rangeActions addObject:action];
            [self.actionWorker.actions removeObject:action];
        }
        if (action.range.location > offset && (action.range.location + action.range.length) < (offset + size)) {
            [rangeActions addObject:action];
            [self.actionWorker.actions removeObject:action];
        }
        if (action.range.location < (offset + size) && (action.range.location + action.range.length) > (offset + size)) {
            [rangeActions addObject:action];
            [self.actionWorker.actions removeObject:action];
            break;
        }
    }
}
- (void)downloadTaskFromOffset:(unsigned long long)fromOffset
                        length:(unsigned long long)length
                         toEnd:(BOOL)toEnd {
    // ---
    NSRange range = NSMakeRange((NSUInteger)fromOffset, length);
    [self setTotalLength:fromOffset + length];
    if (toEnd) {
        range.length = (NSUInteger)self.cacheWorker.cacheConfiguration.contentInfo.contentLength - range.location;
    }
    
    NSArray *actions = [self.cacheWorker cachedDataActionsForRange:range];
    self.actionWorker = [[AIGActionWorker alloc] initWithActions:actions url:self.url cacheWorker:self.cacheWorker];
    self.actionWorker.canSaveToCache = self.saveToCache;
    self.actionWorker.delegate = self;
    [self.actionWorker start];
}

- (void)downloadFromStartToEnd {
    // ---
    self.downloadToEnd = YES;
    NSRange range = NSMakeRange(0, 2);
    NSArray *actions = [self.cacheWorker cachedDataActionsForRange:range];

    self.actionWorker = [[AIGActionWorker alloc] initWithActions:actions url:self.url cacheWorker:self.cacheWorker];
    self.actionWorker.canSaveToCache = self.saveToCache;
    self.actionWorker.delegate = self;
    [self.actionWorker start];
}

- (void)cancel {
    self.actionWorker.delegate = nil;
    [[AIGMediaDownloaderStatus shared] removeURL:self.url];
    [self.actionWorker cancel];
    self.actionWorker = nil;
}

#pragma mark - AIGActionWorkerDelegate

- (void)actionWorker:(AIGActionWorker *)actionWorker didReceiveResponse:(NSURLResponse *)response {
    if (!self.info) {
        AIGContentInfo *info = [AIGContentInfo new];
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)response;
            NSString *acceptRange = HTTPURLResponse.allHeaderFields[@"Accept-Ranges"];
            info.byteRangeAccessSupported = [acceptRange isEqualToString:@"bytes"];
            info.contentLength = [[[HTTPURLResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
        }
        NSString *mimeType = response.MIMEType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        info.contentType = CFBridgingRelease(contentType);
        self.info = info;
        
        NSError *error;
        [self.cacheWorker setContentInfo:info error:&error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(mediaDownloader:didFinishedWithError:)]) {
                [self.delegate mediaDownloader:self didFinishedWithError:error];
            }
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(mediaDownloader:didReceiveResponse:)]) {
        [self.delegate mediaDownloader:self didReceiveResponse:response];
    }
}

- (void)actionWorker:(AIGActionWorker *)actionWorker didReceiveData:(NSData *)data isLocal:(BOOL)isLocal {
    if ([self.delegate respondsToSelector:@selector(mediaDownloader:didReceiveData:)]) {
        _progress = actionWorker.startOffset * 1.0 / self.totalLength;
        [self.delegate mediaDownloader:self didReceiveData:data];
    }
}

- (void)actionWorker:(AIGActionWorker *)actionWorker didFinishWithError:(NSError *)error {
    [[AIGMediaDownloaderStatus shared] removeURL:self.url];
    
    if (!error && self.downloadToEnd) {
        self.downloadToEnd = NO;
        [self downloadTaskFromOffset:2 length:(NSUInteger)(self.cacheWorker.cacheConfiguration.contentInfo.contentLength - 2) toEnd:YES];
    } else {
        if ([self.delegate respondsToSelector:@selector(mediaDownloader:didFinishedWithError:)]) {
            [self.delegate mediaDownloader:self didFinishedWithError:error];
        }
    }
}


#pragma mark -- getter
- (float)progress {
    return _progress;
}
- (long long)currentDownloadEndOffset {
    AIGCacheAction *cacheAction = self.actionWorker.actions.firstObject;
    return cacheAction.range.location - 1;
}
@end
