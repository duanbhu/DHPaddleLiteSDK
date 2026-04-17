//
//  DLVideoCapture.m
//  XbdOCR
//
//  Created by Duanhu on 2023/3/16.
//

#import "DLVideoCapture.h"
#import <UIKit/UIKit.h>

@interface DLVideoCapture () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong, readwrite) DLVideoCaptureConfig *config;

/// 视频采集设备。
@property (nonatomic, strong, readonly) AVCaptureDevice *captureDevice;

/// 后置摄像头采集输入。
@property (nonatomic, strong) AVCaptureDeviceInput *backDeviceInput;

/// 前置摄像头采集输入。
@property (nonatomic, strong) AVCaptureDeviceInput *frontDeviceInput;

/// 视频采集输出。
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

/// 条形码采集
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;

/// 视频采集会话。
@property (nonatomic, strong) AVCaptureSession *captureSession;

/// 视频预览渲染 layer。
@property (nonatomic, strong, readwrite) AVCaptureVideoPreviewLayer *previewLayer;

/// 阴影区域
@property (nonatomic, strong) CAShapeLayer *borderLayer;

/// 预览区域边框
@property (nonatomic, strong) UIImageView *borderImageView;

/// 预览区扫描 动画
@property (nonatomic, strong) UIImageView *scanLineImageView;

@property (nonatomic, assign, readonly) CMVideoDimensions sessionPresetSize; // 视频采集分辨率。

/// 识别区域
@property (nonatomic, assign) CGRect borderFrame;

/// 识别区域在图片上的坐标
@property (nonatomic, assign) CGRect borderRectInImage;

@property (nonatomic, strong) dispatch_queue_t captureQueue;

@end

@implementation DLVideoCapture

#pragma mark - LifeCycle
- (instancetype)initWithConfig:(DLVideoCaptureConfig *)config {
    if (self = [super init]) {
        _config = config;
        _captureQueue = dispatch_queue_create("com.KeyFrameKit.videoCapture", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
        self.collecting = YES;
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Method
- (void)startRunning {
    typeof(self) __weak weakSelf = self;
    dispatch_async(_captureQueue, ^{
        [weakSelf _startRunning];
    });
}

- (void)stopRunning {
    typeof(self) __weak weakSelf = self;
    dispatch_async(_captureQueue, ^{
        [weakSelf _stopRunning];
    });
}

- (void)changeDevicePosition:(AVCaptureDevicePosition)position {
    typeof(self) __weak weakSelf = self;
    dispatch_async(_captureQueue, ^{
        [weakSelf _updateDeveicePosition:position];
    });
}

/// 闪光灯
/// @param isOpenFlash YES:开启，NO：关闭
- (void)openFlash:(BOOL)isOpenFlash {
    if ([self.captureDevice hasTorch]) {
        NSError *error = nil;
        BOOL locked = [self.captureDevice lockForConfiguration:&error];
        if (locked) {
            self.captureDevice.torchMode = isOpenFlash ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
            [self.captureDevice unlockForConfiguration];
        }
    }
}

#pragma mark - Private Method
- (void)_startRunning {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        if (!self.captureSession.isRunning) {
            [self.captureSession startRunning];
        }
    } else {
        NSLog(@"没有相机使用权限");
    }
}

- (void)_stopRunning {
    if (_captureSession && _captureSession.isRunning) {
        [_captureSession stopRunning];
    }
}

- (void)_updateDeveicePosition:(AVCaptureDevicePosition)position {
    // 切换采集的摄像头。
    
    if (position == self.config.position || !_captureSession.isRunning) {
        return;
    }
    
    // 1、切换采集输入。
    AVCaptureDeviceInput *curInput = self.config.position == AVCaptureDevicePositionBack ? self.backDeviceInput : self.frontDeviceInput;
    AVCaptureDeviceInput *addInput = self.config.position == AVCaptureDevicePositionBack ? self.frontDeviceInput : self.backDeviceInput;
    if (!curInput || !addInput) {
        return;
    }
    [self.captureSession removeInput:curInput];
    for (AVCaptureSessionPreset selectPreset in [self sessionPresetList]) {
        if ([_captureSession canSetSessionPreset:selectPreset]) {
            [_captureSession setSessionPreset:selectPreset];
            if ([_captureSession canAddInput:addInput]) {
                [_captureSession addInput:addInput];
                self.config.position = position;
                break;
            }
        }
    }
    
    // 2、更新画面方向。
    [self _updateOrientation];
    
    // 3、更新画面镜像。
    [self _updateMirror];

    // 4、更新采集实时帧率。
    [self.captureDevice lockForConfiguration:nil];
    [self _updateActiveFrameDuration];
    [self.captureDevice unlockForConfiguration];
}

- (void)_updateOrientation {
    // 更新画面方向。
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]; // AVCaptureConnection 用于把输入和输出连接起来。
    if ([connection isVideoOrientationSupported] && connection.videoOrientation != self.config.orientation) {
        connection.videoOrientation = self.config.orientation;
    }
}

- (void)_updateMirror {
    // 更新画面镜像。
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoMirroringSupported]) {
        if ((self.config.mirrorType & DLVideoCaptureMirrorFront) && self.config.position == AVCaptureDevicePositionFront) {
            connection.videoMirrored = YES;
        } else if ((self.config.mirrorType & DLVideoCaptureMirrorBack) && self.config.position == AVCaptureDevicePositionBack) {
            connection.videoMirrored = YES;
        } else {
            connection.videoMirrored = NO;
        }
    }
}

- (BOOL)_updateActiveFrameDuration {
    // 更新采集实时帧率。
    
    // 1、帧率换算成帧间隔时长。
    CMTime frameDuration = CMTimeMake(1, (int32_t) self.config.fps);
    
    // 2、设置帧率大于 30 时，找到满足该帧率及其他参数，并且当前设备支持的 AVCaptureDeviceFormat。
    if (self.config.fps > 30) {
        for (AVCaptureDeviceFormat *vFormat in [self.captureDevice formats]) {
            CMFormatDescriptionRef description = vFormat.formatDescription;
            CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(description);
            float maxRate = ((AVFrameRateRange *) [vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
            if (maxRate >= self.config.fps && CMFormatDescriptionGetMediaSubType(description) == self.config.pixelFormatType && self.sessionPresetSize.width * self.sessionPresetSize.height == dims.width * dims.height) {
                self.captureDevice.activeFormat = vFormat;
                break;
            }
        }
    }
    
    // 3、检查设置的帧率是否在当前设备的 activeFormat 支持的最低和最高帧率之间。如果是，就设置帧率。
    __block BOOL support = NO;
    [self.captureDevice.activeFormat.videoSupportedFrameRateRanges enumerateObjectsUsingBlock:^(AVFrameRateRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CMTimeCompare(frameDuration, obj.minFrameDuration) >= 0 &&
            CMTimeCompare(frameDuration, obj.maxFrameDuration) <= 0) {
            support = YES;
            *stop = YES;
        }
    }];
    if (support) {
        [self.captureDevice setActiveVideoMinFrameDuration:frameDuration];
        [self.captureDevice setActiveVideoMaxFrameDuration:frameDuration];
        return YES;
    }
    
    return NO;
}

- (void)_addMetadataOutput {
    if (!_config.supportBarCode) {
        return;
    }
    
    if ([_captureSession canAddOutput:self.metadataOutput]) {
        [_captureSession addOutput:self.metadataOutput];
//             [.qr, .ean13, .ean8, .upce, .code39, .code39Mod43, .code93, .code128, .pdf417]
        _metadataOutput.metadataObjectTypes = @[
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeCode93Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code];
    }
}

#pragma mark - NSNotification
- (void)sessionRuntimeError:(NSNotification *)notification {
    if (self.sessionErrorCallBack) {
        self.sessionErrorCallBack(notification.userInfo[AVCaptureSessionErrorKey]);
    }
}

#pragma mark - Utility
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    // 从当前手机寻找符合需要的采集设备。
    NSArray *devices = nil;
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version.doubleValue >= 10.0) {
        AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
        devices = deviceDiscoverySession.devices;
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
#pragma GCC diagnostic pop
    }
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

- (NSArray *)sessionPresetList {
    return @[self.config.preset, AVCaptureSessionPreset3840x2160, AVCaptureSessionPreset1920x1080, AVCaptureSessionPreset1280x720, AVCaptureSessionPresetLow];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFRetain(sampleBuffer);
    @autoreleasepool {
        // 向外回调数据。
        if (output == self.videoOutput) {
            if (self.sampleBufferOutputCallBack && self.isCollecting) {
                self.sampleBufferOutputCallBack(sampleBuffer, self.borderRectInImage);
            }
        }
    }
    CFRelease(sampleBuffer);
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if ([metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        // 获取扫描结果
        if (self.metadataOutputCallBack) {
            self.metadataOutputCallBack(metadataObject.stringValue);
        }
    }
}

#pragma mark - setter

- (void)setBorderFrame:(CGRect)borderFrame {
    _borderFrame = borderFrame;
    //阴影框
    UIBezierPath *superPath = [UIBezierPath bezierPathWithRoundedRect:self.previewLayer.superlayer.bounds cornerRadius:0];
    [superPath setUsesEvenOddFillRule:YES];
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:borderFrame cornerRadius:0];
    [borderPath setUsesEvenOddFillRule:YES];
    [superPath appendPath:borderPath];
    self.borderLayer.path = superPath.CGPath;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.duration = 1;
    anim.repeatCount = HUGE_VALF;
    anim.fillMode = kCAFillModeForwards;
    anim.removedOnCompletion = NO;
    anim.fromValue = [NSValue valueWithCGPoint:CGPointMake(borderFrame.size.width / 2, 0)];
    anim.toValue = [NSValue valueWithCGPoint:CGPointMake(borderFrame.size.width / 2, borderFrame.size.height)];
    [self.scanLineImageView.layer addAnimation:anim forKey:@"slide"];
}

#pragma mark - lazy loading
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDeviceInput *)backDeviceInput {
    if (!_backDeviceInput) {
        _backDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:nil];
    }
    
    return _backDeviceInput;
}

- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDeviceInput *)frontDeviceInput {
    if (!_frontDeviceInput) {
        _frontDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:nil];
    }
    
    return _frontDeviceInput;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue]; // 设置返回采集数据的代理和回调。
        _videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(_config.pixelFormatType)};
        _videoOutput.alwaysDiscardsLateVideoFrames = YES; // YES 表示：采集的下一帧到来前，如果有还未处理完的帧，丢掉。
    }

    return _videoOutput;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        AVCaptureDeviceInput *deviceInput = self.config.position == AVCaptureDevicePositionBack ? self.backDeviceInput : self.frontDeviceInput;
        if (!deviceInput) {
            return nil;
        }
        // 1、初始化采集会话。
        _captureSession = [[AVCaptureSession alloc] init];
        
        // 2、添加采集输入。
        for (AVCaptureSessionPreset selectPreset in [self sessionPresetList]) {
            if ([_captureSession canSetSessionPreset:selectPreset]) {
                [_captureSession setSessionPreset:selectPreset];
                if ([_captureSession canAddInput:deviceInput]) {
                    [_captureSession addInput:deviceInput];
                    break;
                }
            }
        }
        
        // 3、添加采集输出。
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }
        
        [self _addMetadataOutput];
        
        // 4、更新画面方向。
        [self _updateOrientation];
        
        // 5、更新画面镜像。
        [self _updateMirror];
    
        // 6、更新采集实时帧率。
        [self.captureDevice lockForConfiguration:nil];
        [self _updateActiveFrameDuration];
        [self.captureDevice unlockForConfiguration];
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        if (self.config.rootView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.config.rootView.layer insertSublayer:self.previewLayer atIndex:0];
                [self.config.rootView.layer insertSublayer:self.borderLayer atIndex:1];
                [self.config.rootView addSubview:self.borderImageView];
                self.previewLayer.frame = self.config.rootView.bounds;
                self.borderImageView.frame = self.config.borderFrame;
                self.borderFrame = self.config.borderFrame;
                
                NSInteger width  = MIN(self.sessionPresetSize.width, self.sessionPresetSize.height);
                NSInteger height = MAX(self.sessionPresetSize.width, self.sessionPresetSize.height);
                CGFloat scaleX = width  * 1.0f / CGRectGetWidth(self.previewLayer.bounds);
                CGFloat scaleY = height * 1.0f / CGRectGetHeight(self.previewLayer.bounds);
                CGFloat originX = self.borderFrame.origin.x * scaleX;
                CGFloat originY = (self.borderFrame.origin.y - self.previewLayer.frame.origin.y) * scaleY;
                self.borderRectInImage = CGRectMake(originX, originY, CGRectGetWidth(self.borderFrame) * scaleX, CGRectGetHeight(self.borderFrame) * scaleY);
            });
        }
        // 7、回报成功。
        if (self.sessionInitSuccessCallBack) {
            self.sessionInitSuccessCallBack();
        }
    }
    
    return _captureSession;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_captureSession) {
        return nil;
    }
    if (!_previewLayer) {
        // 初始化预览渲染 layer。这里就直接用系统提供的 API 来渲染。
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return _previewLayer;
}

- (AVCaptureDevice *)captureDevice {
    // 视频采集设备。
    return (self.config.position == AVCaptureDevicePositionBack) ? [self backCamera] : [self frontCamera];
}

- (CMVideoDimensions)sessionPresetSize {
    // 视频采集分辨率。
    return CMVideoFormatDescriptionGetDimensions([self captureDevice].activeFormat.formatDescription);
}

- (CAShapeLayer *)borderLayer {
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer layer];
        _borderLayer.borderColor = [UIColor blueColor].CGColor;
        _borderLayer.fillRule = kCAFillRuleEvenOdd;
        _borderLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        _borderLayer.opacity = 0.60;
    }
    return _borderLayer;
}

- (UIImageView *)borderImageView {
    if (!_borderImageView) {
        _borderImageView = [[UIImageView alloc] init];
        _borderImageView.image = self.config.borderImage;
        [_borderImageView addSubview:self.scanLineImageView];
    }
    return _borderImageView;
}

- (UIImageView *)scanLineImageView {
    if (!_scanLineImageView) {
        _scanLineImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DLVideoCapture.bundle/icon_scan_line"]];
    }
    return _scanLineImageView;
}

- (AVCaptureMetadataOutput *)metadataOutput {
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        _metadataOutput.rectOfInterest = CGRectMake(0.1, 0, 0.9, 1);
        
        dispatch_queue_t captureQueue = dispatch_queue_create("com.KeyFrameKit.metadataOutput", DISPATCH_QUEUE_SERIAL);
        [_metadataOutput setMetadataObjectsDelegate:self queue:captureQueue];
    }
    return _metadataOutput;
}

@end
