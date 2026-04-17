//
//  DLVideoCaptureConfig.m
//  XbdOCR
//
//  Created by Duanhu on 2023/3/16.
//

#import "DLVideoCaptureConfig.h"

@implementation DLVideoCaptureConfig

- (instancetype)init {
    if (self = [super init]) {
        _preset = AVCaptureSessionPreset1920x1080;
        _position = AVCaptureDevicePositionBack;
        _orientation = AVCaptureVideoOrientationPortrait;
        _fps = 30;
        _mirrorType = DLVideoCaptureMirrorFront;
        
        // 设置颜色空间格式，这里要注意了：
        // 1、一般我们采集图像用于后续的编码时，这里设置 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 即可。
        // 2、如果想支持 HDR 时（iPhone12 及之后设备才支持），这里设置为：kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange。
        _pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    }
    return self;
}

@end
