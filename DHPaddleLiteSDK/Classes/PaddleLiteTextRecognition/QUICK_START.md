# PaddleLiteTextRecognition 快速入门指南

## 5分钟快速上手

本指南将帮助您在5分钟内开始使用PaddleLiteTextRecognition SDK进行文本识别。

## 第一步：导入头文件

在需要使用OCR功能的文件中导入SDK头文件：

```objective-c
#import <PaddleLiteTextRecognition.h>
#import <DLTextRecognitionResult.h>
```

## 第二步：准备图像

准备一张包含文本的图像：

```objective-c
// 从资源文件加载
UIImage *image = [UIImage imageNamed:@"document.jpg"];

// 或从相机/相册获取
// UIImage *image = ... (从UIImagePickerController获取)
```

## 第三步：执行识别

使用SDK识别图像中的文本：

```objective-c
// 获取SDK实例
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];

// 执行识别
[ocr recognizeImage:image
      effectiveArea:CGRectZero  // 识别整张图像
         completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    
    // 检查错误
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    // 处理识别结果
    for (DLTextRecognitionResult *result in results) {
        NSLog(@"识别文本: %@", result.text);
        NSLog(@"置信度: %.2f", result.confidence);
    }
}];
```

## 完整示例

这是一个完整的ViewController示例：

```objective-c
#import "MyViewController.h"
#import <PaddleLiteTextRecognition.h>
#import <DLTextRecognitionResult.h>

@interface MyViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 加载测试图像
    UIImage *image = [UIImage imageNamed:@"test_document.jpg"];
    self.imageView.image = image;
    
    // 执行OCR识别
    [self recognizeText:image];
}

- (void)recognizeText:(UIImage *)image {
    // 显示加载状态
    self.resultTextView.text = @"正在识别...";
    
    // 获取OCR SDK实例
    PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];
    
    // 执行识别
    [ocr recognizeImage:image
          effectiveArea:CGRectZero
             completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
        
        // 切换到主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.resultTextView.text = [NSString stringWithFormat:@"识别失败: %@", 
                                           error.localizedDescription];
                return;
            }
            
            // 拼接识别结果
            NSMutableString *text = [NSMutableString string];
            [text appendFormat:@"识别到 %lu 行文本:\n\n", (unsigned long)results.count];
            
            for (DLTextRecognitionResult *result in results) {
                [text appendFormat:@"%@ (置信度: %.2f)\n", 
                 result.text, result.confidence];
            }
            
            self.resultTextView.text = text;
        });
    }];
}

@end
```

## 常见使用场景

### 场景1：识别身份证号码

```objective-c
UIImage *idCardImage = [UIImage imageNamed:@"id_card.jpg"];

// 定义身份证号码区域（根据实际图像调整坐标）
CGRect idNumberRegion = CGRectMake(100, 300, 400, 50);

[[PaddleLiteTextRecognition sharedInstance] recognizeImage:idCardImage
                                              effectiveArea:idNumberRegion
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (!error && results.count > 0) {
        NSString *idNumber = results.firstObject.text;
        NSLog(@"身份证号码: %@", idNumber);
    }
}];
```

### 场景2：识别名片

```objective-c
UIImage *businessCardImage = [UIImage imageNamed:@"business_card.jpg"];

[[PaddleLiteTextRecognition sharedInstance] recognizeImage:businessCardImage
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (!error) {
        // 提取姓名、电话、邮箱等信息
        for (DLTextRecognitionResult *result in results) {
            NSString *text = result.text;
            
            // 简单的模式匹配（实际应用中可使用正则表达式）
            if ([text containsString:@"@"]) {
                NSLog(@"邮箱: %@", text);
            } else if ([text hasPrefix:@"1"] && text.length == 11) {
                NSLog(@"手机号: %@", text);
            }
        }
    }
}];
```

### 场景3：扫描文档

```objective-c
UIImage *documentImage = [UIImage imageNamed:@"document.jpg"];

// 设置较高的置信度阈值以确保准确性
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];
[ocr setConfidenceThreshold:0.85];

[ocr recognizeImage:documentImage
      effectiveArea:CGRectZero
         completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    if (!error) {
        // 按顺序拼接文档内容
        NSMutableString *documentText = [NSMutableString string];
        for (DLTextRecognitionResult *result in results) {
            [documentText appendFormat:@"%@\n", result.text];
        }
        
        // 保存或显示文档内容
        NSLog(@"文档内容:\n%@", documentText);
    }
}];
```

## 进阶配置

### 调整置信度阈值

根据图像质量调整阈值：

```objective-c
PaddleLiteTextRecognition *ocr = [PaddleLiteTextRecognition sharedInstance];

// 高质量图像：使用较低阈值
[ocr setConfidenceThreshold:0.6];

// 低质量图像：使用较高阈值
[ocr setConfidenceThreshold:0.85];

// 查看当前阈值
CGFloat currentThreshold = [ocr confidenceThreshold];
NSLog(@"当前阈值: %.2f", currentThreshold);
```

### 处理识别结果

```objective-c
[ocr recognizeImage:image
      effectiveArea:CGRectZero
         completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
    
    if (error) {
        // 错误处理
        return;
    }
    
    // 1. 获取所有文本
    NSArray *allTexts = [results valueForKey:@"text"];
    
    // 2. 过滤高置信度结果
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"confidence >= 0.9"];
    NSArray *highConfidenceResults = [results filteredArrayUsingPredicate:predicate];
    
    // 3. 按置信度排序
    NSArray *sortedResults = [results sortedArrayUsingComparator:^NSComparisonResult(DLTextRecognitionResult *obj1, DLTextRecognitionResult *obj2) {
        return obj2.confidence > obj1.confidence ? NSOrderedDescending : NSOrderedAscending;
    }];
    
    // 4. 统计信息
    NSInteger totalLines = results.count;
    CGFloat avgConfidence = [[results valueForKeyPath:@"@avg.confidence"] doubleValue];
    
    NSLog(@"总行数: %ld, 平均置信度: %.2f", (long)totalLines, avgConfidence);
}];
```

## 性能优化建议

### 1. 图像预处理

在识别前调整图像大小可以提高速度：

```objective-c
- (UIImage *)resizeImage:(UIImage *)image maxDimension:(CGFloat)maxDimension {
    CGSize size = image.size;
    if (size.width <= maxDimension && size.height <= maxDimension) {
        return image;
    }
    
    CGFloat scale = MIN(maxDimension / size.width, maxDimension / size.height);
    CGSize newSize = CGSizeMake(size.width * scale, size.height * scale);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

// 使用
UIImage *originalImage = [UIImage imageNamed:@"large_image.jpg"];
UIImage *resizedImage = [self resizeImage:originalImage maxDimension:1280];
[ocr recognizeImage:resizedImage effectiveArea:CGRectZero completion:^(NSArray *results, NSError *error) {
    // 处理结果
}];
```

### 2. 只识别需要的区域

指定识别区域可以显著提高速度：

```objective-c
// 只识别图像的上半部分
CGRect topHalfRegion = CGRectMake(0, 0, image.size.width, image.size.height / 2);

[ocr recognizeImage:image
      effectiveArea:topHalfRegion
         completion:^(NSArray *results, NSError *error) {
    // 处理结果
}];
```

### 3. 批量处理优化

使用GCD并发处理多张图像：

```objective-c
NSArray *images = @[image1, image2, image3];
dispatch_group_t group = dispatch_group_create();

for (UIImage *image in images) {
    dispatch_group_enter(group);
    
    [ocr recognizeImage:image effectiveArea:CGRectZero completion:^(NSArray *results, NSError *error) {
        // 处理单张图像的结果
        dispatch_group_leave(group);
    }];
}

dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"所有图像处理完成");
});
```

## 故障排除

### 问题1：识别结果为空

**可能原因**：
- 图像中没有文本
- 置信度阈值设置过高
- 图像质量太差

**解决方法**：
```objective-c
// 降低置信度阈值
[ocr setConfidenceThreshold:0.5];

// 使用CGRectZero确保识别整张图像
[ocr recognizeImage:image effectiveArea:CGRectZero completion:...];
```

### 问题2：识别速度慢

**可能原因**：
- 图像尺寸过大
- 识别整张大图

**解决方法**：
```objective-c
// 调整图像大小
UIImage *resizedImage = [self resizeImage:image maxDimension:1280];

// 或只识别需要的区域
[ocr recognizeImage:image effectiveArea:specificRegion completion:...];
```

### 问题3：识别准确率低

**可能原因**：
- 图像质量差（模糊、光线不足）
- 文本太小或倾斜

**解决方法**：
```objective-c
// 提高置信度阈值，只保留高质量结果
[ocr setConfidenceThreshold:0.85];

// 对图像进行预处理（增强对比度、去噪等）
UIImage *enhancedImage = [self enhanceImage:image];
```

## 下一步

- 查看 [README.md](README.md) 了解完整的API文档
- 查看 [OCRExamples.m](../../../Example/OCRExamples.m) 了解更多示例代码
- 根据您的具体需求调整配置参数

## 技术支持

如有问题，请查阅完整文档或联系技术支持团队。
