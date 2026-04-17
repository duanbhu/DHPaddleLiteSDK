//
//  DHPhoneNumberRecognizer.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import "DHPhoneNumberTypes.h"

@class DHPhoneNumberResult;

NS_ASSUME_NONNULL_BEGIN





/**
 * @brief 手机号识别器
 *
 * DHPhoneNumberRecognizer 基于 DHPaddleLiteTextRecognition OCR 能力构建，
 * 提供专用的手机号识别、分类和验证功能。
 *
 * @discussion 主要特性：
 * - 单例模式，全局共享一个实例
 * - 支持三种手机号类型：普通手机号、虚拟转接号、隐私号码
 * - 支持类型过滤，可指定识别特定类型
 * - 自动格式验证和错误修正
 * - 支持单次识别和视频流识别
 * - 智能过滤运单号，避免误识别
 * - 线程安全，支持并发调用
 *
 * @see DHPhoneNumberResult
 * @see DHPhoneNumberType
 */
@interface DHPhoneNumberRecognizer : NSObject

/**
 * @brief 获取单例实例
 *
 * @return DHPhoneNumberRecognizer的单例对象
 *
 * @note 线程安全
 */
+ (instancetype)sharedInstance;

/**
 * @brief 识别图像中的手机号
 *
 * @param image 输入图像，必须为有效的UIImage对象
 * @param types 类型过滤器，指定需要识别的手机号类型
 * @param rect 有效识别区域，传入CGRectZero表示识别整个图像
 * @param completion 完成回调
 *                   - results: 识别结果数组，按位置排序
 *                   - error: 错误对象，识别成功时为nil
 */
- (void)recognizePhoneNumbers:(UIImage *)image
                   phoneTypes:(DHPhoneNumberTypes)types
                effectiveArea:(CGRect)rect
                   completion:(void(^)(NSArray<DHPhoneNumberResult *> * _Nullable results, NSError * _Nullable error))completion;

/**
 * @brief 启动视频流识别
 *
 * @param types 类型过滤器，指定需要识别的手机号类型
 * @param framesPerSecond 每秒处理的帧数
 * @param callback 识别结果回调，当识别到新的手机号时触发
 */
- (void)startStreamRecognition:(DHPhoneNumberTypes)types
                     frameRate:(NSInteger)framesPerSecond
                      callback:(void(^)(NSArray<DHPhoneNumberResult *> *results))callback;

/**
 * @brief 处理视频帧
 *
 * @param sampleBuffer 视频帧数据
 */
- (void)processVideoFrame:(CMSampleBufferRef)sampleBuffer;

/**
 * @brief 停止视频流识别
 */
- (void)stopStreamRecognition;

/**
 * @brief 设置置信度阈值
 *
 * @param threshold 置信度阈值，有效范围为0.0到1.0
 */
- (void)setConfidenceThreshold:(CGFloat)threshold;

/**
 * @brief 设置是否启用OCR错误修正
 *
 * @param enabled YES启用，NO禁用
 */
- (void)setOCRCorrectionEnabled:(BOOL)enabled;

/**
 * @brief 设置运单号前缀黑名单
 *
 * @param prefixes 运单号前缀数组
 */
- (void)setTrackingNumberPrefixes:(NSArray<NSString *> *)prefixes;

@end

NS_ASSUME_NONNULL_END
