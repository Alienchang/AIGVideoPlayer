//
//  AIGMediaDownloaderStatus.h
//  UpLive
//
//  Created by Alienchang on 2021/10/9.
//  Copyright © 2021 AsiaInnovations. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIGMediaDownloaderStatus : NSObject
+ (instancetype)shared;

- (void)addURL:(NSURL *)url;
- (void)removeURL:(NSURL *)url;

/**
 return YES if downloading the url source
 */
- (BOOL)containsURL:(NSURL *)url;
- (NSSet *)urls;
@end

NS_ASSUME_NONNULL_END
