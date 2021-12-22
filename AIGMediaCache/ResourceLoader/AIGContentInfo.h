//
//  AIGTContentInfo.h
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface AIGContentInfo : NSObject <NSCoding ,NSSecureCoding>

@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, assign) BOOL byteRangeAccessSupported;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic) unsigned long long downloadedContentLength;

@end
