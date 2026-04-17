//
//  NSString+DL.m
//  DLPaddleLiteSDK_Example
//
//  Created by Duanhu on 2023/3/21.
//  Copyright © 2023 dbh. All rights reserved.
//

#import "NSString+SDK.h"

@implementation NSString (SDK)

/// 判断字符串是否是纯数字
/// - Parameter string: 字符串
+ (BOOL)isPureNumandCharacters:(NSString *)string {
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    return string.length <= 0;
}

/// 搜索子串的位置
/// - Parameter reg: 正则表达式 @"【(.{1,6})】"
+ (NSArray *)searchRegular:(NSString *)reg atString:(NSString *)string {
    NSError *error;
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:reg
    options:NSRegularExpressionCaseInsensitive error:&error];
    if (!error) {
        NSArray *results = [regular matchesInString:string options:NSMatchingReportProgress range:NSMakeRange(0, string.length)];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSTextCheckingResult *match in results) {
            NSRange range = [match range];
            NSString *mStr = [string substringWithRange:range];
            [array addObject:mStr];
        }
        return array;
    }
    return nil;
}

/// 检索子串
/// - Parameters:
///   - reg: 子串的正则表达式
///   - string: 被检索的字符串
+ (NSString *)searchFirstRegular:(NSString *)reg inString:(NSString *)string {
    NSError *error;
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:reg
    options:NSRegularExpressionCaseInsensitive error:&error];
    if (!error) {
        NSRange range = [regular rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:NSMakeRange(0, string.length)];
        return [string substringWithRange:range];
    }
    return nil;
}

+ (NSString *)replaceRegular:(NSString *)reg byString:(NSString *)byString inString:(NSString *)string {
    return [[string componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:reg] invertedSet]] componentsJoinedByString:byString];
}

/// 子串个数
+ (NSInteger)countOfSub:(NSString *)sub inString:(NSString *)string {
    NSArray *array = [string componentsSeparatedByString:sub];
    return [array count] - 1;
}

@end
