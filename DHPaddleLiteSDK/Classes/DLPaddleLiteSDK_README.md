# DLPaddleLiteSDK - 手机号识别 SDK

## 简介

DLPaddleLiteSDK 是一个专门用于识别图像中手机号码的 SDK，基于 PaddleLiteTextRecognition 通用 OCR 引擎构建。该 SDK 专注于手机号识别的业务逻辑，支持多种手机号格式。

### 架构说明

```
DLPaddleLiteSDK (业务层)
    ↓ 使用
PaddleLiteTextRecognition (OCR引擎层)
    ↓ 使用
PaddleOCR + OpenCV (底层)
```

- **PaddleLiteTextRecognition**: 通用 OCR 文本识别引擎，负责图像文本识别
- **DLPaddleLiteSDK**: 业务逻辑层，专注于手机号的提取、验证和过滤

### 支持的手机号类型

1. **标准手机号**: 11位数字，如 `13812345678`
2. **隐私号码**: 带*号的手机号，如 `138****5678`
3. **虚拟号码**: 带分机号的手机号，如 `13812345678转1234`

## 快速开始

### 依赖说明

`PhoneNumberRecognizer` 仅包含手机号识别逻辑，不包含 OCR 模型资源。集成时请确保同时安装至少一个模型子模块（`OCRModelV4` 或 `OCRModelV5`），否则运行时无法完成识别。

### 基本使用

```objective-c
#import <DLPaddleLiteSDK.h>

// 1. 获取 SDK 实例
DLPaddleLiteSDK *sdk = [DLPaddleLiteSDK sharedManager];

// 2. 配置识别类型（可选，默认为标准手机号）
sdk.matchType = DLPaddleLiteMatchTypePhoneAll;

// 3. 识别图像中的手机号
UIImage *image = [UIImage imageNamed:@"screenshot.jpg"];
[sdk recognitionImage:image
        effectiveArea:CGRectZero
               result:^(NSDictionary *info) {
    
    // 4. 获取识别结果
    NSArray *phones = info[kKeyPhone];              // 标准手机号
    NSArray *virtualPhones = info[kKeyVirtualPhone]; // 虚拟号
    NSArray *privacyNumbers = info[kKeyPrivacyNumber]; // 隐私号
    
    NSLog(@"标准手机号: %@", phones);
    NSLog(@"虚拟号: %@", virtualPhones);
    NSLog(@"隐私号: %@", privacyNumbers);
}];
```

## 使用示例

### 示例1：识别标准手机号

```objective-c
DLPaddleLiteSDK *sdk = [DLPaddleLiteSDK sharedManager];

// 只识别标准手机号
sdk.matchType = DLPaddleLiteMatchTypePhone;

UIImage *image = [UIImage imageNamed:@"contact.jpg"];
[sdk recognitionImage:image
        effectiveArea:CGRectZero
               result:^(NSDictionary *info) {
    NSArray *phones = info[kKeyPhone];
    
    if (phones.count > 0) {
        NSLog(@"识别到手机号: %@", phones.firstObject);
    } else {
        NSLog(@"未识别到手机号");
    }
}];
```

### 示例2：识别指定区域

```objective-c
DLPaddleLiteSDK *sdk = [DLPaddleLiteSDK sharedManager];

UIImage *image = [UIImage imageNamed:@"screenshot.jpg"];

// 只识别图像的上半部分
CGRect topHalfRegion = CGRectMake(0, 0, image.size.width, image.size.height / 2);

[sdk recognitionImage:image
        effectiveArea:topHalfRegion
               result:^(NSDictionary *info) {
    NSArray *phones = info[kKeyPhone];
    NSLog(@"上半部分识别到的手机号: %@", phones);
}];
```

### 示例3：识别所有类型的手机号

```objective-c
DLPaddleLiteSDK *sdk = [DLPaddleLiteSDK sharedManager];

// 识别所有类型
sdk.matchType = DLPaddleLiteMatchTypePhoneAll;

UIImage *image = [UIImage imageNamed:@"call_log.jpg"];
[sdk recognitionImage:image
        effectiveArea:CGRectZero
               result:^(NSDictionary *info) {
    
    NSArray *phones = info[kKeyPhone];
    NSArray *virtualPhones = info[kKeyVirtualPhone];
    NSArray *privacyNumbers = info[kKeyPrivacyNumber];
    
    // 处理标准手机号
    for (NSString *phone in phones) {
        NSLog(@"标准手机号: %@", phone);
    }
    
    // 处理虚拟号
    for (NSString *virtualPhone in virtualPhones) {
        NSLog(@"虚拟号: %@", virtualPhone);
    }
    
    // 处理隐私号
    for (NSString *privacyNumber in privacyNumbers) {
        NSLog(@"隐私号: %@", privacyNumber);
    }
}];
```

### 示例4：在主线程更新 UI

```objective-c
DLPaddleLiteSDK *sdk = [DLPaddleLiteSDK sharedManager];

[sdk recognitionImage:image
        effectiveArea:CGRectZero
               result:^(NSDictionary *info) {
    
    // 切换到主线程更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *phones = info[kKeyPhone];
        
        if (phones.count > 0) {
            self.phoneLabel.text = phones.firstObject;
        } else {
            self.phoneLabel.text = @"未识别到手机号";
        }
    });
}];
```

## API 参考

### DLPaddleLiteMatchType

手机号匹配类型枚举，支持按位组合。

| 类型 | 说明 |
|------|------|
| `DLPaddleLiteMatchTypePhone` | 标准手机号（11位数字） |
| `DLPaddleLiteMatchTypeVirtualPhone` | 虚拟手机号（带分机号） |
| `DLPaddleLiteMatchTypePrivatePhone` | 隐私手机号（带*号） |
| `DLPaddleLiteMatchTypePhoneAll` | 所有类型 |

### 属性

#### `matchType`

```objective-c
@property(nonatomic, assign) DLPaddleLiteMatchType matchType;
```

配置需要识别的手机号类型，默认为 `DLPaddleLiteMatchTypePhone`。

### 方法

#### `+ (DLPaddleLiteSDK *)sharedManager`

获取单例实例。

**返回值**: DLPaddleLiteSDK 的单例对象

#### `- (void)recognitionImage:effectiveArea:result:`

识别图像中的手机号。

**参数**:
- `image`: 输入图像（UIImage）
- `rect`: 有效识别区域，CGRectZero 表示识别整个图像
- `result`: 完成回调，返回识别结果字典

**回调字典键**:
- `kKeyPhone`: 标准手机号数组（NSArray<NSString *>）
- `kKeyVirtualPhone`: 虚拟手机号数组（NSArray<NSString *>）
- `kKeyPrivacyNumber`: 隐私号码数组（NSArray<NSString *>）

## 识别规则

### 频率过滤

SDK 会统计每个手机号在图像中出现的次数，只返回出现频率 >= 3 次的手机号。这样可以过滤掉误识别的结果。

### 格式验证

- **标准手机号**: 必须是11位数字，以1开头，第二位为3-9
- **隐私号码**: 支持带*号的手机号，如 `138****5678`
- **虚拟号码**: 支持带分机号的手机号，分机号3-4位

### 特殊处理

- 自动处理*号识别成"水"的情况
- 自动补全不完整的隐私号码
- 自动提取虚拟号码的分机号

## 性能说明

- **识别速度**: 取决于底层 PaddleLiteTextRecognition 的性能（< 500ms）
- **内存使用**: < 100MB
- **线程安全**: 支持并发调用

## 与 PaddleLiteTextRecognition 的关系

DLPaddleLiteSDK 是基于 PaddleLiteTextRecognition 构建的业务层 SDK：

- **PaddleLiteTextRecognition**: 提供通用的 OCR 文本识别能力
- **DLPaddleLiteSDK**: 在 OCR 结果基础上，添加手机号识别的业务逻辑

如果您需要识别其他类型的文本（如身份证号、银行卡号等），可以直接使用 PaddleLiteTextRecognition。

## 常见问题

### Q: 为什么识别结果为空？

**A**: 可能的原因：
1. 图像中没有手机号
2. 手机号出现次数 < 3 次（被频率过滤）
3. 手机号格式不符合规则
4. 图像质量太差

**解决方法**：
- 确保图像清晰
- 检查手机号格式是否正确
- 尝试识别整个图像（CGRectZero）

### Q: 如何提高识别准确率？

**A**: 建议：
1. 使用高质量、清晰的图像
2. 确保手机号区域光线充足
3. 只识别包含手机号的区域
4. 使用合适的 matchType

### Q: 支持哪些图像格式？

**A**: 支持 UIImage 支持的所有格式（JPEG、PNG、BMP 等）。

## 技术支持

如有问题或建议，请联系技术支持团队。

## 相关文档

- [PaddleLiteTextRecognition 文档](PaddleLiteTextRecognition/README.md)
- [PaddleLiteTextRecognition API 参考](PaddleLiteTextRecognition/API_REFERENCE.md)
