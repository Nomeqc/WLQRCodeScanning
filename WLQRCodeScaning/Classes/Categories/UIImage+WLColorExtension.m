//
//  UIImage+WLAdd.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/1.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "UIImage+WLColorExtension.h"

@implementation UIImage (WLColorExtension)

+ (UIImage *)wlqr_imageWithColor:(UIColor *)color {
    return [self imageWithColor:color size:CGSizeMake(1, 1)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
