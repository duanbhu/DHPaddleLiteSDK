# PaddleLiteTextRecognition - OCR文本识别SDK

## 简介

PaddleLiteTextRecognition是一个基于PaddleOCR的通用文本识别SDK，提供简洁易用的API来识别图像中的文本内容。该SDK使用PaddleLite引擎和OpenCV进行高效的图像处理，支持中英文文本识别。

### 主要特性

- ✅ **简单易用**：单例模式，只需几行代码即可完成文本识别
- ✅ **高性能**：基于PaddleLite优化引擎，识别速度快
- ✅ **灵活配置**：支持全图识别和指定区域识别
- ✅ **置信度过滤**：可配置置信度阈值，过滤低质量结果
- ✅ **异步处理**：后台线程执行，不阻塞主线程
- ✅ **线程安全**：支持并发调用，适用于多线程环境
- ✅ **结构化结果**：返回文本内容和置信度信息

### 技术栈

- **OCR引擎**：PaddleLite
- **图像处理**：OpenCV
- **模型**：PaddleOCR v5 mobile（检测、识别、方向分类）
- **平台**：iOS 9.0+

## 快速开始

### 基本使用

```objective-c
#import <PaddleLiteTextRecognition.h>

// 1. 获取SDK实例
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];

// 2. 准备图像
UIImage *image = [UIImage imageNamed:@"document.jpg"];

// 3. 执行识别
[ocr recognizeImage:image
      effectiveArea:CGRectZero  // CGRectZero表示识别整个图像
         completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    // 4. 处理识别结果
    for (DLTextRecognitionResult *result in results) {
        NSLog(@"文本: %@, 置信度: %.2f", result.text, result.confidence);
    }
}];
```

## 使用示例

### 示例1：识别整张图像

识别图像中的所有文本内容：

```objective-c
UIImage *image = [UIImage imageNamed:@"receipt.jpg"];

[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    // 拼接所有识别的文本
    NSMutableString *fullText = [NSMutableString string];
    for (DLTextRecognitionResult *result in results) {
        [fullText appendFormat:@"%@\n", result.text];
    }
    
    NSLog(@"完整文本:\n%@", fullText);
}];
```

### 示例2：识别指定区域

只识别图像中的特定区域（例如：身份证号码区域）：

```objective-c
UIImage *image = [UIImage imageNamed:@"id_card.jpg"];

// 定义感兴趣区域（ROI）- 身份证号码区域
// 坐标系统：原点在图像左上角，单位为像素
CGRect idNumberRegion = CGRectMake(100, 300, 400, 50);

[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:idNumberRegion
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    // 提取身份证号码
    if (results.count > 0) {
        NSString *idNumber = results.firstObject.text;
        NSLog(@"身份证号码: %@", idNumber);
    }
}];
```

### 示例3：配置置信度阈值

调整置信度阈值以平衡准确性和召回率：

```objective-c
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];

// 设置较高的阈值，只返回高置信度的结果
[ocr setConfidenceThreshold:0.85];

UIImage *image = [UIImage imageNamed:@"blurry_text.jpg"];

[ocr recognizeImage:image
      effectiveArea:CGRectZero
         completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    // 只会返回置信度 >= 0.85 的结果
    for (DLTextRecognitionResult *result in results) {
        NSLog(@"高置信度文本: %@ (%.2f)", result.text, result.confidence);
    }
}];
```

### 示例4：处理识别结果

根据置信度和位置处理识别结果：

```objective-c
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    // 按置信度分类
    NSMutableArray *highConfidence = [NSMutableArray array];
    NSMutableArray *mediumConfidence = [NSMutableArray array];
    
    for (DLTextRecognitionResult *result in results) {
        if (result.confidence >= 0.9) {
            [highConfidence addObject:result];
        } else if (result.confidence >= 0.7) {
            [mediumConfidence addObject:result];
        }
    }
    
    NSLog(@"高置信度结果 (>=0.9): %lu条", (unsigned long)highConfidence.count);
    NSLog(@"中等置信度结果 (0.7-0.9): %lu条", (unsigned long)mediumConfidence.count);
    
    // 结果已按位置排序（从上到下，从左到右）
    NSLog(@"第一行文本: %@", results.firstObject.text);
    NSLog(@"最后一行文本: %@", results.lastObject.text);
}];
```

### 示例5：在主线程更新UI

识别完成后在主线程更新UI：

```objective-c
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    // 切换到主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            self.statusLabel.text = @"识别失败";
            return;
        }
        
        // 更新UI
        NSMutableString *text = [NSMutableString string];
        for (DLTextRecognitionResult *result in results) {
            [text appendFormat:@"%@\n", result.text];
        }
        self.resultTextView.text = text;
        self.statusLabel.text = [NSString stringWithFormat:@"识别到%lu行文本", (unsigned long)results.count];
    });
}];
```

### 示例6：批量处理多张图像

处理多张图像并收集结果：

```objective-c
NSArray *images = @[
    [UIImage imageNamed:@"page1.jpg"],
    [UIImage imageNamed:@"page2.jpg"],
    [UIImage imageNamed:@"page3.jpg"]
];

dispatch_group_t group = dispatch_group_create();
NSMutableArray *allResults = [NSMutableArray array];

for (UIImage *image in images) {
    dispatch_group_enter(group);
    
    [[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                                  effectiveArea:CGRectZero
                                                     completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
        if (!error && results) {
            @synchronized (allResults) {
                [allResults addObject:results];
            }
        }
        dispatch_group_leave(group);
    }];
}

// 等待所有识别完成
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"批量识别完成，共处理%lu张图像", (unsigned long)allResults.count);
});
```

## API参考

### PaddleLiteTextRecognition

主SDK类，提供OCR文本识别功能。

#### 方法

##### `+ (instancetype)sharedInstance`

获取单例实例。

**返回值**：PaddleLiteTextRecognition的单例对象

**示例**：
```objective-c
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];
```

---

##### `- (void)recognizeImage:effectiveArea:completion:`

识别图像中的文本。

**参数**：
- `image`：输入图像（UIImage），必须为有效对象
- `rect`：有效识别区域（CGRect），CGRectZero表示识别整个图像
- `completion`：完成回调，返回识别结果数组或错误

**回调参数**：
- `results`：识别结果数组（NSArray<DLTextRecognitionResult *>），按位置排序
- `error`：错误对象（NSError），成功时为nil

**示例**：
```objective-c
[ocr recognizeImage:image
      effectiveArea:CGRectZero
         completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    // 处理结果
}];
```

---

##### `- (void)setConfidenceThreshold:(CGFloat)threshold`

设置置信度阈值。

**参数**：
- `threshold`：置信度阈值，范围[0.0, 1.0]，默认0.7

**示例**：
```objective-c
[ocr setConfidenceThreshold:0.8];
```

---

##### `- (CGFloat)confidenceThreshold`

获取当前置信度阈值。

**返回值**：当前配置的置信度阈值

**示例**：
```objective-c
CGFloat threshold = [ocr confidenceThreshold];
```

### DLTextRecognitionResult

识别结果数据模型。

#### 属性

##### `text`（NSString，只读）

识别出的文本内容。

##### `confidence`（CGFloat，只读）

置信度分数，范围[0.0, 1.0]。

##### `index`（NSInteger，只读）

文本在图像中的位置索引，从0开始。

## 错误处理

### 错误码

SDK定义了以下错误码（`PaddleLiteTextRecognitionErrorCode`）：

| 错误码 | 常量 | 说明 |
|-------|------|------|
| 1001 | `PaddleLiteTextRecognitionErrorCodeInvalidImage` | 无效图像：输入图像为nil或无效 |
| 1002 | `PaddleLiteTextRecognitionErrorCodeUnsupportedFormat` | 不支持的格式：图像格式不支持或转换失败 |
| 1003 | `PaddleLiteTextRecognitionErrorCodeModelLoadFailed` | 模型加载失败：OCR模型文件加载失败 |
| 1004 | `PaddleLiteTextRecognitionErrorCodeProcessingFailed` | 处理失败：OCR识别过程中发生异常 |
| 1005 | `PaddleLiteTextRecognitionErrorCodeInvalidThreshold` | 无效阈值：置信度阈值超出有效范围 |

### 错误处理示例

```objective-c
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (error) {
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
            default:
                NSLog(@"未知错误: %@", error.localizedDescription);
                break;
        }
        return;
    }
    
    // 处理成功结果
}];
```

## 配置指南

### 置信度阈值配置

置信度阈值决定了哪些识别结果会被返回。选择合适的阈值对于平衡准确性和召回率很重要。

#### 推荐配置

| 场景 | 推荐阈值 | 说明 |
|------|---------|------|
| 高质量图像（清晰、光线好） | 0.5 - 0.7 | 可以使用较低阈值获取更多文本 |
| 中等质量图像 | 0.7 - 0.8 | 默认值，平衡准确性和召回率 |
| 低质量图像（模糊、光线差） | 0.8 - 0.9 | 使用较高阈值确保准确性 |
| 对准确性要求极高 | 0.9 - 1.0 | 只返回最可靠的结果 |
| 需要尽可能多的文本 | 0.3 - 0.5 | 可能包含一些错误识别 |

#### 动态调整示例

```objective-c
// 根据图像质量动态调整阈值
- (void)recognizeImageWithAdaptiveThreshold:(UIImage *)image {
    PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];
    
    // 评估图像质量（示例：基于图像大小和亮度）
    CGFloat imageQuality = [self evaluateImageQuality:image];
    
    if (imageQuality > 0.8) {
        [ocr setConfidenceThreshold:0.6];  // 高质量图像
    } else if (imageQuality > 0.5) {
        [ocr setConfidenceThreshold:0.7];  // 中等质量图像
    } else {
        [ocr setConfidenceThreshold:0.85]; // 低质量图像
    }
    
    [ocr recognizeImage:image effectiveArea:CGRectZero completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
        // 处理结果
    }];
}
```

## 性能优化

### 最佳实践

1. **复用SDK实例**：使用单例模式，避免重复初始化
2. **合理设置识别区域**：只识别需要的区域可以提高速度
3. **图像预处理**：在传入SDK前进行适当的图像预处理（调整大小、增强对比度）
4. **批量处理**：使用GCD并发处理多张图像
5. **内存管理**：及时释放不需要的图像对象

### 性能指标

在iPhone 8及以上设备上的典型性能：

- **单张图像识别时间**：< 500ms
- **内存使用**：< 100MB
- **并发支持**：支持至少3个并发请求

### 优化示例

```objective-c
// 图像预处理优化
- (UIImage *)preprocessImage:(UIImage *)originalImage {
    // 调整图像大小以提高处理速度
    CGFloat maxDimension = 1280;
    CGSize size = originalImage.size;
    
    if (size.width > maxDimension || size.height > maxDimension) {
        CGFloat scale = MIN(maxDimension / size.width, maxDimension / size.height);
        CGSize newSize = CGSizeMake(size.width * scale, size.height * scale);
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [originalImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resizedImage;
    }
    
    return originalImage;
}
```

## 常见问题

### Q: 为什么识别结果为空？

**A**: 可能的原因：
1. 图像中没有文本
2. 置信度阈值设置过高，过滤掉了所有结果
3. 图像质量太差，无法识别
4. 指定的识别区域不包含文本

**解决方法**：
- 降低置信度阈值
- 检查图像质量
- 使用CGRectZero识别整个图像

### Q: 如何提高识别准确率？

**A**: 建议：
1. 使用高质量、清晰的图像
2. 确保文本区域光线充足
3. 提高置信度阈值（0.8-0.9）
4. 对图像进行预处理（增强对比度、去噪）
5. 只识别包含文本的区域

### Q: 回调在哪个线程执行？

**A**: 回调不保证在主线程执行。如果需要更新UI，请使用`dispatch_async`切换到主线程：

```objective-c
completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新UI
    });
}
```

### Q: 支持哪些图像格式？

**A**: SDK支持UIImage支持的所有格式（JPEG、PNG、BMP等）。RGBA格式会自动转换为RGB。

### Q: 可以同时处理多张图像吗？

**A**: 可以。SDK是线程安全的，支持并发调用。建议使用GCD的dispatch_group来管理批量处理。

### Q: 如何识别特定语言的文本？

**A**: 当前版本使用的PaddleOCR模型支持中英文混合识别。如需识别其他语言，需要替换相应的模型文件。

## 技术支持

如有问题或建议，请联系技术支持团队。

## 故障排除

遇到问题？请查看 [故障排除指南](TROUBLESHOOTING.md) 获取常见问题的解决方案。

常见问题包括：
- 模型文件不存在错误
- SDK初始化失败
- 识别结果为空
- 线程安全问题

## 许可证

本SDK基于PaddleLite和PaddleOCR开发，遵循Apache 2.0许可证。
