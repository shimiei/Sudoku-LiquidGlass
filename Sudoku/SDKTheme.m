//
//  SDKTheme.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKTheme.h"

static inline UIColor *SDKRGBA(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];
}

@implementation SDKTheme

#pragma mark - Background

+ (UIColor *)bgTop    { return SDKRGBA(13, 17, 33, 1.0); }
+ (UIColor *)bgBottom { return SDKRGBA(4, 6, 14, 1.0); }

+ (NSArray<UIColor *> *)auroraColors {
    return @[
        SDKRGBA(88, 101, 242, 0.95),   // indigo
        SDKRGBA(0, 196, 255, 0.85),    // cyan
        SDKRGBA(167, 108, 255, 0.80),  // violet
        SDKRGBA(0, 240, 200, 0.65)     // teal
    ];
}

#pragma mark - Glass

+ (UIColor *)glassFill       { return [UIColor colorWithWhite:1.0 alpha:0.055]; }
+ (UIColor *)glassFillStrong { return [UIColor colorWithWhite:1.0 alpha:0.11]; }
+ (UIColor *)strokeBright    { return [UIColor colorWithWhite:1.0 alpha:0.50]; }
+ (UIColor *)strokeDim       { return [UIColor colorWithWhite:1.0 alpha:0.10]; }

#pragma mark - Text

+ (UIColor *)textPrimary   { return [UIColor colorWithWhite:1.0 alpha:0.96]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:1.0 alpha:0.60]; }
+ (UIColor *)textTertiary  { return [UIColor colorWithWhite:1.0 alpha:0.36]; }

#pragma mark - Accents

+ (UIColor *)accent     { return SDKRGBA(94, 214, 255, 1.0); }
+ (UIColor *)accentAlt  { return SDKRGBA(167, 139, 250, 1.0); }
+ (UIColor *)accentWarm { return SDKRGBA(255, 176, 102, 1.0); }
+ (UIColor *)danger     { return SDKRGBA(255, 99, 122, 1.0); }
+ (UIColor *)success    { return SDKRGBA(86, 226, 170, 1.0); }
+ (UIColor *)gold       { return SDKRGBA(255, 209, 102, 1.0); }

#pragma mark - Board

+ (UIColor *)givenText      { return [UIColor colorWithWhite:1.0 alpha:0.95]; }
+ (UIColor *)userText       { return SDKRGBA(104, 219, 255, 1.0); }
+ (UIColor *)noteText       { return [UIColor colorWithWhite:1.0 alpha:0.52]; }
+ (UIColor *)gridLine       { return [UIColor colorWithWhite:1.0 alpha:0.085]; }
+ (UIColor *)gridLineStrong { return [UIColor colorWithWhite:1.0 alpha:0.30]; }
+ (UIColor *)cellSelect     { return SDKRGBA(94, 214, 255, 0.20); }
+ (UIColor *)cellPeer       { return [UIColor colorWithWhite:1.0 alpha:0.055]; }
+ (UIColor *)cellSame       { return SDKRGBA(167, 139, 250, 0.17); }
+ (UIColor *)cellError      { return SDKRGBA(255, 71, 96, 0.22); }
+ (UIColor *)errorText      { return SDKRGBA(255, 122, 141, 1.0); }

#pragma mark - Fonts

+ (UIFont *)roundedFont:(CGFloat)size weight:(UIFontWeight)weight {
    UIFont *base = [UIFont systemFontOfSize:size weight:weight];
    if (@available(iOS 13.0, *)) {
        UIFontDescriptor *desc = [base.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
        if (desc) {
            UIFont *f = [UIFont fontWithDescriptor:desc size:size];
            if (f) return f;
        }
    }
    return base;
}

+ (UIFont *)monoDigitFont:(CGFloat)size weight:(UIFontWeight)weight {
    UIFont *base = [UIFont monospacedDigitSystemFontOfSize:size weight:weight];
    if (@available(iOS 13.0, *)) {
        UIFontDescriptor *desc = [base.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
        if (desc) {
            UIFont *f = [UIFont fontWithDescriptor:desc size:size];
            if (f) return f;
        }
    }
    return base;
}

#pragma mark - Metrics

+ (CGFloat)hair {
    static CGFloat hair = 0;
    if (hair == 0) {
        CGFloat scale = [UIScreen mainScreen].scale;
        hair = (scale > 0) ? (1.0 / scale) : 0.5;
    }
    return hair;
}

#pragma mark - Feedback

+ (void)impact:(UIImpactFeedbackStyle)style {
    if (![SDKTheme hapticsEnabled]) return;
    UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [g prepare];
    [g impactOccurred];
}

+ (void)notify:(UINotificationFeedbackType)type {
    if (![SDKTheme hapticsEnabled]) return;
    UINotificationFeedbackGenerator *g = [UINotificationFeedbackGenerator new];
    [g prepare];
    [g notificationOccurred:type];
}

+ (void)selectionTick {
    if (![SDKTheme hapticsEnabled]) return;
    UISelectionFeedbackGenerator *g = [UISelectionFeedbackGenerator new];
    [g prepare];
    [g selectionChanged];
}

/// Set from SDKStore once settings load, so theme stays dependency free.
static BOOL SDKHapticsEnabled = YES;
+ (BOOL)hapticsEnabled { return SDKHapticsEnabled; }
+ (void)setHapticsEnabled:(BOOL)on { SDKHapticsEnabled = on; }

#pragma mark - Helpers

+ (NSString *)timeString:(NSInteger)seconds {
    if (seconds < 0) seconds = 0;
    NSInteger h = seconds / 3600;
    NSInteger m = (seconds % 3600) / 60;
    NSInteger s = seconds % 60;
    if (h > 0) {
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)m, (long)s];
}

@end

@implementation UILabel (SDKTheme)

+ (instancetype)sdk_label:(NSString *)text
                     font:(UIFont *)font
                    color:(UIColor *)color
                alignment:(NSTextAlignment)alignment {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = font ?: [SDKTheme roundedFont:14 weight:UIFontWeightRegular];
    label.textColor = color ?: [SDKTheme textPrimary];
    label.textAlignment = alignment;
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 1;
    return label;
}

@end
