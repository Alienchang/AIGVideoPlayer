//
//  AIGActionWorker.h
//  UpLive
//
//  Created by Alienchang on 2021/10/9.
//  Copyright © 2021 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIGURLSessionDelegateObject.h"
#import "AIGCacheAction.h"
#import "AIGMediaCacheWorker.h"
@class AIGActionWorker;

NS_ASSUME_NONNULL_BEGIN
@protocol AIGActionWorkerDelegate <NSObject>

- (void)actionWorker:(AIGActionWorker *)actionWorker didReceiveResponse:(NSURLResponse *)response;
- (void)actionWorker:(AIGActionWorker *)actionWorker didReceiveData:(NSData *)data isLocal:(BOOL)isLocal;
- (void)actionWorker:(AIGActionWorker *)actionWorker didFinishWithError:(NSError *)error;

@end

@interface AIGActionWorker : NSObject <AIGURLSessionDelegateObjectDelegate>
@property (nonatomic) NSTimeInterval notifyTime;
@property (nonatomic, strong) NSMutableArray<AIGCacheAction *> *actions;
- (instancetype)initWithActions:(NSArray<AIGCacheAction *> *)actions url:(NSURL *)url cacheWorker:(AIGMediaCacheWorker *)cacheWorker;

@property (nonatomic, assign) BOOL canSaveToCache;
@property (nonatomic, weak) id<AIGActionWorkerDelegate> delegate;

- (void)start;
- (void)cancel;

@property (nonatomic, getter=isCancelled) BOOL cancelled;
@property (nonatomic, strong) AIGMediaCacheWorker *cacheWorker;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) AIGURLSessionDelegateObject *sessionDelegateObject;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic) NSInteger startOffset;
@end

NS_ASSUME_NONNULL_END
