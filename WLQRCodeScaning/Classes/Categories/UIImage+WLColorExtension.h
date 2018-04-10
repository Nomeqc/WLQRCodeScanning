//
//  UIImage+WLAdd.h
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/1.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (WLColorExtension)

+ (UIImage *)wlqr_imageWithColor:(UIColor *)color;

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

@end
