//
//  SDKBarChartView.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKBarChartView.h"
#import "SDKTheme.h"

@implementation SDKBarChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        _barColor = [SDKTheme accent];
    }
    return self;
}

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = [values copy];
    [self setNeedsDisplay];
}

- (void)setLabels:(NSArray<NSString *> *)labels {
    _labels = [labels copy];
    [self setNeedsDisplay];
}

- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    NSInteger count = (NSInteger)self.values.count;
    if (count == 0) return;

    CGFloat labelHeight = 18.0;
    CGFloat chartHeight = CGRectGetHeight(self.bounds) - labelHeight;

    NSInteger maxValue = 0;
    for (NSNumber *n in self.values) maxValue = MAX(maxValue, n.integerValue);
    if (maxValue == 0) maxValue = 1;

    // baseline
    CGContextSetStrokeColorWithColor(ctx, [[UIColor colorWithWhite:1.0 alpha:0.10] CGColor]);
    CGContextSetLineWidth(ctx, 0.8);
    CGContextMoveToPoint(ctx, 0, chartHeight - 0.5);
    CGContextAddLineToPoint(ctx, CGRectGetWidth(self.bounds), chartHeight - 0.5);
    CGContextStrokePath(ctx);

    CGFloat slot = CGRectGetWidth(self.bounds) / (CGFloat)count;
    CGFloat barWidth = MIN(28.0, slot * 0.52);
    UIColor *color = self.barColor ?: [SDKTheme accent];

    for (NSInteger i = 0; i < count; i++) {
        CGFloat value = self.values[(NSUInteger)i].doubleValue;
        CGFloat ratio = value / (CGFloat)maxValue;
        CGFloat height = MAX(3.0, (chartHeight - 12.0) * ratio);
        CGFloat x = slot * i + (slot - barWidth) / 2.0;
        CGFloat y = chartHeight - height;
        CGRect barRect = CGRectMake(x, y, barWidth, height);

        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:barRect
                                                       cornerRadius:MIN(barWidth / 2.0, 6.0)];
        CGContextSaveGState(ctx);
        [path addClip];
        CGFloat alpha = value > 0 ? 0.95 : 0.22;
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        const CGFloat *components = CGColorGetComponents([color colorWithAlphaComponent:alpha].CGColor);
        CGFloat comps[8] = { components[0], components[1], components[2], alpha,
                             components[0], components[1], components[2], alpha * 0.25 };
        CGFloat locs[2] = { 0.0, 1.0 };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(space, comps, locs, 2);
        CGContextDrawLinearGradient(ctx, gradient,
                                    CGPointMake(CGRectGetMidX(barRect), CGRectGetMinY(barRect)),
                                    CGPointMake(CGRectGetMidX(barRect), CGRectGetMaxY(barRect)),
                                    0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(space);
        CGContextRestoreGState(ctx);
    }

    // labels
    if ((NSInteger)self.labels.count == count) {
        NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSTextAlignmentCenter;
        NSDictionary *attrs = @{ NSFontAttributeName: [SDKTheme roundedFont:10 weight:UIFontWeightMedium],
                                 NSForegroundColorAttributeName: [SDKTheme textTertiary],
                                 NSParagraphStyleAttributeName: para };
        for (NSInteger i = 0; i < count; i++) {
            CGRect labelRect = CGRectMake(slot * i, chartHeight + 3.0, slot, labelHeight - 3.0);
            [self.labels[(NSUInteger)i] drawInRect:labelRect withAttributes:attrs];
        }
    }
}

@end
