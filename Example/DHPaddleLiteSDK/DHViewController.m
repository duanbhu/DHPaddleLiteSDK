//
//  DHViewController.m
//  DHPaddleLiteSDK
//
//  Created by duanbhu on 04/17/2026.
//  Copyright (c) 2026 duanbhu. All rights reserved.
//

#import "DHViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import <DHPaddleLiteSDK/DHPaddleLiteTextRecognition.h>
#import <DHPaddleLiteSDK/DLTextRecognitionResult.h>

@interface DHViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextView *resultTextView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *recognitionBoxView;
@property (nonatomic, strong) UILabel *recognitionHintLabel;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CAShapeLayer *textBoxesLayer;
@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) DHPaddleLiteTextRecognition *textRecognizer;

@property (atomic, assign) BOOL isSessionRunning;
@property (atomic, assign) BOOL isFrameProcessing;
@property (atomic, assign) CFTimeInterval lastInferenceTime;
@property (atomic, assign) CGRect recognitionRectNormalized;
@property (atomic, assign) CGSize previewSizeForMapping;

@end

@implementation DHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.captureQueue = dispatch_queue_create("com.dhpaddlelite.example.camera", DISPATCH_QUEUE_SERIAL);
    self.ciContext = [[CIContext alloc] initWithOptions:nil];
    self.textRecognizer = [DHPaddleLiteTextRecognition sharedInstance];
    [_textRecognizer setDirectionClassifyEnabled:false];
    [_textRecognizer setOCRThreads:4];
    
    [self.textRecognizer setConfidenceThreshold:0.75];
    self.lastInferenceTime = 0;
    
    [self setupUI];
    [self requestCameraPermissionAndPrepareSession];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.previewView.bounds;
    self.textBoxesLayer.frame = self.previewView.bounds;
    [self updateRecognitionRectCache];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopSession];
}

#pragma mark - UI

- (void)setupUI {
    self.previewView = [[UIView alloc] init];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    self.previewView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.previewView];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.statusLabel.font = [UIFont fontWithName:@"Menlo-Bold" size:14] ?: [UIFont boldSystemFontOfSize:14];
    self.statusLabel.text = @"准备中...";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.layer.cornerRadius = 8;
    self.statusLabel.layer.masksToBounds = YES;
    [self.view addSubview:self.statusLabel];
    
    self.resultTextView = [[UITextView alloc] init];
    self.resultTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultTextView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.58];
    self.resultTextView.textColor = [UIColor colorWithRed:0.41 green:1.0 blue:0.62 alpha:1.0];
    self.resultTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:14] ?: [UIFont systemFontOfSize:14];
    self.resultTextView.editable = NO;
    self.resultTextView.text = @"识别结果会实时显示在这里";
    self.resultTextView.layer.cornerRadius = 10;
    self.resultTextView.layer.masksToBounds = YES;
    self.resultTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.view addSubview:self.resultTextView];
    
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleButton setTitle:@"开始识别" forState:UIControlStateNormal];
    [self.toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
    self.toggleButton.layer.cornerRadius = 10;
    self.toggleButton.layer.masksToBounds = YES;
    self.toggleButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.toggleButton addTarget:self action:@selector(toggleRecognition) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];
    
    self.recognitionBoxView = [[UIView alloc] init];
    self.recognitionBoxView.translatesAutoresizingMaskIntoConstraints = NO;
    self.recognitionBoxView.backgroundColor = [UIColor clearColor];
    self.recognitionBoxView.layer.borderWidth = 2.0;
    self.recognitionBoxView.layer.borderColor = [UIColor colorWithRed:0.3 green:1.0 blue:0.45 alpha:0.95].CGColor;
    self.recognitionBoxView.layer.cornerRadius = 8.0;
    [self.view addSubview:self.recognitionBoxView];
    
    self.recognitionHintLabel = [[UILabel alloc] init];
    self.recognitionHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.recognitionHintLabel.textColor = [UIColor colorWithRed:0.75 green:1.0 blue:0.8 alpha:1.0];
    self.recognitionHintLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:12] ?: [UIFont systemFontOfSize:12];
    self.recognitionHintLabel.textAlignment = NSTextAlignmentCenter;
    self.recognitionHintLabel.text = @"仅识别框内文本";
    [self.view addSubview:self.recognitionHintLabel];
    
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [self.statusLabel.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.statusLabel.heightAnchor constraintEqualToConstant:38],
        
        [self.resultTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.resultTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.resultTextView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-66],
        [self.resultTextView.heightAnchor constraintEqualToConstant:170],
        
        [self.toggleButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.toggleButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.toggleButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-10],
        [self.toggleButton.heightAnchor constraintEqualToConstant:44],
        
        [self.recognitionBoxView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.recognitionBoxView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.recognitionBoxView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-56],
        [self.recognitionBoxView.heightAnchor constraintEqualToAnchor:self.recognitionBoxView.widthAnchor multiplier:0.32],
        
        [self.recognitionHintLabel.topAnchor constraintEqualToAnchor:self.recognitionBoxView.bottomAnchor constant:8],
        [self.recognitionHintLabel.centerXAnchor constraintEqualToAnchor:self.recognitionBoxView.centerXAnchor]
    ]];
}

- (void)updateStatus:(NSString *)status result:(NSString *)result {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = status;
        if (result.length > 0) {
            self.resultTextView.text = result;
        }
    });
}

#pragma mark - Camera

- (void)requestCameraPermissionAndPrepareSession {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self prepareCaptureSession];
        return;
    }
    
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [weakSelf prepareCaptureSession];
                } else {
                    [weakSelf updateStatus:@"相机权限未开启" result:@"请在系统设置中允许相机权限后重试"];
                }
            });
        }];
        return;
    }
    
    [self updateStatus:@"相机权限未开启" result:@"请在系统设置中允许相机权限后重试"];
}

- (void)prepareCaptureSession {
    if (self.captureSession) {
        [self startSession];
        return;
    }
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!camera) {
        [self updateStatus:@"相机不可用" result:@"未找到可用摄像头"];
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    if (error || !input || ![session canAddInput:input]) {
        [self updateStatus:@"相机初始化失败" result:error.localizedDescription ?: @"无法添加相机输入"];
        return;
    }
    [session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    output.alwaysDiscardsLateVideoFrames = YES;
    [output setSampleBufferDelegate:self queue:self.captureQueue];
    
    if (![session canAddOutput:output]) {
        [self updateStatus:@"相机初始化失败" result:@"无法添加视频输出"];
        return;
    }
    [session addOutput:output];
    
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
    if (connection && connection.isVideoOrientationSupported) {
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    self.captureSession = session;
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewView.layer insertSublayer:self.previewLayer atIndex:0];
    
    self.textBoxesLayer = [CAShapeLayer layer];
    self.textBoxesLayer.strokeColor = [UIColor colorWithRed:1.0 green:0.86 blue:0.22 alpha:0.95].CGColor;
    self.textBoxesLayer.fillColor = [[UIColor colorWithRed:1.0 green:0.86 blue:0.22 alpha:0.12] CGColor];
    self.textBoxesLayer.lineWidth = 2.0;
    [self.previewView.layer addSublayer:self.textBoxesLayer];
    
    [self viewDidLayoutSubviews];
    
    [self startSession];
}

- (void)startSession {
    if (!self.captureSession || self.isSessionRunning) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.captureQueue, ^{
        [weakSelf.captureSession startRunning];
        weakSelf.isSessionRunning = YES;
    });
    
    [self.toggleButton setTitle:@"停止识别" forState:UIControlStateNormal];
    [self updateStatus:@"实时识别中（每 ~0.4 秒识别一帧）" result:@"等待识别结果..."];
}

- (void)stopSession {
    if (!self.captureSession || !self.isSessionRunning) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.captureQueue, ^{
        [weakSelf.captureSession stopRunning];
        weakSelf.isSessionRunning = NO;
        weakSelf.isFrameProcessing = NO;
    });
    
    [self.toggleButton setTitle:@"开始识别" forState:UIControlStateNormal];
    [self updateStatus:@"已停止" result:nil];
    [self clearTextBoxesOverlay];
}

- (void)toggleRecognition {
    if (self.isSessionRunning) {
        [self stopSession];
    } else {
        [self startSession];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (!self.isSessionRunning || self.isFrameProcessing) {
        return;
    }
    
    CFTimeInterval currentTime = CACurrentMediaTime();
    if (currentTime - self.lastInferenceTime < 0.4) {
        return;
    }
    
    self.lastInferenceTime = currentTime;
    self.isFrameProcessing = YES;
    
    @autoreleasepool {
        UIImage *frameImage = [self imageFromSampleBuffer:sampleBuffer];
        if (!frameImage) {
            self.isFrameProcessing = NO;
            return;
        }
        CGSize imageSize = CGSizeMake((CGFloat)CGImageGetWidth(frameImage.CGImage),
                                      (CGFloat)CGImageGetHeight(frameImage.CGImage));
        CGRect effectiveArea = [self effectiveAreaForImage:frameImage];
        
        __weak typeof(self) weakSelf = self;
        [self.textRecognizer recognizeImage:frameImage effectiveArea:effectiveArea completion:^(NSArray<DLTextRecognitionResult *> * _Nullable results, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            strongSelf.isFrameProcessing = NO;
            
            if (error) {
                [strongSelf clearTextBoxesOverlay];
                [strongSelf updateStatus:@"识别失败" result:error.localizedDescription];
                return;
            }
            
            [strongSelf updateTextBoxesOverlayWithResults:results imageSize:imageSize];
            NSString *resultText = [strongSelf renderResultText:results];
            NSString *status = [NSString stringWithFormat:@"实时识别中（当前 %lu 行）", (unsigned long)results.count];
            [strongSelf updateStatus:status result:resultText];
        }];
    }
}

#pragma mark - Helpers

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (imageBuffer == NULL) {
        return nil;
    }
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CGRect extent = CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
    CGImageRef cgImage = [self.ciContext createCGImage:ciImage fromRect:extent];
    if (cgImage == NULL) {
        return nil;
    }
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    return image;
}

- (NSString *)renderResultText:(NSArray<DLTextRecognitionResult *> *)results {
    if (results.count == 0) {
        return @"未识别到文本";
    }
    
    NSMutableString *text = [NSMutableString stringWithFormat:@"识别到 %lu 行：\n", (unsigned long)results.count];
    NSUInteger maxLines = MIN(results.count, (NSUInteger)6);
    for (NSUInteger idx = 0; idx < maxLines; idx++) {
        DLTextRecognitionResult *result = results[idx];
        if (result.text.length == 0) {
            continue;
        }
        [text appendFormat:@"%lu. %@ (%.2f)\n", (unsigned long)(idx + 1), result.text, result.confidence];
    }
    
    if (results.count > maxLines) {
        [text appendString:@"..."];
    }
    
    return text;
}

- (void)clearTextBoxesOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textBoxesLayer.path = nil;
    });
}

- (void)updateTextBoxesOverlayWithResults:(NSArray<DLTextRecognitionResult *> *)results
                                imageSize:(CGSize)imageSize {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (results.count == 0 || imageSize.width <= 0 || imageSize.height <= 0) {
            self.textBoxesLayer.path = nil;
            return;
        }
        
        UIBezierPath *combinedPath = [UIBezierPath bezierPath];
        for (DLTextRecognitionResult *result in results) {
            NSArray<NSValue *> *corners = result.corners;
            if (corners.count >= 4) {
                CGPoint firstPoint = [self previewPointFromImagePoint:[[corners firstObject] CGPointValue]
                                                            imageSize:imageSize];
                [combinedPath moveToPoint:firstPoint];
                for (NSUInteger idx = 1; idx < corners.count; idx++) {
                    CGPoint point = [self previewPointFromImagePoint:[[corners objectAtIndex:idx] CGPointValue]
                                                           imageSize:imageSize];
                    [combinedPath addLineToPoint:point];
                }
                [combinedPath closePath];
                continue;
            }
            
            if (!CGRectIsEmpty(result.boundingBox)) {
                CGPoint topLeft = [self previewPointFromImagePoint:result.boundingBox.origin imageSize:imageSize];
                CGPoint bottomRight = [self previewPointFromImagePoint:CGPointMake(CGRectGetMaxX(result.boundingBox),
                                                                                  CGRectGetMaxY(result.boundingBox))
                                                             imageSize:imageSize];
                CGRect previewRect = CGRectMake(topLeft.x,
                                                topLeft.y,
                                                MAX(0.0, bottomRight.x - topLeft.x),
                                                MAX(0.0, bottomRight.y - topLeft.y));
                [combinedPath appendPath:[UIBezierPath bezierPathWithRect:previewRect]];
            }
        }
        
        self.textBoxesLayer.path = combinedPath.CGPath;
    });
}

- (void)updateRecognitionRectCache {
    CGRect previewBounds = self.previewView.bounds;
    if (CGRectIsEmpty(previewBounds) || CGRectIsEmpty(self.recognitionBoxView.frame)) {
        return;
    }
    
    CGRect boxInPreview = [self.previewView convertRect:self.recognitionBoxView.frame fromView:self.view];
    CGRect clipped = CGRectIntersection(previewBounds, boxInPreview);
    if (CGRectIsNull(clipped) || CGRectIsEmpty(clipped)) {
        return;
    }
    
    CGFloat previewWidth = CGRectGetWidth(previewBounds);
    CGFloat previewHeight = CGRectGetHeight(previewBounds);
    self.previewSizeForMapping = previewBounds.size;
    self.recognitionRectNormalized = CGRectMake(CGRectGetMinX(clipped) / previewWidth,
                                                CGRectGetMinY(clipped) / previewHeight,
                                                CGRectGetWidth(clipped) / previewWidth,
                                                CGRectGetHeight(clipped) / previewHeight);
}

- (CGPoint)previewPointFromImagePoint:(CGPoint)imagePoint imageSize:(CGSize)imageSize {
    CGSize previewSize = self.previewView.bounds.size;
    if (previewSize.width <= 0 || previewSize.height <= 0 || imageSize.width <= 0 || imageSize.height <= 0) {
        return CGPointZero;
    }
    
    CGFloat scale = MAX(previewSize.width / imageSize.width, previewSize.height / imageSize.height);
    CGFloat renderedWidth = imageSize.width * scale;
    CGFloat renderedHeight = imageSize.height * scale;
    CGFloat cropX = (renderedWidth - previewSize.width) * 0.5;
    CGFloat cropY = (renderedHeight - previewSize.height) * 0.5;
    
    return CGPointMake(imagePoint.x * scale - cropX, imagePoint.y * scale - cropY);
}

- (CGRect)effectiveAreaForImage:(UIImage *)image {
    CGRect normalized = self.recognitionRectNormalized;
    if (CGRectIsEmpty(normalized)) {
        return CGRectZero;
    }
    
    CGSize previewSize = self.previewSizeForMapping;
    if (previewSize.width <= 0 || previewSize.height <= 0) {
        return CGRectZero;
    }
    
    size_t pixelWidth = CGImageGetWidth(image.CGImage);
    size_t pixelHeight = CGImageGetHeight(image.CGImage);
    CGSize imageSize = CGSizeMake((CGFloat)pixelWidth, (CGFloat)pixelHeight);
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        imageSize = image.size;
    }
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        return CGRectZero;
    }
    
    CGRect previewRect = CGRectMake(normalized.origin.x * previewSize.width,
                                    normalized.origin.y * previewSize.height,
                                    normalized.size.width * previewSize.width,
                                    normalized.size.height * previewSize.height);
    
    // Map from preview coordinates to source image coordinates with aspect-fill crop compensation.
    CGFloat scale = MAX(previewSize.width / imageSize.width, previewSize.height / imageSize.height);
    if (scale <= 0) {
        return CGRectZero;
    }
    CGFloat renderedWidth = imageSize.width * scale;
    CGFloat renderedHeight = imageSize.height * scale;
    CGFloat cropX = (renderedWidth - previewSize.width) * 0.5;
    CGFloat cropY = (renderedHeight - previewSize.height) * 0.5;
    
    CGRect imageRect = CGRectMake((previewRect.origin.x + cropX) / scale,
                                  (previewRect.origin.y + cropY) / scale,
                                  previewRect.size.width / scale,
                                  previewRect.size.height / scale);
    
    CGRect imageBounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGRect clipped = CGRectIntersection(imageRect, imageBounds);
    if (CGRectIsNull(clipped) || CGRectIsEmpty(clipped)) {
        return CGRectZero;
    }
    
    return CGRectIntegral(clipped);
}

@end
