//
//  QRCodeScanController.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/2/25.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "WLQRCodeScanController.h"
#import "Masonry.h"
#import "POP.h"
#import "UIImage+WLColorExtension.h"
#import "WLCameraPreviewView.h"
#import "WLCropLensRectView.h"
#import "WLScanZoomSlider.h"

@import MobileCoreServices;
@import AVFoundation;

static void * SessionRunningContext = &SessionRunningContext;

static void * ZoomSliderFractionContext = &ZoomSliderFractionContext;

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface WLQRCodeScanController ()
<AVCaptureMetadataOutputObjectsDelegate,
 UIImagePickerControllerDelegate,
 UINavigationControllerDelegate>


//加载框
@property (strong, nonatomic) UIView *loadingView;

@property (strong, nonatomic) UIImageView *netImageView;

@property (strong, nonatomic) WLScanZoomSlider *zoomSlider;

@property (strong, nonatomic) UIButton *flashSwitchButton;

@property (strong, nonatomic) UIButton *photoPickerButton;

@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;

@property (strong, nonatomic) AVCaptureMetadataOutput *metadataOutput;

@property (strong, nonatomic) AVCaptureSession *session;

@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;


@property (strong, nonatomic) WLCameraPreviewView *previewView;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@property (assign, nonatomic) AVCamSetupResult setupResult;

@property (assign, nonatomic) NSInteger detectedCount;

@property (strong, nonatomic) NSTimer *sliderDissmissTimer;


@end

@implementation WLQRCodeScanController {
    UIView *_sweepView;
    dispatch_semaphore_t _metadataSemaphore;
    NSArray<WLCropLensRectView *> *_lensViews;
    UIPanGestureRecognizer *_panGesture;
    CGPoint _panTrackingPoint;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidLoad {
    [super viewDidLoad];
    BOOL isPodEnv = WL_IS_POD_ENV;
    NSBundle *bundle = QRResourceBundle;
    NSLog(@"QRCode Resource Bundle path:%@",bundle.bundlePath);
    
    NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
    NSURL *URL = [classBundle URLForResource:@"Resource" withExtension:@"bundle"];
    
    ;
    
    self.extendedLayoutIncludesOpaqueBars = NO;
    [self setupUI];
    self.session = [[AVCaptureSession alloc] init];
    self.previewView.session = self.session;
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);

    self.setupResult = AVCamSetupResultSuccess;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        {
            break;
        }
        default:
        {
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    dispatch_async(self.sessionQueue, ^(void) {
        [self configureSession];
    });
    
    [self addGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _metadataSemaphore = dispatch_semaphore_create(1);
    self.detectedCount = 0;
    [self changeFlashOn:NO];
    self.loadingView.hidden = NO;
    self.zoomSlider.alpha = 0.;
    [self initializeLens];
    [self initializeZoomSlider];
    
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult) {
            case AVCamSetupResultSuccess:
            {
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    self.loadingView.hidden = YES;
                });
                break;
            }
            case AVCamSetupResultCameraNotAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self showGuideAlert];
                });
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed: {
                NSLog(@"设备故障");
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self showSetupErrorAlert];
                });
                break;
            }
        }
    });
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startGriddingSweepAnimation];
}


- (void)viewDidDisappear:(BOOL)animated {
    [self changeFlashOn:NO];
    [self stopGriddingSweepAnimation];
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == AVCamSetupResultSuccess) {
            [self.session stopRunning];
            self.sessionRunning = self.session.isRunning;
            [self removeObservers];
        }
    });
    [super viewDidDisappear:animated];
}


- (void)startGriddingSweepAnimation {
    self.netImageView.alpha = 1.0;
    self.netImageView.frame = ({
        CGRect rect = self.netImageView.superview.bounds;
        rect.origin.y = -rect.size.height;
        rect;
    });
    [UIView animateWithDuration:0.8 delay:0.8 options:UIViewAnimationOptionCurveEaseIn  animations:^{
        self.netImageView.frame = self.netImageView.superview.bounds;
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.2 animations:^{
                self.netImageView.alpha = 0.0;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self startGriddingSweepAnimation];
                }
            }];
        }
    }];
}

- (void)stopGriddingSweepAnimation {
    self.netImageView.alpha = 0.0;
    [self.netImageView.layer removeAllAnimations];
}

#pragma mark - Session Management

- (void)configureSession {
    if (self.setupResult != AVCamSetupResultSuccess) {
        return;
    }
    NSError *error = nil;
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
    AVCaptureDevice *videoDevice;
    //如果ios 10 及以上 尝试调用多摄像头
    BOOL systemVersionGraterThanOrEqual10 = [[UIDevice currentDevice].systemVersion compare:@"10" options:NSNumericSearch] != NSOrderedAscending;
    if (systemVersionGraterThanOrEqual10) {
        //优先双摄像头
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDuoCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        //其次是广角镜头
        if (!videoDevice) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        }
    } else {
        videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!videoDeviceInput) {
        NSLog( @"Could not create video device input: %@", error );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    if ([self.session canAddInput:videoDeviceInput]) {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
    } else {
        NSLog( @"Could not add video device input to the session" );
        [self.session commitConfiguration];
        return;
    }
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.session canAddOutput:metadataOutput]) {
        [self.session addOutput:metadataOutput];
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        self.metadataOutput = metadataOutput;
    } else {
        NSLog( @"Could not add metadata  output to the session" );
        [self.session commitConfiguration];
        return;
    }
    [self.session commitConfiguration];
}



- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.previewView.frame = self.view.bounds;
    NSMutableArray *lensViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < 3; i++) {
        WLCropLensRectView *lensView = [[WLCropLensRectView alloc] init];
        [self.view addSubview:lensView];
        [lensViews addObject:lensView];
        if (i == 0) {
            lensView.layer.masksToBounds = YES;
            [lensView addSubview:self.netImageView];
        }
    }
    _lensViews = [lensViews copy];
    
    [self.view addSubview:self.loadingView];
    [self.view addSubview:self.previewView];
    [self.view addSubview:self.zoomSlider];
    [self.view bringSubviewToFront:self.loadingView];
    [self.view sendSubviewToBack:self.previewView];

    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];

    
    UIBarButtonItem *photoBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:QRImageNamed(@"scanning_pick_photo") forState:UIControlStateNormal];
        [button setImage:QRImageNamed(@"scanning_pick_photo_highlighted") forState:UIControlStateHighlighted];
        button.frame = CGRectMake(0, 0, 35, 35);
        [button addTarget:self action:@selector(photoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _photoPickerButton = button;
        button;
    })];
    UIBarButtonItem *flashBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:QRImageNamed(@"scanning_flash") forState:UIControlStateNormal];
        [button setImage:QRImageNamed(@"scanning_flash_selected") forState:UIControlStateSelected];
        button.frame = CGRectMake(0, 0, 35, 35);
        [button addTarget:self action:@selector(flashButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _flashSwitchButton = button;
        button;
    })];
    
    if (self.navigationController.viewControllers.count > 1 || self.presentationController) {
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setImage:QRImageNamed(@"scanning_back") forState:UIControlStateNormal];
            [button setImage:QRImageNamed(@"scanning_back_highlighted") forState:UIControlStateHighlighted];
            button.frame = ({
                CGRect frame;
                frame.origin = CGPointZero;
                frame.size = button.intrinsicContentSize;
                frame;
            });
            [button addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            button;
        })];
        self.navigationItem.leftBarButtonItem = backBarButtonItem;
    }
    
    
    self.navigationItem.rightBarButtonItems = @[flashBarButtonItem,
                                                photoBarButtonItem];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage wlqr_imageWithColor:[UIColor clearColor]] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage wlqr_imageWithColor:[UIColor clearColor]]];
    
    
}

- (void)initializeLens {
    CGSize size = [self lensSize];
    [_lensViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        view.frame = ({
            CGRect frame = CGRectInset(self.view.bounds,(CGRectGetWidth(self.view.bounds) - size.width)/2 , (CGRectGetHeight(self.view.bounds) - size.height)/2);
            frame.origin.y -= 24.0;
            frame;
        });
        view.alpha = (idx > 0? 0.0 : 1.);
    }];
}

- (void)initializeZoomSlider {
    WLCropLensRectView *lensView = _lensViews.firstObject;
    self.zoomSlider.frame = ({
        CGRect frame;
        frame.size = CGSizeMake(20, CGRectGetHeight(lensView.frame));
        frame.origin.x = CGRectGetMaxX(lensView.frame) + 10;
        frame.origin.y = CGRectGetMinY(lensView.frame);
        frame;
    });
}

#pragma mark - Bar button Action Handler
- (void)backButtonTapped:(UIButton *)button {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    if (self.presentationController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)photoButtonTapped:(UIButton *)button {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.mediaTypes = @[(NSString *)kUTTypeImage];

    pickerController.allowsEditing = YES;
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)flashButtonTapped:(UIButton *)button {
    [self changeFlashOn:!button.selected];
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        self.detectedCount++;
        if (dispatch_semaphore_wait(_metadataSemaphore, DISPATCH_TIME_NOW) == 0) {
            AVMetadataObject *metadata = [metadataObjects lastObject];
            AVMetadataMachineReadableCodeObject *transformedMetadata = (AVMetadataMachineReadableCodeObject *)[(AVCaptureVideoPreviewLayer *)self.previewView.layer transformedMetadataObjectForMetadataObject:metadata];
            CGRect objectFrame = transformedMetadata.bounds;
            NSString *result = [transformedMetadata stringValue];
            
            dispatch_async(self.sessionQueue, ^(void) {
                if (self.session.isRunning) {
                    [self.session stopRunning];
                    self.sessionRunning = self.session.isRunning;
                    dispatch_semaphore_signal(self->_metadataSemaphore);
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self animationLensWithFrame:objectFrame completion:^{
                            if (self.enablePlaySounds) {
                                [self playScanningSound];
                            }
                            [self processResult:result];
                        }];
                    });
                }
            });
        }
    }
}

- (void)animationLensWithFrame:(CGRect)frame completion:(void (^) ())completion {
    
    [_lensViews enumerateObjectsUsingBlock:^(WLCropLensRectView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        view.alpha = 1.0;
        
        POPSpringAnimation *frameAnima = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
        frameAnima.clampMode = kPOPAnimationClampEnd;
        frameAnima.beginTime = CACurrentMediaTime() + 0.05 *idx;
        frameAnima.toValue = [NSValue valueWithCGRect:frame];
        frameAnima.springBounciness = 0.0;
        [view pop_addAnimation:frameAnima forKey:@"frame"];
        
        POPSpringAnimation *fadeAnima = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlpha];
        fadeAnima.clampMode = kPOPAnimationClampEnd;
        fadeAnima.springBounciness = 0.0;
        fadeAnima.beginTime = CACurrentMediaTime() + 0.05 *idx;
        fadeAnima.fromValue = @(1.0);
        fadeAnima.toValue = @(0.0);
        if (idx > 0) {
            [view pop_addAnimation:fadeAnima forKey:@"fade"];
        }
        if (idx == 0) {
            [frameAnima setCompletionBlock:^(POPAnimation *anima, BOOL finished) {
                if (finished && completion) {
                    completion();
                }
            }];
        }
    }];
    
    [self stopGriddingSweepAnimation];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSLog(@"%@",info);
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    [picker  dismissViewControllerAnimated:YES completion:nil];
    [self detectQRCodeWithImage:image];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)detectQRCodeWithImage:(UIImage *)image {
    self.loadingView.hidden = NO;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        CIImage *ciImage = [CIImage imageWithData:UIImagePNGRepresentation(image)];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy :CIDetectorAccuracyHigh}];
        NSArray<CIFeature *> *features = [detector featuresInImage:ciImage];
        CIQRCodeFeature *feature = (id)features.firstObject;

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.loadingView.hidden = YES;
            if (feature) {
                if (self.enablePlaySounds) {
                    [self playScanningSound];
                }
                NSString *result = feature.messageString;
                [self processResult:result];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"照片中未识别到二维码" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
                [alert show];
            }
        });
    });
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper

- (void)showGuideAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未获得授权使用摄像头" message:@"请在iOS\"设置\"-\"隐私\"-\"相机\"中打开" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
    [alert show];
}

- (void)showSetupErrorAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法打开摄像头" message:@"请检查摄像头是否可用" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
    [alert show];
}

- (BOOL)isCanAccessCamera {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized;
}

- (UIColor *)cropThemeColor {
    return [UIColor colorWithRed:56/255.0 green:195/255.0 blue:236/255.0 alpha:1];
}

- (void)changeFlashOn:(BOOL)isOn {
    [self.videoDeviceInput.device lockForConfiguration:nil];
    if ([self.videoDeviceInput.device hasFlash]) {
        if (isOn) {
            self.videoDeviceInput.device.torchMode = AVCaptureTorchModeOn;
            self.videoDeviceInput.device.flashMode = AVCaptureFlashModeOn;
            _flashSwitchButton.selected = YES;
        } else {
            self.videoDeviceInput.device.torchMode = AVCaptureTorchModeOff;
            self.videoDeviceInput.device.flashMode = AVCaptureFlashModeOff;
            _flashSwitchButton.selected = NO;
        }
    }
    [self.videoDeviceInput.device unlockForConfiguration];
}

- (void)processResult:(NSString *)result {
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        NSLog(@"detect result:%@",result);
        if (self.navigationController.viewControllers.count > 1) {
            [self.navigationController popViewControllerAnimated:YES];
            if (self.detectQRCodeHandler) {
                self.detectQRCodeHandler(result);
            }
            return;
        }
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.detectQRCodeHandler) {
                self.detectQRCodeHandler(result);
            }
        }];
    });
}

#pragma mark - Accessors
- (UIView *)loadingView {
	if(_loadingView == nil) {
		_loadingView = [[UIView alloc] init];
        _loadingView.backgroundColor = [UIColor blackColor];
        UILabel *tipsLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.text = @"正在加载...";
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:14];
            tipsLabel = label;
            label;
        });
        UIActivityIndicatorView *indicator = ({
            UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] init];
            [view startAnimating];
            view.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            indicator = view;
            view;
        });
        UIView *assistView = ({
            UIView *view = [[UIView alloc] init];
            view;
        });
        [_loadingView addSubview:tipsLabel];
        [_loadingView addSubview:indicator];
        [_loadingView addSubview:assistView];
        [indicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
        }];
        [tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
            make.top.equalTo(indicator.mas_bottom).offset(15);
        }];
        [assistView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
            make.top.equalTo(indicator);
            make.bottom.equalTo(tipsLabel);
        }];
	}
	return _loadingView;
}



- (WLCameraPreviewView *)previewView {
	if(_previewView == nil) {
		_previewView = [[WLCameraPreviewView alloc] init];
	}
	return _previewView;
}

- (UIImageView *)netImageView {
    if(_netImageView == nil) {
        _netImageView = [[UIImageView alloc] initWithImage:QRImageNamed(@"qrcode_scan_full_net")];
    }
    return _netImageView;
}

- (WLScanZoomSlider *)zoomSlider {
    if(_zoomSlider == nil) {
        _zoomSlider = [[WLScanZoomSlider alloc] init];
    }
    return _zoomSlider;
}

- (CGRect )lensFrame {
    return _lensViews.firstObject.frame;
}

- (CGSize)lensSize {
    return CGSizeMake(240, 240);
}

#pragma mark - Gesture Handler
- (void)addGesture {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [self.view addGestureRecognizer:panGesture];
    _panGesture = panGesture;
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self.sliderDissmissTimer invalidate];
            self.sliderDissmissTimer = nil;
            _panTrackingPoint = [gesture locationInView:gesture.view];
            self.zoomSlider.alpha = 1.0;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint newPoint = [gesture locationInView:gesture.view];
            CGFloat yOffset = newPoint.y - _panTrackingPoint.y;
            CGFloat value = _zoomSlider.value - (yOffset/_zoomSlider.trackMaximumHeight) * _zoomSlider.maximumValue;
            _zoomSlider.value = MIN(_zoomSlider.maximumValue, MAX(_zoomSlider.minimumValue, value));
            _panTrackingPoint = newPoint;
            dispatch_async(self.sessionQueue, ^(void) {
                @try {
                    [self.videoDeviceInput.device lockForConfiguration:nil];
                    self.videoDeviceInput.device.videoZoomFactor = self.zoomSlider.value;
                    [self.videoDeviceInput.device unlockForConfiguration];
                } @catch (NSException *exception) {
                    NSLog(@"Could not look for configuration:%@",exception);
                }
            });
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self.sliderDissmissTimer invalidate];
            self.sliderDissmissTimer = nil;
            self.sliderDissmissTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(dissmissTimer:) userInfo:nil repeats:NO];
            break;
        }
            
        default:
            break;
    }
}

- (void)dissmissTimer:(NSTimer *)timer {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [UIView animateWithDuration:0.33 animations:^{
            self.zoomSlider.alpha = 0.0;
        }];
    });
}

#pragma mark KVO and Notifications

- (void)addObservers {
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAppBecomeAciveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAppDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];

}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == SessionRunningContext) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        if (isSessionRunning) {
            dispatch_async(self.sessionQueue, ^{
                CGRect rectOfInterest = [self.previewView.videoPreviewLayer metadataOutputRectOfInterestForRect:[self lensFrame]];
                [self.metadataOutput setRectOfInterest:rectOfInterest];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingView.hidden = isSessionRunning || self.detectedCount > 0;
            self.photoPickerButton.enabled = isSessionRunning;
            self.flashSwitchButton.enabled = isSessionRunning;
            self->_panGesture.enabled = isSessionRunning;
            self.zoomSlider.hidden = !isSessionRunning;
            self.zoomSlider.minimumValue = 1.;
            self.zoomSlider.maximumValue = MIN(3., self.videoDeviceInput.device.activeFormat.videoMaxZoomFactor);
            self.zoomSlider.value = self.videoDeviceInput.device.videoZoomFactor;
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)sessionRuntimeError:(NSNotification *)notification {
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    /*
     Automatically try to restart the session running if media services were
     reset and the last start running succeeded. Otherwise, enable the user
     to try to resume the session running.
     */
    if (error.code == AVErrorMediaServicesWereReset) {
        NSLog(@"reset");
        dispatch_async(self.sessionQueue, ^{
            if (self.isSessionRunning) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
        });
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification {
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
}

- (void)sessionInterruptionEnded:(NSNotification *)notification {
    NSLog( @"Capture session interruption ended" );
}


- (void)didReceiveAppBecomeAciveNotification:(NSNotification *)notification {
    [self startGriddingSweepAnimation];
}

- (void)didReceiveAppDidEnterBackgroundNotification:(NSNotification *)notification {
    [self stopGriddingSweepAnimation];
}

// MARK: Helper
- (void)playScanningSound {
    static AVAudioPlayer *player;
    
    NSString *path = [QRResourceBundle pathForResource:@"scan" ofType:@"m4a"];
    if (path) {
        //下面这句代码让播放声音的时候不打断其它音频播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
        player = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:path] error:nil];
        player.numberOfLoops = 1;
        player.volume = 1.;
        [player play];
    }
}

@end
