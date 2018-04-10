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

- (void)viewDidLoad
{
    [super viewDidLoad];
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
