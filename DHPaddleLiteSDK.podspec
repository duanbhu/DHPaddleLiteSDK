#
# Be sure to run `pod lib lint DHPaddleLiteSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DHPaddleLiteSDK'
  s.version          = '0.0.3'
  s.summary          = '基于PaddleLite实现OCR识别'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://192.168.3.182/dbh/DHPaddleLiteSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dbh' => '310701836@qq.com' }
  s.source           = { :git => 'http://192.168.3.182/dbh/DHPaddleLiteSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.default_subspecs = 'Core'
  s.static_framework = true
  
  s.subspec 'Core' do |core|
    core.source_files = [
      'DHPaddleLiteSDK/Classes/DHPaddleLiteSDK.{h,m,mm}',
      'DHPaddleLiteSDK/Classes/Private/*.{h,m,mm}',
      'DHPaddleLiteSDK/Classes/PaddleLiteTextRecognition/*.{h,m,mm}',
      'DHPaddleLiteSDK/paddleUtil/*',
      'DHPaddleLiteSDK/ThirdParty/PaddleLite/include/*.h'
    ]
    core.public_header_files = [
      'DHPaddleLiteSDK/Classes/DHPaddleLiteSDK.h',
      'DHPaddleLiteSDK/Classes/PaddleLiteTextRecognition/*.h'
    ]
    core.private_header_files = [
      'DHPaddleLiteSDK/Classes/Private/*.h',
      'DHPaddleLiteSDK/paddleUtil/*.{hpp,h}'
    ]
    core.resource_bundles = {
      'DHPaddleLiteSDK' => ['DHPaddleLiteSDK/Classes/**/*.{txt,nb}']
    }
    core.vendored_libraries = 'DHPaddleLiteSDK/ThirdParty/PaddleLite/lib/libpaddle_api_light_bundled.a'
    core.vendored_frameworks = 'DHPaddleLiteSDK/ThirdParty/opencv2.framework'
    core.libraries = 'c++'
    core.frameworks = 'CoreMedia', 'AssetsLibrary', 'AVFoundation', 'opencv2'
    core.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      'VALID_ARCHS[sdk=iphonesimulator*]' => '',
      'OTHER_LDFLAGS' => '$(inherited) -undefined dynamic_lookup',
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/DHPaddleLiteSDK/ThirdParty"'
    }
  end

  s.subspec 'PhoneNumberRecognizer' do |phone_number_recognizer|
    phone_number_recognizer.dependency 'DHPaddleLiteSDK/Core'
    phone_number_recognizer.source_files = 'DHPaddleLiteSDK/Classes/PhoneNumberRecognizer/*.{h,m,mm}'
    phone_number_recognizer.public_header_files = 'DHPaddleLiteSDK/Classes/PhoneNumberRecognizer/*.h'
  end
end
