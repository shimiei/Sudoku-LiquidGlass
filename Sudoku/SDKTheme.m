//
//  SDKTheme.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKTheme.h"

@implementation SDKTheme

#pragma mark - Board palette

+ (UIColor *)boardBackground { return [UIColor secondarySystemGroupedBackgroundColor]; }
+ (UIColor *)givenColor      { return [UIColor labelColor]; }
+ (UIColor *)userColor       { return [UIColor systemBlueColor]; }
+ (UIColor *)noteColor       { return [UIColor secondaryLabelColor]; }
+ (UIColor *)errorColor      { return [UIColor systemRedColor]; }
+ (UIColor *)errorFill       { return [[UIColor systemRedColor] colorWithAlphaComponent:0.16]; }
+ (UIColor *)selectFill      { return [[UIColor systemBlueColor] colorWithAlphaComponent:0.18]; }
+ (UIColor *)peerFill        { return [UIColor tertiarySystemFillColor]; }
+ (UIColor *)sameFill        { return [[UIColor systemBlueColor] colorWithAlphaComponent:0.10]; }
+ (UIColor *)gridLine        { return [UIColor separatorColor]; }
+ (UIColor *)boxLine         { return [UIColor opaqueSeparatorColor]; }

+ (UIColor *)colorForDifficulty:(NSInteger)difficulty {
    switch (difficulty) {
        case 0:  return [UIColor systemGreenColor];
        case 1:  return [UIColor systemOrangeColor];
        default: return [UIColor systemRedColor];
    }
}

#pragma mark - Fonts

+ (UIFont *)digitsFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    return [UIFont monospacedDigitSystemFontOfSize:size weight:weight];
}

+ (UIFont *)timerFont {
    UIFont *base = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    return [[UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote] scaledFontForFont:base];
}

#pragma mark - Status line

+ (NSString *)statusLineWithSeconds:(NSInteger)seconds mistakes:(NSInteger)mistakes {
    NSString *time = [self timeString:seconds];
    if (mistakes <= 0) return time;
    return [NSString stringWithFormat:@"%@ · 失误 %ld", time, (long)mistakes];
}

#pragma mark - Formatting

+ (NSString *)timeString:(NSInteger)seconds {
    if (seconds < 0) seconds = 0;
    NSInteger h = seconds / 3600;
    NSInteger m = (seconds % 3600) / 60;
    NSInteger s = seconds % 60;
    if (h > 0) return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)m, (long)s];
}

+ (NSString *)randomPraise {
    static NSArray<NSString *> *lines = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        lines = @[ @"思路很清晰。", @"干净利落。", @"这一局很稳。", @"漂亮的推理。", @"干得漂亮！" ];
    });
    return lines[(NSUInteger)arc4random_uniform((uint32_t)lines.count)];
}

#pragma mark - Feedback

static BOOL SDKHapticsEnabled = YES;

+ (BOOL)hapticsEnabled { return SDKHapticsEnabled; }
+ (void)setHapticsEnabled:(BOOL)on { SDKHapticsEnabled = on; }

+ (void)impact:(UIImpactFeedbackStyle)style {
    if (!SDKHapticsEnabled) return;
    UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [g prepare];
    [g impactOccurred];
}

+ (void)notify:(UINotificationFeedbackType)type {
    if (!SDKHapticsEnabled) return;
    UINotificationFeedbackGenerator *g = [UINotificationFeedbackGenerator new];
    [g prepare];
    [g notificationOccurred:type];
}

+ (void)selection {
    if (!SDKHapticsEnabled) return;
    UISelectionFeedbackGenerator *g = [UISelectionFeedbackGenerator new];
    [g prepare];
    [g selectionChanged];
}

#pragma mark - Misc

+ (CGColorRef)cgColor:(UIColor *)color traits:(UITraitCollection *)traits {
    return [color resolvedColorWithTraitCollection:traits].CGColor;
}

@end
