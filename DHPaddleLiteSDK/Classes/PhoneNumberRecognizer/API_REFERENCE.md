# DHPhoneNumberRecognizer API 参考手册

本文档提供 DHPhoneNumberRecognizer SDK 的详细 API 参考信息。

## 目录

- [核心类](#核心类)
- [数据模型](#数据模型)
- [枚举和常量](#枚举和常量)
- [错误处理](#错误处理)
- [回调和代理](#回调和代理)
- [线程安全](#线程安全)

## 核心类

### DHPhoneNumberRecognizer

手机号识别器主类，提供单次识别和视频流识别功能。

#### 类方法

##### `+ (instancetype)sharedInstance`

获取 DHPhoneNumberRecognizer 的单例实例。

**返回值：**
- `DHPhoneNumberRecognizer *` - 单例实例

**线程安全：** 是

**示例：**
```objective-c
DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
```

#### 实例方法

##### 单次识别

```objective-c
- (void)recognizePhoneNumbers:(UIImage *)image
                   phoneTypes:(DHPhoneNumberTypes)types
                effectiveArea:(CGRect)rect
                   completion:(void(^)(NSArray<DHPhoneNumberResult *> * _Nullable results, 
                                      NSError * _Nullable error))completion;
```

从图像中识别手机号。

**参数：**
- `image` (`UIImage *`) - 输入图像，不能为 nil
- `types` (`DHPhoneNumberTypes`) - 类型过滤器，指定需要识别的手机号类型
- `rect` (`CGRect`) - 有效识别区域，CGRectZero 表示识别整个图像
- `completion` (`Block`) - 完成回调，在主线程执行

**回调参数：**
- `results` (`NSArray<DHPhoneNumberResult *> *`) - 识别结果数组，按位置排序
- `error` (`NSError *`) - 错误对象，成功时为 nil

**可能的错误：**
- `DHPhoneNumberRecognizerErrorCodeInvalidImage` - 图像无效
- `DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed` - OCR 处理失败
- `DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter` - 类型过滤器无效

**线程安全：** 是

**示例：**
```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    for (DHPhoneNumberResult *result in results) {
        NSLog(@"识别到: %@", result.phoneNumber);
    }
}];
```

##### 视频流识别

```objective-c
- (void)startStreamRecognition:(DHPhoneNumberTypes)types
                     frameRate:(NSInteger)framesPerSecond
                      callback:(void(^)(NSArray<DHPhoneNumberResult *> *results))callback;
```

启动视频流识别。

**参数：**
- `types` (`DHPhoneNumberTypes`) - 类型过滤器
- `framesPerSecond` (`NSInteger`) - 每秒处理的帧数，建议 2-3
- `callback` (`Block`) - 识别结果回调，当识别到新的手机号时触发

**注意事项：**
- 必须调用 `processVideoFrame:` 提供视频帧数据
- 使用去重机制，相同手机号不会重复回调
- 回调在主线程执行

**线程安全：** 是

**示例：**
```objective-c
[recognizer startStreamRecognition:DHPhoneNumberTypesAll
                         frameRate:2
                          callback:^(NSArray<DHPhoneNumberResult *> *results) {
    for (DHPhoneNumberResult *result in results) {
        NSLog(@"实时识别到: %@", result.phoneNumber);
    }
}];
```

```objective-c
- (void)processVideoFrame:(CMSampleBufferRef)sampleBuffer;
```

处理视频帧数据。

**参数：**
- `sampleBuffer` (`CMSampleBufferRef`) - 视频帧数据

**前提条件：** 必须先调用 `startStreamRecognition:frameRate:callback:`

**内存管理：** SDK 内部会正确管理 CMSampleBufferRef 的生命周期

**线程安全：** 是

**示例：**
```objective-c
- (void)captureOutput:(AVCaptureOutput *)output 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection {
    [recognizer processVideoFrame:sampleBuffer];
}
```

```objective-c
- (void)stopStreamRecognition;
```

停止视频流识别并清理资源。

**线程安全：** 是

**示例：**
```objective-c
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[DHPhoneNumberRecognizer sharedInstance] stopStreamRecognition];
}
```

##### 配置方法

```objective-c
- (void)setConfidenceThreshold:(CGFloat)threshold;
```

设置置信度阈值。

**参数：**
- `threshold` (`CGFloat`) - 置信度阈值，有效范围 0.0-1.0

**默认值：** 0.7

**说明：** 低于阈值的识别结果会被过滤掉

**线程安全：** 是

**示例：**
```objective-c
[recognizer setConfidenceThreshold:0.8];  // 提高准确性
```

```objective-c
- (void)setOCRCorrectionEnabled:(BOOL)enabled;
```

设置是否启用 OCR 错误修正。

**参数：**
- `enabled` (`BOOL`) - YES 启用，NO 禁用

**默认值：** YES

**说明：** 
- 启用时会自动修正常见的 OCR 错误（如 O/0、l/1 混淆）
- 修正后会降低置信度分数
- 可以识别更多手机号，但可能增加误识别

**线程安全：** 是

**示例：**
```objective-c
[recognizer setOCRCorrectionEnabled:YES];
```

```objective-c
- (void)setTrackingNumberPrefixes:(NSArray<NSString *> *)prefixes;
```

设置运单号前缀黑名单。

**参数：**
- `prefixes` (`NSArray<NSString *> *`) - 运单号前缀数组

**默认值：** `@[@"YT", @"ZT", @"ST", @"JD", @"SF", @"TT", @"JT"]`

**说明：** 匹配这些前缀的数字序列会被过滤掉，避免误识别为手机号

**线程安全：** 是

**示例：**
```objective-c
NSArray *customPrefixes = @[@"SF", @"JD", @"YT", @"EMS"];
[recognizer setTrackingNumberPrefixes:customPrefixes];
```

## 数据模型

### DHPhoneNumberResult

识别结果对象，包含识别出的手机号信息。

#### 属性

```objective-c
@property (nonatomic, copy, readonly) NSString *phoneNumber;
```

识别出的手机号文本。

**类型：** `NSString *`
**访问权限：** 只读
**说明：** 保留格式化后的手机号文本

**示例值：**
- 普通手机号：`@"13812345678"`
- 虚拟转接号：`@"13812345678转123"`
- 隐私号码：`@"138****1234"`

```objective-c
@property (nonatomic, assign, readonly) DHPhoneNumberType type;
```

手机号类型。

**类型：** `DHPhoneNumberType`
**访问权限：** 只读

**可能的值：**
- `DHPhoneNumberTypeRegular` - 普通手机号
- `DHPhoneNumberTypeVirtual` - 虚拟转接号
- `DHPhoneNumberTypePrivacy` - 隐私号码

```objective-c
@property (nonatomic, assign, readonly) CGFloat confidence;
```

置信度分数。

**类型：** `CGFloat`
**访问权限：** 只读
**范围：** 0.0 - 1.0
**说明：** 值越高表示识别结果越可靠

```objective-c
@property (nonatomic, assign, readonly) NSInteger index;
```

在图像中的位置索引。

**类型：** `NSInteger`
**访问权限：** 只读
**说明：** 表示手机号在图像中的相对位置，用于排序

#### 初始化方法

```objective-c
- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber
                               type:(DHPhoneNumberType)type
                         confidence:(CGFloat)confidence
                              index:(NSInteger)index;
```

指定初始化方法。

**参数：**
- `phoneNumber` (`NSString *`) - 手机号文本
- `type` (`DHPhoneNumberType`) - 手机号类型
- `confidence` (`CGFloat`) - 置信度分数
- `index` (`NSInteger`) - 位置索引

**返回值：** 初始化的 DHPhoneNumberResult 实例

```objective-c
+ (instancetype)resultWithPhoneNumber:(NSString *)phoneNumber
                                 type:(DHPhoneNumberType)type
                           confidence:(CGFloat)confidence
                                index:(NSInteger)index;
```

便利构造方法。

**参数：** 同 `initWithPhoneNumber:type:confidence:index:`
**返回值：** 自动释放的 DHPhoneNumberResult 实例

## 枚举和常量

### DHPhoneNumberType

手机号类型枚举。

```objective-c
typedef NS_ENUM(NSInteger, DHPhoneNumberType) {
    DHPhoneNumberTypeRegular = 1 << 0,   // 普通手机号
    DHPhoneNumberTypeVirtual = 1 << 1,   // 虚拟转接号
    DHPhoneNumberTypePrivacy = 1 << 2,   // 隐私号码
};
```

**说明：**
- 使用位掩码设计，支持组合操作
- 每种类型对应不同的识别规则和格式化方式

**类型详情：**

| 类型 | 值 | 说明 | 示例 |
|------|----|----- |------|
| `DHPhoneNumberTypeRegular` | 1 | 11位标准手机号 | `13812345678` |
| `DHPhoneNumberTypeVirtual` | 2 | 带分机号的手机号 | `13812345678转123` |
| `DHPhoneNumberTypePrivacy` | 4 | 部分隐藏的手机号 | `138****1234` |

### DHPhoneNumberTypes

手机号类型位掩码，用于类型过滤。

```objective-c
typedef NS_OPTIONS(NSInteger, DHPhoneNumberTypes) {
    DHPhoneNumberTypesAll = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual | DHPhoneNumberTypePrivacy,
};
```

**常用组合：**

```objective-c
// 识别所有类型
DHPhoneNumberTypes allTypes = DHPhoneNumberTypesAll;

// 只识别普通手机号
DHPhoneNumberTypes regularOnly = DHPhoneNumberTypeRegular;

// 识别普通手机号和虚拟转接号
DHPhoneNumberTypes combined = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual;

// 排除隐私号码
DHPhoneNumberTypes excludePrivacy = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual;
```

### DHPhoneNumberRecognizerErrorCode

错误码枚举。

```objective-c
typedef NS_ENUM(NSInteger, DHPhoneNumberRecognizerErrorCode) {
    DHPhoneNumberRecognizerErrorCodeInvalidImage = 2001,
    DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed = 2002,
    DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter = 2003,
    DHPhoneNumberRecognizerErrorCodeInvalidConfiguration = 2004,
};
```

**错误详情：**

| 错误码 | 值 | 说明 | 解决方案 |
|--------|----|----- |----------|
| `InvalidImage` | 2001 | 输入图像无效 | 检查图像是否为 nil 或损坏 |
| `OCRProcessingFailed` | 2002 | OCR 引擎处理失败 | 检查图像质量，重试 |
| `InvalidTypeFilter` | 2003 | 类型过滤器参数无效 | 使用有效的 DHPhoneNumberTypes 值 |
| `InvalidConfiguration` | 2004 | 配置参数无效 | 检查参数范围和有效性 |

### 错误域

```objective-c
FOUNDATION_EXPORT NSString *const DHPhoneNumberRecognizerErrorDomain;
```

错误域常量，用于创建 NSError 对象。

**值：** `@"DHPhoneNumberRecognizerErrorDomain"`

## 错误处理

### NSError 对象结构

识别失败时，completion 回调会收到包含详细错误信息的 NSError 对象：

```objective-c
NSError *error = // 从回调获取
NSLog(@"错误域: %@", error.domain);           // DHPhoneNumberRecognizerErrorDomain
NSLog(@"错误码: %ld", (long)error.code);      // DHPhoneNumberRecognizerErrorCode 值
NSLog(@"错误描述: %@", error.localizedDescription);
NSLog(@"用户信息: %@", error.userInfo);
```

### 错误处理最佳实践

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    
    if (error) {
        // 记录错误日志
        NSLog(@"DHPhoneNumberRecognizer 错误: %@ (代码: %ld)", 
              error.localizedDescription, (long)error.code);
        
        // 根据错误类型处理
        switch (error.code) {
            case DHPhoneNumberRecognizerErrorCodeInvalidImage:
                // 提示用户重新选择图像
                [self showErrorAlert:@"图像无效，请重新选择"];
                break;
                
            case DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed:
                // 建议用户改善图像质量
                [self showErrorAlert:@"识别失败，请确保图像清晰"];
                break;
                
            case DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter:
                // 开发者错误，修复代码
                NSAssert(NO, @"类型过滤器参数错误");
                break;
                
            case DHPhoneNumberRecognizerErrorCodeInvalidConfiguration:
                // 重置为默认配置
                [recognizer setConfidenceThreshold:0.7];
                [self showErrorAlert:@"配置错误，已重置为默认值"];
                break;
                
            default:
                [self showErrorAlert:@"未知错误，请重试"];
                break;
        }
        return;
    }
    
    // 处理成功结果
    [self handleResults:results];
}];
```

## 回调和代理

### 完成回调

单次识别的完成回调在主线程执行：

```objective-c
typedef void(^DHPhoneNumberRecognitionCompletion)(NSArray<DHPhoneNumberResult *> * _Nullable results, 
                                                NSError * _Nullable error);
```

**参数：**
- `results` - 识别结果数组，失败时为 nil
- `error` - 错误对象，成功时为 nil

**执行线程：** 主线程

### 视频流回调

视频流识别的结果回调在主线程执行：

```objective-c
typedef void(^DHPhoneNumberStreamCallback)(NSArray<DHPhoneNumberResult *> *results);
```

**参数：**
- `results` - 识别结果数组，不会为 nil 但可能为空

**执行线程：** 主线程
**触发条件：** 识别到新的手机号时（去重后）

### 回调注意事项

1. **线程安全**：所有回调都在主线程执行，可以直接更新 UI
2. **内存管理**：回调中的对象都是自动释放的，如需长期持有请手动 retain
3. **错误处理**：始终检查 error 参数，不要假设识别一定成功
4. **去重机制**：视频流回调使用去重机制，相同手机号不会重复触发

## 线程安全

### 线程安全保证

DHPhoneNumberRecognizer 是完全线程安全的：

1. **单例创建**：使用 dispatch_once 确保线程安全
2. **方法调用**：所有公共方法都可以在任意线程调用
3. **内部同步**：使用适当的同步机制保护共享状态
4. **回调执行**：所有回调都在主线程执行

### 并发使用示例

```objective-c
// 可以在多个线程同时调用
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [recognizer recognizePhoneNumbers:image1
                           phoneTypes:DHPhoneNumberTypesAll
                        effectiveArea:CGRectZero
                           completion:^(NSArray *results, NSError *error) {
        // 回调在主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUI1:results];
        });
    }];
});

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [recognizer recognizePhoneNumbers:image2
                           phoneTypes:DHPhoneNumberTypeRegular
                        effectiveArea:CGRectZero
                           completion:^(NSArray *results, NSError *error) {
        // 回调在主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUI2:results];
        });
    }];
});
```

### 性能考虑

1. **避免阻塞主线程**：识别操作在后台线程执行，不会阻塞 UI
2. **控制并发数量**：虽然支持并发，但建议控制同时进行的识别任务数量
3. **内存管理**：及时停止不需要的视频流识别，释放资源

---

## 版本兼容性

- **最低 iOS 版本**：iOS 9.0
- **架构支持**：arm64, armv7
- **Xcode 版本**：Xcode 10.0+

## 依赖关系

- **PaddleLiteTextRecognition**：底层 OCR 引擎
- **OpenCV**：图像处理
- **Foundation**：基础框架
- **UIKit**：UI 相关功能
- **CoreMedia**：视频帧处理