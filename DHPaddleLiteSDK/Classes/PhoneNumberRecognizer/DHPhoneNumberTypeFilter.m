//
//  DHPhoneNumberTypeFilter.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import "DHPhoneNumberTypeFilter.h"

@implementation DHPhoneNumberTypeFilter

+ (BOOL)matchesTypeFilter:(DHPhoneNumberType)phoneType types:(DHPhoneNumberTypes)types {
    // 使用位掩码操作检查类型是否匹配
    // 如果 phoneType 的位在 types 中被设置，则返回 YES
    return (phoneType & types) != 0;
}

@end
