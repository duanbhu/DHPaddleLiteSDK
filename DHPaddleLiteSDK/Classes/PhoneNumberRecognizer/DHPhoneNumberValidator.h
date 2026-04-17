//
//  DHPhoneNumberValidator.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHPhoneNumberTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 手机号格式验证器
 * 负责验证文本是否符合各种手机号格式规则
 */
@interface DHPhoneNumberValidator : NSObject

/**
 * 验证并返回手机号类型
 * @param text 待验证的文本
 * @return 手机号类型，如果不是有效手机号则返回 0
 */
+ (DHPhoneNumberType)validatePhoneNumber:(NSString *)text;

/**
 * 验证是否为普通手机号
 * @param text 待验证的文本
 * @return YES 如果是有效的普通手机号
 */
+ (BOOL)isRegularPhoneNumber:(NSString *)text;

/**
 * 验证是否为虚拟转接号
 * @param text 待验证的文本
 * @return YES 如果是有效的虚拟转接号
 */
+ (BOOL)isVirtualPhoneNumber:(NSString *)text;

/**
 * 验证是否为隐私号码
 * @param text 待验证的文本
 * @return YES 如果是有效的隐私号码
 */
+ (BOOL)isPrivacyPhoneNumber:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
