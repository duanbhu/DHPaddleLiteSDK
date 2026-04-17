//
//  DHPaddleLiteTextRecognition.mm
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import "DHPaddleLiteTextRecognition.h"
#import "DLTextRecognitionResult.h"

// OpenCV headers
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>

// PaddleLite headers
#include "paddle_api.h"
#include "paddle_use_kernels.h"
#include "paddle_use_ops.h"

// Pipeline header
#include "pipeline.h"

// C++ standard library
#include <string>
#include <vector>

using namespace paddle::lite_api;
using namespace cv;

// Error domain
NSString *const DHPaddleLiteTextRecognitionErrorDomain = @"com.paddlelite.textrecognition";

// Pipeline instance
Pipeline *pipeline_;

@interface DHPaddleLiteTextRecognition ()

// Internal properties
@property (nonatomic) std::string dict_path;
@property (nonatomic) std::string config_path;
@property (nonatomic, assign) CGFloat confidenceThreshold;
@property (nonatomic, assign) BOOL initializationFailed;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

// Throttle control properties
@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, assign) NSTimeInterval lastProcessTime;

// Private helper methods
- (cv::Mat)convertUIImageToMat:(UIImage *)image error:(NSError **)error;
- (cv::Mat)cropMat:(cv::Mat)srcMat withRect:(CGRect)rect error:(NSError **)error;

@end

@implementation DHPaddleLiteTextRecognition

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static DHPaddleLiteTextRecognition *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DHPaddleLiteTextRecognition alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        // Set default confidence threshold
        _confidenceThreshold = 0.7;
        
        // Initialize failure flag
        _initializationFailed = NO;
        
        // Initialize throttle control
        _isProcessing = NO;
        _lastProcessTime = 0;
        
        // Create serial queue for thread-safe resource access
        _processingQueue = dispatch_queue_create("com.paddlelite.textrecognition.processing", DISPATCH_QUEUE_SERIAL);
        
        // Setup the SDK
        [self setup];
    }
    return self;
}

- (void)setup {
    // Get bundle path - try multiple approaches for robustness
    NSBundle *resourceBundle = nil;
    NSString *path = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *candidateBundleNames = @[
        @"DHPaddleLiteSDK",
        @"DHPaddleLiteSDK_DHPaddleLiteSDK",
        @"DLPaddleLiteSDK",
        @"DLPaddleLiteSDK_DLPaddleLiteSDK"
    ];
    NSString *requiredFileName = @"cn_PP-OCRv5_mobile_det_opt.nb";
    
    // Approach 1: Try to find known resource bundle names from class bundle and main bundle
    NSBundle *currentBundle = [NSBundle bundleForClass:self.class];
    for (NSString *bundleName in candidateBundleNames) {
        if (path) {
            break;
        }
        NSURL *bundleURL = [currentBundle URLForResource:bundleName withExtension:@"bundle"];
        if (!bundleURL) {
            bundleURL = [[NSBundle mainBundle] URLForResource:bundleName withExtension:@"bundle"];
        }
        if (bundleURL) {
            NSBundle *candidateBundle = [NSBundle bundleWithURL:bundleURL];
            NSString *candidatePath = [candidateBundle bundlePath];
            NSString *requiredFilePath = [candidatePath stringByAppendingPathComponent:requiredFileName];
            if ([fileManager fileExistsAtPath:requiredFilePath]) {
                resourceBundle = candidateBundle;
                path = candidatePath;
                NSLog(@"[DHPaddleLiteTextRecognition] 找到资源包 (方法1): %@", path);
            }
        }
    }
    
    // Approach 2: Scan all bundles/frameworks for the required model file
    if (!path) {
        NSMutableArray<NSBundle *> *searchBundles = [NSMutableArray array];
        [searchBundles addObjectsFromArray:[NSBundle allBundles]];
        [searchBundles addObjectsFromArray:[NSBundle allFrameworks]];
        
        for (NSBundle *bundle in searchBundles) {
            NSString *candidatePath = [bundle bundlePath];
            if (!candidatePath.length) {
                continue;
            }
            NSString *requiredFilePath = [candidatePath stringByAppendingPathComponent:requiredFileName];
            if ([fileManager fileExistsAtPath:requiredFilePath]) {
                resourceBundle = bundle;
                path = candidatePath;
                NSLog(@"[DHPaddleLiteTextRecognition] 找到资源包 (方法2): %@", path);
                break;
            }
        }
    }
    
    // Approach 3: Fallback to main bundle for diagnostics
    if (!path) {
        resourceBundle = [NSBundle mainBundle];
        path = [resourceBundle bundlePath];
        NSLog(@"[DHPaddleLiteTextRecognition] 使用主包兜底 (方法3): %@", path);
    }
    
    // Setup model paths
    // Note: CocoaPods resource_bundles flattens the directory structure,
    // so files are at the bundle root, not in subdirectories
    std::string paddle_dir = std::string([path UTF8String]);
    std::string det_model_file = paddle_dir + "/cn_PP-OCRv5_mobile_det_opt.nb";
    std::string rec_model_file = paddle_dir + "/cn_PP-OCRv5_mobile_rec_opt.nb";
    std::string cls_model_file = paddle_dir + "/cn_ppocr_mobile_v2.0_cls_opt.nb";
    
    // Setup dictionary and config paths
    self.dict_path = paddle_dir + "/ppocrv5_dict.txt";
    self.config_path = paddle_dir + "/config.txt";
    
    // Check if model files exist
    NSString *detModelPath = [NSString stringWithUTF8String:det_model_file.c_str()];
    NSString *recModelPath = [NSString stringWithUTF8String:rec_model_file.c_str()];
    NSString *clsModelPath = [NSString stringWithUTF8String:cls_model_file.c_str()];
    NSString *dictPath = [NSString stringWithUTF8String:self.dict_path.c_str()];
    NSString *configPath = [NSString stringWithUTF8String:self.config_path.c_str()];
    
    // Validate all required files exist and provide detailed diagnostics
    BOOL allFilesExist = YES;
    
    if (![fileManager fileExistsAtPath:detModelPath]) {
        NSLog(@"[DHPaddleLiteTextRecognition] 错误: 检测模型文件不存在: %@", detModelPath);
        NSLog(@"[DHPaddleLiteTextRecognition] 提示: 请确保运行 'pod install' 并重新编译项目");
        allFilesExist = NO;
    }
    
    if (![fileManager fileExistsAtPath:recModelPath]) {
        NSLog(@"[DHPaddleLiteTextRecognition] 错误: 识别模型文件不存在: %@", recModelPath);
        allFilesExist = NO;
    }
    
    if (![fileManager fileExistsAtPath:clsModelPath]) {
        NSLog(@"[DHPaddleLiteTextRecognition] 错误: 分类模型文件不存在: %@", clsModelPath);
        allFilesExist = NO;
    }
    
    if (![fileManager fileExistsAtPath:dictPath]) {
        NSLog(@"[DHPaddleLiteTextRecognition] 错误: 字典文件不存在: %@", dictPath);
        allFilesExist = NO;
    }
    
    if (![fileManager fileExistsAtPath:configPath]) {
        NSLog(@"[DHPaddleLiteTextRecognition] 错误: 配置文件不存在: %@", configPath);
        allFilesExist = NO;
    }
    
    // If any files are missing, log the bundle contents for debugging
    if (!allFilesExist) {
        NSLog(@"[DHPaddleLiteTextRecognition] 调试信息 - 包路径: %@", path);
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
        NSLog(@"[DHPaddleLiteTextRecognition] 调试信息 - 包内容: %@", contents);
        
        // Check if models directory exists (for reference, though CocoaPods flattens structure)
        NSString *modelsDir = [NSString stringWithFormat:@"%@/models", path];
        if ([fileManager fileExistsAtPath:modelsDir]) {
            NSArray *modelsContents = [fileManager contentsOfDirectoryAtPath:modelsDir error:nil];
            NSLog(@"[DHPaddleLiteTextRecognition] 调试信息 - models目录内容: %@", modelsContents);
        } else {
            NSLog(@"[DHPaddleLiteTextRecognition] 调试信息 - models目录不存在（这是正常的，CocoaPods会将文件扁平化到包根目录）");
        }
        
        // Check if labels directory exists
        NSString *labelsDir = [NSString stringWithFormat:@"%@/labels", path];
        if ([fileManager fileExistsAtPath:labelsDir]) {
            NSArray *labelsContents = [fileManager contentsOfDirectoryAtPath:labelsDir error:nil];
            NSLog(@"[DHPaddleLiteTextRecognition] 调试信息 - labels目录内容: %@", labelsContents);
        }
        
        self.initializationFailed = YES;
        return;
    }
    
    // Initialize Pipeline with LITE_POWER_HIGH mode and 2 threads
    // Default confidence threshold is set to 0.7 in init method
    @try {
        pipeline_ = new Pipeline(det_model_file, cls_model_file, rec_model_file,
                                "LITE_POWER_HIGH", 2, self.config_path, self.dict_path);
        NSLog(@"[DHPaddleLiteTextRecognition] SDK初始化成功");
    } @catch (NSException *exception) {
        NSLog(@"[DHPaddleLiteTextRecognition] 错误: Pipeline初始化失败: %@", exception.reason);
        self.initializationFailed = YES;
    }
}

#pragma mark - Public Methods

- (void)recognizeImage:(UIImage *)image
        effectiveArea:(CGRect)rect
           completion:(void(^)(NSArray<DLTextRecognitionResult *> * _Nullable results, NSError * _Nullable error))completion {
    // Throttle control: Skip if already processing
    if (self.isProcessing) {
//        NSLog(@"[DHPaddleLiteTextRecognition] 正在处理中，跳过本次请求");
        if (completion) {
            completion(@[], nil); // Return empty results instead of error
        }
        return;
    }
    
    // Throttle control: Limit processing frequency (max 2 times per second)
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval minInterval = 0.3; // 500ms interval
    
    if (currentTime - self.lastProcessTime < minInterval) {
//        NSLog(@"[DHPaddleLiteTextRecognition] 处理频率过高，跳过本次请求");
        if (completion) {
            completion(@[], nil); // Return empty results instead of error
        }
        return;
    }
    
    // Mark as processing and update last process time
    self.isProcessing = YES;
    self.lastProcessTime = currentTime;
    
    // Check if initialization failed
    if (self.initializationFailed) {
        self.isProcessing = NO; // Reset flag before returning
        NSError *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                             code:DHPaddleLiteTextRecognitionErrorCodeModelLoadFailed
                                         userInfo:@{NSLocalizedDescriptionKey: @"SDK初始化失败，模型文件或配置文件加载失败"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 1. Validate input image is not nil
    if (!image) {
        self.isProcessing = NO; // Reset flag before returning
        NSError *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                             code:DHPaddleLiteTextRecognitionErrorCodeInvalidImage
                                         userInfo:@{NSLocalizedDescriptionKey: @"输入图像不能为nil"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    // 2. Call image preprocessing logic - convert UIImage to cv::Mat
    NSError *conversionError = nil;
    cv::Mat convertedMat = [self convertUIImageToMat:image error:&conversionError];
    
    if (conversionError || convertedMat.empty()) {
        self.isProcessing = NO; // Reset flag before returning
        if (completion) {
            completion(nil, conversionError);
        }
        return;
    }
    
    // 3. Call crop helper method with effectiveArea
    NSError *cropError = nil;
    cv::Mat processedMat = [self cropMat:convertedMat withRect:rect error:&cropError];
    
    // Release convertedMat after cropping (it's no longer needed)
    // Note: cv::Mat uses reference counting, setting to empty Mat releases memory
    convertedMat = cv::Mat();
    
    if (cropError || processedMat.empty()) {
        self.isProcessing = NO; // Reset flag before returning
        if (completion) {
            completion(nil, cropError);
        }
        return;
    }
    
    // Clone processedMat to ensure it's independent and can be safely used in async block
    // Use __block to allow modification in the block
    __block cv::Mat processedMatCopy = processedMat.clone();
    // Release original processedMat
    processedMat = cv::Mat();
    
    // 4. Execute OCR on background thread using serial queue for thread-safe resource access
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.processingQueue, ^{
        NSMutableArray<DLTextRecognitionResult *> *results = [NSMutableArray array];
        NSError *processingError = nil;
        
        @try {
            // Use processedMatCopy for processing
            
            // Pipeline's Process method requires an output image path for visualization
            // Use /dev/null to avoid writing large files (memory optimization)
            // Note: We still need a valid extension for imwrite to work
            std::string output_path = "/tmp/ocr_vis_temp.jpg";
            
            // Call Pipeline Process method
            std::vector<std::string> res_txt;
            __block cv::Mat img_vis = pipeline_->Process(processedMatCopy, output_path, res_txt);
            
            // Release img_vis immediately after use (Requirement 7.2)
            img_vis = cv::Mat();
            
            // Release processedMatCopy after processing
            processedMatCopy = cv::Mat();
            
            // Delete temporary file immediately to free disk space
            [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/ocr_vis_temp.jpg" error:nil];
            
            // Parse res_txt vector (text and confidence alternate)
            // Format: [text_0, confidence_0, text_1, confidence_1, ...]
            if (res_txt.size() > 0 && res_txt.size() % 2 == 0) {
                NSInteger index = 0;
                
                for (size_t i = 0; i < res_txt.size(); i += 2) {
                    // Even indices contain text
                    std::string textStr = res_txt[i];
                    NSString *text = [NSString stringWithUTF8String:textStr.c_str()];
                    
                    // Odd indices contain confidence as string
                    std::string confidenceStr = res_txt[i + 1];
                    CGFloat confidence = [[NSString stringWithUTF8String:confidenceStr.c_str()] floatValue];
                    
                    // Apply confidence threshold filter
                    if (confidence >= self.confidenceThreshold) {
                        // Create DLTextRecognitionResult object
                        DLTextRecognitionResult *result = [[DLTextRecognitionResult alloc] initWithText:text
                                                                                             confidence:confidence
                                                                                                  index:index];
                        [results addObject:result];
                        index++;
                    }
                }
            }
            
        } @catch (NSException *exception) {
            // Handle Pipeline processing exceptions
            processingError = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                                  code:DHPaddleLiteTextRecognitionErrorCodeProcessingFailed
                                              userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"OCR处理失败: %@", exception.reason]}];
            NSLog(@"[DHPaddleLiteTextRecognition] 错误: %@, 错误码: %ld", processingError.localizedDescription, (long)processingError.code);
        }
        
        // Release temporary resources after processing (Requirement 7.2)
        // Note: convertedMat and processedMat will be automatically released when they go out of scope
        
        // Reset processing flag
        weakSelf.isProcessing = NO;
        
        // Call completion callback with results or error
        if (completion) {
            if (processingError) {
                completion(nil, processingError);
            } else {
                // Return results array (empty if no text detected or all filtered by threshold)
                completion([results copy], nil);
            }
        }
    });
}

- (void)setConfidenceThreshold:(CGFloat)threshold {
    // Validate threshold range (0.0 - 1.0)
    if (threshold < 0.0 || threshold > 1.0) {
        NSLog(@"[DHPaddleLiteTextRecognition] 警告: 置信度阈值超出有效范围 [0.0, 1.0]，输入值: %.2f，将被限制到有效范围", threshold);
    }
    
    // Clamp threshold to valid range [0.0, 1.0]
    CGFloat clampedThreshold = MAX(0.0, MIN(1.0, threshold));
    _confidenceThreshold = clampedThreshold;
    
    NSLog(@"[DHPaddleLiteTextRecognition] 置信度阈值已设置为: %.2f", _confidenceThreshold);
}

#pragma mark - Private Helper Methods

- (cv::Mat)convertUIImageToMat:(UIImage *)image error:(NSError **)error {
    cv::Mat resultMat;
    
    @try {
        // Memory optimization: Resize large images before processing
        UIImage *processImage = image;
        CGFloat maxDimension = 1920.0; // Maximum dimension to prevent memory issues
        
        if (image.size.width > maxDimension || image.size.height > maxDimension) {
            CGFloat scale = MIN(maxDimension / image.size.width, maxDimension / image.size.height);
            CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
            
            NSLog(@"[DHPaddleLiteTextRecognition] 图片过大 (%.0f x %.0f)，缩放到 (%.0f x %.0f)",
                  image.size.width, image.size.height, newSize.width, newSize.height);
            
            UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
            [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
            processImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        // Convert UIImage to cv::Mat using OpenCV helper function
        cv::Mat tempMat;
        UIImageToMat(processImage, tempMat);
        
        // Check if conversion was successful
        if (tempMat.empty()) {
            if (error) {
                *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                             code:DHPaddleLiteTextRecognitionErrorCodeUnsupportedFormat
                                         userInfo:@{NSLocalizedDescriptionKey: @"图像转换失败，无法将UIImage转换为cv::Mat"}];
                NSLog(@"[DHPaddleLiteTextRecognition] 错误: %@, 错误码: %ld", (*error).localizedDescription, (long)(*error).code);
            }
            return resultMat;
        }
        
        // Convert RGBA to RGB if necessary
        if (tempMat.channels() == 4) {
            @try {
                cvtColor(tempMat, resultMat, COLOR_RGBA2RGB);
            } @catch (NSException *exception) {
                if (error) {
                    *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                                 code:DHPaddleLiteTextRecognitionErrorCodeUnsupportedFormat
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"颜色空间转换失败: %@", exception.reason]}];
                    NSLog(@"[DHPaddleLiteTextRecognition] 错误: %@, 错误码: %ld", (*error).localizedDescription, (long)(*error).code);
                }
                return cv::Mat();
            }
        } else if (tempMat.channels() == 3) {
            // Already RGB, use directly
            resultMat = tempMat;
        } else {
            // Unsupported channel count
            if (error) {
                *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                             code:DHPaddleLiteTextRecognitionErrorCodeUnsupportedFormat
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"不支持的图像格式，通道数: %d", tempMat.channels()]}];
                NSLog(@"[DHPaddleLiteTextRecognition] 错误: %@, 错误码: %ld", (*error).localizedDescription, (long)(*error).code);
            }
            return cv::Mat();
        }
        
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                         code:DHPaddleLiteTextRecognitionErrorCodeUnsupportedFormat
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"图像转换异常: %@", exception.reason]}];
            NSLog(@"[DHPaddleLiteTextRecognition] 错误: %@, 错误码: %ld", (*error).localizedDescription, (long)(*error).code);
        }
        return cv::Mat();
    }
    
    return resultMat;
}

- (cv::Mat)cropMat:(cv::Mat)srcMat withRect:(CGRect)rect error:(NSError **)error {
    // Handle CGRectZero case - return original image
    if (CGRectIsEmpty(rect) || CGRectEqualToRect(rect, CGRectZero)) {
        return srcMat;
    }
    
    // Validate source image is not empty
    if (srcMat.empty()) {
        if (error) {
            *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                         code:DHPaddleLiteTextRecognitionErrorCodeInvalidImage
                                     userInfo:@{NSLocalizedDescriptionKey: @"源图像为空，无法进行裁剪"}];
        }
        return cv::Mat();
    }
    
    // Convert CGRect to cv::Rect
    // Note: CGRect uses (x, y, width, height) and cv::Rect uses (x, y, width, height)
    int x = (int)rect.origin.x;
    int y = (int)rect.origin.y;
    int width = (int)rect.size.width;
    int height = (int)rect.size.height;
    
    // Validate rectangle bounds are within image dimensions
    if (x < 0 || y < 0 || width <= 0 || height <= 0) {
        if (error) {
            *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                         code:DHPaddleLiteTextRecognitionErrorCodeInvalidImage
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无效的裁剪区域: x=%d, y=%d, width=%d, height=%d", x, y, width, height]}];
        }
        return cv::Mat();
    }
    
    if (x + width > srcMat.cols || y + height > srcMat.rows) {
        if (error) {
            *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                         code:DHPaddleLiteTextRecognitionErrorCodeInvalidImage
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"裁剪区域超出图像边界: 图像尺寸(%d x %d), 裁剪区域(%d, %d, %d, %d)", srcMat.cols, srcMat.rows, x, y, width, height]}];
        }
        return cv::Mat();
    }
    
    // Create cv::Rect and crop the image
    @try {
        cv::Rect cropRect(x, y, width, height);
        cv::Mat croppedMat = srcMat(cropRect);
        
        // Return a clone to ensure the cropped image is independent
        return croppedMat.clone();
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:DHPaddleLiteTextRecognitionErrorDomain
                                         code:DHPaddleLiteTextRecognitionErrorCodeProcessingFailed
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"图像裁剪异常: %@", exception.reason]}];
        }
        return cv::Mat();
    }
}

@end
