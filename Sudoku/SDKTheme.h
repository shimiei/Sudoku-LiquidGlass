//
//  SDKTheme.h
//  Sudoku — Liquid Glass Edition
//
//  Central design system: colours, fonts, haptics.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKTheme : NSObject

#pragma mark - Background

+ (UIColor *)bgTop;
+ (UIColor *)bgBottom;
+ (NSArray<UIColor *> *)auroraColors;

#pragma mark - Glass

+ (UIColor *)glassFill;
+ (UIColor *)glassFillStrong;
+ (UIColor *)strokeBright;
+ (UIColor *)strokeDim;

#pragma mark - Text

+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textTertiary;

#pragma mark - Accents

+ (UIColor *)accent;
+ (UIColor *)accentAlt;
+ (UIColor *)accentWarm;
+ (UIColor *)danger;
+ (UIColor *)success;
+ (UIColor *)gold;

#pragma mark - Board

+ (UIColor *)givenText;
+ (UIColor *)userText;
+ (UIColor *)noteText;
+ (UIColor *)gridLine;
+ (UIColor *)gridLineStrong;
+ (UIColor *)cellSelect;
+ (UIColor *)cellPeer;
+ (UIColor *)cellSame;
+ (UIColor *)cellError;
+ (UIColor *)errorText;

#pragma mark - Fonts

+ (UIFont *)roundedFont:(CGFloat)size weight:(UIFontWeight)weight;
+ (UIFont *)monoDigitFont:(CGFloat)size weight:(UIFontWeight)weight;

#pragma mark - Metrics

+ (CGFloat)hair;

#pragma mark - Feedback

+ (void)impact:(UIImpactFeedbackStyle)style;
+ (void)notify:(UINotificationFeedbackType)type;
+ (void)selectionTick;

/// Global haptics switch (mirrored from settings by SDKStore).
+ (BOOL)hapticsEnabled;
+ (void)setHapticsEnabled:(BOOL)on;

#pragma mark - Helpers

+ (NSString *)timeString:(NSInteger)seconds;

@end

@interface UILabel (SDKTheme)
+ (instancetype)sdk_label:(nullable NSString *)text
                     font:(nullable UIFont *)font
                    color:(nullable UIColor *)color
                alignment:(NSTextAlignment)alignment;
@end

NS_ASSUME_NONNULL_END
