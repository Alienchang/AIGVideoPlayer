//
//  AIGURLSessionDelegateObject.m
//  UpLive
//
//  Created by Alienchang on 2021/10/9.
//  Copyright © 2021 AsiaInnovations. All rights reserved.
//

#import "AIGURLSessionDelegateObject.h"
static NSInteger kBufferSize = 10 * 1024;

@implementation AIGURLSessionDelegateObject

- (instancetype)initWithDelegate:(id<AIGURLSessionDelegateObjectDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _bufferData = [NSMutableData data];
    }
    return self;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    [self.delegate URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    @synchronized (self.bufferData) {
        [self.bufferData appendData:data];
        if (self.bufferData.length > kBufferSize) {
            NSRange chunkRange = NSMakeRange(0, self.bufferData.length);
            NSData *chunkData = [self.bufferData subdataWithRange:chunkRange];
            [self.bufferData replaceBytesInRange:chunkRange withBytes:NULL length:0];
            [self.delegate URLSession:session dataTask:dataTask didReceiveData:chunkData];
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDataTask *)task
didCompleteWithError:(nullable NSError *)error {
    @synchronized (self.bufferData) {
        if (self.bufferData.length > 0 && !error) {
            NSRange chunkRange = NSMakeRange(0, self.bufferData.length);
            NSData *chunkData = [self.bufferData subdataWithRange:chunkRange];
            [self.bufferData replaceBytesInRange:chunkRange withBytes:NULL length:0];
            [self.delegate URLSession:session dataTask:task didReceiveData:chunkData];
        }
    }
    [self.delegate URLSession:session task:task didCompleteWithError:error];
}

@end
