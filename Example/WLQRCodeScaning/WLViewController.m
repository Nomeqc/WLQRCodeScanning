//
//  WLViewController.m
//  WLQRCodeScaning
//
//  Created by nomeqc@gmail.com on 04/10/2018.
//  Copyright (c) 2018 nomeqc@gmail.com. All rights reserved.
//

#import "WLViewController.h"
#import "WLQRCodeScanController.h"

@interface WLViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation WLViewController

#ifndef WLPodResourceBundleNamed
#define WLPodResourceBundleNamed(bundleName) ({\
NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:bundleName withExtension:@"bundle"];\
NSBundle *bundle = nil;\
if (url) {\
    bundle = [NSBundle bundleWithURL:url];\
}\
bundle;\
})
#endif
//
//
//
//#ifndef WLIsPodEnv
//
//#define WLIsPodEnv ({\
//BOOL isPodRelease = NO;\
//BOOL isPodDebug = NO;\
//#ifdef POD_CONFIGURATION_RELEASE\
//    isPodRelease = YES;\
//#endif\
//#ifdef POD_CONFIGURATION_DEBUG\
//    isPodDebug = YES;\
//#endif\
//isPodRelease || isPodDebug;\
//})
//
//#endif
//
//#ifndef QRResourceBundle
//#define QRResourceBundle ({\
//NSBundle *bundle = nil;\
//BOOL isPodDebug = NO;\
//BOOL isPodRelease = NO;\
//#ifdef POD_CONFIGURATION_DEBUG\
//isPodDebug = YES;\
//#endif\
//#ifdef POD_CONFIGURATION_RELEASE\
//isPodRelease = YES;\
//#endif\
//if (isPodDebug || isPodRelease) {\
//bundle = WLPodResourceBundleNamed(@"Resource");\
//} else {\
//bundle = [NSBundle mainBundle];\
//}\
//bundle;\
//})
//#endif
//
//#ifndef QRImageNamed
//#define QRImageNamed(imageName) ({\
//NSBundle *bundle = QRResourceBundle;\
//[UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];\
//})
//#endif





- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
//    NSBundle *bundle = WLPodResourceBundleNamed(@"bundle");
//    BOOL isPodEnv = ({
//        BOOL isPodRelease = NO;
//        BOOL isPodDebug = NO;
//#ifdef POD_CONFIGURATION_RELEASE
//        isPodRelease = YES;
//#endif
//#ifdef POD_CONFIGURATION_DEBUG
//        isPodDebug = YES;
//#endif
//        isPodRelease || isPodDebug;
//    });
//    NSLog(@"%@",isPodEnv? @"pod env":@"not pod env");
}

- (IBAction)rightBarButtonTapped:(UIBarButtonItem *)sender {
    WLQRCodeScanController *scanController = [[WLQRCodeScanController alloc] init];
    __weak typeof(self) weakSelf = self;
    [scanController setDetectQRCodeHandler:^(NSString *result) {
        typeof(weakSelf) self = weakSelf;
        self.label.text = result;
    }];
    scanController.enablePlaySounds = YES;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scanController];
    [self presentViewController:navController animated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
