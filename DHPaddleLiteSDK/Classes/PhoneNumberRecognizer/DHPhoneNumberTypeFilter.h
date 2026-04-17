//
//  DHPhoneNumberTypeFilter.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHPhoneNumberTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 手机号类型过滤器
 * 使用位掩码操作检查手机号类型是否匹配指定的类型过滤器
 */
@interface DHPhoneNumberTypeFilter : NSObject

/**
 * 检查手机号类型是否匹配类型过滤器
 *
 * @param phoneType 手机号类型
 * @param types 类型过滤器位掩码
 * @return YES 如果手机号类型包含在类型过滤器中，否则返回 NO
 */
+ (BOOL)matchesTypeFilter:(DHPhoneNumberType)phoneType types:(DHPhoneNumberTypes)types;

@end

NS_ASSUME_NONNULL_END
