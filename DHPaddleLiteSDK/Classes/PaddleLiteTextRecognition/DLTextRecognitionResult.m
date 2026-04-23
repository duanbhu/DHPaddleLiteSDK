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
    return [self initWithText:text
                   confidence:confidence
                        index:index
                  boundingBox:CGRectZero
                      corners:@[]];
}

- (instancetype)initWithText:(NSString *)text
                  confidence:(CGFloat)confidence
                       index:(NSInteger)index
                 boundingBox:(CGRect)boundingBox
                     corners:(NSArray<NSValue *> *)corners {
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
        _boundingBox = boundingBox;
        _corners = [corners copy] ?: @[];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<DLTextRecognitionResult: text='%@', confidence=%.2f, index=%ld, boundingBox={x=%.1f,y=%.1f,w=%.1f,h=%.1f}>",
            self.text,
            self.confidence,
            (long)self.index,
            self.boundingBox.origin.x,
            self.boundingBox.origin.y,
            self.boundingBox.size.width,
            self.boundingBox.size.height];
}

@end
