//
//  DHStreamRecognitionManager.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import "DHStreamRecognitionManager.h"
#import "DHPhoneNumberResult.h"
#import <CoreVideo/CoreVideo.h>

@interface DHStreamRecognitionManager ()

/**
 * 上次处理帧的时间戳
 * 用于计算帧间隔，实现帧率控制
 */
@property (nonatomic, assign) NSTimeInterval lastProcessedFrameTimestamp;

/**
 * 识别结果缓存
 * 用于去重机制，存储已识别的手机号
 */
@property (nonatomic, strong) NSMutableSet<NSString *> *recognizedPhoneNumbers;

/**
 * 是否正在运行
 */
@property (nonatomic, assign) BOOL isRunning;

@end

@implementation DHStreamRecognitionManager

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _framesPerSecond = 3; // 默认每秒处理3帧
        _lastProcessedFrameTimestamp = 0;
        _recognizedPhoneNumbers = [NSMutableSet set];
        _isRunning = NO;
    }
    return self;
}

#pragma mark - Public Methods

- (void)start {
    self.isRunning = YES;
    self.lastProcessedFrameTimestamp = 0;
    [self.recognizedPhoneNumbers removeAllObjects];
}

- (void)stop {
    self.isRunning = NO;
    self.lastProcessedFrameTimestamp = 0;
    [self.recognizedPhoneNumbers removeAllObjects];
    self.callback = nil;
}

- (BOOL)shouldProcessFrame {
    if (!self.isRunning) {
        return NO;
    }
    
    // 获取当前时间戳
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    
    // 计算帧间隔（秒）
    // 如果 framesPerSecond 为 3，则帧间隔为 1/3 = 0.333 秒
    NSTimeInterval frameInterval = 1.0 / (NSTimeInterval)self.framesPerSecond;
    
    // 如果是第一帧，或者距离上次处理已经超过帧间隔，则处理
    if (self.lastProcessedFrameTimestamp == 0 || 
        (currentTimestamp - self.lastProcessedFrameTimestamp) >= frameInterval) {
        self.lastProcessedFrameTimestamp = currentTimestamp;
        return YES;
    }
    
    return NO;
}

- (nullable UIImage *)convertSampleBufferToImage:(CMSampleBufferRef)sampleBuffer {
    if (sampleBuffer == NULL) {
        return nil;
    }
    
    // 获取图像缓冲区
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (imageBuffer == NULL) {
        return nil;
    }
    
    // 锁定像素缓冲区
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // 获取图像信息
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 创建颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 创建位图上下文
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // 创建 CGImage
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // 创建 UIImage
    UIImage *image = nil;
    if (cgImage != NULL) {
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    
    // 清理资源
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    return image;
}

- (void)addResult:(DHPhoneNumberResult *)result {
    if (result && result.phoneNumber) {
        [self.recognizedPhoneNumbers addObject:result.phoneNumber];
    }
}

- (NSArray<DHPhoneNumberResult *> *)getUniqueResults {
    // 此方法返回空数组，因为去重逻辑在外部调用时处理
    // 调用者应该检查 recognizedPhoneNumbers 集合来判断是否已识别
    return @[];
}

#pragma mark - Internal Helper

/**
 * 检查手机号是否已被识别
 * @param phoneNumber 手机号
 * @return YES 如果已识别，NO 如果未识别
 */
- (BOOL)isPhoneNumberRecognized:(NSString *)phoneNumber {
    return [self.recognizedPhoneNumbers containsObject:phoneNumber];
}

@end
