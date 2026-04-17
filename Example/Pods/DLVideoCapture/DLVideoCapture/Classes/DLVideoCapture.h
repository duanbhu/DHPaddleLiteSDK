//
//  DLVideoCapture.h
//  XbdOCR
//
//  Created by Duanhu on 2023/3/16.
//

#import <Foundation/Foundation.h>
#import "DLVideoCaptureConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface DLVideoCapture : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(DLVideoCaptureConfig *)config;

@property (nonatomic, strong, readonly) DLVideoCaptureConfig *config;

/// 视频预览渲染 layer。
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong, readonly) CAShapeLayer *borderLayer;

@property (nonatomic, assign, readonly) CGRect borderRectInImage;

/// 视频采集数据回调。
@property (nonatomic, copy) void (^sampleBufferOutputCallBack)(CMSampleBufferRef sample, CGRect borderRectInImage);

@property (nonatomic, copy) void (^metadataOutputCallBack)(NSString *barcode);

///  视频采集会话错误回调。
@property (nonatomic, copy) void (^sessionErrorCallBack)(NSError *error);

/// 视频采集会话初始化成功回调。
@property (nonatomic, copy) void (^sessionInitSuccessCallBack)(void);

/// 是否需要采集  默认是YES， 为NO时， sampleBufferOutputCallBack不在回调
@property (nonatomic, assign, getter=isCollecting) BOOL collecting;

///  开始采集。
- (void)startRunning;

/// 停止采集。
- (void)stopRunning;

/// 切换摄像头。
/// @param position 前后
- (void)changeDevicePosition:(AVCaptureDevicePosition)position;

/// 闪光灯
/// @param isOpenFlash YES:开启，NO：关闭
- (void)openFlash:(BOOL)isOpenFlash;

@end

NS_ASSUME_NONNULL_END
