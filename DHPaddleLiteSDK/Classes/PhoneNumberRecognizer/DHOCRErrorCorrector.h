//
//  DHOCRErrorCorrector.h
//  DLPaddleLiteSDK
//
//  Created by Phone Number Recognizer
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * OCR 错误修正器
 * 用于修正 OCR 识别中的常见字符混淆错误
 */
@interface DHOCRErrorCorrector : NSObject

/**
 * 修正 OCR 错误
 * @param text 原始识别文本
 * @param confidence 原始置信度
 * @return 包含修正后文本和调整后置信度的字典
 *         - @"text": 修正后的文本 (NSString)
 *         - @"confidence": 调整后的置信度 (NSNumber)
 */
+ (NSDictionary<NSString *, id> *)correctOCRErrors:(NSString *)text
                                        confidence:(CGFloat)confidence;

@end

NS_ASSUME_NONNULL_END
