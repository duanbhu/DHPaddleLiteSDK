//
//  DHStreamRecognitionManager.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@class DHPhoneNumberResult;

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频流识别管理器
 * 负责管理视频流识别过程，包括帧率控制、去重和结果回调
 */
@interface DHStreamRecognitionManager : NSObject

/**
 * 每秒处理的帧数
 * 用于控制视频流识别的帧处理频率，避免过度消耗资源
 */
@property (nonatomic, assign) NSInteger framesPerSecond;

/**
 * 识别结果回调
 * 当识别到新的手机号时触发
 */
@property (nonatomic, copy, nullable) void(^callback)(NSArray<DHPhoneNumberResult *> *results);

/**
 * 启动视频流识别
 */
- (void)start;

/**
 * 停止视频流识别
 * 清理资源和缓存
 */
- (void)stop;

/**
 * 判断是否应该处理当前帧
 * 基于配置的帧率和上次处理时间判断
 * @return YES 如果应该处理当前帧，NO 如果应该跳过
 */
- (BOOL)shouldProcessFrame;

/**
 * 将 CMSampleBufferRef 转换为 UIImage
 * @param sampleBuffer 视频帧数据
 * @return 转换后的 UIImage，如果转换失败返回 nil
 */
- (nullable UIImage *)convertSampleBufferToImage:(CMSampleBufferRef)sampleBuffer;

/**
 * 添加识别结果到缓存
 * 用于去重机制
 * @param result 识别结果
 */
- (void)addResult:(DHPhoneNumberResult *)result;

/**
 * 获取去重后的唯一结果
 * @return 去重后的结果数组
 */
- (NSArray<DHPhoneNumberResult *> *)getUniqueResults;

/**
 * 检查手机号是否已被识别
 * @param phoneNumber 手机号
 * @return YES 如果已识别，NO 如果未识别
 */
- (BOOL)isPhoneNumberRecognized:(NSString *)phoneNumber;

@end

NS_ASSUME_NONNULL_END
