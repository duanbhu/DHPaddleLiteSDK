# PaddleLiteTextRecognition 故障排除指南

## 常见问题

### 1. 模型文件不存在错误

**错误信息:**
```
[PaddleLiteTextRecognition] 错误: 检测模型文件不存在: /path/to/DLPaddleLiteSDK.bundle/models/cn_PP-OCRv4_mobile_det_opt.nb
```

**原因:**
CocoaPods 的 `resource_bundles` 会将文件扁平化到 bundle 根目录，不保留原始的子目录结构。

**已修复:**
代码已更新为从 bundle 根目录读取文件，而不是从子目录。如果您看到此错误，请：

1. 确保使用最新版本的代码
2. 重新编译项目

**如果仍有问题，尝试以下解决方案:**

#### 方案 1: 重新安装 CocoaPods 依赖（推荐）

```bash
cd Example
pod deintegrate
pod install
```

然后在 Xcode 中清理并重新编译项目:
- Product → Clean Build Folder (Shift + Cmd + K)
- Product → Build (Cmd + B)

#### 方案 2: 验证 Podspec 配置

确保 `DLPaddleLiteSDK.podspec` 包含正确的资源配置:

```ruby
s.resource_bundles = {
  'DLPaddleLiteSDK' => ['DLPaddleLiteSDK/Classes/**/*.{txt,nb}']
}
```

#### 方案 3: 手动检查资源包

1. 编译项目后，在 Xcode 中找到生成的 `.app` 文件
2. 右键点击 → Show in Finder
3. 右键点击 `.app` → Show Package Contents
4. 检查是否存在 `DLPaddleLiteSDK.bundle`
5. 检查 bundle 内是否包含:
   - `models/cn_PP-OCRv4_mobile_det_opt.nb`
   - `models/cn_PP-OCRv4_mobile_rec_opt.nb`
   - `models/cn_ppocr_mobile_v2.0_cls_opt.nb`
   - `labels/ppocrv4_dict.txt`
   - `config.txt`

#### 方案 4: 检查文件位置

**重要提示:** CocoaPods 的 `resource_bundles` 会将所有文件扁平化到 bundle 根目录。

源代码中的文件结构:
```
DLPaddleLiteSDK/
  Classes/
    models/
      cn_PP-OCRv4_mobile_det_opt.nb
      cn_PP-OCRv4_mobile_rec_opt.nb
      cn_ppocr_mobile_v2.0_cls_opt.nb
    labels/
      ppocrv4_dict.txt
    config.txt
```

打包后的 bundle 结构（扁平化）:
```
DLPaddleLiteSDK.bundle/
  cn_PP-OCRv4_mobile_det_opt.nb
  cn_PP-OCRv4_mobile_rec_opt.nb
  cn_ppocr_mobile_v2.0_cls_opt.nb
  ppocrv4_dict.txt
  config.txt
  Info.plist
```

SDK 代码已更新为从 bundle 根目录读取文件。

### 2. SDK 初始化失败

**症状:**
调用 `recognizeText:` 方法返回错误，错误码为 `PaddleLiteTextRecognitionErrorNotInitialized`

**解决方案:**

检查初始化日志，查看具体失败原因:
```objective-c
[[PaddleLiteTextRecognition sharedInstance] recognizeText:image error:&error];
if (error) {
    NSLog(@"错误: %@", error.localizedDescription);
}
```

### 3. 识别结果为空

**可能原因:**
1. 图片质量太低
2. 置信度阈值设置过高
3. 图片中没有文本

**解决方案:**

1. 降低置信度阈值:
```objective-c
[[PaddleLiteTextRecognition sharedInstance] setConfidenceThreshold:0.5 error:&error];
```

2. 检查图片质量和内容
3. 查看调试日志了解详细信息

### 4. 线程安全问题

**症状:**
多线程环境下出现崩溃或不可预测的结果

**解决方案:**

SDK 已经内置线程安全保护，但如果仍有问题:
1. 确保使用单例模式: `[PaddleLiteTextRecognition sharedInstance]`
2. 避免同时创建多个实例
3. 查看 SDK 文档中的线程安全说明

## 调试技巧

### CocoaPods Resource Bundles 行为

**重要:** CocoaPods 的 `resource_bundles` 会将所有匹配的文件扁平化到 bundle 根目录，不保留原始目录结构。

例如，podspec 配置:
```ruby
s.resource_bundles = {
  'DLPaddleLiteSDK' => ['DLPaddleLiteSDK/Classes/**/*.{txt,nb}']
}
```

会将以下文件:
- `DLPaddleLiteSDK/Classes/models/model.nb`
- `DLPaddleLiteSDK/Classes/labels/dict.txt`
- `DLPaddleLiteSDK/Classes/config.txt`

全部打包到:
- `DLPaddleLiteSDK.bundle/model.nb`
- `DLPaddleLiteSDK.bundle/dict.txt`
- `DLPaddleLiteSDK.bundle/config.txt`

SDK 代码已经适配了这种行为，从 bundle 根目录读取文件。

### 启用详细日志

SDK 会自动输出详细的调试信息。查看 Xcode 控制台中以 `[PaddleLiteTextRecognition]` 开头的日志。

### 检查包内容

如果遇到资源文件问题，SDK 会自动输出包内容的调试信息:
```
[PaddleLiteTextRecognition] 调试信息 - 包路径: /path/to/bundle
[PaddleLiteTextRecognition] 调试信息 - 包内容: [...]
[PaddleLiteTextRecognition] 调试信息 - models目录内容: [...]
```

## 获取帮助

如果以上方案都无法解决问题:

1. 收集完整的错误日志
2. 记录重现步骤
3. 检查 SDK 版本和依赖版本
4. 联系技术支持
