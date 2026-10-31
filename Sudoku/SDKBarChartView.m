//
//  SDKBarChartView.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKBarChartView.h"
#import "SDKTheme.h"

@implementation SDKBarChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"最近七天完成数";
    }
    return self;
}

@synthesize barColor = _barColor;

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = [values copy];
    [self setNeedsDisplay];
}

- (void)setLabels:(NSArray<NSString *> *)labels {
    _labels = [labels copy];
    [self setNeedsDisplay];
}

- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor ?: [UIColor systemBlueColor];
    [self setNeedsDisplay];
}

- (UIColor *)barColor {
    return _barColor ?: [UIColor systemBlueColor];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    NSInteger count = (NSInteger)self.values.count;
    if (count == 0) return;

    UIFont *numberFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    UIFont *labelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    NSMutableParagraphStyle *center = [NSMutableParagraphStyle new];
    center.alignment = NSTextAlignmentCenter;

    NSInteger maxValue = 1;
    for (NSNumber *n in self.values) maxValue = MAX(maxValue, n.integerValue);

    CGFloat boundsHeight = CGRectGetHeight(self.bounds);
    CGFloat labelZone = 16.0;
    CGFloat numberZone = 14.0;
    CGFloat chartTop = numberZone;
    CGFloat chartBottom = boundsHeight - labelZone;
    CGFloat chartHeight = MAX(1.0, chartBottom - chartTop);

    CGFloat slot = CGRectGetWidth(self.bounds) / (CGFloat)count;
    CGFloat barWidth = MIN(22.0, slot * 0.52);

    for (NSInteger i = 0; i < count; i++) {
        NSInteger value = self.values[(NSUInteger)i].integerValue;
        CGFloat ratio = (CGFloat)value / (CGFloat)maxValue;
        CGFloat barHeight = MAX(value > 0 ? 4.0 : 2.0, chartHeight * ratio);

        CGFloat cx = slot * (CGFloat)i + slot / 2.0;
        CGRect barRect = CGRectMake(cx - barWidth / 2.0, chartBottom - barHeight, barWidth, barHeight);

        UIColor *fill = value > 0 ? self.barColor : [UIColor tertiarySystemFillColor];
        CGContextSetFillColorWithColor(ctx, [SDKTheme cgColor:fill traits:self.traitCollection]);
        UIBezierPath *bar = [UIBezierPath bezierPathWithRoundedRect:barRect
                                                          cornerRadius:MIN(4.0, barWidth / 2.0)];
        CGContextAddPath(ctx, bar.CGPath);
        CGContextFillPath(ctx);

        if (value > 0) {
            NSString *number = [NSString stringWithFormat:@"%ld", (long)value];
            NSDictionary *attrs = @{ NSFontAttributeName : numberFont,
                                     NSForegroundColorAttributeName : [UIColor secondaryLabelColor],
                                     NSParagraphStyleAttributeName : center };
            CGSize size = [number sizeWithAttributes:attrs];
            [number drawInRect:CGRectMake(cx - size.width / 2.0,
                                          MAX(0.0, barRect.origin.y - size.height - 1.0),
                                          size.width, size.height)
                withAttributes:attrs];
        }

        if (i < (NSInteger)self.labels.count) {
            NSString *label = self.labels[(NSUInteger)i];
            NSDictionary *attrs = @{ NSFontAttributeName : labelFont,
                                     NSForegroundColorAttributeName : [UIColor tertiaryLabelColor],
                                     NSParagraphStyleAttributeName : center };
            CGSize size = [label sizeWithAttributes:attrs];
            [label drawInRect:CGRectMake(cx - slot / 2.0, boundsHeight - labelZone + 2.0, slot, size.height)
               withAttributes:attrs];
        }
    }
}

@end
