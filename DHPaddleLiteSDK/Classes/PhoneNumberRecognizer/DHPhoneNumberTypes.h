//
//  DHPhoneNumberTypes.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 手机号类型枚举
 * 使用位掩码设计，支持组合类型过滤
 */
typedef NS_ENUM(NSInteger, DHPhoneNumberType) {
    /// 普通手机号（11位标准格式）
    DHPhoneNumberTypeRegular = 1 << 0,
    
    /// 虚拟转接号（带分机号）
    DHPhoneNumberTypeVirtual = 1 << 1,
    
    /// 隐私号码（部分隐藏）
    DHPhoneNumberTypePrivacy = 1 << 2,
};

/**
 * 手机号类型位掩码
 * 支持组合多种类型进行过滤
 */
typedef NS_OPTIONS(NSInteger, DHPhoneNumberTypes) {
    /// 识别所有类型
    DHPhoneNumberTypesAll = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual | DHPhoneNumberTypePrivacy,
};

/**
 * 错误域
 */
FOUNDATION_EXPORT NSErrorDomain const DHPhoneNumberRecognizerErrorDomain;

/**
 * 错误码枚举
 */
typedef NS_ENUM(NSInteger, DHPhoneNumberRecognizerErrorCode) {
    /// 输入图像无效
    DHPhoneNumberRecognizerErrorCodeInvalidImage = 2001,
    
    /// OCR 处理失败
    DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed = 2002,
    
    /// 类型过滤器参数无效
    DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter = 2003,
    
    /// 配置参数无效
    DHPhoneNumberRecognizerErrorCodeInvalidConfiguration = 2004,
};

NS_ASSUME_NONNULL_END
