//
//  AIGMediaDownloaderStatus.m
//  UpLive
//
//  Created by Alienchang on 2021/10/9.
//  Copyright © 2021 AsiaInnovations. All rights reserved.
//

#import "AIGMediaDownloaderStatus.h"

@interface AIGMediaDownloaderStatus ()

@property (nonatomic ,strong) NSMutableSet *downloadingURLS;
@end

@implementation AIGMediaDownloaderStatus

+ (instancetype)shared {
    static AIGMediaDownloaderStatus *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.downloadingURLS = [NSMutableSet set];
    });
    
    return instance;
}

- (void)addURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        [self.downloadingURLS addObject:url];
    }
}

- (void)removeURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        [self.downloadingURLS removeObject:url];
    }
}

- (BOOL)containsURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        return [self.downloadingURLS containsObject:url];
    }
}

- (NSSet *)urls {
    return [self.downloadingURLS copy];
}

@end
