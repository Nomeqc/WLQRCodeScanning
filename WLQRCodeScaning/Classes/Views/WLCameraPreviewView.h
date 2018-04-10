//
//  WLCameraPreviewView.h
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/7.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession,AVCaptureVideoPreviewLayer;

@interface WLCameraPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) AVCaptureSession *session;

@end
