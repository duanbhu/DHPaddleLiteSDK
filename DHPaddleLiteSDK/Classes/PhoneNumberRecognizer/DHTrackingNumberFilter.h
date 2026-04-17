//
//  DHTrackingNumberFilter.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 运单号过滤器
 * 用于检测并过滤运单号，避免误识别为手机号
 */
@interface DHTrackingNumberFilter : NSObject

/**
 * 运单号前缀列表
 * 默认包含：YT、ZT、ST、JD、SF、TT、JT
 */
@property (nonatomic, strong) NSArray<NSString *> *prefixes;

/**
 * 初始化方法，使用默认前缀列表
 */
- (instancetype)init;

/**
 * 初始化方法，使用自定义前缀列表
 * @param prefixes 运单号前缀数组
 */
- (instancetype)initWithPrefixes:(NSArray<NSString *> *)prefixes;

/**
 * 检测文本是否为运单号
 * @param text 待检测的文本
 * @return YES 如果是运单号，NO 如果不是
 */
- (BOOL)isTrackingNumber:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
