//
//  DLVideoCaptureConfig.h
//  XbdOCR
//
//  Created by Duanhu on 2023/3/16.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DLVideoCaptureMirrorType) {
    DLVideoCaptureMirrorTypeNone = 0,
    DLVideoCaptureMirrorFront = 1 << 0,
    DLVideoCaptureMirrorBack = 1 << 1,
    DLVideoCaptureMirrorAll = (DLVideoCaptureMirrorFront | DLVideoCaptureMirrorBack),
};

@interface DLVideoCaptureConfig : NSObject

/// 视频采集参数，比如分辨率等，与画质相关。
@property (nonatomic, copy) AVCaptureSessionPreset preset;

/// 摄像头位置，前置/后置摄像头。
@property (nonatomic, assign) AVCaptureDevicePosition position;

/// 视频画面方向。
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;

/// 视频帧率。
@property (nonatomic, assign) NSInteger fps; // 视频帧率。

/// 颜色空间格式。
@property (nonatomic, assign) OSType pixelFormatType;

/// 镜像类型。
@property (nonatomic, assign) DLVideoCaptureMirrorType mirrorType;

/// 支持扫描条形码
@property (nonatomic, assign) BOOL supportBarCode;

@property (nonatomic, weak) UIView *rootView;

@property (nonatomic, assign) CGRect borderFrame;

@property (nonatomic, strong) UIImage *borderImage;

@end

NS_ASSUME_NONNULL_END
