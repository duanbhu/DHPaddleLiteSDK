# PaddleLiteTextRecognition API 参考文档

## 概述

本文档提供 PaddleLiteTextRecognition SDK 的完整 API 参考，包括所有类、方法、属性和常量的详细说明。

## 目录

- [PaddleLiteTextRecognition 类](#paddlelitetextrecognition-类)
- [DLTextRecognitionResult 类](#dltextrecognitionresult-类)
- [错误处理](#错误处理)
- [常量定义](#常量定义)

---

## PaddleLiteTextRecognition 类

### 类描述

`PaddleLiteTextRecognition` 是 OCR 文本识别 SDK 的主类，提供文本识别功能。

**继承关系：** `NSObject`

**线程安全：** 是

**单例模式：** 是

### 类方法

#### `+ (instancetype)sharedInstance`

获取 SDK 的单例实例。

**返回值：**
- `instancetype` - PaddleLiteTextRecognition 的单例对象

**说明：**
- 该方法返回全局唯一的 SDK 实例
- 多次调用返回同一个实例
- 线程安全，可以在任何线程调用

**示例：**
```objective-c
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];
```

---

### 实例方法

#### `- (void)recognizeImage:effectiveArea:completion:`

识别图像中的文本内容。

**方法签名：**
```objective-c
- (void)recognizeImage:(UIImage *)image
        effectiveArea:(CGRect)rect
           completion:(void(^)(NSArray<DLTextRecognitionResult *> * _Nullable results, 
                              NSError * _Nullable error))completion;
```

**参数：**

| 参数名 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `image` | `UIImage *` | 是 | 输入图像，必须为有效的 UIImage 对象 |
| `rect` | `CGRect` | 是 | 有效识别区域。传入 `CGRectZero` 表示识别整个图像 |
| `completion` | `Block` | 是 | 完成回调，在识别完成或发生错误时调用 |

**回调参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `results` | `NSArray<DLTextRecognitionResult *> *` | 识别结果数组，按文本在图像中的位置排序。识别失败时为 `nil` |
| `error` | `NSError *` | 错误对象，识别成功时为 `nil` |

**说明：**
- 识别操作在后台线程异步执行
- 回调不保证在主线程执行，如需更新 UI 请切换到主线程
- 只返回置信度大于等于设置阈值的结果
- 结果按照从上到下、从左到右的顺序排列
- 如果没有识别到文本，返回空数组（不是 `nil`）

**坐标系统：**
- 原点在图像左上角
- 单位为像素
- X 轴向右，Y 轴向下

**错误情况：**
- 输入图像为 `nil`：返回 `PaddleLiteTextRecognitionErrorCodeInvalidImage` 错误
- 图像格式不支持：返回 `PaddleLiteTextRecognitionErrorCodeUnsupportedFormat` 错误
- 处理失败：返回 `PaddleLiteTextRecognitionErrorCodeProcessingFailed` 错误

**示例：**

```objective-c
// 识别整张图像
UIImage *image = [UIImage imageNamed:@"document.jpg"];
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    for (DLTextRecognitionResult *result in results) {
        NSLog(@"文本: %@, 置信度: %.2f", result.text, result.confidence);
    }
}];

// 识别指定区域
CGRect region = CGRectMake(100, 200, 300, 50);
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:region
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    // 处理结果
}];

// 在主线程更新 UI
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新 UI
        self.resultLabel.text = results.firstObject.text;
    });
}];
```

---

#### `- (void)setConfidenceThreshold:(CGFloat)threshold`

设置置信度阈值。

**方法签名：**
```objective-c
- (void)setConfidenceThreshold:(CGFloat)threshold;
```

**参数：**

| 参数名 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `threshold` | `CGFloat` | 是 | 置信度阈值，有效范围为 0.0 到 1.0 |

**说明：**
- 只有置信度大于等于该阈值的识别结果才会被返回
- 默认值为 0.7
- 超出有效范围的值会被自动限制在 [0.0, 1.0] 范围内
- 设置立即生效，影响后续所有识别操作
- 不影响已经开始的识别操作

**阈值选择建议：**

| 阈值范围 | 适用场景 | 特点 |
|---------|---------|------|
| 0.0 - 0.5 | 需要尽可能多的文本 | 召回率高，但可能包含错误识别 |
| 0.5 - 0.7 | 高质量图像 | 平衡准确性和召回率 |
| 0.7 - 0.8 | 中等质量图像 | 默认推荐值 |
| 0.8 - 0.9 | 低质量图像或高准确性要求 | 准确性高，但可能遗漏一些文本 |
| 0.9 - 1.0 | 对准确性要求极高 | 只返回最可靠的结果 |

**示例：**

```objective-c
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];

// 设置较低阈值，获取更多结果
[ocr setConfidenceThreshold:0.5];

// 设置较高阈值，确保准确性
[ocr setConfidenceThreshold:0.85];

// 使用默认阈值
[ocr setConfidenceThreshold:0.7];

// 超出范围的值会被限制
[ocr setConfidenceThreshold:1.5];  // 实际设置为 1.0
[ocr setConfidenceThreshold:-0.1]; // 实际设置为 0.0
```

---

#### `- (CGFloat)confidenceThreshold`

获取当前置信度阈值。

**方法签名：**
```objective-c
- (CGFloat)confidenceThreshold;
```

**返回值：**
- `CGFloat` - 当前配置的置信度阈值，范围为 0.0 到 1.0

**说明：**
- 返回当前生效的置信度阈值
- 默认值为 0.7

**示例：**

```objective-c
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];

// 获取当前阈值
CGFloat currentThreshold = [ocr confidenceThreshold];
NSLog(@"当前置信度阈值: %.2f", currentThreshold);

// 根据当前阈值做决策
if (currentThreshold < 0.7) {
    NSLog(@"当前阈值较低，可能返回较多结果");
} else {
    NSLog(@"当前阈值较高，只返回高质量结果");
}
```

---

## DLTextRecognitionResult 类

### 类描述

`DLTextRecognitionResult` 封装了单行文本的 OCR 识别结果。

**继承关系：** `NSObject`

**不可变性：** 所有属性为只读

### 属性

#### `text`

识别出的文本内容。

**类型：** `NSString *`

**访问权限：** 只读

**说明：**
- 包含 OCR 识别出的完整文本字符串
- 对于中英文混合文本，保持原始顺序
- 不会为 `nil`，但可能为空字符串

**示例：**
```objective-c
DLTextRecognitionResult *result = results.firstObject;
NSString *text = result.text;
NSLog(@"识别文本: %@", text);
```

---

#### `confidence`

置信度分数。

**类型：** `CGFloat`

**访问权限：** 只读

**取值范围：** 0.0 到 1.0

**说明：**
- 表示 OCR 识别结果的可信程度
- 值越高表示识别结果越可靠
- 只有置信度大于等于设置阈值的结果才会被返回

**置信度解读：**

| 置信度范围 | 可信程度 | 说明 |
|-----------|---------|------|
| 0.9 - 1.0 | 非常高 | 识别结果几乎确定正确 |
| 0.7 - 0.9 | 较高 | 识别结果大概率正确 |
| 0.5 - 0.7 | 中等 | 识别结果可能存在错误 |
| 0.0 - 0.5 | 低 | 识别结果不太可靠 |

**示例：**
```objective-c
DLTextRecognitionResult *result = results.firstObject;
CGFloat confidence = result.confidence;

if (confidence >= 0.9) {
    NSLog(@"高置信度结果: %@ (%.2f)", result.text, confidence);
} else if (confidence >= 0.7) {
    NSLog(@"中等置信度结果: %@ (%.2f)", result.text, confidence);
} else {
    NSLog(@"低置信度结果: %@ (%.2f)", result.text, confidence);
}
```

---

#### `index`

文本在图像中的位置索引。

**类型：** `NSInteger`

**访问权限：** 只读

**取值范围：** >= 0

**说明：**
- 表示该文本行在图像中的相对位置
- 按照从上到下、从左到右的顺序排列
- 索引从 0 开始
- 可用于保持文本的原始顺序或重建空间布局

**示例：**
```objective-c
for (DLTextRecognitionResult *result in results) {
    NSLog(@"位置 %ld: %@", (long)result.index, result.text);
}

// 输出：
// 位置 0: 第一行文本
// 位置 1: 第二行文本
// 位置 2: 第三行文本
```

---

### 初始化方法

#### `- (instancetype)initWithText:confidence:index:`

初始化识别结果对象。

**方法签名：**
```objective-c
- (instancetype)initWithText:(NSString *)text
                  confidence:(CGFloat)confidence
                       index:(NSInteger)index;
```

**参数：**

| 参数名 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `text` | `NSString *` | 是 | 识别出的文本内容，不能为 `nil` |
| `confidence` | `CGFloat` | 是 | 置信度分数，范围 [0.0, 1.0] |
| `index` | `NSInteger` | 是 | 位置索引，从 0 开始 |

**返回值：**
- `instancetype` - 初始化的 DLTextRecognitionResult 实例

**说明：**
- 该方法通常由 SDK 内部调用
- 开发者一般不需要手动创建实例
- 如果 `confidence` 超出有效范围，会被自动限制在 [0.0, 1.0] 范围内

**示例：**
```objective-c
// 通常不需要手动创建，SDK 会自动创建
DLTextRecognitionResult *result = [[DLTextRecognitionResult alloc] initWithText:@"示例文本"
                                                                      confidence:0.95
                                                                           index:0];
```

---

## 错误处理

### 错误域

**常量名：** `PaddleLiteTextRecognitionErrorDomain`

**类型：** `NSString *`

**值：** `"com.paddlelite.textrecognition.error"`

**说明：**
- 用于标识 PaddleLiteTextRecognition 相关的错误
- 所有 SDK 返回的错误都使用该错误域

---

### 错误码

**枚举名：** `PaddleLiteTextRecognitionErrorCode`

**类型：** `NSInteger`

#### 错误码列表

| 错误码 | 常量名 | 值 | 说明 |
|-------|--------|---|------|
| 无效图像 | `PaddleLiteTextRecognitionErrorCodeInvalidImage` | 1001 | 输入图像为 `nil` 或无效 |
| 不支持的格式 | `PaddleLiteTextRecognitionErrorCodeUnsupportedFormat` | 1002 | 图像格式不支持或转换失败 |
| 模型加载失败 | `PaddleLiteTextRecognitionErrorCodeModelLoadFailed` | 1003 | OCR 模型文件加载失败 |
| 处理失败 | `PaddleLiteTextRecognitionErrorCodeProcessingFailed` | 1004 | OCR 识别过程中发生异常 |
| 无效阈值 | `PaddleLiteTextRecognitionErrorCodeInvalidThreshold` | 1005 | 置信度阈值超出有效范围 |

#### 错误处理示例

```objective-c
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        // 检查错误域
        if ([error.domain isEqualToString:PaddleLiteTextRecognitionErrorDomain]) {
            // 根据错误码处理
            switch (error.code) {
                case PaddleLiteTextRecognitionErrorCodeInvalidImage:
                    NSLog(@"图像无效，请检查输入");
                    break;
                    
                case PaddleLiteTextRecognitionErrorCodeUnsupportedFormat:
                    NSLog(@"图像格式不支持");
                    break;
                    
                case PaddleLiteTextRecognitionErrorCodeModelLoadFailed:
                    NSLog(@"模型加载失败，请检查模型文件");
                    break;
                    
                case PaddleLiteTextRecognitionErrorCodeProcessingFailed:
                    NSLog(@"识别处理失败: %@", error.localizedDescription);
                    break;
                    
                case PaddleLiteTextRecognitionErrorCodeInvalidThreshold:
                    NSLog(@"无效的置信度阈值");
                    break;
                    
                default:
                    NSLog(@"未知错误: %@", error.localizedDescription);
                    break;
            }
        }
        return;
    }
    
    // 处理成功结果
}];
```

---

## 常量定义

### 默认值

| 常量 | 值 | 说明 |
|------|---|------|
| 默认置信度阈值 | 0.7 | SDK 初始化时的默认置信度阈值 |
| 最小置信度阈值 | 0.0 | 置信度阈值的最小值 |
| 最大置信度阈值 | 1.0 | 置信度阈值的最大值 |

### 特殊值

| 常量 | 值 | 说明 |
|------|---|------|
| 全图识别区域 | `CGRectZero` | 传入此值表示识别整个图像 |

---

## 类型定义

### 完成回调类型

```objective-c
typedef void(^PaddleLiteTextRecognitionCompletion)(NSArray<DLTextRecognitionResult *> * _Nullable results, 
                                                    NSError * _Nullable error);
```

**说明：**
- 识别完成时调用的回调类型
- `results` 和 `error` 互斥：成功时 `error` 为 `nil`，失败时 `results` 为 `nil`

---

## 线程安全说明

### 线程安全的方法

以下方法是线程安全的，可以在任何线程调用：

- `+ (instancetype)sharedInstance`
- `- (void)recognizeImage:effectiveArea:completion:`
- `- (void)setConfidenceThreshold:`
- `- (CGFloat)confidenceThreshold`

### 回调线程

- 完成回调不保证在主线程执行
- 如需更新 UI，请使用 `dispatch_async` 切换到主线程

**示例：**
```objective-c
[ocr recognizeImage:image effectiveArea:CGRectZero completion:^(NSArray *results, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 在主线程更新 UI
        self.resultLabel.text = results.firstObject.text;
    });
}];
```

---

## 性能指标

### 典型性能（iPhone 8 及以上设备）

| 指标 | 值 | 说明 |
|------|---|------|
| 单张图像识别时间 | < 500ms | 1280x720 分辨率图像 |
| 内存使用 | < 100MB | 峰值内存占用 |
| 并发支持 | >= 3 | 同时处理的请求数 |

### 性能优化建议

1. **图像尺寸**：建议将图像调整到 1280x720 或更小
2. **识别区域**：只识别需要的区域可以提高速度
3. **批量处理**：使用 GCD 并发处理多张图像
4. **复用实例**：使用单例模式，避免重复初始化

---

## 版本历史

### v1.0.0
- 初始版本
- 支持中英文文本识别
- 支持全图和区域识别
- 支持置信度阈值配置
- 线程安全设计

---

## 相关文档

- [README.md](README.md) - 完整使用文档
- [QUICK_START.md](QUICK_START.md) - 快速入门指南
- [OCRExamples.m](../../../Example/OCRExamples.m) - 示例代码

---

## 技术支持

如有问题或建议，请联系技术支持团队。
