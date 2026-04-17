# PaddleLiteTextRecognition 文档索引

欢迎使用 PaddleLiteTextRecognition OCR 文本识别 SDK！本文档索引将帮助您快速找到所需的文档资源。

## 📚 文档导航

### 新手入门

如果您是第一次使用本 SDK，建议按以下顺序阅读：

1. **[快速入门指南 (QUICK_START.md)](QUICK_START.md)** ⭐ 推荐首选
   - 5 分钟快速上手
   - 基本使用示例
   - 常见场景演示
   - 故障排除

2. **[完整使用文档 (README.md)](README.md)**
   - SDK 功能特性介绍
   - 详细使用示例（6 个场景）
   - 配置指南
   - 性能优化建议
   - 常见问题解答

### 深入学习

3. **[API 参考文档 (API_REFERENCE.md)](API_REFERENCE.md)**
   - 完整的 API 说明
   - 所有类、方法、属性的详细文档
   - 参数说明和返回值
   - 错误码定义
   - 线程安全说明

4. **[故障排除指南 (TROUBLESHOOTING.md)](TROUBLESHOOTING.md)** 🔧
   - 模型文件不存在错误的解决方案
   - SDK初始化失败的诊断步骤
   - 资源包配置问题
   - 详细的调试技巧

5. **[示例代码 (Example/OCRExamples.m)](../../../Example/OCRExamples.m)**
   - 6 个完整的使用示例
   - 可直接运行的代码
   - 涵盖各种使用场景

### 头文件文档

6. **[PaddleLiteTextRecognition.h](PaddleLiteTextRecognition.h)**
   - 主 SDK 类的头文件
   - 包含详细的 API 文档注释
   - 使用示例代码

7. **[DLTextRecognitionResult.h](DLTextRecognitionResult.h)**
   - 识别结果类的头文件
   - 属性说明和使用指南

## 📖 按主题查找

### 基础使用

- **如何开始使用？** → [快速入门指南](QUICK_START.md#第一步导入头文件)
- **基本识别示例** → [快速入门指南](QUICK_START.md#第三步执行识别)
- **完整示例代码** → [快速入门指南](QUICK_START.md#完整示例)

### 功能特性

- **识别整张图像** → [README.md - 示例1](README.md#示例1识别整张图像)
- **识别指定区域** → [README.md - 示例2](README.md#示例2识别指定区域)
- **配置置信度阈值** → [README.md - 示例3](README.md#示例3配置置信度阈值)
- **批量处理图像** → [README.md - 示例6](README.md#示例6批量处理多张图像)

### API 详解

- **PaddleLiteTextRecognition 类** → [API 参考 - PaddleLiteTextRecognition](API_REFERENCE.md#paddlelitetextrecognition-类)
- **DLTextRecognitionResult 类** → [API 参考 - DLTextRecognitionResult](API_REFERENCE.md#dltextrecognitionresult-类)
- **错误处理** → [API 参考 - 错误处理](API_REFERENCE.md#错误处理)
- **线程安全** → [API 参考 - 线程安全说明](API_REFERENCE.md#线程安全说明)

### 配置和优化

- **置信度阈值配置** → [README.md - 配置指南](README.md#置信度阈值配置)
- **性能优化建议** → [README.md - 性能优化](README.md#性能优化)
- **图像预处理** → [快速入门 - 性能优化](QUICK_START.md#1-图像预处理)

### 问题解决

- **常见问题** → [README.md - 常见问题](README.md#常见问题)
- **故障排除** → [故障排除指南](TROUBLESHOOTING.md)
- **模型文件错误** → [故障排除 - 模型文件不存在](TROUBLESHOOTING.md#1-模型文件不存在错误)
- **SDK初始化失败** → [故障排除 - SDK初始化失败](TROUBLESHOOTING.md#2-sdk-初始化失败)
- **错误码说明** → [README.md - 错误处理](README.md#错误码)

## 🎯 快速链接

### 最常用的代码片段

#### 基本识别
```objective-c
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:CGRectZero
                                                 completion:^(NSArray *results, NSError *error) {
    // 处理结果
}];
```
详见：[快速入门 - 第三步](QUICK_START.md#第三步执行识别)

#### 设置置信度阈值
```objective-c
[[PaddleLiteTextRecognition sharedInstance] setConfidenceThreshold:0.8];
```
详见：[README - 示例3](README.md#示例3配置置信度阈值)

#### 识别指定区域
```objective-c
CGRect region = CGRectMake(100, 200, 300, 50);
[[PaddleLiteTextRecognition sharedInstance] recognizeImage:image
                                              effectiveArea:region
                                                 completion:^(NSArray *results, NSError *error) {
    // 处理结果
}];
```
详见：[README - 示例2](README.md#示例2识别指定区域)

## 📝 文档结构

```
PaddleLiteTextRecognition/
├── DOCUMENTATION_INDEX.md      # 本文档 - 文档导航索引
├── QUICK_START.md              # 快速入门指南（推荐首选）
├── README.md                   # 完整使用文档
├── API_REFERENCE.md            # API 参考文档
├── TROUBLESHOOTING.md          # 故障排除指南
├── PaddleLiteTextRecognition.h # 主类头文件（含文档注释）
└── DLTextRecognitionResult.h   # 结果类头文件（含文档注释）

Example/
├── OCRExamples.h               # 示例代码头文件
└── OCRExamples.m               # 示例代码实现
```

## 🔍 搜索建议

如果您在寻找特定内容，可以尝试以下关键词：

- **初始化** → 快速入门指南
- **单例** → API 参考 - sharedInstance
- **识别** → README - 使用示例
- **区域** → README - 示例2
- **阈值** → README - 配置指南
- **置信度** → API 参考 - confidence
- **错误** → README - 错误处理
- **性能** → README - 性能优化
- **线程** → API 参考 - 线程安全
- **批量** → README - 示例6

## 💡 学习路径建议

### 路径 1：快速上手（推荐新手）
1. 阅读 [快速入门指南](QUICK_START.md)（10 分钟）
2. 运行 [示例代码](../../../Example/OCRExamples.m)（5 分钟）
3. 根据需求查阅 [README](README.md) 相关章节

### 路径 2：深入学习（推荐进阶）
1. 阅读 [README](README.md) 完整文档（30 分钟）
2. 查阅 [API 参考](API_REFERENCE.md)（20 分钟）
3. 研究 [示例代码](../../../Example/OCRExamples.m)（15 分钟）
4. 实践和优化

### 路径 3：问题解决
1. 查看 [故障排除指南](TROUBLESHOOTING.md)
2. 查看 [常见问题](README.md#常见问题)
3. 查阅 [错误处理](API_REFERENCE.md#错误处理)
4. 检查调试日志输出

## 📞 获取帮助

如果您在文档中找不到答案，可以：

1. 查看 [常见问题](README.md#常见问题)
2. 查看 [API 参考](API_REFERENCE.md) 中的详细说明
3. 运行 [示例代码](../../../Example/OCRExamples.m) 进行对比
4. 联系技术支持团队

## 🔄 文档更新

本文档会随 SDK 版本更新而更新。建议定期查看最新版本的文档。

---

**提示**：建议将本文档添加到书签，方便随时查阅！
