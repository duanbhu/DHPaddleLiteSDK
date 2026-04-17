//
//  NSString+DL.h
//  DLPaddleLiteSDK_Example
//
//  Created by Duanhu on 2023/3/21.
//  Copyright © 2023 dbh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SDK)

/// 判断字符串是否是纯数字
/// - Parameter string: 字符串
+ (BOOL)isPureNumandCharacters:(NSString *)string;

/// 检索子串
/// - Parameters:
///   - reg: 子串的正则表达式
///   - string: 被检索的字符串
+ (NSString *)searchFirstRegular:(NSString *)reg inString:(NSString *)string;

+ (NSArray *)searchRegular:(NSString *)reg atString:(NSString *)string;

+ (NSString *)replaceRegular:(NSString *)reg byString:(NSString *)byString inString:(NSString *)string;

/// 子串个数
+ (NSInteger)countOfSub:(NSString *)sub inString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
