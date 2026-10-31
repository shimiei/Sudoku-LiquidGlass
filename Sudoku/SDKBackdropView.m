//
//  SDKBackdropView.m
//  Sudoku
//

#import "SDKBackdropView.h"

@implementation SDKBackdropView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];
        self.opaque = YES;
        self.contentMode = UIViewContentModeRedraw;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGRect b = self.bounds;
    CGFloat w = CGRectGetWidth(b);
    CGFloat h = CGRectGetHeight(b);
    if (w < 1.0 || h < 1.0) return;

    [[UIColor systemGroupedBackgroundColor] setFill];
    UIRectFill(b);

    [self drawGlowInContext:ctx
                     center:CGPointMake(w * 0.12, h * 0.08)
                     radius:w * 0.92
                      color:[UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.13]];
    [self drawGlowInContext:ctx
                     center:CGPointMake(w * 0.96, h * 0.92)
                     radius:w * 0.82
                      color:[UIColor colorWithRed:0.35 green:0.34 blue:0.84 alpha:0.10]];
}

- (void)drawGlowInContext:(CGContextRef)ctx
                   center:(CGPoint)center
                   radius:(CGFloat)radius
                    color:(UIColor *)color {
    if (radius < 1.0) return;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    if (!space) return;

    UIColor *clear = [color colorWithAlphaComponent:0.0];
    NSArray *colors = @[ (id)color.CGColor, (id)clear.CGColor ];
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, NULL);
    CGColorSpaceRelease(space);
    if (!gradient) return;

    CGContextSaveGState(ctx);
    CGContextDrawRadialGradient(ctx, gradient, center, 0.0, center, radius,
                                kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(ctx);
    CGGradientRelease(gradient);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self setNeedsDisplay];
    }
}

@end
