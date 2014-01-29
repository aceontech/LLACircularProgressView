//
//  LLACircularProgressView.m
//  LLACircularProgressView
//
//  Created by Lukas Lipka on 26/10/13.
//  Copyright (c) 2013 Lukas Lipka. All rights reserved.
//

#import "LLACircularProgressView.h"

#import <UIView+POViewFrameBuilder.h>
#import <UIView+AOTToolkitAdditions.h>
#import <QuartzCore/QuartzCore.h>

@interface LLACircularProgressView ()

@property (nonatomic,strong) CAShapeLayer *progressLayer;
@property (nonatomic,strong) UIImageView *iconView;
@property (nonatomic,strong) NSMutableDictionary *iconDictionary;

@end

@implementation LLACircularProgressView

@synthesize progressTintColor = _progressTintColor;

- (id)init
{
    self = [super init];
    if (self) {
        self.currentState = 0; // Default state
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

#pragma mark - Subviews

- (UIImageView *)iconView
{
    if (!_iconView) {
        _iconView = [[UIImageView alloc] init];
    }
    return _iconView;
}

#pragma mark - Lifecycle

- (void)initialize {
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor whiteColor];
    
    _progressTintColor = [UIColor blackColor];
    
    _progressLayer = [[CAShapeLayer alloc] init];
    _progressLayer.strokeColor = self.progressTintColor.CGColor;
    _progressLayer.strokeEnd = 0;
    _progressLayer.fillColor = nil;
    _progressLayer.lineWidth = 3;
    [self.layer addSublayer:_progressLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.progressLayer.frame = self.bounds;
    
    [self updatePath];
    
    if (self.icon)
    {
        [self addSubviewOnce:self.iconView];
        [self.iconView.po_frameBuilder update:^(POViewFrameBuilder *builder) {
            [builder setWidth:CGRectGetWidth(self.bounds) / 2];
            [builder setHeight:CGRectGetHeight(self.bounds) / 2];
            [builder centerInSuperview];
        }];
        
        [self setNeedsDisplay];
    }
    
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ctx, self.progressTintColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, self.progressTintColor.CGColor);
    CGContextStrokeEllipseInRect(ctx, CGRectInset(self.bounds, 1, 1));
    
    CGRect stopRect;
    if (![self.iconView isDescendantOfView:self])
    {
        stopRect.origin.x = CGRectGetMidX(self.bounds) - self.bounds.size.width / 8;
        stopRect.origin.y = CGRectGetMidY(self.bounds) - self.bounds.size.height / 8;
        stopRect.size.width = self.bounds.size.width / 4;
        stopRect.size.height = self.bounds.size.height / 4;
        CGContextFillRect(ctx, CGRectIntegral(stopRect));
    } else {
        if (CGRectEqualToRect(stopRect, CGRectZero)) {
            CGContextClearRect(ctx, CGRectIntegral(stopRect));
        }
    }
}

#pragma mark - Accessors

- (void)setCurrentState:(NSInteger)currentState
{
    if (_currentState == currentState) return;
    _currentState = currentState;
    
    UIImage *iconForState = [self.iconDictionary objectForKey:@(currentState)];
    if (iconForState) {
        self.icon = iconForState;
    }
}

- (void)setIcon:(UIImage *)image forState:(NSInteger)state
{
    self.iconDictionary[@(state)] = image;
    
    if (self.currentState == state) {
        self.icon = image;
    }
}

- (NSMutableDictionary *)iconDictionary
{
    if (!_iconDictionary) {
        _iconDictionary = [[NSMutableDictionary alloc] init];
    }
    return _iconDictionary;
}

- (void)setIcon:(UIImage *)icon
{
    self.iconView.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)icon
{
    return self.iconView.image;
}

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    if (progress > 0) {
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.fromValue = self.progress == 0 ? @0 : nil;
            animation.toValue = [NSNumber numberWithFloat:progress];
            animation.duration = 1;
            self.progressLayer.strokeEnd = progress;
            [self.progressLayer addAnimation:animation forKey:@"animation"];
        } else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.progressLayer.strokeEnd = progress;
            [CATransaction commit];
        }
        
        [self setNeedsLayout];
    } else {
        self.progressLayer.strokeEnd = 0.0f;
        [self.progressLayer removeAnimationForKey:@"animation"];
    }
    
    _progress = progress;
}

- (UIColor *)progressTintColor {
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(tintColor)]) {
        return self.tintColor;
    }
#endif
    return _progressTintColor;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        self.tintColor = progressTintColor;
        return;
    }
#endif
    _progressTintColor = progressTintColor;
    self.progressLayer.strokeColor = progressTintColor.CGColor;
    [self setNeedsDisplay];
}

#pragma mark - Other

#ifdef __IPHONE_7_0
- (void)tintColorDidChange {
    [super tintColorDidChange];
    
    self.progressLayer.strokeColor = self.tintColor.CGColor;
    [self setNeedsDisplay];
}
#endif

#pragma mark - Private

- (void)updatePath {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.progressLayer.path = [UIBezierPath bezierPathWithArcCenter:center radius:self.bounds.size.width / 2 - 2 startAngle:-M_PI_2 endAngle:-M_PI_2 + 2 * M_PI clockwise:YES].CGPath;
}

@end
