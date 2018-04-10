//
//  ScanZoomSlider.h
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/13.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLScanZoomSlider : UIView

@property (assign, nonatomic) CGFloat value;

@property (assign, nonatomic) CGFloat minimumValue;

@property (assign, nonatomic) CGFloat maximumValue;

//轨道最大高度
@property (assign, nonatomic) CGFloat trackMaximumHeight;

@end
