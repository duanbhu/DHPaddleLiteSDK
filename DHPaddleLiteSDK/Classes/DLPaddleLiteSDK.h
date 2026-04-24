//
//  DLPaddleLiteSDK.h
//  Pole
//
//  Created by Duanhu on 2023/3/20.
//  Copyright © 2023 刘伟. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief 手机号识别类型
 *
 * 定义了可以识别的手机号类型，支持按位组合
 */
typedef NS_OPTIONS(NSUInteger, DLPaddleLiteMatchType) {
    /// 标准手机号（11位数字）
    DLPaddleLiteMatchTypePhone = 1 << 0,
    /// 虚拟手机号（带分机号）
    DLPaddleLiteMatchTypeVirtualPhone = 1 << 1,
    /// 隐私手机号（带*号）
    DLPaddleLiteMatchTypePrivatePhone = 1 << 2,
    /// 所有类型
    DLPaddleLiteMatchTypePhoneAll = (DLPaddleLiteMatchTypePhone | DLPaddleLiteMatchTypeVirtualPhone | DLPaddleLiteMatchTypePrivatePhone)
};

NS_ASSUME_NONNULL_BEGIN

/// 标准手机号结果键
UIKIT_EXTERN NSString *const kKeyPhone;

/// 隐私号码结果键
UIKIT_EXTERN NSString *const kKeyPrivacyNumber;

/// 虚拟手机号结果键
UIKIT_EXTERN NSString *const kKeyVirtualPhone;

/**
 * @brief 手机号识别 SDK
 *
 * DLPaddleLiteSDK 基于 DHPaddleLiteTextRecognition 提供专门的手机号识别功能。
 * 该 SDK 使用 OCR 技术识别图像中的手机号码，支持标准手机号、隐私号和虚拟号。
 *
 * @discussion 主要特性：
 * - 基于 DHPaddleLiteTextRecognition 的通用 OCR 引擎
 * - 专注于手机号识别的业务逻辑
 * - 支持多种手机号格式（标准号、隐私号、虚拟号）
 * - 自动过滤和验证手机号格式
 * - 统计出现频率，返回最可能的手机号
 *
 * @discussion 使用流程：
 * 1. 获取单例实例
 * 2. 配置识别类型（matchType）
 * 3. 调用识别方法，传入图像和回调
 * 4. 在回调中获取识别出的手机号
 *
 * @note 识别操作异步执行，不阻塞调用线程
 * @note 返回的手机号按出现频率过滤（至少出现3次）
 *
 * @see DHPaddleLiteTextRecognition
 */
__attribute__((deprecated("DLPaddleLiteSDK is deprecated. Use DHPaddleLiteTextRecognition instead.")))
@interface DLPaddleLiteSDK : NSObject

/**
 * @brief 手机号匹配类型
 *
 * 配置需要识别的手机号类型，可以按位组合多种类型
 *
 * @discussion 默认值为 DLPaddleLiteMatchTypePhone（仅识别标准手机号）
 */
@property(nonatomic, assign) DLPaddleLiteMatchType matchType;

/**
 * @brief 获取单例实例
 *
 * @return DLPaddleLiteSDK 的单例对象
 *
 * @discussion 该方法返回全局唯一的 SDK 实例
 */
+ (DLPaddleLiteSDK *)sharedManager __attribute__((deprecated("Use DHPaddleLiteTextRecognition sharedInstance instead.")));

/**
 * @brief 识别图像中的手机号
 *
 * 对输入图像进行 OCR 识别，提取并验证手机号码。
 * 识别操作异步执行，通过回调返回结果。
 *
 * @param image 输入图像，必须为有效的 UIImage 对象
 * @param rect 有效识别区域，传入 CGRectZero 表示识别整个图像
 * @param result 完成回调，返回识别出的手机号字典
 *               - kKeyPhone: 标准手机号数组
 *               - kKeyVirtualPhone: 虚拟手机号数组
 *               - kKeyPrivacyNumber: 隐私号码数组
 *
 * @discussion 使用示例：
 * @code
 * UIImage *image = [UIImage imageNamed:@"screenshot.jpg"];
 * [[DLPaddleLiteSDK sharedManager] recognitionImage:image
 *                                     effectiveArea:CGRectZero
 *                                            result:^(NSDictionary *info) {
 *     NSArray *phones = info[kKeyPhone];
 *     NSArray *virtualPhones = info[kKeyVirtualPhone];
 *     NSArray *privacyNumbers = info[kKeyPrivacyNumber];
 *     NSLog(@"识别到的手机号: %@", phones);
 * }];
 * @endcode
 *
 * @note 只返回出现频率 >= 3 次的手机号
 * @note 回调不保证在主线程执行
 */
- (void)recognitionImage:(UIImage *)image
           effectiveArea:(CGRect)rect
                  result:(void(^)(NSDictionary *info))result __attribute__((deprecated("Use DHPaddleLiteTextRecognition -recognizeImage:effectiveArea:completion: instead.")));

@end

NS_ASSUME_NONNULL_END
