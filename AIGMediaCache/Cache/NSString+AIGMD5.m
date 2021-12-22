//
//  NSString+AIGMD5.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/25.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import "NSString+AIGMD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (AIGMD5)

- (NSString *)AIG_md5 {
    const char* str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end

