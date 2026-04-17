//
//  DLTextRecognitionResult.m
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import "DLTextRecognitionResult.h"

@implementation DLTextRecognitionResult

- (instancetype)initWithText:(NSString *)text
                  confidence:(CGFloat)confidence
                       index:(NSInteger)index {
    self = [super init];
    if (self) {
        _text = [text copy];
        
        // 验证置信度范围 [0.0, 1.0]
        if (confidence < 0.0 || confidence > 1.0) {
            NSLog(@"[DLTextRecognitionResult] 警告: 置信度 %.2f 超出有效范围 [0.0, 1.0]，将被限制在有效范围内", confidence);
            _confidence = MAX(0.0, MIN(1.0, confidence));
        } else {
            _confidence = confidence;
        }
        
        _index = index;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<DLTextRecognitionResult: text='%@', confidence=%.2f, index=%ld>",
            self.text, self.confidence, (long)self.index];
}

@end
