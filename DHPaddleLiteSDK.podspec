#
# Be sure to run `pod lib lint DHPaddleLiteSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DHPaddleLiteSDK'
  s.version          = '1.0.0'
  s.summary          = '基于PaddleLite实现OCR识别'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
DHPaddleLiteSDK 提供基于 PaddleLite 的端侧 OCR 能力，包含文本识别与手机号识别组件。
                       DESC

  s.homepage         = 'https://github.com/duanbhu/DHPaddleLiteSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dbh' => '310701836@qq.com' }
  s.source           = {
    :http => "https://github.com/duanbhu/DHPaddleLiteSDK/releases/download/#{s.version}/DHPaddleLiteSDK-#{s.version}.zip"
  }

  s.ios.deployment_target = '12.0'
  s.default_subspecs = 'Core'
  s.static_framework = true
  
  s.subspec 'Core' do |core|
    # Decouple business SDK release cadence from runtime binary pod releases.
    core.dependency 'PaddleLiteiOS', '~> 0.0.5'
    core.source_files = [
      'DHPaddleLiteSDK/Classes/DLPaddleLiteSDK.h',
      'DHPaddleLiteSDK/Classes/Private/*.{h,m,mm}',
      'DHPaddleLiteSDK/Classes/PaddleLiteTextRecognition/*.{h,m,mm}',
      'DHPaddleLiteSDK/paddleUtil/*'
    ]
    core.public_header_files = [
      'DHPaddleLiteSDK/Classes/DLPaddleLiteSDK.h',
      'DHPaddleLiteSDK/Classes/PaddleLiteTextRecognition/*.h'
    ]
    core.private_header_files = [
      'DHPaddleLiteSDK/Classes/Private/*.h',
      'DHPaddleLiteSDK/paddleUtil/*.{hpp,h}'
    ]
    core.frameworks = 'CoreMedia', 'AssetsLibrary', 'AVFoundation'
    core.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      'VALID_ARCHS[sdk=iphonesimulator*]' => '',
      'OTHER_LDFLAGS' => '$(inherited) -undefined dynamic_lookup'
    }
  end

  s.subspec 'OCRModelV4' do |model_v4|
    model_v4.dependency 'DHPaddleLiteSDK/Core'
    model_v4.resource_bundles = {
      'DHPaddleLiteSDKOCRModelV4' => [
        'DHPaddleLiteSDK/Classes/config.txt',
        'DHPaddleLiteSDK/Classes/models/ppocrv4/*.nb',
        'DHPaddleLiteSDK/Classes/labels/ppocrv4_dict.txt'
      ]
    }
  end

  s.subspec 'OCRModelV5' do |model_v5|
    model_v5.dependency 'DHPaddleLiteSDK/Core'
    model_v5.resource_bundles = {
      'DHPaddleLiteSDKOCRModelV5' => [
        'DHPaddleLiteSDK/Classes/config.txt',
        'DHPaddleLiteSDK/Classes/models/ppocrv5/*.nb',
        'DHPaddleLiteSDK/Classes/labels/ppocrv5_dict.txt'
      ]
    }
  end

  s.subspec 'PhoneNumberRecognizer' do |phone_number_recognizer|
    phone_number_recognizer.dependency 'DHPaddleLiteSDK/Core'
    phone_number_recognizer.source_files = 'DHPaddleLiteSDK/Classes/PhoneNumberRecognizer/*.{h,m,mm}'
    phone_number_recognizer.public_header_files = 'DHPaddleLiteSDK/Classes/PhoneNumberRecognizer/*.h'
  end
end
