//
//  ALTPlayer.m
//  AIGVideoPlayer
//
//  Created by Alienchang on 2019/3/18.
//  Copyright © 2019年 Alienchang. All rights reserved.
//

#import "AIGVideoPlayer.h"
#import <AVKit/AVKit.h>
#import "AIGMediaCache.h"
#import "AIGMediaCacheWorker.h"

@interface AIGVideoPlayer() <
AIGMediaDownloaderDelegate,
AIGResourceLoaderManagerDelegate
> {
    NSString *_currentPlayUrl;
    CGRect   _playerFrame;
}
@property (nonatomic ,strong) AVPlayer       *player;
@property (nonatomic ,strong) AVPlayerItem   *playerItem;
@property (nonatomic ,strong) UIView         *containView;
@property (nonatomic ,strong) AVPlayerLayer  *playerLayer;
@property (nonatomic ,assign) CGFloat        progress;
@property (nonatomic ,assign) NSTimeInterval loopBeginTime; /// 标记开始循环时间
@property (nonatomic ,assign) NSTimeInterval loopEndTime;   /// 标记开始循环时间
@property (nonatomic ,strong) AVPlayerItemVideoOutput *videoOutput; /// 视频输出对象
@property (nonatomic ,assign) BOOL           seeking;       /// 是否正在seek

/// 视频下载管理器
@property (nonatomic ,strong) AIGResourceLoaderManager *resourceLoaderManager;
@property (nonatomic ,strong) NSMutableArray <AIGMediaDownloader *>*mediaDownloaders;

@property (nonatomic ,assign) float currentVideoCacheProgress;
@end

@implementation AIGVideoPlayer
+ (void)setupCache {
    [AIGCacheManager setCacheDirectory:[NSTemporaryDirectory() stringByAppendingPathComponent:@"AIMedia"]];
}
- (instancetype)initWithFrame:(CGRect)frame
                  containView:(UIView *)containView {
    self = [super init];
    if (self) {
        [self setContainView:containView];
        _playerFrame = frame;
        _resourceLoaderManager = [AIGResourceLoaderManager new];
        [_resourceLoaderManager setDelegate:self];
    }
    return self;
}

- (void)playWithUrl:(NSURL *)url range:(NSRange)range {
    self.playerStatus = ALT_ENUM_PLAYER_PREPARE;
    [self setProgress:0];
    _currentPlayUrl = [url.absoluteString copy];
    [self.resourceLoaderManager cancelLoaders];
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
    }
    
    if ([url.absoluteString containsString:@"http"]) {
        self.playerItem = [self.resourceLoaderManager playerItemWithURL:url];
    } else {
        self.playerItem = [[AVPlayerItem alloc] initWithURL:url];
    }
    self.videoOutput = [AVPlayerItemVideoOutput new];
    [self.playerItem addOutput:self.videoOutput];
    [self.playerItem addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:nil];
    if (self.player) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    } else {
        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        if (@available(iOS 10.0, *)) {
            [self.player setAutomaticallyWaitsToMinimizeStalling:NO];
        }
        __weak typeof(self) weakSelf = self;
        [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:nil usingBlock:^(CMTime time) {
            if (weakSelf.playerStatus == ALT_ENUM_PLAYER_BEGINPLAY)
                weakSelf.playerStatus = ALT_ENUM_PLAYER_PLAYING;
                if ([weakSelf.delegate respondsToSelector:@selector(playProgress:currentTime:)]) {
                    /// 获取当前播放时间
                    float currentTime = (float)CMTimeGetSeconds(weakSelf.playerItem.currentTime);
                    
                    float progress = currentTime / CMTimeGetSeconds(weakSelf.playerItem.duration);
                    if (progress > 1) {
                        progress = 1;
                    }
                    if (progress < 0) {
                        progress = 0;
                    }
                    [weakSelf setProgress:progress];
                    [weakSelf.delegate playProgress:progress currentTime:currentTime];
                }
            
            if (weakSelf.loop && weakSelf.loopBeginTime != 0 && weakSelf.loopEndTime > weakSelf.loopBeginTime) {
                CGFloat currentTime = CMTimeGetSeconds(weakSelf.playerItem.currentTime);
                if (currentTime >= weakSelf.loopEndTime) {
                    [weakSelf pause];
                    [weakSelf seek:weakSelf.loopBeginTime];
                    return;
                }
            }
        }];
    }
    if (!self.playerLayer) {
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        [self.playerLayer setFrame:_playerFrame];
        [self.containView.layer insertSublayer:self.playerLayer atIndex:0];
    }
    
    [self setContentMode:self.contentMode];
    /// 添加事件监听
    [self addNotification];
    [self.player play];
}
- (void)playWithUrl:(NSURL *)url {
    [self playWithUrl:url range:NSMakeRange(0, 0)];
}
- (void)playWithUrlString:(NSString *)urlString {
    [self playWithUrl:[NSURL URLWithString:urlString]];
}

#pragma mark -- private func
- (void)mediaCacheDidChanged:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(cacheProgress:)]) {
        NSDictionary *userInfo = notification.userInfo;
        AIGCacheConfiguration *configuration = userInfo[ALTCacheConfigurationKey];

        if ([configuration.url.absoluteString isEqualToString:self.currentSourceUrl]) {
            NSArray<NSValue *> *cachedFragments = configuration.cacheFragments;
            long long contentLength = configuration.contentInfo.contentLength;
            NSInteger number = 100;
            __weak typeof(self) weakSelf = self;
            [cachedFragments enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSRange range = obj.rangeValue;
                NSInteger length = roundf((range.length / (double)contentLength) * number);
                float progress = length / 100.0;
                [self.delegate cacheProgress:progress];
                [weakSelf setCurrentVideoCacheProgress:progress];
            }];
        }
    }
}

- (void)mediaCacheFinished:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(cacheFinished)]) {
        [self.delegate cacheFinished];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))] && self.playerItem == object) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            /// 获取当前播放视频的fps
            for (AVPlayerItemTrack *track in self.playerItem.tracks) {
                if ([track.assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                    _currentFps = track.assetTrack.nominalFrameRate;
                }
            }
            /// 准备开始播放
            self.playerStatus = ALT_ENUM_PLAYER_BEGINPLAY;
        } else if (self.playerItem.status == AVPlayerItemStatusFailed) {
            _currentFps = 0;
            /// 播放失败
            self.playerStatus = ALT_ENUM_PLAYER_FAILURE;
        } else {
            /// 未知状态
            
        }
    }
}
- (void)addNotification {
    /// 添加视频缓存进度
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaCacheDidChanged:) name:ALTCacheManagerDidUpdateCacheNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaCacheFinished:) name:ALTCacheManagerDidFinishCacheNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}
- (void)playbackFinished:(NSNotification *)notification {
    if ([notification.object isMemberOfClass:[AVPlayerItem class]] && self.playerItem == notification.object) {
        if (self.loop) {
            [self.player seekToTime:CMTimeMake(0, 1)];
            [self.player play];
        } else {
            self.playerStatus = ALT_ENUM_PLAYER_FINISHED;
        }
    }
}

#pragma mark -- public func
- (void)reset {
    _currentPlayUrl = nil;
}
- (void)setContentMode:(ALTVideoFillMode)contentMode {
    _contentMode = contentMode;
    switch (contentMode) {
        case ALTVideoGravityResizeAspect:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
            break;
        case ALTVideoGravityResizeAspectFill:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            break;
        case ALTVideoGravityResize:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
            break;
        default:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
            break;
    }
}

- (void)setPlayerFrame:(CGRect)frame {
    [self.playerLayer setFrame:frame];
}
+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error {
    return [AIGCacheManager calculateCachedSizeWithError:error];
}
+ (void)cleanAllCacheWithError:(NSError **)error {
    [AIGCacheManager cleanAllCacheWithError:error];
}
+ (void)cleanCacheForURL:(NSURL *)url error:(NSError **)error {
    [AIGCacheManager cleanCacheForURL:url error:error];
}
+ (NSArray <NSString *>*)cachedUrls {
    return [AIGCacheManager cachedUrls];
}
+ (NSArray <NSString *>*)cachedFiles {
    return [AIGCacheManager cachedFiles];
}
+ (NSString *)cachePathWithUrlString:(NSString *)urlString {
    return [AIGCacheManager cachedFilePathForURL:[NSURL URLWithString:urlString]];
}
- (void)loopInBegin:(NSTimeInterval)begin
                end:(NSTimeInterval)end {
    [self setLoopBeginTime:begin];
    [self setLoopEndTime:end];
    [self setLoop:YES];
}

- (void)preload:(NSString *)url
    startOffset:(unsigned long long)startOffset
       loadSize:(unsigned long long)size {
    NSURL *temp = [NSURL URLWithString:url];
    AIGMediaCacheWorker *cacheWorker =  [[AIGMediaCacheWorker alloc] initWithURL:temp];
    AIGMediaDownloader *mediaDownloader = [[AIGMediaDownloader alloc] initWithURL:temp cacheWorker:cacheWorker];
    [mediaDownloader setDelegate:self];
    [mediaDownloader downloadTaskFromOffset:startOffset length:size toEnd:NO];
    [self.mediaDownloaders addObject:mediaDownloader];
}
- (void)preload:(NSString *)url
       loadSize:(unsigned long long)size {
    [self preload:url startOffset:0 loadSize:size];
}
- (void)preloadAtOffset:(long long)offset
               loadSize:(long long )size {
    [self.resourceLoaderManager asyncLoadAt:offset size:size videourl:self.currentSourceUrl];
}

- (void)stopNoFinish {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
    self.delegate = nil;
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
    self.playerStatus = ALT_ENUM_PLAYER_FINISHED;
}

- (void)stop {
    [self.playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
    self.playerStatus = ALT_ENUM_PLAYER_FINISHED;
    self.delegate = nil;
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    [self setPlayerLayer:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pause {
    self.playerStatus = ALT_ENUM_PLAYER_PAUSE;
    [self.player pause];
}

- (void)resume {
    self.playerStatus = ALT_ENUM_PLAYER_PLAYING;
    [self.player play];
}

- (void)setMute:(BOOL)mute {
    [self.player setMuted:mute];
}
/// 跳转
- (void)seek:(NSTimeInterval)time {
    if (self.seeking) {
        return;
    }
    [self setSeeking:YES];
    [self.player pause];
    __weak typeof(self) weakSelf = self;
    
    [self.player seekToTime:CMTimeMake(time * 600, 600) toleranceBefore:CMTimeMake(1, 600) toleranceAfter:CMTimeMake(1, 600) completionHandler:^(BOOL finished) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.playerStatus = ALT_ENUM_PLAYER_SEEK_COMPLETED;
        [strongSelf resume];
        [self setSeeking:NO];
    }];
}

- (void)seekAtOffset:(long long)offset  {
    [self stop];
    [self playWithUrl:[NSURL URLWithString:self.currentSourceUrl]];
}

- (UIImage *)videoShort {
    CMTime itemTime = self.playerItem.currentTime;
    CVPixelBufferRef pixelBuffer = [self.videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    UIImage *currentImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return currentImage;
}

/// 播放速率 0.5 - 2 ，超出范围按照极值计算
- (void)setRate:(float)rate {
    _rate = rate;
    [self.player setRate:rate];
}
#pragma mark -- setter
- (void)setLoop:(BOOL)loop {
    _loop = loop;
    if (!loop) {
        _loopBeginTime = 0;
        _loopEndTime = 0;
    }
}
- (void)setPlayerStatus:(ALT_ENUM_PLAYER_STATUS)playerStatus {
    _playerStatus = playerStatus;
    if ([self.delegate respondsToSelector:@selector(playEvent:error:)]) {
        [self.delegate playEvent:playerStatus error:nil];
    }
}

#pragma mark -- getter
- (long long)currentPreloadOffset {
    AIGResourceLoader *resourceLoader = [self.resourceLoaderManager resourceLoaderWithVideoUrl:self.currentSourceUrl];
    return resourceLoader.mediaDownloader.currentDownloadEndOffset;
}

- (NSMutableArray *)mediaDownloaders {
    if (!_mediaDownloaders) {
        _mediaDownloaders = [NSMutableArray new];
    }
    return _mediaDownloaders;
}

- (float)currentCacheProgress {
    return self.currentVideoCacheProgress;
}
- (NSString *)currentSourceUrl {
    return _currentPlayUrl;
}
- (NSTimeInterval)duration {
    return (NSTimeInterval)CMTimeGetSeconds(self.playerItem.duration);
}

- (NSTimeInterval)currentTime {
    return (NSTimeInterval)CMTimeGetSeconds(self.playerItem.currentTime);
}
#pragma mark -- AIGResourceLoaderManagerDelegate
- (void)resourceLoaderManagerLoadData:(NSData *)data {
    if ([self.delegate respondsToSelector:@selector(playbackData:)]) {
        [self.delegate playbackData:data];
    }
}

- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error {
    
}

#pragma mark -- ALTMediaDownloaderDelegate
- (void)mediaDownloader:(AIGMediaDownloader *)downloader didReceiveResponse:(NSURLResponse *)response {
    if ([self.delegate respondsToSelector:@selector(preloadProgress:finished:url:cachePath:)]) {
        [self.delegate preloadProgress:downloader.progress finished:NO url:downloader.url.absoluteString cachePath:downloader.cacheWorker.cacheConfiguration.filePath];
    }
}
- (void)mediaDownloader:(AIGMediaDownloader *)downloader didReceiveData:(NSData *)data {
    if ([self.delegate respondsToSelector:@selector(preloadProgress:finished:url:cachePath:)]) {
        [self.delegate preloadProgress:downloader.progress finished:NO url:downloader.url.absoluteString cachePath:downloader.cacheWorker.cacheConfiguration.filePath];
    }
}
- (void)mediaDownloader:(AIGMediaDownloader *)downloader didFinishedWithError:(NSError *)error {
    if (!error) {
        if ([self.delegate respondsToSelector:@selector(preloadProgress:finished:url:cachePath:)]) {
            [self.delegate preloadProgress:1 finished:YES url:downloader.url.absoluteString cachePath:downloader.cacheWorker.cacheConfiguration.filePath];
        }
        [self.mediaDownloaders removeObject:downloader];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
