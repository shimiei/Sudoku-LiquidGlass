//
//  SDKTheme.h
//  Sudoku — Apple HIG rebuild
//
//  Everything here is either a system semantic colour or a system font, so the
//  app follows the Human Interface Guidelines and adapts to Light/Dark, increased
//  contrast and Dynamic Type without any per-screen work.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKTheme : NSObject

#pragma mark - Board palette (all trait aware)

+ (UIColor *)boardBackground;   // secondarySystemGroupedBackground
+ (UIColor *)givenColor;        // label
+ (UIColor *)userColor;         // systemBlue (the app tint)
+ (UIColor *)noteColor;         // secondaryLabel
+ (UIColor *)errorColor;        // systemRed
+ (UIColor *)errorFill;
+ (UIColor *)selectFill;
+ (UIColor *)peerFill;
+ (UIColor *)sameFill;
+ (UIColor *)gridLine;
+ (UIColor *)boxLine;

/// Difficulty accent dot, matching the system palette.
+ (UIColor *)colorForDifficulty:(NSInteger)difficulty;

#pragma mark - Mascots

/// 每档难度一只动物：熊猫 / 狐狸 / 老虎，圆形贴纸。
+ (nullable UIImage *)mascotForDifficulty:(NSInteger)difficulty;
/// 睡觉的熊猫，用于空白状态。
+ (nullable UIImage *)mascotSleepy;
/// 与插画底色一致的主题色（浅色态下用作行内图标的衬底）。
+ (UIColor *)mascotTintForDifficulty:(NSInteger)difficulty;

#pragma mark - Fonts

+ (UIFont *)digitsFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)timerFont;

#pragma mark - Multiple lines of text, e.g. "02:31 · 失误 2"

+ (NSString *)statusLineWithSeconds:(NSInteger)seconds mistakes:(NSInteger)mistakes;

#pragma mark - Formatting

+ (NSString *)timeString:(NSInteger)seconds;
+ (NSString *)randomPraise;

#pragma mark - Feedback

+ (void)impact:(UIImpactFeedbackStyle)style;
+ (void)notify:(UINotificationFeedbackType)type;
+ (void)selection;
+ (BOOL)hapticsEnabled;
+ (void)setHapticsEnabled:(BOOL)on;

#pragma mark - Misc

/// Resolves a dynamic colour for a specific trait collection (needed for CGColor).
+ (CGColorRef)cgColor:(UIColor *)color traits:(UITraitCollection *)traits;

@end

NS_ASSUME_NONNULL_END
