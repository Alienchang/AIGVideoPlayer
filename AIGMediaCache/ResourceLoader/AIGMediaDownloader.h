//
//  AIGMediaDownloader.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "AIGContentInfo.h"
@protocol AIGMediaDownloaderDelegate;
@class AIGMediaCacheWorker;

@interface AIGMediaDownloader : NSObject

- (instancetype)initWithURL:(NSURL *)url cacheWorker:(AIGMediaCacheWorker *)cacheWorker;
@property (nonatomic ,readonly) long long currentDownloadEndOffset;
@property (nonatomic ,strong, readonly) NSURL *url;
@property (nonatomic ,weak) id<AIGMediaDownloaderDelegate> delegate;
@property (nonatomic ,strong) AIGContentInfo *info;
@property (nonatomic ,assign) BOOL saveToCache;
@property (nonatomic ,readonly) float progress;
@property (nonatomic, strong) AIGMediaCacheWorker *cacheWorker;
- (void)downloadTaskFromOffset:(unsigned long long)fromOffset
                        length:(unsigned long long)length
                         toEnd:(BOOL)toEnd;
- (void)downloadFromStartToEnd;

- (void)cancel;
- (void)asyncDownloadStartOffset:(long long)offset size:(long long)size;
@end

@protocol AIGMediaDownloaderDelegate <NSObject>

@optional
- (void)mediaDownloader:(AIGMediaDownloader *)downloader didReceiveResponse:(NSURLResponse *)response;
- (void)mediaDownloader:(AIGMediaDownloader *)downloader didReceiveData:(NSData *)data;
- (void)mediaDownloader:(AIGMediaDownloader *)downloader didFinishedWithError:(NSError *)error;

@end
