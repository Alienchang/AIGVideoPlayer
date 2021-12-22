//
//  AIGCacheManager.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/25.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import "AIGCacheManager.h"
#import "AIGMediaDownloader.h"
#import "NSString+AIGMD5.h"
#import "AIGMediaDownloaderStatus.h"

NSString *AIGCacheManagerDidUpdateCacheNotification = @"AIGCacheManagerDidUpdateCacheNotification";
NSString *AIGCacheManagerDidFinishCacheNotification = @"AIGCacheManagerDidFinishCacheNotification";

NSString *AIGCacheConfigurationKey = @"AIGCacheConfigurationKey";
NSString *AIGCacheFinishedErrorKey = @"AIGCacheFinishedErrorKey";

static NSString *kMCMediaCacheDirectory;
static NSTimeInterval kMCMediaCacheNotifyInterval;

@implementation AIGCacheManager

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setCacheDirectory:[NSTemporaryDirectory() stringByAppendingPathComponent:@"vimedia"]];
        [self setCacheUpdateNotifyInterval:0.1];
    });
}

+ (void)setCacheDirectory:(NSString *)cacheDirectory {
    kMCMediaCacheDirectory = cacheDirectory;
}

+ (NSString *)cacheDirectory {
    return kMCMediaCacheDirectory;
}

+ (void)setCacheUpdateNotifyInterval:(NSTimeInterval)interval {
    kMCMediaCacheNotifyInterval = interval;
}

+ (NSTimeInterval)cacheUpdateNotifyInterval {
    return kMCMediaCacheNotifyInterval;
}

+ (NSString *)cachedFilePathForURL:(NSURL *)url {
    NSString *pathComponent = [url.absoluteString AIG_md5];
    pathComponent = [pathComponent stringByAppendingPathExtension:url.pathExtension];
    return [[self cacheDirectory] stringByAppendingPathComponent:pathComponent];
}

+ (AIGCacheConfiguration *)cacheConfigurationForURL:(NSURL *)url {
    NSString *filePath = [self cachedFilePathForURL:url];
    AIGCacheConfiguration *configuration = [AIGCacheConfiguration configurationWithFilePath:filePath];
    return configuration;
}

+ (NSArray <NSString *>*)cachedUrls {
    NSArray *files = [self cachedFiles];
    NSMutableArray *urls = [NSMutableArray new];
    for (NSString *file in files) {
        AIGCacheConfiguration *configuration = [AIGCacheConfiguration configurationWithFilePath:file];
        NSString *url = configuration.url.absoluteString;
        [urls addObject:url];
    }
    return urls;
}

+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:error];
    unsigned long long size = 0;
    if (files) {
        for (NSString *path in files) {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:path];
            NSDictionary<NSFileAttributeKey, id> *attribute = [fileManager attributesOfItemAtPath:filePath error:error];
            if (!attribute) {
                size = -1;
                break;
            }
            
            size += [attribute fileSize];
        }
    }
    return size;
}

+ (NSArray <NSString *>*)cachedFiles {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:&error];
    NSMutableArray *fullFilePathes = [NSMutableArray new];
    for (NSString *file in files) {
        if ([file hasSuffix:@"mt_cfg"]) {
            continue;
        } else {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:file];
            [fullFilePathes addObject:filePath];
        }
    }
    return fullFilePathes;
}

+ (void)cleanAllCacheWithError:(NSError **)error {
    // Find downloaing file
    NSMutableSet *downloadingFiles = [NSMutableSet set];
    [[[AIGMediaDownloaderStatus shared] urls] enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *file = [self cachedFilePathForURL:obj];
        [downloadingFiles addObject:file];
        NSString *configurationPath = [AIGCacheConfiguration configurationFilePathForFilePath:file];
        [downloadingFiles addObject:configurationPath];
    }];
    
    // Remove files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:error];
    if (files) {
        for (NSString *path in files) {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:path];
            if ([downloadingFiles containsObject:filePath]) {
                continue;
            }
            if (![fileManager removeItemAtPath:filePath error:error]) {
                break;
            }
        }
    }
}

+ (void)cleanCacheForURL:(NSURL *)url error:(NSError **)error {
    if ([[AIGMediaDownloaderStatus shared] containsURL:url]) {
        NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Clean cache for url `%@` can't be done, because it's downloading", nil), url];
        if (error) {
            *error = [NSError errorWithDomain:@"com.mediadownload" code:2 userInfo:@{NSLocalizedDescriptionKey: description}];
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self cachedFilePathForURL:url];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        if (![fileManager removeItemAtPath:filePath error:error]) {
            return;
        }
    }
    
    NSString *configurationPath = [AIGCacheConfiguration configurationFilePathForFilePath:filePath];
    if ([fileManager fileExistsAtPath:configurationPath]) {
        if (![fileManager removeItemAtPath:configurationPath error:error]) {
            return;
        }
    }
}

+ (BOOL)addCacheFile:(NSString *)filePath forURL:(NSURL *)url error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cachePath = [AIGCacheManager cachedFilePathForURL:url];
    NSString *cacheFolder = [cachePath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:cacheFolder]) {
        if (![fileManager createDirectoryAtPath:cacheFolder
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:error]) {
            return NO;
        }
    }
    
    if (![fileManager copyItemAtPath:filePath toPath:cachePath error:error]) {
        return NO;
    }
    
    if (![AIGCacheConfiguration createAndSaveDownloadedConfigurationForURL:url error:error]) {
        [fileManager removeItemAtPath:cachePath error:nil]; // if remove failed, there is nothing we can do.
        return NO;
    }
    
    return YES;
}

@end
