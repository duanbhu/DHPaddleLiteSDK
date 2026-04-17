# DHPhoneNumberRecognizer 文档索引

欢迎使用 DHPhoneNumberRecognizer！本页面提供了完整的文档导航，帮助您快速找到所需的信息。

## 📚 文档结构

### 🚀 快速开始
- **[README.md](README.md)** - 完整的 API 文档和使用指南
- **[QUICK_START.md](QUICK_START.md)** - 5分钟快速上手指南

### 📖 详细参考
- **[API_REFERENCE.md](API_REFERENCE.md)** - 详细的 API 参考手册
- **[FAQ.md](FAQ.md)** - 常见问题解答

### 💡 示例代码
- **[集成示例](../../../Example/PhoneNumberRecognizerExamples.h)** - 20个完整的使用示例
- **[单元测试](../../../Example/Tests/PhoneNumberRecognizerTests.m)** - 测试用例参考

## 🎯 按需求查找文档

### 我是新手，想快速开始
👉 **推荐路径：**
1. [快速开始指南](QUICK_START.md) - 了解基本用法
2. [README.md](README.md#使用示例) - 查看更多示例
3. [集成示例](../../../Example/PhoneNumberRecognizerExamples.h) - 运行完整示例

### 我需要详细的 API 信息
👉 **推荐路径：**
1. [API 参考手册](API_REFERENCE.md) - 完整的 API 文档
2. [README.md](README.md#api-参考) - API 概览
3. 头文件注释 - 查看源码注释

### 我遇到了问题
👉 **推荐路径：**
1. [常见问题解答](FAQ.md) - 查找解决方案
2. [README.md](README.md#错误处理) - 错误处理指南
3. [README.md](README.md#常见问题) - 基础问题解答

### 我想优化性能
👉 **推荐路径：**
1. [FAQ.md](FAQ.md#性能优化问题) - 性能优化专题
2. [README.md](README.md#性能优化) - 性能优化指南
3. [集成示例](../../../Example/PhoneNumberRecognizerExamples.h) - 性能测试示例

### 我需要集成到项目中
👉 **推荐路径：**
1. [FAQ.md](FAQ.md#集成和配置问题) - 集成指南
2. [快速开始指南](QUICK_START.md#完整示例) - 完整集成示例
3. [README.md](README.md#配置选项) - 配置说明

## 📋 功能特性索引

### 🔍 识别功能
| 功能 | 文档位置 | 示例代码 |
|------|----------|----------|
| 基本识别 | [README.md](README.md#快速开始) | [示例1](../../../Example/PhoneNumberRecognizerExamples.h) |
| 类型过滤 | [README.md](README.md#使用示例) | [示例2-5](../../../Example/PhoneNumberRecognizerExamples.h) |
| 区域识别 | [README.md](README.md#使用示例) | [示例6](../../../Example/PhoneNumberRecognizerExamples.h) |
| 视频流识别 | [README.md](README.md#使用示例) | [示例10-13](../../../Example/PhoneNumberRecognizerExamples.h) |
| 批量处理 | [README.md](README.md#使用示例) | [示例15](../../../Example/PhoneNumberRecognizerExamples.h) |

### ⚙️ 配置选项
| 配置项 | 文档位置 | 示例代码 |
|--------|----------|----------|
| 置信度阈值 | [README.md](README.md#配置选项) | [示例7](../../../Example/PhoneNumberRecognizerExamples.h) |
| OCR错误修正 | [README.md](README.md#配置选项) | [示例8](../../../Example/PhoneNumberRecognizerExamples.h) |
| 运单号过滤 | [README.md](README.md#配置选项) | [示例9](../../../Example/PhoneNumberRecognizerExamples.h) |

### 🎯 应用场景
| 场景 | 文档位置 | 示例代码 |
|------|----------|----------|
| 名片识别 | [FAQ.md](FAQ.md#q11-如何配置不同场景的参数) | [示例18](../../../Example/PhoneNumberRecognizerExamples.h) |
| 文档扫描 | [FAQ.md](FAQ.md#q11-如何配置不同场景的参数) | [示例19](../../../Example/PhoneNumberRecognizerExamples.h) |
| 实时扫描 | [FAQ.md](FAQ.md#q11-如何配置不同场景的参数) | [示例20](../../../Example/PhoneNumberRecognizerExamples.h) |

## 🔧 技术参考索引

### 📱 支持的手机号类型
| 类型 | 格式说明 | 示例 | 文档位置 |
|------|----------|------|----------|
| 普通手机号 | 11位标准格式 | `13812345678` | [README.md](README.md#快速开始) |
| 虚拟转接号 | 带分机号 | `13812345678转123` | [README.md](README.md#快速开始) |
| 隐私号码 | 部分隐藏 | `138****1234` | [README.md](README.md#快速开始) |

### 🚨 错误处理
| 错误类型 | 错误码 | 文档位置 |
|----------|--------|----------|
| 无效图像 | 2001 | [API_REFERENCE.md](API_REFERENCE.md#错误处理) |
| OCR处理失败 | 2002 | [API_REFERENCE.md](API_REFERENCE.md#错误处理) |
| 无效类型过滤器 | 2003 | [API_REFERENCE.md](API_REFERENCE.md#错误处理) |
| 无效配置 | 2004 | [API_REFERENCE.md](API_REFERENCE.md#错误处理) |

### 🎛️ API 方法
| 方法类别 | 文档位置 |
|----------|----------|
| 单例方法 | [API_REFERENCE.md](API_REFERENCE.md#类方法) |
| 识别方法 | [API_REFERENCE.md](API_REFERENCE.md#单次识别) |
| 视频流方法 | [API_REFERENCE.md](API_REFERENCE.md#视频流识别) |
| 配置方法 | [API_REFERENCE.md](API_REFERENCE.md#配置方法) |

## 🎓 学习路径建议

### 初学者路径
1. **了解基础概念** → [README.md](README.md#快速开始)
2. **运行第一个示例** → [QUICK_START.md](QUICK_START.md#第一次识别)
3. **尝试不同场景** → [集成示例](../../../Example/PhoneNumberRecognizerExamples.h)
4. **处理常见问题** → [FAQ.md](FAQ.md#基础使用问题)

### 进阶开发者路径
1. **深入理解 API** → [API_REFERENCE.md](API_REFERENCE.md)
2. **性能优化** → [FAQ.md](FAQ.md#性能优化问题)
3. **高级功能** → [FAQ.md](FAQ.md#高级功能问题)
4. **自定义扩展** → [集成示例](../../../Example/PhoneNumberRecognizerExamples.h)

### 问题解决路径
1. **查找常见问题** → [FAQ.md](FAQ.md)
2. **检查错误处理** → [README.md](README.md#错误处理)
3. **参考示例代码** → [集成示例](../../../Example/PhoneNumberRecognizerExamples.h)
4. **查看测试用例** → [单元测试](../../../Example/Tests/PhoneNumberRecognizerTests.m)

## 📞 技术支持

### 自助资源
- 📖 **完整文档** - 本文档集合
- 💻 **示例代码** - [集成示例](../../../Example/PhoneNumberRecognizerExamples.h)
- 🧪 **测试用例** - [单元测试](../../../Example/Tests/PhoneNumberRecognizerTests.m)
- 📋 **设计文档** - [设计规范](../../../../.kiro/specs/phone-number-recognizer/design.md)

### 联系支持
如果文档无法解决您的问题，请：
1. 检查是否有相关的 Issue 或讨论
2. 提供详细的问题描述和复现步骤
3. 包含相关的代码片段和错误信息
4. 说明您的开发环境和 SDK 版本

## 📝 文档贡献

我们欢迎您为文档做出贡献：

### 如何贡献
1. **报告问题** - 发现文档错误或不清楚的地方
2. **提出改进** - 建议更好的解释或示例
3. **添加示例** - 分享您的使用经验和代码
4. **翻译文档** - 帮助提供多语言版本

### 贡献指南
- 保持文档的准确性和时效性
- 使用清晰、简洁的语言
- 提供可运行的代码示例
- 遵循现有的文档格式和风格

---

## 🔄 文档更新记录

| 版本 | 更新日期 | 更新内容 |
|------|----------|----------|
| 1.0.0 | 2024-12 | 初始版本，包含完整的 API 文档 |

---

**感谢使用 DHPhoneNumberRecognizer！** 🎉

如果您觉得这个 SDK 有用，请考虑给我们反馈或推荐给其他开发者。您的支持是我们持续改进的动力！