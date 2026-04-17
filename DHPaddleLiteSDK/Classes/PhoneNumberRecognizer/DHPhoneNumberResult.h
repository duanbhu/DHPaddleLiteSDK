//
//  DHPhoneNumberResult.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHPhoneNumberTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 手机号识别结果
 * 包含识别出的手机号文本、类型、置信度和位置信息
 */
@interface DHPhoneNumberResult : NSObject

/**
 * 识别出的手机号文本
 */
@property (nonatomic, copy, readonly) NSString *phoneNumber;

/**
 * 手机号类型
 */
@property (nonatomic, assign, readonly) DHPhoneNumberType type;

/**
 * 置信度分数（0.0-1.0）
 */
@property (nonatomic, assign, readonly) CGFloat confidence;

/**
 * 在图像中的位置索引
 */
@property (nonatomic, assign, readonly) NSInteger index;

/**
 * 初始化方法
 *
 * @param phoneNumber 手机号文本
 * @param type 手机号类型
 * @param confidence 置信度分数
 * @param index 位置索引
 * @return 初始化的结果对象
 */
- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber
                               type:(DHPhoneNumberType)type
                         confidence:(CGFloat)confidence
                              index:(NSInteger)index;

/**
 * 便利构造方法
 */
+ (instancetype)resultWithPhoneNumber:(NSString *)phoneNumber
                                 type:(DHPhoneNumberType)type
                           confidence:(CGFloat)confidence
                                index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
