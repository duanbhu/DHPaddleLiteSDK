# DHPhoneNumberRecognizer 快速开始指南

本指南将帮助您在 5 分钟内开始使用 DHPhoneNumberRecognizer 进行手机号识别。

## 1. 基本设置

### 导入必要的头文件

```objective-c
#import <DLPaddleLiteSDK/DHPhoneNumberRecognizer.h>
#import <DLPaddleLiteSDK/DHPhoneNumberResult.h>
#import <DLPaddleLiteSDK/DHPhoneNumberTypes.h>
```

### 获取识别器实例

```objective-c
DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
```

## 2. 第一次识别

### 准备图像

```objective-c
// 从应用包加载图像
UIImage *image = [UIImage imageNamed:@"test_image.jpg"];

// 或从相机/相册获取
// UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
```

### 执行识别

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll  // 识别所有类型
                    effectiveArea:CGRectZero          // 识别整个图像
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    
    if (error) {
        NSLog(@"识别失败: %@", error.localizedDescription);
        return;
    }
    
    if (results.count == 0) {
        NSLog(@"未识别到手机号");
        return;
    }
    
    // 输出识别结果
    for (DHPhoneNumberResult *result in results) {
        NSLog(@"识别到手机号: %@", result.phoneNumber);
        NSLog(@"类型: %@", [self typeStringForType:result.type]);
        NSLog(@"置信度: %.2f", result.confidence);
    }
}];
```

### 辅助方法

```objective-c
- (NSString *)typeStringForType:(DHPhoneNumberType)type {
    switch (type) {
        case DHPhoneNumberTypeRegular:
            return @"普通手机号";
        case DHPhoneNumberTypeVirtual:
            return @"虚拟转接号";
        case DHPhoneNumberTypePrivacy:
            return @"隐私号码";
        default:
            return @"未知类型";
    }
}
```

## 3. 常用场景

### 场景1：只识别普通手机号

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypeRegular  // 只识别普通手机号
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    // 处理结果...
}];
```

### 场景2：名片识别

```objective-c
// 名片识别通常需要更高的准确性
[recognizer setConfidenceThreshold:0.8];
[recognizer setOCRCorrectionEnabled:YES];

[recognizer recognizePhoneNumbers:businessCardImage
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    
    for (DHPhoneNumberResult *result in results) {
        // 可以保存到通讯录
        [self saveToContacts:result.phoneNumber];
    }
}];
```

### 场景3：实时相机扫描

```objective-c
// 启动实时识别
[recognizer startStreamRecognition:DHPhoneNumberTypesAll
                         frameRate:2  // 每秒2帧
                          callback:^(NSArray<DHPhoneNumberResult *> *results) {
    
    if (results.count > 0) {
        // 在UI中显示识别结果
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showResults:results];
        });
    }
}];

// 在相机回调中处理视频帧
- (void)captureOutput:(AVCaptureOutput *)output 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection {
    
    [recognizer processVideoFrame:sampleBuffer];
}

// 记得在适当时候停止识别
- (void)stopScanning {
    [recognizer stopStreamRecognition];
}
```

## 4. 错误处理

### 基本错误处理

```objective-c
[recognizer recognizePhoneNumbers:image
                       phoneTypes:DHPhoneNumberTypesAll
                    effectiveArea:CGRectZero
                       completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
    
    if (error) {
        switch (error.code) {
            case DHPhoneNumberRecognizerErrorCodeInvalidImage:
                [self showAlert:@"图像无效，请重新选择图像"];
                break;
                
            case DHPhoneNumberRecognizerErrorCodeOCRProcessingFailed:
                [self showAlert:@"识别失败，请检查图像质量"];
                break;
                
            default:
                [self showAlert:@"识别出错，请重试"];
                break;
        }
        return;
    }
    
    // 处理成功结果...
}];
```

## 5. 配置优化

### 根据场景调整配置

```objective-c
// 名片识别场景
[recognizer setConfidenceThreshold:0.8];      // 高准确性
[recognizer setOCRCorrectionEnabled:YES];     // 启用错误修正

// 文档扫描场景
[recognizer setConfidenceThreshold:0.7];      // 平衡准确性和召回率
NSArray *trackingPrefixes = @[@"YT", @"SF", @"JD"];
[recognizer setTrackingNumberPrefixes:trackingPrefixes];  // 过滤运单号

// 实时扫描场景
[recognizer setConfidenceThreshold:0.85];     // 高准确性，减少误识别
```

## 6. 完整示例

以下是一个完整的 ViewController 示例：

```objective-c
#import "ViewController.h"
#import <DLPaddleLiteSDK/DHPhoneNumberRecognizer.h>
#import <DLPaddleLiteSDK/DHPhoneNumberResult.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 配置识别器
    DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
    [recognizer setConfidenceThreshold:0.8];
    [recognizer setOCRCorrectionEnabled:YES];
}

- (IBAction)selectImageButtonTapped:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.imageView.image = image;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self recognizePhoneNumbers:image];
    }];
}

- (void)recognizePhoneNumbers:(UIImage *)image {
    self.resultTextView.text = @"识别中...";
    
    DHPhoneNumberRecognizer *recognizer = [DHPhoneNumberRecognizer sharedInstance];
    
    [recognizer recognizePhoneNumbers:image
                           phoneTypes:DHPhoneNumberTypesAll
                        effectiveArea:CGRectZero
                           completion:^(NSArray<DHPhoneNumberResult *> *results, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.resultTextView.text = [NSString stringWithFormat:@"识别失败: %@", 
                                           error.localizedDescription];
                return;
            }
            
            if (results.count == 0) {
                self.resultTextView.text = @"未识别到手机号";
                return;
            }
            
            NSMutableString *resultText = [NSMutableString string];
            [resultText appendFormat:@"识别到 %lu 个手机号:\n\n", (unsigned long)results.count];
            
            for (NSInteger i = 0; i < results.count; i++) {
                DHPhoneNumberResult *result = results[i];
                [resultText appendFormat:@"%ld. %@\n", i + 1, result.phoneNumber];
                [resultText appendFormat:@"   类型: %@\n", [self typeStringForType:result.type]];
                [resultText appendFormat:@"   置信度: %.2f\n\n", result.confidence];
            }
            
            self.resultTextView.text = resultText;
        });
    }];
}

- (NSString *)typeStringForType:(DHPhoneNumberType)type {
    switch (type) {
        case DHPhoneNumberTypeRegular:
            return @"普通手机号";
        case DHPhoneNumberTypeVirtual:
            return @"虚拟转接号";
        case DHPhoneNumberTypePrivacy:
            return @"隐私号码";
        default:
            return @"未知类型";
    }
}

@end
```

## 7. 下一步

现在您已经掌握了基本用法，可以：

1. 查看 [完整 API 文档](README.md) 了解更多功能
2. 运行 [集成示例](../../../Example/PhoneNumberRecognizerExamples.h) 查看更多用法
3. 根据您的具体需求调整配置参数
4. 集成到您的应用中

## 常见问题

**Q: 识别结果为空怎么办？**
A: 尝试降低置信度阈值：`[recognizer setConfidenceThreshold:0.6];`

**Q: 如何提高识别准确率？**
A: 确保图像清晰，启用错误修正，设置适当的置信度阈值。

**Q: 视频流识别卡顿怎么办？**
A: 降低帧率到 2-3 FPS：`frameRate:2`

更多问题请参考 [完整文档](README.md#常见问题)。