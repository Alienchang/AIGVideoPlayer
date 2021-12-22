//
//  AIGMediaDownloader.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIGMediaDownloader, AVAssetResourceLoadingRequest;
@protocol AIGResourceLoadingRequestWorkerDelegate;

@interface AIGResourceLoadingRequestWorker : NSObject

- (instancetype)initWithMediaDownloader:(AIGMediaDownloader *)mediaDownloader resourceLoadingRequest:(AVAssetResourceLoadingRequest *)request;

@property (nonatomic, weak) id<AIGResourceLoadingRequestWorkerDelegate> delegate;

@property (nonatomic, strong, readonly) AVAssetResourceLoadingRequest *request;

- (void)startWork;
- (void)cancel;
- (void)finish;

@end

@protocol AIGResourceLoadingRequestWorkerDelegate <NSObject>
- (void)resourceLoadingData:(NSData *)data ;
- (void)resourceLoadingRequestWorker:(AIGResourceLoadingRequestWorker *)requestWorker didCompleteWithError:(NSError *)error;

@end
