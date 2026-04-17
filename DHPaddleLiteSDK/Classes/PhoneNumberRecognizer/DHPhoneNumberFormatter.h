//
//  DHPhoneNumberFormatter.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 手机号格式化工具
 * 负责将识别出的手机号格式化为标准输出格式
 */
@interface DHPhoneNumberFormatter : NSObject

/**
 * 格式化普通手机号，去除分隔符
 * @param phoneNumber 原始手机号文本（可能包含空格或横线分隔符）
 * @return 纯数字格式的手机号（11位数字）
 */
+ (NSString *)formatRegularPhoneNumber:(NSString *)phoneNumber;

/**
 * 格式化虚拟转接号，统一输出为"主号码转分机号"格式
 * @param virtualNumber 原始虚拟转接号文本（包含各种分隔符形式）
 * @return 标准格式的虚拟转接号（如：13812345678转123）
 */
+ (NSString *)formatVirtualPhoneNumber:(NSString *)virtualNumber;

/**
 * 格式化隐私号码，统一输出为标准格式
 * @param privacyNumber 原始隐私号码文本（包含各种星号字符）
 * @return 标准格式的隐私号码
 *         格式1（1[3-9]X{asterisk}...{asterisk}XXXX）→ "前3位****后4位"（如：138****1234）
 *         格式2（{asterisk}...{asterisk}XXX(X)）→ "1******后4位"（如：1******1234）
 */
+ (NSString *)formatPrivacyPhoneNumber:(NSString *)privacyNumber;

@end

NS_ASSUME_NONNULL_END
