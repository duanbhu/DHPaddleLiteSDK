#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DHPaddleLiteTextRecognition.h"
#import "DLTextRecognitionResult.h"
#import "DHOCRErrorCorrector.h"
#import "DHPhoneNumberFormatter.h"
#import "DHPhoneNumberRecognizer.h"
#import "DHPhoneNumberResult.h"
#import "DHPhoneNumberTypeFilter.h"
#import "DHPhoneNumberTypes.h"
#import "DHPhoneNumberValidator.h"
#import "DHStreamRecognitionManager.h"
#import "DHTrackingNumberFilter.h"

FOUNDATION_EXPORT double DHPaddleLiteSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char DHPaddleLiteSDKVersionString[];

