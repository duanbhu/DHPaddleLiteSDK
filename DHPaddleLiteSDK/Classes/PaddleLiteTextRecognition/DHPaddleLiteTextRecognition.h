//
//  DHPaddleLiteTextRecognition.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DLTextRecognitionResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief OCR文本识别错误域
 *
 * 用于标识DHPaddleLiteTextRecognition相关的错误
 */
FOUNDATION_EXPORT NSString *const DHPaddleLiteTextRecognitionErrorDomain;

/**
 * @brief OCR文本识别错误码
 *
 * 定义了OCR识别过程中可能出现的各种错误类型
 */
typedef NS_ENUM(NSInteger, DHPaddleLiteTextRecognitionErrorCode) {
    /// 无效图像：输入图像为nil或无效
    DHPaddleLiteTextRecognitionErrorCodeInvalidImage = 1001,
    /// 不支持的格式：图像格式不支持或转换失败
    DHPaddleLiteTextRecognitionErrorCodeUnsupportedFormat = 1002,
    /// 模型加载失败：OCR模型文件加载失败
    DHPaddleLiteTextRecognitionErrorCodeModelLoadFailed = 1003,
    /// 处理失败：OCR识别过程中发生异常
    DHPaddleLiteTextRecognitionErrorCodeProcessingFailed = 1004,
    /// 无效阈值：置信度阈值超出有效范围(0.0-1.0)
    DHPaddleLiteTextRecognitionErrorCodeInvalidThreshold = 1005,
};

/**
 * @brief OCR文本识别SDK
 *
 * DHPaddleLiteTextRecognition提供基于PaddleOCR的通用文本识别功能。
 * 该SDK使用PaddleLite引擎和OpenCV进行图像处理，支持中英文文本识别。
 *
 * @discussion 主要特性：
 * - 单例模式，全局共享一个实例
 * - 支持全图识别和指定区域识别
 * - 可配置的置信度阈值过滤
 * - 异步处理，不阻塞主线程
 * - 线程安全，支持并发调用
 * - 返回结构化的识别结果（文本+置信度）
 *
 * @discussion 使用流程：
 * 1. 获取单例实例
 * 2. （可选）配置置信度阈值
 * 3. 调用识别方法，传入图像和回调
 * 4. 在回调中处理识别结果或错误
 *
 * @note 识别操作在后台线程执行，回调在完成时触发
 * @note 默认置信度阈值为0.7，只返回置信度>=阈值的结果
 *
 * @see DLTextRecognitionResult
 */
@interface DHPaddleLiteTextRecognition : NSObject

/**
 * @brief 获取单例实例
 *
 * @return DHPaddleLiteTextRecognition的单例对象
 *
 * @discussion 该方法返回全局唯一的SDK实例，确保模型只加载一次。
 * 多次调用返回同一个实例。
 *
 * @note 线程安全
 */
+ (instancetype)sharedInstance;

/**
 * @brief 识别图像中的文本
 *
 * 对输入图像进行OCR文本识别，返回识别出的文本内容及其置信度。
 * 识别操作在后台线程异步执行，不会阻塞调用线程。
 *
 * @param image 输入图像，必须为有效的UIImage对象
 * @param rect 有效识别区域，指定图像中需要识别的矩形区域。
 *             传入CGRectZero表示识别整个图像。
 *             坐标系统：原点在图像左上角，单位为像素
 * @param completion 完成回调，在识别完成或发生错误时调用
 *                   - results: 识别结果数组，按文本在图像中的位置排序（从上到下，从左到右）
 *                             只包含置信度>=阈值的结果。如果没有识别到文本，返回空数组
 *                   - error: 错误对象，识别成功时为nil
 *
 * @discussion 使用示例：
 * @code
 * UIImage *image = [UIImage imageNamed:@"test.jpg"];
 * [[DHPaddleLiteTextRecognition sharedInstance] recognizeImage:image
 *                                              effectiveArea:CGRectZero
 *                                                 completion:^(NSArray<DLTextRecognitionResult *> *results, NSError *error) {
 *     if (error) {
 *         NSLog(@"识别失败: %@", error.localizedDescription);
 *         return;
 *     }
 *     for (DLTextRecognitionResult *result in results) {
 *         NSLog(@"文本: %@, 置信度: %.2f", result.text, result.confidence);
 *     }
 * }];
 * @endcode
 *
 * @note 回调不保证在主线程执行，如需更新UI请使用dispatch_async切换到主线程
 * @note 图像格式支持：RGBA自动转换为RGB，其他格式可能导致错误
 *
 * @see DLTextRecognitionResult
 * @see setConfidenceThreshold:
 */
- (void)recognizeImage:(UIImage *)image
        effectiveArea:(CGRect)rect
           completion:(void(^)(NSArray<DLTextRecognitionResult *> * _Nullable results, NSError * _Nullable error))completion;

/**
 * @brief 设置置信度阈值
 *
 * 配置OCR识别结果的置信度过滤阈值。只有置信度大于等于该阈值的识别结果
 * 才会被返回。较高的阈值可以提高结果准确性，但可能遗漏一些文本。
 *
 * @param threshold 置信度阈值，有效范围为0.0到1.0
 *                  - 0.0: 返回所有识别结果
 *                  - 0.7: 默认值，平衡准确性和召回率
 *                  - 1.0: 只返回完全确定的结果
 *
 * @discussion 使用建议：
 * - 高质量图像：可以使用较低阈值（0.5-0.7）
 * - 低质量图像：建议使用较高阈值（0.7-0.9）
 * - 对准确性要求高：使用0.8以上
 * - 需要尽可能多的文本：使用0.5-0.6
 *
 * @note 阈值设置立即生效，影响后续所有识别操作
 * @note 超出有效范围的值会被自动限制在[0.0, 1.0]范围内
 */
- (void)setConfidenceThreshold:(CGFloat)threshold;

/**
 * @brief 获取当前置信度阈值
 *
 * @return 当前配置的置信度阈值，范围为0.0到1.0
 *
 * @discussion 默认值为0.7
 */
- (CGFloat)confidenceThreshold;

/**
 * @brief 设置是否开启方向分类（文本角度分类）
 *
 * @param enabled YES 开启，NO 关闭
 *
 * @discussion
 * - 开启可提升旋转文本场景下的准确率，但会增加耗时。
 * - 设置后立即生效。
 */
- (void)setDirectionClassifyEnabled:(BOOL)enabled;

/**
 * @brief 获取当前方向分类开关状态
 */
- (BOOL)isDirectionClassifyEnabled;

/**
 * @brief 设置OCR线程数
 *
 * @param threads 线程数，范围 1~8
 *
 * @discussion
 * - 默认值为4。
 * - 线程数调整会触发Pipeline重建，并在后续识别中生效。
 */
- (void)setOCRThreads:(NSInteger)threads;

/**
 * @brief 获取当前OCR线程数
 */
- (NSInteger)ocrThreads;

@end

NS_ASSUME_NONNULL_END
