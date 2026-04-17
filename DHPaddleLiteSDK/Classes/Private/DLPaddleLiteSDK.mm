//
//  DLPaddleLiteSDK.m
//  Pole
//
//  Created by Duanhu on 2023/3/20.
//  Copyright © 2023 刘伟. All rights reserved.
//

#import "../DLPaddleLiteSDK.h"
#import "NSString+SDK.h"
#import "DLScanResult.h"
#import "DHPaddleLiteTextRecognition.h"
#import "DLTextRecognitionResult.h"

NSString *const kKeyPhone = @"kKeyPhone";

NSString *const kKeyPrivacyNumber = @"kKeyPrivacyNumber";

NSString *const kKeyVirtualPhone = @"kKeyVirtualPhone";

@interface DLPaddleLiteSDK ()

@property(nonatomic, strong) NSPredicate *predicate;

/// 手机号
@property(nonatomic, strong) NSCountedSet *mobileSet;

/// 隐私号
@property(nonatomic, strong) NSCountedSet *privateSet;

/// 虚拟号
@property(nonatomic, strong) NSCountedSet *mobileExtSet;

@end

@implementation DLPaddleLiteSDK

+ (DLPaddleLiteSDK *)sharedManager {
    static DLPaddleLiteSDK *sharedManager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedManager = [[DLPaddleLiteSDK alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.matchType = DLPaddleLiteMatchTypePhone;
    }
    return self;
}

- (void)recognitionImage:(UIImage *)image effectiveArea:(CGRect)rect result:(void(^)(NSDictionary *info))result {
    // 使用 DHPaddleLiteTextRecognition 进行 OCR 识别
    // 节流控制已在 DHPaddleLiteTextRecognition 内部实现
    DHPaddleLiteTextRecognition *ocr = [DHPaddleLiteTextRecognition sharedInstance];
    
    __weak typeof(self) weakSelf = self;
    [ocr recognizeImage:image
          effectiveArea:rect
             completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
        
        if (error) {
            NSLog(@"[DLPaddleLiteSDK] OCR识别失败: %@", error.localizedDescription);
            if (result) {
                result(@{
                    kKeyPhone: @[],
                    kKeyVirtualPhone: @[],
                    kKeyPrivacyNumber: @[]
                });
            }
            return;
        }
        
        // 如果结果为空（可能是节流跳过），不处理，保持计数集合不变
        if (results.count == 0) {
//            NSLog(@"[DLPaddleLiteSDK] 识别结果为空，跳过处理");
            return;
        }
        
        // 处理识别结果，提取手机号
        [weakSelf processRecognitionResults:results completion:result];
    }];
}

- (void)processRecognitionResults:(NSArray<DLTextRecognitionResult *> *)results completion:(void(^)(NSDictionary *info))completion {
    // 处理每个识别结果
    for (DLTextRecognitionResult *result in results) {
        NSString *str = result.text;
        CGFloat score = result.confidence;
        // 置信度过滤已由 DHPaddleLiteTextRecognition 处理，这里不需要再次过滤
        
        NSLog(@"原始数据：%@",str);
        
        // 处理特殊字符（*号识别成水的情况）
        if ([NSString countOfSub:@"*" inString:str] > 2 || [NSString countOfSub:@"水" inString:str] > 2) {
            // 针对有些*号识别成水的情况，不足11位时，补成11位
            str = [NSString replaceRegular:@"0123456789*" byString:@"*" inString:str];
            if (str.length < 11 && str.length > 7) {
                str = [NSString stringWithFormat:@"%@****%@",[str substringToIndex:3], [str substringFromIndex:str.length - 4]];
            } else if ([str hasPrefix:@"*"] && str.length > 11) {
                str = [str substringFromIndex:str.length - 11];
            }
        }
        
        // 使用 predicate 进行匹配
        if ([self.predicate evaluateWithObject:str]) {
            if ([str hasPrefix:@"*"]) {
                str = [NSString stringWithFormat:@"1%@", [str substringFromIndex:1]];
            }
            NSLog(@"[DLPaddleLiteSDK] 匹配到: %@", str);
            
            // 提取手机号
            NSArray *list = [NSString searchRegular:@"[1*][3-9*][\\d*]{9}([\\s\\S]{0,3}\\d{3,4})?" atString:str];
            if (!list || !list.count) {
                continue;
            }
            
            for (NSString *mobile in list) {
                NSLog(@"[DLPaddleLiteSDK] 手机号: %@", mobile);
                if ([mobile containsString:@"*"]) {
                    // 隐私号
                    [self.privateSet addObject:mobile];
                } else if (mobile.length > 11) {
                    // 虚拟号（带分机号）
                    NSString *pureNumbers = [[mobile componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
                    if ([NSString isPureNumandCharacters:pureNumbers] && pureNumbers.length > 12) {
                        NSString *sub = [pureNumbers substringFromIndex:11];
                        NSRange range = NSMakeRange(11, sub.length);
                        pureNumbers = [pureNumbers stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"转%@", sub]];
                    }
                    [self.mobileExtSet addObject:pureNumbers];
                } else if (mobile.length == 11) {
                    // 标准手机号
                    [self.mobileSet addObject:mobile];
                }
            }
        }
    }
    
    // 提取出现次数最多的手机号
    NSArray *mobiles = [self maxCountItemInSet:self.mobileSet];
    NSArray *mobileExts = [self maxCountItemInSet:self.mobileExtSet];
    NSArray *privateNos = [self maxCountItemInSet:self.privateSet];
    
    if (mobileExts.count || mobiles.count || privateNos.count) {
        NSDictionary *dict = @{
            kKeyPhone        : mobiles,
            kKeyVirtualPhone : mobileExts,
            kKeyPrivacyNumber: privateNos
//            @"image" : MatToUIImage(self->_cvimg)
        };
        if (completion) {
            completion(dict);
        }
        [self.mobileSet removeAllObjects];
        [self.mobileExtSet removeAllObjects];
        [self.privateSet removeAllObjects];
    }
}

//- (void)recognitionSampleBuffer:(CMSampleBufferRef)sampleBuffer effectiveArea:(CGRect)rect result:(void (^)(NSDictionary * _Nonnull))result {
//
//}

/// 返回集合里重复最多的元素，这里认为至少要出现两次，否则返回[]
/// @param set 数据集合
- (NSArray *)maxCountItemInSet:(NSCountedSet *)set {
    NSEnumerator *enumerator = [set objectEnumerator];
    id obj;
    NSMutableArray *array = @[].mutableCopy;
    while (obj = [enumerator nextObject]) {
        // 降低阈值从3次到2次，因为节流机制限制了处理频率
        if ([set countForObject:obj] >= 2) {
            [array addObject:obj];
        }
    }
    return array;
}

- (NSArray<NSString *> *)matchesRegex:(NSString *)pattern inString:(NSString *)str set:(NSCountedSet *)set {
    NSRegularExpression *phoneRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSArray<NSTextCheckingResult *> *phoneMatches = [phoneRegex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSMutableArray *array = @[].mutableCopy;
    for (NSTextCheckingResult *match in phoneMatches) {
        NSString *phoneNumber = [str substringWithRange:match.range];
        NSLog(@"手机号: %@", phoneNumber);
        [array addObject:phoneNumber];
        [set addObject:phoneNumber];
    }
    return array;
}

#pragma mark - setter
- (void)setMatchType:(DLPaddleLiteMatchType)matchType {
    _matchType = matchType;
    
    NSString *reg = @"";
    switch (matchType) {
        case DLPaddleLiteMatchTypePhone:
            reg = @"^([^a-zA-Z]*[1][3-9][0-9]{9})(?:/[\\S]*)?$";
            break;
        case DLPaddleLiteMatchTypePrivatePhone:
            reg = @"^([^a-zA-Z]*[1*][3-9*][0-9*]{9})(?:/[\\S]*)?$";
            break;
        case DLPaddleLiteMatchTypeVirtualPhone:
            reg = @"^([^a-zA-Z]*[1][3-9][0-9]{9}([\\s\\S]{0,5}[0-9]{3,4})?)(?:/[\\S]*)?$";
            break;
        case DLPaddleLiteMatchTypePhoneAll:
            reg = @"^([^a-zA-Z]*[1*][3-9*][0-9*]{9}([\\s\\S]{0,5}[0-9]{3,4})?)(?:/[\\S]*)?$";
            break;
    }
    _predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", reg];
}

#pragma mark - lazy loading

- (NSCountedSet *)mobileSet {
    if (!_mobileSet) {
        _mobileSet = [[NSCountedSet alloc] init];
    }
    return _mobileSet;
}

- (NSCountedSet *)mobileExtSet {
    if (!_mobileExtSet) {
        _mobileExtSet = [[NSCountedSet alloc] init];
    }
    return _mobileExtSet;
}

- (NSCountedSet *)privateSet {
    if (!_privateSet) {
        _privateSet = [[NSCountedSet alloc] init];
    }
    return _privateSet;
}

@end
