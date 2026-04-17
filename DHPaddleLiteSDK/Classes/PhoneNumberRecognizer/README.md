# DHPhoneNumberRecognizer API 文档

DHPhoneNumberRecognizer 是一个基于 PaddleLiteTextRecognition OCR 能力构建的专用手机号识别系统。该系统能够从图像或视频流中识别三种类型的手机号：普通手机号、虚拟转接号和隐私号码。

## 目录

- [快速开始](#快速开始)
- [API 参考](#api-参考)
- [使用示例](#使用示例)
- [配置选项](#配置选项)
- [错误处理](#错误处理)
- [性能优化](#性能优化)
- [常见问题](#常见问题)

## 快速开始

### 1. 导入头文件

```objective-c
#import <DLPaddleLiteSDK/DHPhoneNumberRecognizer.h>
#import <DLPaddleLiteSDK/DHPhoneNumberResult.h>
#import <DLPaddleLiteSDK/DHPhoneNumberTypes.h>
```

### 2. 基本使用

```objective-c
// 获取识别器实例
DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];

// 识别图像中的手机号
UIImage *image = [UIImage imageNamed:@"test_image.jpg"];
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    for (DHPhoneNumberResult *result in results) {
        NSLog(@"识别到手机号: %@ (类型: %ld, 置信度: %.2f)", 
              result.phoneNumber, (long)result.type, result.confidence);
    }
}];
```

### 3. 支持的手机号类型

| 类型 | 说明 | 示例 |
|------|------|------|
| **普通手机号** | 11位标准格式 | `13812345678` |
| **虚拟转接号** | 带分机号的手机号 | `13812345678转123` |
| **隐私号码** | 部分隐藏的手机号 | `138****1234` |

## API 参考

### DHPhoneNumberRecognizer 类

#### 单例方法

```objective-c
+ (instancetype)sharedInstance;
```

获取 DHPhoneNumberRecognizer 的单例实例。线程安全。

#### 单次识别

```objective-c
- (void)recognizePhoneNumbers:(UIImage *)image
                   phoneTypes:(DHPhoneNumberTypes)types
                effectiveArea:(CGRect)rect
                   completion:(void(^)(NSArray<DHPhoneNumberResult *> * _Nullable results, 
                                      NSError * _Nullable error))completion;
```

**参数说明：**
- `image`: 输入图像，必须为有效的 UIImage 对象
- `types`: 类型过滤器，指定需要识别的手机号类型
- `rect`: 有效识别区域，传入 CGRectZero 表示识别整个图像
- `completion`: 完成回调，在主线程执行

**返回结果：**
- `results`: 识别结果数组，按位置排序（从上到下，从左到右）
- `error`: 错误对象，识别成功时为 nil

#### 视频流识别

```objective-c
// 启动视频流识别
- (void)startStreamRecognition:(DHPhoneNumberTypes)types
                     frameRate:(NSInteger)framesPerSecond
                      callback:(void(^)(NSArray<DHPhoneNumberResult *> *results))callback;

// 处理视频帧
- (void)processVideoFrame:(CMSampleBufferRef)sampleBuffer;

// 停止视频流识别
- (void)stopStreamRecognition;
```

**参数说明：**
- `types`: 类型过滤器
- `framesPerSecond`: 每秒处理的帧数，建议 2-3 FPS
- `callback`: 识别结果回调，当识别到新的手机号时触发
- `sampleBuffer`: 视频帧数据

#### 配置方法

```objective-c
// 设置置信度阈值
- (void)setConfidenceThreshold:(CGFloat)threshold;

// 设置是否启用OCR错误修正
- (void)setOCRCorrectionEnabled:(BOOL)enabled;

// 设置运单号前缀黑名单
- (void)setTrackingNumberPrefixes:(NSArray<NSString *> *)prefixes;
```

### DHPhoneNumberResult 类

识别结果对象，包含识别出的手机号信息。

```objective-c
@interface DHPhoneNumberResult : NSObject

@property (nonatomic, copy, readonly) NSString *phoneNumber;    // 手机号文本
@property (nonatomic, assign, readonly) DHPhoneNumberType type;  // 手机号类型
@property (nonatomic, assign, readonly) CGFloat confidence;    // 置信度分数（0.0-1.0）
@property (nonatomic, assign, readonly) NSInteger index;       // 位置索引

@end
```

### DHPhoneNumberTypes 枚举

```objective-c
typedef NS_ENUM(NSInteger, DHPhoneNumberType) {
    DHPhoneNumberTypeRegular = 1 << 0,   // 普通手机号
    DHPhoneNumberTypeVirtual = 1 << 1,   // 虚拟转接号
    DHPhoneNumberTypePrivacy = 1 << 2,   // 隐私号码
};

typedef NS_OPTIONS(NSInteger, DHPhoneNumberTypes) {
    DHPhoneNumberTypesAll = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual | DHPhoneNumberTypePrivacy,
};
```

### 错误码

```objective-c
typedef NS_ENUM(NSInteger, DHPhoneNumberRecognizerErrorCode) {
    DHPhoneNumberRecognizerErrorCodeInvalidImage = 2001,           // 无效图像
    DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed = 2002,    // OCR处理失败
    DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter = 2003,      // 无效类型过滤器
    DHPhoneNumberRecognizerErrorCodeInvalidConfiguration = 2004,   // 无效配置
};
```

## 使用示例

### 1. 类型过滤识别

```objective-c
DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];

// 只识别普通手机号
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypeRegular
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    // 处理结果...
}];

// 同时识别普通手机号和虚拟转接号
DHPhoneNumberTypes combinedTypes = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual;
[recognizer recognizePhoneNumbers:image
                       phoneTypes:combinedTypes
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    // 处理结果...
}];
```

### 2. 指定区域识别

```objective-c
// 只在图像的特定区域识别手机号
CGRect region = CGRectMake(0, 0, 200, 100);
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:region
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    // 处理结果...
}];
```

### 3. 视频流识别

```objective-c
DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];

// 启动视频流识别
[recognizer startStreamRecognition:DHPhoneNumberTypesAll
                         frameRate:2
                          callback:^(NSArray<DHPhoneNumberResult *> *results) {
    // 处理实时识别结果
    for (DHPhoneNumberResult *result in results) {
        NSLog(@"实时识别到: %@", result.phoneNumber);
    }
}];

// 在相机回调中处理视频帧
- (void)captureOutput:(AVCaptureOutput *)output 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection {
    [recognizer processVideoFrame:sampleBuffer];
}

// 停止识别
[recognizer stopStreamRecognition];
```

### 4. 批量处理

```objective-c
NSArray *images = @[image1, image2, image3];
dispatch_group_t group = dispatch_group_create();
NSMutableArray *allResults = [NSMutableArray array];

for (UIImage *image in images) {
    dispatch_group_enter(group);
    
    [recognizer recognizePhoneNumbers:image
                           phoneTypes:DHPhoneNumberTypesAll
                        effectiveArea:CGRectZero
                           completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
        if (!error) {
            @synchronized (allResults) {
                [allResults addObjectsFromArray:results];
            }
        }
        dispatch_group_leave(group);
    }];
}

dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"批量处理完成，共识别到 %lu 个手机号", (unsigned long)allResults.count);
});
```

## 配置选项

### 1. 置信度阈值

```objective-c
// 设置置信度阈值，过滤低质量结果
[recognizer setConfidenceThreshold:0.8];  // 默认: 0.7
```

**建议值：**
- 名片识别：0.8+
- 文档扫描：0.7+
- 实时扫描：0.85+

### 2. OCR 错误修正

```objective-c
// 启用OCR错误自动修正（默认启用）
[recognizer setOCRCorrectionEnabled:YES];
```

**说明：**
- 自动修正常见的 OCR 错误（如 O/0、l/1 混淆）
- 修正后会降低置信度分数
- 可以识别更多手机号，但可能增加误识别

### 3. 运单号过滤

```objective-c
// 设置运单号前缀黑名单
NSArray *prefixes = @[@"YT", @"ZT", @"SF", @"JD", @"TT", @"JT"];
[recognizer setTrackingNumberPrefixes:prefixes];
```

**默认过滤前缀：**
- YT、ZT、ST、JD、SF、TT、JT
- 12位以上的纯数字序列

## 错误处理

### 错误类型处理

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    if (error) {
        switch (error.code) {
            case DHPhoneNumberRecognizerErrorCodeInvalidImage:
                NSLog(@"图像无效，请检查输入图像");
                break;
                
            case DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed:
                NSLog(@"OCR处理失败，请检查图像质量或重试");
                break;
                
            case DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter:
                NSLog(@"类型过滤器无效，请使用有效的DHPhoneNumberTypes值");
                break;
                
            case DHPhoneNumberRecognizerErrorCodeInvalidConfiguration:
                NSLog(@"配置参数无效，请检查参数范围");
                break;
                
            default:
                NSLog(@"未知错误: %@", error.localizedDescription);
                break;
        }
        return;
    }
    
    // 处理成功结果
    if (results.count == 0) {
        NSLog(@"未识别到手机号");
    } else {
        NSLog(@"识别成功，共 %lu 个手机号", (unsigned long)results.count);
    }
}];
```

### 常见错误解决方案

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| InvalidImage | 图像为 nil 或无效 | 检查图像是否正确加载 |
| OCRProcessingFailed | OCR 引擎处理失败 | 检查图像质量，调整光照，重试 |
| InvalidTypeFilter | 类型过滤器参数错误 | 使用正确的 DHPhoneNumberTypes 值 |
| InvalidConfiguration | 配置参数超出范围 | 检查阈值范围（0.0-1.0） |

## 性能优化

### 1. 视频流识别优化

```objective-c
// 使用适中的帧率，平衡性能和实时性
[recognizer startStreamRecognition:DHPhoneNumberTypesAll
                         frameRate:2  // 推荐 2-3 FPS
                          callback:callback];

// 在后台线程处理视频帧
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [recognizer processVideoFrame:sampleBuffer];
});
```

### 2. 批量处理优化

```objective-c
// 控制并发数量，避免内存峰值
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
queue.maxConcurrentOperationCount = 3;  // 限制并发数

for (UIImage *image in images) {
    [queue addOperationWithBlock:^{
        [recognizer recognizePhoneNumbers:image
                               phoneTypes:DHPhoneNumberTypesAll
                            effectiveArea:CGRectZero
                               completion:^(NSArray *results, NSError *error) {
            // 处理结果...
        }];
    }];
}
```

### 3. 内存管理

```objective-c
// 及时停止视频流识别
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[DHPhoneNumberRecognizer sharedInstance] stopStreamRecognition];
}

// 正确处理 CMSampleBufferRef
- (void)processVideoFrame:(CMSampleBufferRef)sampleBuffer {
    // SDK 内部会正确管理 CMSampleBufferRef 的生命周期
    [[DHPhoneNumberRecognizer sharedInstance] processVideoFrame:sampleBuffer];
    // 不需要手动 CFRelease
}
```

## 常见问题

### Q: 为什么识别结果为空？

**A:** 可能的原因和解决方案：

1. **图像质量问题**
   - 确保图像清晰，手机号完整可见
   - 调整拍摄角度，避免倾斜或模糊
   - 检查光照条件

2. **置信度阈值过高**
   ```objective-c
   // 尝试降低置信度阈值
   [recognizer setConfidenceThreshold:0.6];
   ```

3. **手机号格式不符合规则**
   - 确认是否为中国大陆11位手机号格式
   - 检查是否被运单号过滤器误过滤

### Q: 如何提高识别准确率？

**A:** 优化建议：

1. **图像预处理**
   - 确保图像分辨率足够（建议 > 300 DPI）
   - 调整对比度和亮度
   - 去除噪声和干扰

2. **配置优化**
   ```objective-c
   // 启用错误修正
   [recognizer setOCRCorrectionEnabled:YES];
   
   // 设置适当的置信度阈值
   [recognizer setConfidenceThreshold:0.8];
   
   // 配置运单号过滤
   [recognizer setTrackingNumberPrefixes:@[@"YT", @"SF", @"JD"]];
   ```

3. **使用区域识别**
   ```objective-c
   // 限制识别区域，减少干扰
   CGRect phoneRegion = CGRectMake(x, y, width, height);
   [recognizer recognizePhoneNumbers:image
                          phoneTypes:DHPhoneNumberTypesAll
                       effectiveArea:phoneRegion
                          completion:completion];
   ```

### Q: 视频流识别性能如何优化？

**A:** 性能优化策略：

1. **帧率控制**
   ```objective-c
   // 使用较低的帧率
   [recognizer startStreamRecognition:DHPhoneNumberTypesAll
                            frameRate:2  // 2-3 FPS 即可
                             callback:callback];
   ```

2. **类型过滤**
   ```objective-c
   // 只识别需要的类型
   [recognizer startStreamRecognition:DHPhoneNumberTypeRegular
                            frameRate:2
                             callback:callback];
   ```

3. **及时停止**
   ```objective-c
   // 在不需要时及时停止识别
   [recognizer stopStreamRecognition];
   ```

### Q: 如何处理特殊格式的手机号？

**A:** 支持的格式：

1. **普通手机号**
   - `13812345678`
   - `138-1234-5678`
   - `138 1234 5678`

2. **虚拟转接号**
   - `13812345678转123`
   - `13812345678-123`
   - `13812345678 ext 123`

3. **隐私号码**
   - `138****1234`
   - `****1234`
   - `138米米米米1234`（支持多种星号字符）

### Q: 如何集成到现有项目？

**A:** 集成步骤：

1. **添加依赖**
   ```ruby
   # Podfile
   pod 'DLPaddleLiteSDK'
   ```

2. **导入头文件**
   ```objective-c
   #import <DLPaddleLiteSDK/DHPhoneNumberRecognizer.h>
   ```

3. **基本使用**
   ```objective-c
   DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
   [recognizer recognizePhoneNumbers:image
                          phoneTypes:DHPhoneNumberTypesAll
                       effectiveArea:CGRectZero
                          completion:^(NSArray *results, NSError *error) {
       // 处理结果
   }];
   ```

### Q: 线程安全吗？

**A:** 是的，DHPhoneNumberRecognizer 是线程安全的：

- 单例实例创建是线程安全的
- 可以在任意线程调用识别方法
- 回调会在主线程执行
- 支持并发调用

```objective-c
// 可以在后台线程调用
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [recognizer recognizePhoneNumbers:image
                           phoneTypes:DHPhoneNumberTypesAll
                        effectiveArea:CGRectZero
                           completion:^(NSArray *results, NSError *error) {
        // 回调在主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新UI
        });
    }];
});
```

---

## 技术支持

如需更多帮助，请参考：

- [集成示例代码](../../../Example/PhoneNumberRecognizerExamples.h)
- [单元测试用例](../../../Example/Tests/PhoneNumberRecognizerTests.m)
- [设计文档](../../../../.kiro/specs/phone-number-recognizer/design.md)

或联系技术支持团队。