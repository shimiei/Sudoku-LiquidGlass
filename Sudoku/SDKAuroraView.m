//
//  SDKAuroraView.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKAuroraView.h"
#import "SDKTheme.h"

@interface SDKAuroraView ()
- (void)applyAnimations;
@end

@implementation SDKAuroraView {
    CAGradientLayer *_base;
    NSMutableArray<CAGradientLayer *> *_blobs;
    CAGradientLayer *_vignette;
    BOOL _animating;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [SDKTheme bgBottom];
        self.userInteractionEnabled = NO;

        _base = [CAGradientLayer layer];
        _base.colors = @[ (id)[SDKTheme bgTop].CGColor, (id)[SDKTheme bgBottom].CGColor ];
        _base.startPoint = CGPointMake(0.15, 0.0);
        _base.endPoint = CGPointMake(0.85, 1.0);
        [self.layer addSublayer:_base];

        _blobs = [NSMutableArray array];
        NSArray<UIColor *> *colors = [SDKTheme auroraColors];
        for (NSInteger i = 0; i < (NSInteger)colors.count; i++) {
            CAGradientLayer *blob = [CAGradientLayer layer];
            blob.type = kCAGradientLayerRadial;
            blob.startPoint = CGPointMake(0.5, 0.5);
            blob.endPoint = CGPointMake(1.0, 1.0);
            blob.colors = @[ (id)[colors[(NSUInteger)i] colorWithAlphaComponent:0.55].CGColor,
                             (id)[colors[(NSUInteger)i] colorWithAlphaComponent:0.16].CGColor,
                             (id)[colors[(NSUInteger)i] colorWithAlphaComponent:0.0].CGColor ];
            blob.locations = @[ @0.0, @0.55, @1.0 ];
            [self.layer addSublayer:blob];
            [_blobs addObject:blob];
        }

        _vignette = [CAGradientLayer layer];
        _vignette.type = kCAGradientLayerRadial;
        _vignette.startPoint = CGPointMake(0.5, 0.42);
        _vignette.endPoint = CGPointMake(1.15, 1.15);
        _vignette.colors = @[ (id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
                              (id)[UIColor colorWithWhite:0.0 alpha:0.30].CGColor,
                              (id)[UIColor colorWithWhite:0.0 alpha:0.62].CGColor ];
        _vignette.locations = @[ @0.0, @0.62, @1.0 ];
        [self.layer addSublayer:_vignette];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _base.frame = self.bounds;
    _vignette.frame = self.bounds;

    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    CGFloat side = MAX(w, h) * 0.92;
    CGSize sizes[4] = {
        CGSizeMake(side * 1.05, side * 1.05),
        CGSizeMake(side * 0.85, side * 0.85),
        CGSizeMake(side * 0.95, side * 0.95),
        CGSizeMake(side * 0.70, side * 0.70)
    };
    CGPoint centers[4] = {
        CGPointMake(w * 0.22, h * 0.14),
        CGPointMake(w * 0.86, h * 0.30),
        CGPointMake(w * 0.30, h * 0.82),
        CGPointMake(w * 0.80, h * 0.92)
    };
    for (NSInteger i = 0; i < (NSInteger)_blobs.count && i < 4; i++) {
        CAGradientLayer *blob = _blobs[(NSUInteger)i];
        blob.bounds = CGRectMake(0, 0, sizes[i].width, sizes[i].height);
        blob.position = centers[i];
    }
    [CATransaction commit];

    if (_animating) [self applyAnimations];
}

- (void)startAnimating {
    _animating = YES;
    [self applyAnimations];
}

- (void)stopAnimating {
    _animating = NO;
    for (CAGradientLayer *blob in _blobs) [blob removeAllAnimations];
}

- (void)applyAnimations {
    CGFloat w = CGRectGetWidth(self.bounds), h = CGRectGetHeight(self.bounds);
    if (w < 1 || h < 1) return;

    NSArray<NSValue *> *paths = @[
        [NSValue valueWithCGPoint:CGPointMake(w * 0.22, h * 0.14)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.34, h * 0.26)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.16, h * 0.32)]
    ];
    NSArray<NSValue *> *paths2 = @[
        [NSValue valueWithCGPoint:CGPointMake(w * 0.86, h * 0.30)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.72, h * 0.18)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.90, h * 0.46)]
    ];
    NSArray<NSValue *> *paths3 = @[
        [NSValue valueWithCGPoint:CGPointMake(w * 0.30, h * 0.82)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.44, h * 0.70)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.20, h * 0.66)]
    ];
    NSArray<NSValue *> *paths4 = @[
        [NSValue valueWithCGPoint:CGPointMake(w * 0.80, h * 0.92)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.66, h * 0.98)],
        [NSValue valueWithCGPoint:CGPointMake(w * 0.88, h * 0.78)]
    ];
    NSArray<NSArray<NSValue *> *> *all = @[ paths, paths2, paths3, paths4 ];
    NSTimeInterval durations[4] = { 26.0, 31.0, 34.0, 29.0 };

    for (NSInteger i = 0; i < (NSInteger)_blobs.count && i < 4; i++) {
        CAGradientLayer *blob = _blobs[(NSUInteger)i];
        NSArray<NSValue *> *points = all[(NSUInteger)i];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        NSMutableArray *values = [NSMutableArray array];
        for (NSValue *v in points) [values addObject:[NSValue valueWithCGPoint:v.CGPointValue]];
        anim.values = values;
        anim.duration = durations[i];
        anim.repeatCount = HUGE_VALF;
        anim.autoreverses = YES;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [blob addAnimation:anim forKey:@"drift"];
    }
}

@end
