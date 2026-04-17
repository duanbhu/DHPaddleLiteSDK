//
//  DHTrackingNumberFilter.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import "DHTrackingNumberFilter.h"

@implementation DHTrackingNumberFilter

- (instancetype)init {
    // 默认前缀列表
    NSArray<NSString *> *defaultPrefixes = @[@"YT", @"ZT", @"ST", @"JD", @"SF", @"TT", @"JT"];
    return [self initWithPrefixes:defaultPrefixes];
}

- (instancetype)initWithPrefixes:(NSArray<NSString *> *)prefixes {
    self = [super init];
    if (self) {
        _prefixes = prefixes ?: @[];
    }
    return self;
}

- (BOOL)isTrackingNumber:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }
    
    // 移除空格，便于检测
    NSString *trimmedText = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // 检测前缀模式：已知前缀 + 数字序列（长度 >= 10）
    for (NSString *prefix in self.prefixes) {
        if ([trimmedText hasPrefix:prefix]) {
            // 提取前缀后的部分
            NSString *afterPrefix = [trimmedText substringFromIndex:prefix.length];
            
            // 检查是否为纯数字且长度 >= 10
            if ([self isDigitsOnly:afterPrefix] && afterPrefix.length >= 10) {
                return YES;
            }
        }
    }
    
    // 检测纯数字模式：纯数字序列（长度 >= 12）
    if ([self isDigitsOnly:trimmedText] && trimmedText.length >= 12) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Private Methods

/**
 * 检查字符串是否仅包含数字
 */
- (BOOL)isDigitsOnly:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }
    
    NSCharacterSet *nonDigitSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [text rangeOfCharacterFromSet:nonDigitSet].location == NSNotFound;
}

@end
