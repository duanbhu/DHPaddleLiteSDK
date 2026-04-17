//
//  DHPhoneNumberFormatter.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import "DHPhoneNumberFormatter.h"

@implementation DHPhoneNumberFormatter

#pragma mark - Public Methods

+ (NSString *)formatRegularPhoneNumber:(NSString *)phoneNumber {
    if (!phoneNumber || phoneNumber.length == 0) {
        return phoneNumber;
    }
    
    // 去除所有空格和横线分隔符，返回纯数字格式
    NSString *formatted = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    formatted = [formatted stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    return formatted;
}

+ (NSString *)formatVirtualPhoneNumber:(NSString *)virtualNumber {
    if (!virtualNumber || virtualNumber.length == 0) {
        return virtualNumber;
    }
    
    // 虚拟转接号格式：11位手机号 + 分隔符 + 2-4位分机号
    // 分隔符支持：空格、-、,、_、#、*、转、ext、分机
    // 正则表达式：^(1[3-9]\d{9})[\s\-,_#*]*(?:转|ext|分机)?[\s\-,_#*]*(\d{2,4})$
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(1[3-9]\\d{9})[\\s\\-,_#*]*(?:转|ext|分机)?[\\s\\-,_#*]*(\\d{2,4})$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    if (error) {
        return virtualNumber;
    }
    
    NSTextCheckingResult *match = [regex firstMatchInString:virtualNumber
                                                    options:0
                                                      range:NSMakeRange(0, virtualNumber.length)];
    
    if (!match || match.numberOfRanges != 3) {
        return virtualNumber;
    }
    
    // 提取主号码和分机号
    NSString *mainNumber = [virtualNumber substringWithRange:[match rangeAtIndex:1]];
    NSString *extension = [virtualNumber substringWithRange:[match rangeAtIndex:2]];
    
    // 格式化为标准格式："主号码转分机号"
    return [NSString stringWithFormat:@"%@转%@", mainNumber, extension];
}

+ (NSString *)formatPrivacyPhoneNumber:(NSString *)privacyNumber {
    if (!privacyNumber || privacyNumber.length == 0) {
        return privacyNumber;
    }
    
    // 星号字符集合：*、^、_、斗、米、关、大、美、长、女、本、水、#、+、$、o、k、a、t、4
    // 注意：这些字符只在星号位置替换，不在数字位置替换
    NSString *asteriskChars = @"*^_斗米关大美长女本水#+$okat4";
    
    // 格式1：1[3-9]X{asterisk}{3,7}XXXX → "前3位****后4位"（如：138****1234）
    // 正则表达式：^(1[3-9]\d)[*^_斗米关大美长女本水#+$okat4]{3,7}(\d{4})$
    NSString *asteriskPattern = [NSString stringWithFormat:@"[%@]", [NSRegularExpression escapedPatternForString:asteriskChars]];
    NSString *format1Pattern = [NSString stringWithFormat:@"^(1[3-9]\\d)%@{3,7}(\\d{4})$", asteriskPattern];
    
    NSError *error1 = nil;
    NSRegularExpression *format1Regex = [NSRegularExpression regularExpressionWithPattern:format1Pattern
                                                                                  options:0
                                                                                    error:&error1];
    
    if (!error1) {
        NSTextCheckingResult *match1 = [format1Regex firstMatchInString:privacyNumber
                                                                options:0
                                                                  range:NSMakeRange(0, privacyNumber.length)];
        
        if (match1 && match1.numberOfRanges == 3) {
            // 提取前3位和后4位
            NSString *prefix = [privacyNumber substringWithRange:[match1 rangeAtIndex:1]];
            NSString *suffix = [privacyNumber substringWithRange:[match1 rangeAtIndex:2]];
            
            // 格式化为："前3位****后4位"
            return [NSString stringWithFormat:@"%@****%@", prefix, suffix];
        }
    }
    
    // 格式2：{asterisk}{3,7}XXX(X) → "1******后4位"（如：1******1234）
    // 正则表达式：^[*^_斗米关大美长女本水#+$okat4]{3,7}(\d{3,4})$
    NSString *format2Pattern = [NSString stringWithFormat:@"^%@{3,7}(\\d{3,4})$", asteriskPattern];
    
    NSError *error2 = nil;
    NSRegularExpression *format2Regex = [NSRegularExpression regularExpressionWithPattern:format2Pattern
                                                                                  options:0
                                                                                    error:&error2];
    
    if (!error2) {
        NSTextCheckingResult *match2 = [format2Regex firstMatchInString:privacyNumber
                                                                options:0
                                                                  range:NSMakeRange(0, privacyNumber.length)];
        
        if (match2 && match2.numberOfRanges == 2) {
            // 提取后3-4位
            NSString *suffix = [privacyNumber substringWithRange:[match2 rangeAtIndex:1]];
            
            // 格式化为："1******后4位"
            // 如果后缀是3位，补齐为4位（前面加0）
            if (suffix.length == 3) {
                suffix = [@"0" stringByAppendingString:suffix];
            }
            
            return [NSString stringWithFormat:@"1******%@", suffix];
        }
    }
    
    // 如果不匹配任何格式，返回原始输入
    return privacyNumber;
}

@end
