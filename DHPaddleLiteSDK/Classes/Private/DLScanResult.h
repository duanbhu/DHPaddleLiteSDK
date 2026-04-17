//
//  DLScanResult.h
//  DLPaddleLiteSDK
//
//  Created by Duanhu on 2023/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLScanResult : NSObject

/// 手机号
@property(nonatomic, strong) NSString *mobile;

/// 隐私号码
@property(nonatomic, strong) NSString *privatePhone;

/// 虚拟号
@property(nonatomic, strong) NSString *virtualNo;

@end

NS_ASSUME_NONNULL_END
