//
//  DHPhoneNumberRecognizer.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import "DHPhoneNumberRecognizer.h"
#import "DHPhoneNumberResult.h"
#import "DHPaddleLiteTextRecognition.h"
#import "DHPhoneNumberValidator.h"
#import "DHOCRErrorCorrector.h"
#import "DHTrackingNumberFilter.h"
#import "DHPhoneNumberFormatter.h"
#import "DHPhoneNumberTypeFilter.h"
#import "DHStreamRecognitionManager.h"
#import "DLTextRecognitionResult.h"



@interface DHPhoneNumberRecognizer ()

/// OCR识别引擎
@property (nonatomic, strong) DHPaddleLiteTextRecognition *ocrEngine;

/// 运单号过滤器
@property (nonatomic, strong) DHTrackingNumberFilter *trackingFilter;

/// 视频流管理器
@property (nonatomic, strong) DHStreamRecognitionManager *streamManager;

/// 是否启用OCR错误修正
@property (nonatomic, assign) BOOL ocrCorrectionEnabled;

/// 当前类型过滤器（用于视频流识别）
@property (nonatomic, assign) DHPhoneNumberTypes currentTypeFilter;

@end

@implementation DHPhoneNumberRecognizer

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static DHPhoneNumberRecognizer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化 DHPaddleLiteTextRecognition 实例
        _ocrEngine = [DHPaddleLiteTextRecognition sharedInstance];
        
        // 初始化运单号过滤器
        _trackingFilter = [[DHTrackingNumberFilter alloc] init];
        
        // 初始化视频流管理器
        _streamManager = [[DHStreamRecognitionManager alloc] init];
        
        // 默认启用OCR错误修正
        _ocrCorrectionEnabled = YES;
        
        // 默认识别所有类型
        _currentTypeFilter = DHPhoneNumberTypesAll;
    }
    return self;
}

#pragma mark - Public Methods - Single Recognition

- (void)recognizePhoneNumbers:(UIImage *)image
                   phoneTypes:(DHPhoneNumberTypes)types
                effectiveArea:(CGRect)rect
                   completion:(void(^)(NSArray<DHPhoneNumberResult *> * _Nullable results, NSError * _Nullable error))completion {
    // 验证输入参数
    if (!image) {
        NSError *error = [NSError errorWithDomain:DHPhoneNumberRecognizerErrorDomain
                                             code:DHPhoneNumberRecognizerErrorCodeInvalidImage
                                         userInfo:@{NSLocalizedDescriptionKey: @"输入图像不能为空"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 验证类型过滤器
    if (types == 0 || (types & ~DHPhoneNumberTypesAll) != 0) {
        NSError *error = [NSError errorWithDomain:DHPhoneNumberRecognizerErrorDomain
                                             code:DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter
                                         userInfo:@{NSLocalizedDescriptionKey: @"无效的手机号类型过滤器"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 在后台线程执行识别操作
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 调用 DHPaddleLiteTextRecognition 进行 OCR 识别
        [self.ocrEngine recognizeImage:image
                        effectiveArea:rect
                           completion:^(NSArray<DLTextRecognitionResult *> * _Nullable ocrResults, NSError * _Nullable ocrError) {
            
            // 如果 OCR 识别失败，传递错误
            if (ocrError) {
                NSError *error = [NSError errorWithDomain:DHPhoneNumberRecognizerErrorDomain
                                                     code:DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed
                                                 userInfo:@{
                                                     NSLocalizedDescriptionKey: @"OCR识别失败",
                                                     NSUnderlyingErrorKey: ocrError
                                                 }];
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            
            // 处理识别结果
            NSArray<DHPhoneNumberResult *> *phoneResults = [self processOCRResults:ocrResults withTypeFilter:types];
            
            // 返回结果
            if (completion) {
                completion(phoneResults, nil);
            }
        }];
    });
}

#pragma mark - Public Methods - Stream Recognition

- (void)startStreamRecognition:(DHPhoneNumberTypes)types
                     frameRate:(NSInteger)framesPerSecond
                      callback:(void(^)(NSArray<DHPhoneNumberResult *> *results))callback {
    // 验证类型过滤器
    if (types == 0 || (types & ~DHPhoneNumberTypesAll) != 0) {
        NSLog(@"[DHPhoneNumberRecognizer] 警告：无效的手机号类型过滤器，使用默认值");
        types = DHPhoneNumberTypesAll;
    }
    
    // 验证帧率参数
    if (framesPerSecond <= 0 || framesPerSecond > 30) {
        NSLog(@"[DHPhoneNumberRecognizer] 警告：无效的帧率参数 %ld，使用默认值 3", (long)framesPerSecond);
        framesPerSecond = 3;
    }
    
    // 保存当前配置
    self.currentTypeFilter = types;
    
    // 配置视频流管理器
    self.streamManager.framesPerSecond = framesPerSecond;
    self.streamManager.callback = callback;
    
    // 启动视频流识别
    [self.streamManager start];
    
    NSLog(@"[DHPhoneNumberRecognizer] 视频流识别已启动，类型过滤器：%ld，帧率：%ld fps", (long)types, (long)framesPerSecond);
}

- (void)processVideoFrame:(CMSampleBufferRef)sampleBuffer {
    // 检查视频流管理器是否正在运行
    if (![self.streamManager shouldProcessFrame]) {
        return; // 跳过此帧
    }
    
    // 检查输入参数
    if (sampleBuffer == NULL) {
        NSLog(@"[DHPhoneNumberRecognizer] 警告：视频帧数据为空，跳过处理");
        return;
    }
    
    // 在后台线程处理视频帧，避免阻塞主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // 将 CMSampleBufferRef 转换为 UIImage
            UIImage *image = [self.streamManager convertSampleBufferToImage:sampleBuffer];
            if (!image) {
                NSLog(@"[DHPhoneNumberRecognizer] 警告：视频帧转换为图像失败，跳过处理");
                return;
            }
            
            // 调用 DHPaddleLiteTextRecognition 进行 OCR 识别
            [self.ocrEngine recognizeImage:image
                            effectiveArea:CGRectZero
                               completion:^(NSArray<DLTextRecognitionResult *> * _Nullable ocrResults, NSError * _Nullable ocrError) {
                
                // 如果 OCR 识别失败，记录错误但不中断处理流程
                if (ocrError) {
                    NSLog(@"[DHPhoneNumberRecognizer] 视频流识别错误：%@", ocrError.localizedDescription);
                    return;
                }
                
                // 处理识别结果
                NSArray<DHPhoneNumberResult *> *phoneResults = [self processOCRResults:ocrResults withTypeFilter:self.currentTypeFilter];
                
                // 过滤已识别的手机号（去重）
                NSMutableArray<DHPhoneNumberResult *> *newResults = [NSMutableArray array];
                for (DHPhoneNumberResult *result in phoneResults) {
                    if (![self.streamManager isPhoneNumberRecognized:result.phoneNumber]) {
                        [newResults addObject:result];
                        [self.streamManager addResult:result];
                    }
                }
                
                // 如果有新的识别结果，触发回调
                if (newResults.count > 0 && self.streamManager.callback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.streamManager.callback([newResults copy]);
                    });
                }
            }];
        } @catch (NSException *exception) {
            // 捕获异常，记录错误但不中断处理流程
            NSLog(@"[DHPhoneNumberRecognizer] 视频帧处理异常：%@", exception.reason);
        }
    });
}

- (void)stopStreamRecognition {
    // 停止视频流管理器
    [self.streamManager stop];
    
    // 重置当前类型过滤器
    self.currentTypeFilter = DHPhoneNumberTypesAll;
    
    NSLog(@"[DHPhoneNumberRecognizer] 视频流识别已停止");
}

#pragma mark - Public Methods - Configuration

- (void)setConfidenceThreshold:(CGFloat)threshold {
    [self.ocrEngine setConfidenceThreshold:threshold];
}

- (void)setOCRCorrectionEnabled:(BOOL)enabled {
    self.ocrCorrectionEnabled = enabled;
}

- (void)setTrackingNumberPrefixes:(NSArray<NSString *> *)prefixes {
    if (prefixes && prefixes.count > 0) {
        self.trackingFilter.prefixes = prefixes;
    }
}

#pragma mark - Private Methods - Result Processing

/**
 * 处理 OCR 识别结果，执行完整的手机号识别流程
 *
 * @param ocrResults OCR 识别结果数组
 * @param types 类型过滤器
 * @return 处理后的手机号识别结果数组
 */
- (NSArray<DHPhoneNumberResult *> *)processOCRResults:(NSArray<DLTextRecognitionResult *> *)ocrResults
                                     withTypeFilter:(DHPhoneNumberTypes)types {
    NSMutableArray<DHPhoneNumberResult *> *phoneResults = [NSMutableArray array];
    
    for (DLTextRecognitionResult *ocrResult in ocrResults) {
        NSString *text = ocrResult.text;
        CGFloat confidence = ocrResult.confidence;
        NSInteger index = ocrResult.index;
        
        // 1. 使用 DHTrackingNumberFilter 过滤运单号（优先剔除明显不是手机号的文本）
        if ([self.trackingFilter isTrackingNumber:text]) {
            continue; // 跳过运单号
        }
        
        // 2. 使用 DHOCRErrorCorrector 修正 OCR 错误（如果启用）
        if (self.ocrCorrectionEnabled) {
            NSDictionary *correctionResult = [DHOCRErrorCorrector correctOCRErrors:text confidence:confidence];
            text = correctionResult[@"text"];
            confidence = [correctionResult[@"confidence"] floatValue];
        }
        
        // 3. 使用 DHPhoneNumberValidator 验证格式并提取手机号类型
        DHPhoneNumberType phoneType = [DHPhoneNumberValidator validatePhoneNumber:text];
        if (phoneType == 0) {
            continue; // 跳过无效格式
        }
        
        // 4. 使用 DHPhoneNumberTypeFilter 过滤类型
        if (![DHPhoneNumberTypeFilter matchesTypeFilter:phoneType types:types]) {
            continue; // 跳过不匹配的类型
        }
        
        // 5. 使用 DHPhoneNumberFormatter 格式化输出
        NSString *formattedPhoneNumber = [self formatPhoneNumber:text withType:phoneType];
        
        // 6. 创建 DHPhoneNumberResult 对象
        DHPhoneNumberResult *result = [[DHPhoneNumberResult alloc] initWithPhoneNumber:formattedPhoneNumber
                                                                              type:phoneType
                                                                        confidence:confidence
                                                                             index:index];
        [phoneResults addObject:result];
    }
    
    // 按位置排序结果（从上到下，从左到右）
    [phoneResults sortUsingComparator:^NSComparisonResult(DHPhoneNumberResult *obj1, DHPhoneNumberResult *obj2) {
        return [@(obj1.index) compare:@(obj2.index)];
    }];
    
    return [phoneResults copy];
}

/**
 * 根据手机号类型格式化手机号
 *
 * @param phoneNumber 原始手机号文本
 * @param type 手机号类型
 * @return 格式化后的手机号
 */
- (NSString *)formatPhoneNumber:(NSString *)phoneNumber withType:(DHPhoneNumberType)type {
    switch (type) {
        case DHPhoneNumberTypeRegular:
            return [DHPhoneNumberFormatter formatRegularPhoneNumber:phoneNumber];
        case DHPhoneNumberTypeVirtual:
            return [DHPhoneNumberFormatter formatVirtualPhoneNumber:phoneNumber];
        case DHPhoneNumberTypePrivacy:
            return [DHPhoneNumberFormatter formatPrivacyPhoneNumber:phoneNumber];
        default:
            return phoneNumber; // 保持原样
    }
}

@end
