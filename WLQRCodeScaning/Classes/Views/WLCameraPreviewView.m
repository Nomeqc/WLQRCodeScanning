//
//  WLCameraPreviewView.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/7.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "WLCameraPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation WLCameraPreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    self.videoPreviewLayer.session = session;
}


@end
