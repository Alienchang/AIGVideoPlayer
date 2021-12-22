//
//  AIGTContentInfo.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/26.
//  Copyright © 2019年 Alienchang. All rights reserved.
//


#import "AIGContentInfo.h"

static NSString *kContentLengthKey = @"kContentLengthKey";
static NSString *kContentTypeKey = @"kContentTypeKey";
static NSString *kByteRangeAccessSupported = @"kByteRangeAccessSupported";

@implementation AIGContentInfo

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@\ncontentLength: %lld\ncontentType: %@\nbyteRangeAccessSupported:%@", NSStringFromClass([self class]), self.contentLength, self.contentType, @(self.byteRangeAccessSupported)];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.contentLength) forKey:kContentLengthKey];
    [aCoder encodeObject:self.contentType forKey:kContentTypeKey];
    [aCoder encodeObject:@(self.byteRangeAccessSupported) forKey:kByteRangeAccessSupported];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _contentLength = [[aDecoder decodeObjectForKey:kContentLengthKey] longLongValue];
        _contentType = [aDecoder decodeObjectForKey:kContentTypeKey];
        _byteRangeAccessSupported = [[aDecoder decodeObjectForKey:kByteRangeAccessSupported] boolValue];
    }
    return self;
}

@end
