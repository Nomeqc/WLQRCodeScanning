//
//  ScanZoomSlider.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/3/13.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "WLScanZoomSlider.h"
#import "Chameleon.h"




@implementation WLScanZoomSlider {
    UIView *_bgView;
    UIView *_fillView;
    UIView *_trackView;
    UIView *_dotView;
    
    UILabel *_increaseLabel;
    UILabel *_decreaseLabel;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    [self setupViews];
    return self;
}

- (void)setupViews {
    UIView *bgView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        view;
    });
    UIView *fillView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [HexColor(@"999999") flatten];
        view;
    });
    UIView *trackView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [[UIColor whiteColor] flatten];
        view;
    });
    UIView *dotView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    
    UILabel *increaseLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.text = @"+";
        label.font = [UIFont boldSystemFontOfSize:21];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    UILabel *decreaseLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.text = @"-";
        label.font = [UIFont boldSystemFontOfSize:21];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [self addSubview:bgView];
    [self addSubview:fillView];
    [self addSubview:trackView];
    [self addSubview:dotView];
    [self addSubview:increaseLabel];
    [self addSubview:decreaseLabel];
    _bgView = bgView;
    _fillView = fillView;
    _trackView = trackView;
    _dotView = dotView;
    
    _increaseLabel = increaseLabel;
    _decreaseLabel = decreaseLabel;
}


- (void)setValue:(CGFloat)value {
    _value = value;
    [self setNeedsLayout];
}

- (void)setMaximumValue:(CGFloat)maximumValue {
    _maximumValue = maximumValue;
    [self setNeedsLayout];
}

- (void)setMinimumValue:(CGFloat)minimumValue {
    _minimumValue = minimumValue;
    [self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame {
    frame = ({
        CGRect fixedFrame = frame;
        fixedFrame.size.width = 20.0;
        fixedFrame;
    });
    [super setFrame:frame];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat fraction;
    if (_maximumValue == 0) {
        fraction = 0.;
    } else {
        fraction =  (_value - _minimumValue)/(_maximumValue - _minimumValue);
    }
    
    
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    CGFloat trackWidth = 2.0;
    CGSize labelSize = CGSizeMake(width, width);
    CGFloat dotWidth = 12.0;
    _bgView.frame = self.bounds;
    _increaseLabel.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
    
    _fillView.frame = CGRectMake((width - trackWidth)/2 , CGRectGetMaxY(_increaseLabel.frame) + 8 , trackWidth, height - 2 * (labelSize.height + 5));
    _trackView.frame = ({
        CGRect frame;
        CGFloat trackHeight = CGRectGetHeight(_fillView.frame) * fraction;
        frame = CGRectMake((width - trackWidth)/2, CGRectGetMaxY(_fillView.frame) - trackHeight, trackWidth, trackHeight);
        frame;
    });
    
    _dotView.frame = CGRectMake(0, 0, dotWidth, dotWidth);
    _dotView.center = CGPointMake(_trackView.center.x, CGRectGetMinY(_trackView.frame));
    
    _decreaseLabel.frame = CGRectMake(0, height - labelSize.height, labelSize.width, labelSize.height);
    
    _bgView.layer.cornerRadius = width /2;
    _dotView.layer.cornerRadius = dotWidth /2;
    
    _trackMaximumHeight = CGRectGetHeight(_fillView.frame);
}

#pragma mark - Accessors



@end
