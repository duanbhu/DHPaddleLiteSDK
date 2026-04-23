//
//  DLTextRecognitionResult.h
//  DLPaddleLiteSDK
//
//  Created by Kiro on 2024.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief OCR识别结果数据模型
 *
 * DLTextRecognitionResult封装了单行文本的OCR识别结果，
 * 包含识别出的文本内容、置信度分数和位置索引。
 *
 * @discussion 该类的实例由DHPaddleLiteTextRecognition自动创建，
 * 开发者通常不需要手动创建该类的实例。
 *
 * @see DHPaddleLiteTextRecognition
 */
@interface DLTextRecognitionResult : NSObject

/**
 * @brief 识别出的文本内容
 *
 * @discussion 包含OCR识别出的完整文本字符串。
 * 对于中英文混合文本，会保持原始顺序。
 *
 * @note 该属性为只读，不可修改
 */
@property (nonatomic, copy, readonly) NSString *text;

/**
 * @brief 置信度分数
 *
 * 表示OCR识别结果的可信程度，取值范围为[0.0, 1.0]。
 *
 * @discussion 置信度解读：
 * - 0.9-1.0: 非常高的可信度，识别结果几乎确定正确
 * - 0.7-0.9: 较高的可信度，识别结果大概率正确
 * - 0.5-0.7: 中等可信度，识别结果可能存在错误
 * - 0.0-0.5: 低可信度，识别结果不太可靠
 *
 * @note 该属性为只读，不可修改
 * @note 只有置信度>=设置的阈值的结果才会被返回
 */
@property (nonatomic, assign, readonly) CGFloat confidence;

/**
 * @brief 文本在图像中的位置索引
 *
 * 表示该文本行在图像中的相对位置，按照从上到下、从左到右的顺序排列。
 * 索引从0开始。
 *
 * @discussion 使用场景：
 * - 保持文本的原始顺序
 * - 重建文本的空间布局
 * - 按位置对文本进行分组或排序
 *
 * @note 该属性为只读，不可修改
 */
@property (nonatomic, assign, readonly) NSInteger index;

/**
 * @brief 文本行的外接矩形
 *
 * 坐标系统与输入图像一致：原点在左上角，单位为像素。
 *
 * @note 当底层未返回定位信息时，该值为CGRectZero
 */
@property (nonatomic, assign, readonly) CGRect boundingBox;

/**
 * @brief 文本行四边形顶点（按顺时针）
 *
 * 使用 NSValue(CGPoint) 封装四个顶点，数量通常为4。
 * 坐标系统与输入图像一致：原点在左上角，单位为像素。
 *
 * @note 当底层未返回定位信息时，该数组为空
 */
@property (nonatomic, copy, readonly) NSArray<NSValue *> *corners;

/**
 * @brief 初始化识别结果对象
 *
 * 创建一个新的识别结果对象，包含文本内容、置信度和位置索引。
 *
 * @param text 识别出的文本内容，不能为nil
 * @param confidence 置信度分数，范围[0.0, 1.0]
 * @param index 位置索引，从0开始
 *
 * @return 初始化的DLTextRecognitionResult实例
 *
 * @discussion 该方法通常由SDK内部调用，开发者一般不需要手动创建实例。
 *
 * @note 如果confidence超出有效范围，会被自动限制在[0.0, 1.0]范围内
 */
- (instancetype)initWithText:(NSString *)text
                  confidence:(CGFloat)confidence
                       index:(NSInteger)index;

/**
 * @brief 初始化识别结果对象（含行级位置信息）
 *
 * @param text 识别出的文本内容，不能为nil
 * @param confidence 置信度分数，范围[0.0, 1.0]
 * @param index 位置索引，从0开始
 * @param boundingBox 文本行外接矩形（像素坐标）
 * @param corners 文本行四边形顶点（NSValue(CGPoint)）
 *
 * @return 初始化的DLTextRecognitionResult实例
 */
- (instancetype)initWithText:(NSString *)text
                  confidence:(CGFloat)confidence
                       index:(NSInteger)index
                 boundingBox:(CGRect)boundingBox
                     corners:(NSArray<NSValue *> *)corners;

@end

NS_ASSUME_NONNULL_END
