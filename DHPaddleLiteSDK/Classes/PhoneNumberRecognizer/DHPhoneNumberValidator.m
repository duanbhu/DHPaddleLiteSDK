//
//  DHPhoneNumberValidator.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import "DHPhoneNumberValidator.h"

@implementation DHPhoneNumberValidator

#pragma mark - Public Methods

+ (DHPhoneNumberType)validatePhoneNumber:(NSString *)text {
    if (!text || text.length == 0) {
        return 0;
    }
    
    // 按顺序检查三种类型
    if ([self isRegularPhoneNumber:text]) {
        return DHPhoneNumberTypeRegular;
    }
    
    if ([self isVirtualPhoneNumber:text]) {
        return DHPhoneNumberTypeVirtual;
    }
    
    if ([self isPrivacyPhoneNumber:text]) {
        return DHPhoneNumberTypePrivacy;
    }
    
    return 0;
}

+ (BOOL)isRegularPhoneNumber:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }
    
    // 正则表达式：^1[3-9]\d{9}$
    // 匹配标准11位手机号：以1开头，第二位为3-9，后面9位数字
    NSString *regularPattern = @"^1[3-9]\\d{9}$";
    NSRegularExpression *regularRegex = [NSRegularExpression regularExpressionWithPattern:regularPattern
                                                                                  options:0
                                                                                    error:nil];
    NSUInteger regularMatches = [regularRegex numberOfMatchesInString:text
                                                              options:0
                                                                range:NSMakeRange(0, text.length)];
    
    if (regularMatches > 0) {
        return YES;
    }
    
    // 正则表达式：^1[3-9]\d[\s\-]?\d{4}[\s\-]?\d{4}$
    // 匹配带分隔符的手机号格式（如：138-1234-5678 或 138 1234 5678）
    NSString *separatorPattern = @"^1[3-9]\\d[\\s\\-]?\\d{4}[\\s\\-]?\\d{4}$";
    NSRegularExpression *separatorRegex = [NSRegularExpression regularExpressionWithPattern:separatorPattern
                                                                                    options:0
                                                                                      error:nil];
    NSUInteger separatorMatches = [separatorRegex numberOfMatchesInString:text
                                                                  options:0
                                                                    range:NSMakeRange(0, text.length)];
    
    return separatorMatches > 0;
}

+ (BOOL)isVirtualPhoneNumber:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }
    
    // 正则表达式：^1[3-9]\d{9}(?:[\s\-,_#*转]|ext|分机){0,2}\d{2,4}$
    // 匹配虚拟转接号：11位普通手机号 + 分隔符 + 2-4位分机号
    // 分隔符支持：空格、横线(-)、逗号(,)、下划线(_)、井号(#)、星号(*)、"转"、"ext"、"分机"
    NSString *virtualPattern = @"^1[3-9]\\d{9}(?:[\\s\\-,_#*转]|ext|分机){0,2}\\d{2,4}$";
    NSRegularExpression *virtualRegex = [NSRegularExpression regularExpressionWithPattern:virtualPattern
                                                                                  options:0
                                                                                    error:nil];
    NSUInteger matches = [virtualRegex numberOfMatchesInString:text
                                                       options:0
                                                         range:NSMakeRange(0, text.length)];
    
    if (matches == 0) {
        return NO;
    }
    
    // 验证主号码部分符合普通手机号规则
    // 提取前11位作为主号码
    if (text.length >= 11) {
        NSString *baseNumber = [text substringToIndex:11];
        return [self isRegularPhoneNumber:baseNumber];
    }
    
    return NO;
}

+ (BOOL)isPrivacyPhoneNumber:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }
    
    // 星号字符集合：*、^、_、斗、米、关、大、美、长、女、本、水、#、+、$、o、k、a、t、4
    NSString *asteriskChars = @"[*^_斗米关大美长女本水#+$okat4]";
    
    // 格式1：^1[3-9]\d[*^_斗米关大美长女本水#+$okat4]{3,7}\d{4}$
    // 以手机号前缀开头的隐私号（如：138****1234）
    NSString *format1Pattern = [NSString stringWithFormat:@"^1[3-9]\\d%@{3,7}\\d{4}$", asteriskChars];
    NSRegularExpression *format1Regex = [NSRegularExpression regularExpressionWithPattern:format1Pattern
                                                                                  options:0
                                                                                    error:nil];
    NSUInteger format1Matches = [format1Regex numberOfMatchesInString:text
                                                              options:0
                                                                range:NSMakeRange(0, text.length)];
    
    if (format1Matches > 0) {
        // 验证星号字符数量在3-7个之间
        return [self countAsteriskCharacters:text] >= 3 && [self countAsteriskCharacters:text] <= 7;
    }
    
    // 格式2：^[*^_斗米关大美长女本水#+$okat4]{3,7}\d{3,4}$
    // 仅显示后几位的隐私号（如：****1234）
    NSString *format2Pattern = [NSString stringWithFormat:@"^%@{3,7}\\d{3,4}$", asteriskChars];
    NSRegularExpression *format2Regex = [NSRegularExpression regularExpressionWithPattern:format2Pattern
                                                                                  options:0
                                                                                    error:nil];
    NSUInteger format2Matches = [format2Regex numberOfMatchesInString:text
                                                              options:0
                                                                range:NSMakeRange(0, text.length)];
    
    if (format2Matches > 0) {
        // 验证星号字符数量在3-7个之间
        return [self countAsteriskCharacters:text] >= 3 && [self countAsteriskCharacters:text] <= 7;
    }
    
    return NO;
}

#pragma mark - Private Helper Methods

+ (NSInteger)countAsteriskCharacters:(NSString *)text {
    if (!text || text.length == 0) {
        return 0;
    }
    
    // 星号字符集合
    NSCharacterSet *asteriskSet = [NSCharacterSet characterSetWithCharactersInString:@"*^_斗米关大美长女本水#+$okat4"];
    
    NSInteger count = 0;
    for (NSInteger i = 0; i < text.length; i++) {
        unichar character = [text characterAtIndex:i];
        if ([asteriskSet characterIsMember:character]) {
            count++;
        }
    }
    
    return count;
}

@end
