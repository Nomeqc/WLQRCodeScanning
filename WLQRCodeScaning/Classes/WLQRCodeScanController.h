//
//  QRCodeScanController.h
//  QRCo/Users/iosdeveloper003/Desktop/TestProject/QRCodeScanningDemo/QRCodeScanningDemo/Info.plistdeScanningDemo
//
//  Created by iOSDeveloper003 on 17/2/25.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLQRCodeScanController : UIViewController

///是否开启播放声音
@property (nonatomic) BOOL enablePlaySounds;

@property (nonatomic, copy) void (^detectQRCodeHandler) (NSString *result);

@end
