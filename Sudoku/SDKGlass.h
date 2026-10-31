//
//  SDKGlass.h
//  Sudoku — Liquid Glass Edition
//
//  A small, self contained liquid-glass design kit built on CALayer:
//  frosted blur + tinted gradient + specular rim + top sheen.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Glass panel

@interface SDKGlassView : UIView

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat tintAlpha;
@property (nonatomic, assign) CGFloat sheenAlpha;
@property (nonatomic, assign) BOOL usesBlur;
@property (nonatomic, assign) BOOL showsShadow;
@property (nonatomic, strong, nullable) UIColor *accentTint;
@property (nonatomic, assign) CGFloat highlightBoost;   // 0..1, extra brightness

/// Slow diagonal light streak — the "liquid" part. Off by default.
@property (nonatomic, assign) BOOL ambientSheen;

- (instancetype)initWithCornerRadius:(CGFloat)radius;
- (void)setCornerRadius:(CGFloat)radius animated:(BOOL)animated;
- (void)refreshAppearance;

@end

#pragma mark - Glass button

@interface SDKGlassButton : UIControl

@property (nonatomic, copy, nullable) NSString *symbolName;
@property (nonatomic, copy, nullable) NSString *titleText;
@property (nonatomic, copy, nullable) NSString *subtitleText;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat symbolPointSize;
@property (nonatomic, assign) CGFloat titlePointSize;
@property (nonatomic, strong, nullable) UIColor *contentColor;
@property (nonatomic, assign) BOOL verticalLayout;   // symbol above title
@property (nonatomic, assign) BOOL accentStyle;      // tinted, "active" look
@property (nonatomic, assign) BOOL toggled;
@property (nonatomic, assign) BOOL dimmed;
@property (nonatomic, copy, nullable) void (^onTap)(void);

/// Small counter in the corner of number keys.
- (void)setBadgeText:(nullable NSString *)text;

+ (instancetype)circleButtonWithSymbol:(NSString *)symbol diameter:(CGFloat)diameter;

@end

#pragma mark - Pill label

@interface SDKPillView : UIView

@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) UIColor *textColor;
@property (nonatomic, strong, nullable) UIColor *fillColor;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat horizontalPadding;
@property (nonatomic, assign) BOOL showsDot;

- (void)sizeToFitContent;

@end

#pragma mark - Switch

@interface SDKGlassSwitch : UIControl

@property (nonatomic, assign, getter=isOn) BOOL on;
@property (nonatomic, copy, nullable) void (^onChange)(BOOL isOn);
- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
