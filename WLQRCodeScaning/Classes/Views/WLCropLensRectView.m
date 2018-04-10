//
//  CropLensRectView.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/11.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "WLCropLensRectView.h"
#import "Chameleon.h"

@implementation WLCropLensRectView {
    NSArray<UIImageView *> *_cornerImageViews;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    self.tintColor = [HexColor(@"38c3ec") flatten];
    [self setupViews];
    return self;
}


- (void)setupViews {
    NSMutableArray *views = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < 4; i++) {
        NSString *imageName = [NSString stringWithFormat:@"scan_%ld",(long)i];
        UIImage *image = QRImageNamed(imageName);
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [self addSubview:imageView];
        [views addObject:imageView];
    }
    _cornerImageViews = [views copy];
}

- (void)layoutSubviews {
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    [_cornerImageViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize size = obj.intrinsicContentSize;
        if (idx == 0) {
            obj.frame = CGRectMake(0, 0, size.width, size.height);
        } else if (idx == 1) {
            obj.frame = CGRectMake(width - size.width, 0, size.width, size.height);
        } else if (idx == 2) {
            obj.frame = CGRectMake(0, height - size.height, size.width, size.height);
        } else if (idx == 3) {
            obj.frame = CGRectMake(width - size.width, height - size.height, size.width, size.height);
        }
    }];
    [super layoutSubviews];
    
}
@end
