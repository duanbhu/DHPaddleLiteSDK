//
//  DHOCRErrorCorrector.m
//  DLPaddleLiteSDK
//
//  Created by Phone Number Recognizer
//

#import "DHOCRErrorCorrector.h"

@implementation DHOCRErrorCorrector

/**
 * 错误字符映射表
 * 定义常见的 OCR 识别错误及其正确字符
 */
+ (NSDictionary<NSString *, NSString *> *)errorCharacterMapping {
    static NSDictionary<NSString *, NSString *> *mapping = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = @{
            @"O": @"0",  // 大写字母 O → 数字 0
            @"o": @"0",  // 小写字母 o → 数字 0
            @"l": @"1",  // 小写字母 l → 数字 1
            @"I": @"1",  // 大写字母 I → 数字 1
            @"Z": @"2",  // 大写字母 Z → 数字 2
            @"S": @"5",  // 大写字母 S → 数字 5
            @"B": @"8"   // 大写字母 B → 数字 8
        };
    });
    return mapping;
}

/**
 * 检测字符是否在数字序列上下文中
 * @param text 完整文本
 * @param index 当前字符索引
 * @return YES 如果字符在数字序列中，NO 否则
 */
+ (BOOL)isInDigitContext:(NSString *)text atIndex:(NSInteger)index {
    if (text.length == 0 || index < 0 || index >= text.length) {
        return NO;
    }
    
    // 检查前后字符是否为数字
    BOOL hasPrevDigit = NO;
    BOOL hasNextDigit = NO;
    
    // 检查前一个字符
    if (index > 0) {
        unichar prevChar = [text characterAtIndex:index - 1];
        hasPrevDigit = (prevChar >= '0' && prevChar <= '9');
    }
    
    // 检查后一个字符
    if (index < text.length - 1) {
        unichar nextChar = [text characterAtIndex:index + 1];
        hasNextDigit = (nextChar >= '0' && nextChar <= '9');
    }
    
    // 如果前后至少有一个数字，则认为在数字序列中
    return hasPrevDigit || hasNextDigit;
}

/**
 * 修正 OCR 错误
 * 仅在数字序列上下文中替换错误字符
 */
+ (NSDictionary<NSString *, id> *)correctOCRErrors:(NSString *)text
                                        confidence:(CGFloat)confidence {
    if (text == nil || text.length == 0) {
        return @{
            @"text": text ?: @"",
            @"confidence": @(confidence)
        };
    }
    
    NSDictionary<NSString *, NSString *> *mapping = [self errorCharacterMapping];
    NSMutableString *correctedText = [text mutableCopy];
    NSInteger correctionCount = 0;
    
    // 从后向前遍历，避免索引变化问题
    for (NSInteger i = text.length - 1; i >= 0; i--) {
        NSString *currentChar = [correctedText substringWithRange:NSMakeRange(i, 1)];
        NSString *replacement = mapping[currentChar];
        
        // 如果字符在映射表中，且在数字序列上下文中，则替换
        if (replacement != nil && [self isInDigitContext:correctedText atIndex:i]) {
            [correctedText replaceCharactersInRange:NSMakeRange(i, 1)
                                         withString:replacement];
            correctionCount++;
        }
    }
    
    // 每次修正降低置信度 0.05
    CGFloat adjustedConfidence = confidence - (correctionCount * 0.05);
    // 确保置信度不低于 0.0
    adjustedConfidence = MAX(0.0, adjustedConfidence);
    
    return @{
        @"text": [correctedText copy],
        @"confidence": @(adjustedConfidence)
    };
}

@end
