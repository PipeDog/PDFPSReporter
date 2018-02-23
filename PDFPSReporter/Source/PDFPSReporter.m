//
//  PDFPSReporter.m
//  PDFPSReporter
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "PDFPSReporter.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+PDAdd.h"

static NSInteger const kPDFPSReporterTag = 83948493;
static NSTimeInterval const kAnimationDuration = 0.3f;
static CGFloat const kPDFPSReporterMargin = 5.f;

@interface PDFPSReporter ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger aSecondFpsNumber; // 一秒内刷新的帧数
@property (nonatomic, assign) NSTimeInterval aSecondAgoTimeStamp; // 一秒前的时间戳
@property (nonatomic, strong) UIFont *fpsFont;
@property (nonatomic, strong) UIFont *subFont;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@end

@implementation PDFPSReporter

+ (PDFPSReporter *)defaultReporter {
    static PDFPSReporter *fpsReporter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fpsReporter = [[PDFPSReporter alloc] init];
        fpsReporter.size = CGSizeMake(55, 20);
        fpsReporter.left = kPDFPSReporterMargin;
        fpsReporter.top = 100;
        fpsReporter.layer.cornerRadius = 5;
        fpsReporter.clipsToBounds = YES;
        fpsReporter.textAlignment = NSTextAlignmentCenter;
        fpsReporter.userInteractionEnabled = YES;
        fpsReporter.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.700];
        fpsReporter.fpsFont = [UIFont fontWithName:@"Courier" size:14];
        fpsReporter.subFont = [UIFont fontWithName:@"Courier" size:4];
        fpsReporter.tag = kPDFPSReporterTag;
    });
    return fpsReporter;
}

- (instancetype)init {
#ifndef DEBUG
    return nil;
#else
    self = [super init];
    if (self) {
        _aSecondFpsNumber = 0;
        _aSecondAgoTimeStamp = 0;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkReload:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureAction:)];
        [self addGestureRecognizer:_pan];
    }
    return self;
#endif
}

- (void)show {
    [self removeFromSuperview];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        [keyWindow addSubview:self];
    });
}

- (void)showInView:(UIView *)aView {
    if (!aView) return;
    [self removeFromSuperview];
    [aView addSubview:self];
}

- (void)displayLinkReload:(CADisplayLink *)link {
    if (self.aSecondAgoTimeStamp == 0) {
        self.aSecondAgoTimeStamp = link.timestamp;
        return;
    }
    self.aSecondFpsNumber += 1;
    NSTimeInterval timeStampInterval = link.timestamp - self.aSecondAgoTimeStamp;
    if (timeStampInterval < 1) {
        // 没到一秒的时间间隔 return
        return;
    }
    // 每秒帧数 = 一秒内刷新帧数 / 刚刚大于一秒的时间间隔
    float fps = self.aSecondFpsNumber / timeStampInterval;
    /* ---------------------------------------------------------- */
    // 设置字体大小及颜色
    CGFloat progress = fps / 60.0;
    UIColor *color = [UIColor colorWithHue:0.27 * (progress - 0.2) saturation:1 brightness:0.9 alpha:1];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d FPS",(int)round(fps)]];
    [text addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length - 3)];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(text.length - 3, 3)];
    [text addAttribute:NSFontAttributeName value:self.fpsFont range:NSMakeRange(0, text.length)];
    [text addAttribute:NSFontAttributeName value:self.subFont range:NSMakeRange(text.length - 4, 1)];
    self.attributedText = text;
    /* ---------------------------------------------------------- */
    // 开始下一秒的帧率计算, 数据重置
    self.aSecondAgoTimeStamp = link.timestamp;
    self.aSecondFpsNumber = 0;
}

- (void)handlePanGestureAction:(UIPanGestureRecognizer *)pan {
    CGFloat topMargin = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame);
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    CGPoint point = [pan translationInView:keyWindow];
    
    self.center = CGPointMake(self.center.x + point.x, self.center.y + point.y);
    [pan setTranslation:CGPointZero inView:keyWindow];
    
    if (pan.state == UIGestureRecognizerStateEnded ||
        pan.state == UIGestureRecognizerStateChanged) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            if (self.top < topMargin) {
                self.top = topMargin;
            }
            if (self.left < kPDFPSReporterMargin) {
                self.left = kPDFPSReporterMargin;
            }
            if (self.bottom > self.superview.height - kPDFPSReporterMargin) {
                self.bottom = self.superview.height - kPDFPSReporterMargin;
            }
            if (self.right > self.superview.width - kPDFPSReporterMargin) {
                self.right = self.superview.width - kPDFPSReporterMargin;
            }
        }];
    }
}

@end

@interface UIWindow (PDAdd)

@end

@implementation UIWindow (PDAdd)

- (void)layoutSubviews {
    [super layoutSubviews];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (self != keyWindow) return;

    UIView *fpsView = [keyWindow viewWithTag:kPDFPSReporterTag];
    if (fpsView) [keyWindow bringSubviewToFront:fpsView];
}

@end