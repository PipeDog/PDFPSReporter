//
//  PDFPSReporter.h
//  PDFPSReporter
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDFPSReporter : UILabel

@property (class, strong, readonly) PDFPSReporter *defaultReporter;

- (void)showInView:(UIView *)aView;

@end
