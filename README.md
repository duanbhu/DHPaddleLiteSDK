# DHPaddleLiteSDK

[![CI Status](https://img.shields.io/travis/duanbhu/DHPaddleLiteSDK.svg?style=flat)](https://travis-ci.org/duanbhu/DHPaddleLiteSDK)
[![Version](https://img.shields.io/cocoapods/v/DHPaddleLiteSDK.svg?style=flat)](https://cocoapods.org/pods/DHPaddleLiteSDK)
[![License](https://img.shields.io/cocoapods/l/DHPaddleLiteSDK.svg?style=flat)](https://cocoapods.org/pods/DHPaddleLiteSDK)
[![Platform](https://img.shields.io/cocoapods/p/DHPaddleLiteSDK.svg?style=flat)](https://cocoapods.org/pods/DHPaddleLiteSDK)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

DHPaddleLiteSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DHPaddleLiteSDK'
```

`DHPaddleLiteSDK` 会自动依赖 `PaddleLiteiOS`（独立的 ThirdParty 二进制包），
无需手动额外添加。

### 按需选择模型版本（推荐）

默认仅安装 `Core`（不包含任何 OCR 模型资源）。请在 Podfile 中按需选择模型：

```ruby
# Core + PP-OCRv4
pod 'DHPaddleLiteSDK/Core'
pod 'DHPaddleLiteSDK/OCRModelV4'

# 或：Core + PP-OCRv5
pod 'DHPaddleLiteSDK/Core'
pod 'DHPaddleLiteSDK/OCRModelV5'
```

如需手机号识别组件（不自动携带模型）：

```ruby
# 仅手机号识别逻辑
pod 'DHPaddleLiteSDK/PhoneNumberRecognizer'

# 必须二选一额外安装模型
pod 'DHPaddleLiteSDK/OCRModelV4'
# pod 'DHPaddleLiteSDK/OCRModelV5'
```

## Author

duanbhu, 310701836@qq.com

## License

DHPaddleLiteSDK is available under the MIT license. See the LICENSE file for more info.
