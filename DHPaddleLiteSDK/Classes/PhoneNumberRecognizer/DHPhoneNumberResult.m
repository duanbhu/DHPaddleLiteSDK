//
//  DHPhoneNumberResult.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//  Copyright © 2024 DLPaddleLiteSDK. All rights reserved.
//

#import "DHPhoneNumberResult.h"

@implementation DHPhoneNumberResult

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber
                               type:(DHPhoneNumberType)type
                         confidence:(CGFloat)confidence
                              index:(NSInteger)index {
    self = [super init];
    if (self) {
        _phoneNumber = [phoneNumber copy];
        _type = type;
        _confidence = confidence;
        _index = index;
    }
    return self;
}

+ (instancetype)resultWithPhoneNumber:(NSString *)phoneNumber
                                 type:(DHPhoneNumberType)type
                           confidence:(CGFloat)confidence
                                index:(NSInteger)index {
    return [[self alloc] initWithPhoneNumber:phoneNumber
                                        type:type
                                  confidence:confidence
                                       index:index];
}

- (NSString *)description {
    NSString *typeString;
    switch (self.type) {
        case DHPhoneNumberTypeRegular:
            typeString = @"Regular";
            break;
        case DHPhoneNumberTypeVirtual:
            typeString = @"Virtual";
            break;
        case DHPhoneNumberTypePrivacy:
            typeString = @"Privacy";
            break;
        default:
            typeString = @"Unknown";
            break;
    }
    
    return [NSString stringWithFormat:@"<DHPhoneNumberResult: %p, phoneNumber=%@, type=%@, confidence=%.2f, index=%ld>",
            self, self.phoneNumber, typeString, self.confidence, (long)self.index];
}

@end
