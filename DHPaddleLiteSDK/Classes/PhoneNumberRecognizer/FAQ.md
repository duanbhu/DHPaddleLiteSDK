# DHPhoneNumberRecognizer 常见问题解答

本文档收集了使用 DHPhoneNumberRecognizer 时的常见问题和解决方案。

## 目录

- [基础使用问题](#基础使用问题)
- [识别准确性问题](#识别准确性问题)
- [性能优化问题](#性能优化问题)
- [集成和配置问题](#集成和配置问题)
- [错误处理问题](#错误处理问题)
- [高级功能问题](#高级功能问题)

## 基础使用问题

### Q1: 如何开始使用 DHPhoneNumberRecognizer？

**A:** 按照以下步骤快速开始：

1. 导入必要的头文件：
```objective-c
#import <DLPaddleLiteSDK/DHPhoneNumberRecognizer.h>
#import <DLPaddleLiteSDK/DHPhoneNumberResult.h>
```

2. 获取单例实例：
```objective-c
DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
```

3. 执行识别：
```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    // 处理结果
}];
```

详细步骤请参考 [快速开始指南](QUICK_START.md)。

### Q2: 支持哪些手机号格式？

**A:** DHPhoneNumberRecognizer 支持三种类型的手机号：

1. **普通手机号**（11位标准格式）
   - `13812345678`
   - `138-1234-5678`
   - `138 1234 5678`

2. **虚拟转接号**（带分机号）
   - `13812345678转123`
   - `13812345678-123`
   - `13812345678 ext 123`
   - `13812345678,123`

3. **隐私号码**（部分隐藏）
   - `138****1234`
   - `****1234`
   - `138米米米米1234`（支持多种星号字符）

### Q3: 如何只识别特定类型的手机号？

**A:** 使用类型过滤器参数：

```objective-c
// 只识别普通手机号
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypeRegular
                    effectiveArea:CGRectZero
                       completion:completion];

// 同时识别普通手机号和虚拟转接号
DHPhoneNumberTypes combinedTypes = DHPhoneNumberTypeRegular | DHPhoneNumberTypeVirtual;
[recognizer recognizePhoneNumbers:image
                       phoneTypes:combinedTypes
                    effectiveArea:CGRectZero
                       completion:completion];
```

## 识别准确性问题

### Q4: 为什么识别结果为空？

**A:** 可能的原因和解决方案：

1. **图像质量问题**
   - 确保图像清晰，分辨率足够（建议 > 300 DPI）
   - 检查光照条件，避免过暗或过亮
   - 确保手机号完整可见，没有被遮挡

2. **置信度阈值过高**
   ```objective-c
   // 尝试降低置信度阈值
   [recognizer setConfidenceThreshold:0.6];
   ```

3. **手机号格式不符合规则**
   - 确认是否为中国大陆11位手机号格式
   - 检查是否被运单号过滤器误过滤

4. **类型过滤器设置错误**
   ```objective-c
   // 确保使用正确的类型过滤器
   [recognizer recognizePhoneNumbers:image
                          phoneTypes:DHPhoneNumberTypesAll  // 识别所有类型
                       effectiveArea:CGRectZero
                          completion:completion];
   ```

### Q5: 如何提高识别准确率？

**A:** 以下策略可以提高准确率：

1. **图像预处理**
   - 调整图像对比度和亮度
   - 去除噪声和干扰
   - 确保图像方向正确

2. **配置优化**
   ```objective-c
   // 启用错误修正
   [recognizer setOCRCorrectionEnabled:YES];
   
   // 设置适当的置信度阈值
   [recognizer setConfidenceThreshold:0.8];
   
   // 配置运单号过滤
   NSArray *prefixes = @[@"YT", @"SF", @"JD"];
   [recognizer setTrackingNumberPrefixes:prefixes];
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

### Q6: 为什么会误识别运单号为手机号？

**A:** 运单号通常包含数字序列，可能被误识别。解决方案：

1. **启用运单号过滤**
   ```objective-c
   NSArray *trackingPrefixes = @[@"YT", @"ZT", @"SF", @"JD", @"TT", @"JT"];
   [recognizer setTrackingNumberPrefixes:trackingPrefixes];
   ```

2. **添加自定义前缀**
   ```objective-c
   // 根据业务需要添加更多前缀
   NSArray *customPrefixes = @[@"YT", @"SF", @"JD", @"EMS", @"STO"];
   [recognizer setTrackingNumberPrefixes:customPrefixes];
   ```

3. **提高置信度阈值**
   ```objective-c
   [recognizer setConfidenceThreshold:0.85];  // 减少误识别
   ```

## 性能优化问题

### Q7: 视频流识别卡顿怎么办？

**A:** 性能优化策略：

1. **降低帧率**
   ```objective-c
   // 使用较低的帧率
   [recognizer startStreamRecognition:DHPhoneNumberTypesAll
                            frameRate:2  // 2-3 FPS 即可
                             callback:callback];
   ```

2. **限制识别类型**
   ```objective-c
   // 只识别需要的类型
   [recognizer startStreamRecognition:DHPhoneNumberTypeRegular
                            frameRate:2
                             callback:callback];
   ```

3. **在后台线程处理视频帧**
   ```objective-c
   - (void)captureOutput:(AVCaptureOutput *)output 
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
          fromConnection:(AVCaptureConnection *)connection {
       
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           [recognizer processVideoFrame:sampleBuffer];
       });
   }
   ```

### Q8: 批量处理时内存占用过高怎么办？

**A:** 内存优化方案：

1. **控制并发数量**
   ```objective-c
   NSOperationQueue *queue = [[NSOperationQueue alloc] init];
   queue.maxConcurrentOperationCount = 3;  // 限制并发数
   
   for (UIImage *image in images) {
       [queue addOperationWithBlock:^{
           [recognizer recognizePhoneNumbers:image
                                  phoneTypes:DHPhoneNumberTypesAll
                               effectiveArea:CGRectZero
                                  completion:completion];
       }];
   }
   ```

2. **分批处理**
   ```objective-c
   NSInteger batchSize = 5;
   for (NSInteger i = 0; i < images.count; i += batchSize) {
       NSInteger endIndex = MIN(i + batchSize, images.count);
       NSArray *batch = [images subarrayWithRange:NSMakeRange(i, endIndex - i)];
       
       // 处理当前批次
       [self processBatch:batch completion:^{
           // 批次完成后再处理下一批
       }];
   }
   ```

3. **及时释放资源**
   ```objective-c
   // 及时停止视频流识别
   - (void)viewDidDisappear:(BOOL)animated {
       [super viewDidDisappear:animated];
       [recognizer stopStreamRecognition];
   }
   ```

### Q9: 如何测试识别性能？

**A:** 使用性能测试示例：

```objective-c
[PhoneNumberRecognizerExamples example17_PerformanceTesting:image
                                                 iterations:10
                                                 completion:^(NSDictionary *performance) {
    NSLog(@"平均处理时间: %.3f秒", [performance[@"averageProcessingTime"] doubleValue]);
    NSLog(@"估计FPS: %.1f", [performance[@"estimatedFPS"] doubleValue]);
    NSLog(@"最快处理时间: %.3f秒", [performance[@"minProcessingTime"] doubleValue]);
    NSLog(@"最慢处理时间: %.3f秒", [performance[@"maxProcessingTime"] doubleValue]);
}];
```

## 集成和配置问题

### Q10: 如何集成到现有项目？

**A:** 集成步骤：

1. **添加依赖**（如果使用 CocoaPods）
   ```ruby
   # Podfile
   pod 'DLPaddleLiteSDK'
   ```

2. **手动集成**
   - 将 DLPaddleLiteSDK.framework 添加到项目
   - 在 Build Settings 中添加必要的链接库
   - 确保 Bundle 中包含模型文件

3. **导入头文件**
   ```objective-c
   #import <DLPaddleLiteSDK/DHPhoneNumberRecognizer.h>
   ```

4. **检查集成**
   ```objective-c
   DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
   NSLog(@"集成成功: %@", recognizer ? @"是" : @"否");
   ```

### Q11: 如何配置不同场景的参数？

**A:** 针对不同场景的推荐配置：

1. **名片识别场景**
   ```objective-c
   [recognizer setConfidenceThreshold:0.8];      // 高准确性
   [recognizer setOCRCorrectionEnabled:YES];     // 启用错误修正
   // 识别所有类型的手机号
   ```

2. **文档扫描场景**
   ```objective-c
   [recognizer setConfidenceThreshold:0.7];      // 平衡准确性和召回率
   [recognizer setOCRCorrectionEnabled:YES];
   NSArray *prefixes = @[@"YT", @"SF", @"JD", @"EMS"];
   [recognizer setTrackingNumberPrefixes:prefixes];  // 过滤运单号
   ```

3. **实时相机扫描场景**
   ```objective-c
   [recognizer setConfidenceThreshold:0.85];     // 高准确性，减少误识别
   [recognizer setOCRCorrectionEnabled:YES];
   // 使用较低的帧率：2-3 FPS
   ```

### Q12: 支持哪些 iOS 版本？

**A:** 系统要求：

- **最低 iOS 版本**：iOS 9.0
- **推荐 iOS 版本**：iOS 11.0+
- **架构支持**：arm64, armv7
- **Xcode 版本**：Xcode 10.0+

## 错误处理问题

### Q13: 如何处理识别错误？

**A:** 完整的错误处理示例：

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    
    if (error) {
        NSLog(@"识别错误: %@ (代码: %ld)", error.localizedDescription, (long)error.code);
        
        switch (error.code) {
            case DHPhoneNumberRecognizerErrorCodeInvalidImage:
                [self showAlert:@"图像无效" message:@"请重新选择图像"];
                break;
                
            case DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed:
                [self showAlert:@"识别失败" message:@"请检查图像质量或重试"];
                break;
                
            case DHPhoneNumberRecognizerErrorCodeInvalidTypeFilter:
                NSAssert(NO, @"开发者错误：类型过滤器参数无效");
                break;
                
            case DHPhoneNumberRecognizerErrorCodeInvalidConfiguration:
                // 重置为默认配置
                [recognizer setConfidenceThreshold:0.7];
                [self showAlert:@"配置错误" message:@"已重置为默认配置"];
                break;
                
            default:
                [self showAlert:@"未知错误" message:@"请重试"];
                break;
        }
        return;
    }
    
    // 处理成功结果
    [self handleResults:results];
}];
```

### Q14: 为什么会出现 OCR 处理失败错误？

**A:** 可能的原因和解决方案：

1. **图像质量问题**
   - 图像过于模糊或分辨率太低
   - 光照条件不佳
   - 图像格式不支持

2. **内存不足**
   - 图像尺寸过大
   - 同时处理的图像过多
   - 设备内存不足

3. **模型文件问题**
   - 模型文件损坏或缺失
   - 模型版本不兼容

**解决方案：**
```objective-c
// 1. 检查图像有效性
if (!image || image.size.width == 0 || image.size.height == 0) {
    NSLog(@"图像无效");
    return;
}

// 2. 压缩大图像
if (image.size.width > 2000 || image.size.height > 2000) {
    image = [self resizeImage:image toMaxSize:CGSizeMake(2000, 2000)];
}

// 3. 重试机制
[self retryRecognition:image maxRetries:3];
```

## 高级功能问题

### Q15: 如何实现自定义的结果过滤？

**A:** 在回调中添加自定义过滤逻辑：

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    
    if (error) return;
    
    // 自定义过滤逻辑
    NSMutableArray *filteredResults = [NSMutableArray array];
    
    for (DHPhoneNumberResult *result in results) {
        // 1. 置信度过滤
        if (result.confidence < 0.8) continue;
        
        // 2. 长度过滤
        if (result.phoneNumber.length < 11) continue;
        
        // 3. 自定义规则过滤
        if ([self isValidPhoneNumber:result.phoneNumber]) {
            [filteredResults addObject:result];
        }
    }
    
    [self handleFilteredResults:filteredResults];
}];
```

### Q16: 如何实现结果去重？

**A:** 使用 NSSet 或自定义去重逻辑：

```objective-c
// 方法1：基于手机号文本去重
NSMutableSet *phoneNumbers = [NSMutableSet set];
NSMutableArray *uniqueResults = [NSMutableArray array];

for (DHPhoneNumberResult *result in results) {
    if (![phoneNumbers containsObject:result.phoneNumber]) {
        [phoneNumbers addObject:result.phoneNumber];
        [uniqueResults addObject:result];
    }
}

// 方法2：基于相似度去重
NSMutableArray *uniqueResults = [NSMutableArray array];

for (DHPhoneNumberResult *result in results) {
    BOOL isDuplicate = NO;
    
    for (DHPhoneNumberResult *existing in uniqueResults) {
        if ([self isSimilarPhoneNumber:result.phoneNumber 
                                    to:existing.phoneNumber 
                             threshold:0.8]) {
            isDuplicate = YES;
            break;
        }
    }
    
    if (!isDuplicate) {
        [uniqueResults addObject:result];
    }
}
```

### Q17: 如何实现批量识别的进度回调？

**A:** 使用 NSProgress 或自定义进度跟踪：

```objective-c
- (void)batchRecognizeImages:(NSArray<UIImage *> *)images 
                    progress:(void(^)(NSInteger completed, NSInteger total))progressCallback
                  completion:(void(^)(NSArray<NSArray<DHPhoneNumberResult *> *> *allResults))completion {
    
    NSMutableArray *allResults = [NSMutableArray arrayWithCapacity:images.count];
    __block NSInteger completedCount = 0;
    
    // 初始化结果数组
    for (NSInteger i = 0; i < images.count; i++) {
        [allResults addObject:[NSNull null]];
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    [images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
        dispatch_group_enter(group);
        
        [recognizer recognizePhoneNumbers:image
                               phoneTypes:DHPhoneNumberTypesAll
                            effectiveArea:CGRectZero
                               completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
            
            @synchronized (allResults) {
                allResults[idx] = results ?: @[];
                completedCount++;
                
                // 进度回调
                if (progressCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressCallback(completedCount, images.count);
                    });
                }
            }
            
            dispatch_group_leave(group);
        }];
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion([allResults copy]);
        }
    });
}
```

### Q18: 如何保存和加载识别结果？

**A:** 实现结果的序列化和反序列化：

```objective-c
// 保存结果到文件
- (void)saveResults:(NSArray<DHPhoneNumberResult *> *)results toFile:(NSString *)filePath {
    NSMutableArray *serializedResults = [NSMutableArray array];
    
    for (DHPhoneNumberResult *result in results) {
        NSDictionary *resultDict = @{
            @"phoneNumber": result.phoneNumber,
            @"type": @(result.type),
            @"confidence": @(result.confidence),
            @"index": @(result.index)
        };
        [serializedResults addObject:resultDict];
    }
    
    [serializedResults writeToFile:filePath atomically:YES];
}

// 从文件加载结果
- (NSArray<DHPhoneNumberResult *> *)loadResultsFromFile:(NSString *)filePath {
    NSArray *serializedResults = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *results = [NSMutableArray array];
    
    for (NSDictionary *resultDict in serializedResults) {
        DHPhoneNumberResult *result = [[DHPhoneNumberResult alloc] 
            initWithPhoneNumber:resultDict[@"phoneNumber"]
                           type:[resultDict[@"type"] integerValue]
                     confidence:[resultDict[@"confidence"] floatValue]
                          index:[resultDict[@"index"] integerValue]];
        [results addObject:result];
    }
    
    return [results copy];
}
```

---

## 获取更多帮助

如果您的问题没有在此文档中找到答案，请：

1. 查看 [完整 API 文档](README.md)
2. 运行 [集成示例代码](../../../Example/PhoneNumberRecognizerExamples.h)
3. 查看 [单元测试用例](../../../Example/Tests/PhoneNumberRecognizerTests.m)
4. 联系技术支持团队

## 反馈和建议

如果您发现文档中的错误或有改进建议，请通过以下方式反馈：

- 提交 Issue 或 Pull Request
- 发送邮件到技术支持邮箱
- 在开发者社区中讨论

我们会持续改进文档质量，为开发者提供更好的使用体验。