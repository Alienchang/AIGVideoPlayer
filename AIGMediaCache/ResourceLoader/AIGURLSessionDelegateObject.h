//
//  AIGURLSessionDelegateObject.h
//  UpLive
//
//  Created by Alienchang on 2021/10/9.
//  Copyright © 2021 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#pragma mark - Class: AIGURLSessionDelegateObject
@protocol  AIGURLSessionDelegateObjectDelegate <NSObject>

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error;

@end


@interface AIGURLSessionDelegateObject : NSObject <NSURLSessionDelegate>

- (instancetype)initWithDelegate:(id<AIGURLSessionDelegateObjectDelegate>)delegate;

@property (nonatomic, weak) id<AIGURLSessionDelegateObjectDelegate> delegate;
@property (nonatomic, strong) NSMutableData *bufferData;

@end

NS_ASSUME_NONNULL_END
