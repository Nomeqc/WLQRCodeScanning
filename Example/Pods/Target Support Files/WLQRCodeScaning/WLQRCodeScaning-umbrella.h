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

#import "UIImage+WLColorExtension.h"
#import "WLCameraPreviewView.h"
#import "WLCropLensRectView.h"
#import "WLScanZoomSlider.h"
#import "WLQRCodeScanController.h"

FOUNDATION_EXPORT double WLQRCodeScaningVersionNumber;
FOUNDATION_EXPORT const unsigned char WLQRCodeScaningVersionString[];

