//
//  SDKGlass.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKGlass.h"
#import "SDKTheme.h"

static inline UIColor *SDKWhite(CGFloat alpha) {
    return [UIColor colorWithWhite:1.0 alpha:alpha];
}

#pragma mark - Glass panel

@interface SDKGlassView ()
- (void)commonInit;
@end

@implementation SDKGlassView {
    UIVisualEffectView *_blurView;
    CAGradientLayer *_fillLayer;
    CAGradientLayer *_sheenLayer;
    CAGradientLayer *_rimLayer;
    CAShapeLayer *_rimMask;
    CAGradientLayer *_ambientLayer;
    CALayer *_highlightLayer;
}

- (instancetype)initWithCornerRadius:(CGFloat)radius {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _cornerRadius = radius;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cornerRadius = 20;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.clipsToBounds = NO;
    self.userInteractionEnabled = NO;
    _tintAlpha = 0.055;
    _sheenAlpha = 0.15;
    _borderWidth = 1.0;
    _usesBlur = YES;
    _showsShadow = YES;

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 12);
    self.layer.shadowOpacity = 0.40;
    self.layer.shadowRadius = 22;

    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
    _blurView.userInteractionEnabled = NO;
    [self addSubview:_blurView];

    _fillLayer = [CAGradientLayer layer];
    _fillLayer.startPoint = CGPointMake(0.0, 0.0);
    _fillLayer.endPoint = CGPointMake(0.6, 1.0);
    [self.layer addSublayer:_fillLayer];

    _highlightLayer = [CALayer layer];
    _highlightLayer.backgroundColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:_highlightLayer];

    _sheenLayer = [CAGradientLayer layer];
    _sheenLayer.startPoint = CGPointMake(0.5, 0.0);
    _sheenLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.layer addSublayer:_sheenLayer];

    _rimLayer = [CAGradientLayer layer];
    _rimLayer.startPoint = CGPointMake(0.05, 0.0);
    _rimLayer.endPoint = CGPointMake(0.95, 1.0);
    _rimLayer.colors = @[ (id)SDKWhite(0.62).CGColor,
                          (id)SDKWhite(0.06).CGColor,
                          (id)SDKWhite(0.36).CGColor ];
    _rimLayer.locations = @[ @0.0, @0.48, @1.0 ];
    _rimMask = [CAShapeLayer layer];
    _rimMask.fillColor = [UIColor clearColor].CGColor;
    _rimMask.strokeColor = [UIColor blackColor].CGColor;
    _rimLayer.mask = _rimMask;
    [self.layer addSublayer:_rimLayer];

    _ambientLayer = [CAGradientLayer layer];
    _ambientLayer.startPoint = CGPointMake(0.0, 0.0);
    _ambientLayer.endPoint = CGPointMake(1.0, 1.0);
    _ambientLayer.colors = @[ (id)SDKWhite(0.0).CGColor,
                              (id)SDKWhite(0.13).CGColor,
                              (id)SDKWhite(0.0).CGColor ];
    _ambientLayer.locations = @[ @(-0.8), @(-0.4), @(-0.1) ];
    _ambientLayer.hidden = YES;
    [self.layer addSublayer:_ambientLayer];

    [self refreshAppearance];
}

- (void)refreshAppearance {
    UIColor *top;
    UIColor *bottom;
    if (self.accentTint) {
        top = [self.accentTint colorWithAlphaComponent:MAX(_tintAlpha, 0.22)];
        bottom = [self.accentTint colorWithAlphaComponent:MAX(_tintAlpha * 0.35, 0.05)];
    } else {
        top = SDKWhite(_tintAlpha);
        bottom = SDKWhite(_tintAlpha * 0.30);
    }
    _fillLayer.colors = @[ (id)top.CGColor, (id)bottom.CGColor ];
    _sheenLayer.colors = @[ (id)SDKWhite(_sheenAlpha).CGColor,
                            (id)SDKWhite(_sheenAlpha * 0.35).CGColor,
                            (id)SDKWhite(0.0).CGColor ];
    _sheenLayer.locations = @[ @0.0, @0.42, @0.72 ];
    _blurView.hidden = !_usesBlur;
    self.layer.shadowOpacity = _showsShadow ? 0.40 : 0.0;
    [self setNeedsLayout];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (void)setCornerRadius:(CGFloat)radius animated:(BOOL)animated {
    _cornerRadius = radius;
    if (animated) {
        [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutIfNeeded];
        } completion:nil];
    }
    [self setNeedsLayout];
}

- (void)setTintAlpha:(CGFloat)tintAlpha { _tintAlpha = tintAlpha; [self refreshAppearance]; }
- (void)setSheenAlpha:(CGFloat)sheenAlpha { _sheenAlpha = sheenAlpha; [self refreshAppearance]; }
- (void)setUsesBlur:(BOOL)usesBlur { _usesBlur = usesBlur; [self refreshAppearance]; }
- (void)setShowsShadow:(BOOL)showsShadow { _showsShadow = showsShadow; [self refreshAppearance]; }
- (void)setAccentTint:(UIColor *)accentTint { _accentTint = accentTint; [self refreshAppearance]; }
- (void)setBorderWidth:(CGFloat)borderWidth { _borderWidth = borderWidth; [self setNeedsLayout]; }

- (void)setHighlightBoost:(CGFloat)highlightBoost {
    _highlightBoost = highlightBoost;
    _highlightLayer.backgroundColor = SDKWhite(0.12 * MAX(0.0, MIN(1.0, highlightBoost))).CGColor;
}

- (void)setAmbientSheen:(BOOL)ambientSheen {
    _ambientSheen = ambientSheen;
    _ambientLayer.hidden = !ambientSheen;
    [_ambientLayer removeAnimationForKey:@"sweep"];
    if (ambientSheen) {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"locations"];
        anim.fromValue = @[ @(-0.9), @(-0.6), @(-0.3) ];
        anim.toValue = @[ @(1.3), @(1.6), @(1.9) ];
        anim.duration = 7.0;
        anim.repeatCount = HUGE_VALF;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_ambientLayer addAnimation:anim forKey:@"sweep"];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    CGRect bounds = self.bounds;
    CGFloat radius = MAX(0.0, MIN(self.cornerRadius, MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds)) / 2.0));

    _blurView.frame = bounds;
    _blurView.layer.cornerRadius = radius;
    _blurView.layer.cornerCurve = kCACornerCurveContinuous;
    _blurView.clipsToBounds = YES;

    _fillLayer.frame = bounds;
    _fillLayer.cornerRadius = radius;
    _fillLayer.cornerCurve = kCACornerCurveContinuous;
    _fillLayer.masksToBounds = YES;

    _highlightLayer.frame = bounds;
    _highlightLayer.cornerRadius = radius;
    _highlightLayer.masksToBounds = YES;

    _sheenLayer.frame = bounds;
    _sheenLayer.cornerRadius = radius;
    _sheenLayer.cornerCurve = kCACornerCurveContinuous;
    _sheenLayer.masksToBounds = YES;

    _ambientLayer.frame = bounds;
    _ambientLayer.cornerRadius = radius;
    _ambientLayer.masksToBounds = YES;

    _rimLayer.frame = bounds;
    CGRect rimRect = CGRectInset(bounds, self.borderWidth / 2.0, self.borderWidth / 2.0);
    _rimMask.frame = bounds;
    _rimMask.lineWidth = self.borderWidth;
    _rimMask.path = [UIBezierPath bezierPathWithRoundedRect:rimRect cornerRadius:radius].CGPath;

    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:radius].CGPath;

    [CATransaction commit];
}

@end

#pragma mark - Glass button

@interface SDKGlassButton ()
- (void)commonInit;
- (void)refreshIcon;
- (void)applyStyle;
- (void)setPressed:(BOOL)pressed;
@end

@implementation SDKGlassButton {
    SDKGlassView *_glass;
    UIImageView *_iconView;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UILabel *_badgeLabel;
    BOOL _pressed;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self commonInit];
    return self;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) [self commonInit];
    return self;
}

+ (instancetype)circleButtonWithSymbol:(NSString *)symbol diameter:(CGFloat)diameter {
    SDKGlassButton *b = [[SDKGlassButton alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    b.cornerRadius = diameter / 2.0;
    b.symbolName = symbol;
    b.symbolPointSize = diameter * 0.40;
    return b;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    _cornerRadius = 18;
    _symbolPointSize = 20;
    _titlePointSize = 14;
    _contentColor = [SDKTheme textPrimary];

    _glass = [[SDKGlassView alloc] initWithCornerRadius:_cornerRadius];
    _glass.tintAlpha = 0.065;
    _glass.sheenAlpha = 0.17;
    [_glass refreshAppearance];
    [self addSubview:_glass];

    _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _iconView.contentMode = UIViewContentModeCenter;
    _iconView.userInteractionEnabled = NO;
    [self addSubview:_iconView];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [SDKTheme roundedFont:_titlePointSize weight:UIFontWeightSemibold];
    [_titleLabel setAdjustsFontSizeToFitWidth:YES];
    _titleLabel.minimumScaleFactor = 0.6;
    [self addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.font = [SDKTheme roundedFont:11 weight:UIFontWeightMedium];
    _subtitleLabel.textColor = [SDKTheme textSecondary];
    [self addSubview:_subtitleLabel];

    _badgeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _badgeLabel.textAlignment = NSTextAlignmentRight;
    _badgeLabel.font = [SDKTheme roundedFont:9 weight:UIFontWeightBold];
    _badgeLabel.textColor = [SDKTheme textTertiary];
    _badgeLabel.hidden = YES;
    [self addSubview:_badgeLabel];
}

#pragma mark Content

- (void)setSymbolName:(NSString *)symbolName {
    _symbolName = [symbolName copy];
    [self refreshIcon];
    [self setNeedsLayout];
}

- (void)setSymbolPointSize:(CGFloat)symbolPointSize {
    if (fabs(symbolPointSize - _symbolPointSize) < 0.01) return;
    _symbolPointSize = symbolPointSize;
    [self refreshIcon];
    [self setNeedsLayout];
}

- (void)refreshIcon {
    if (self.symbolName.length == 0) {
        _iconView.image = nil;
        _iconView.hidden = YES;
        return;
    }
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:self.symbolPointSize
                                                       weight:UIImageSymbolWeightSemibold];
    UIImage *img = [UIImage systemImageNamed:self.symbolName withConfiguration:cfg];
    if (!img) {
        cfg = [UIImageSymbolConfiguration configurationWithPointSize:self.symbolPointSize weight:UIImageSymbolWeightRegular];
        img = [UIImage systemImageNamed:self.symbolName withConfiguration:cfg];
    }
    _iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _iconView.hidden = (img == nil);
    _iconView.tintColor = self.dimmed ? [SDKTheme textTertiary] : self.contentColor;
}

- (void)setTitleText:(NSString *)titleText {
    _titleText = [titleText copy];
    _titleLabel.text = titleText;
    [self setNeedsLayout];
}

- (void)setSubtitleText:(NSString *)subtitleText {
    _subtitleText = [subtitleText copy];
    _subtitleLabel.text = subtitleText;
    [self setNeedsLayout];
}

- (void)setTitlePointSize:(CGFloat)titlePointSize {
    if (fabs(titlePointSize - _titlePointSize) < 0.01) return;
    _titlePointSize = titlePointSize;
    _titleLabel.font = [SDKTheme roundedFont:titlePointSize weight:UIFontWeightSemibold];
    [self setNeedsLayout];
}

- (void)setContentColor:(UIColor *)contentColor {
    _contentColor = contentColor;
    [self applyStyle];
}

- (void)setDimmed:(BOOL)dimmed {
    _dimmed = dimmed;
    [self applyStyle];
}

- (void)setAccentStyle:(BOOL)accentStyle {
    _accentStyle = accentStyle;
    [self applyStyle];
}

- (void)setToggled:(BOOL)toggled {
    _toggled = toggled;
    [self applyStyle];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    _glass.cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (void)setBadgeText:(NSString *)text {
    _badgeLabel.text = text;
    _badgeLabel.hidden = (text.length == 0);
    [self setNeedsLayout];
}

- (void)applyStyle {
    BOOL active = self.accentStyle || self.toggled;
    _glass.accentTint = active ? [SDKTheme accent] : nil;
    _glass.tintAlpha = active ? 0.26 : 0.065;
    _glass.sheenAlpha = active ? 0.24 : 0.17;
    _glass.borderWidth = active ? 1.2 : 1.0;
    _glass.cornerRadius = _cornerRadius;
    [_glass refreshAppearance];

    UIColor *color = active ? [SDKTheme accent] : self.contentColor;
    if (self.dimmed) color = [SDKTheme textTertiary];
    _titleLabel.textColor = color;
    _iconView.tintColor = color;
    self.alpha = self.dimmed ? 0.55 : 1.0;
    [self setNeedsLayout];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    _glass.frame = self.bounds;

    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    BOOL hasIcon = (_iconView.image != nil);
    BOOL hasTitle = (_titleLabel.text.length > 0);
    BOOL hasSubtitle = (_subtitleLabel.text.length > 0);

    if (hasIcon && hasTitle) {
        if (self.verticalLayout) {
            CGFloat iconHeight = self.symbolPointSize * 1.30;
            CGFloat titleHeight = self.titlePointSize * 1.35;
            CGFloat gap = 2.0;
            CGFloat total = iconHeight + gap + titleHeight;
            CGFloat top = (h - total) / 2.0;
            _iconView.frame = CGRectMake(0, top, w, iconHeight);
            _titleLabel.frame = CGRectMake(2, top + iconHeight + gap, w - 4, titleHeight);
        } else {
            CGSize fit = [_titleLabel sizeThatFits:CGSizeMake(w, h)];
            CGFloat textWidth = ceil(fit.width) + 2;
            CGFloat iconWidth = self.symbolPointSize * 1.25;
            CGFloat gap = 7.0;
            CGFloat total = iconWidth + gap + textWidth;
            CGFloat left = (w - total) / 2.0;
            _iconView.frame = CGRectMake(left, 0, iconWidth, h);
            _titleLabel.frame = CGRectMake(left + iconWidth + gap, 0, textWidth, h);
        }
    } else if (hasIcon) {
        _iconView.frame = CGRectInset(self.bounds, 4, 4);
        _titleLabel.frame = CGRectZero;
    } else {
        _iconView.frame = CGRectZero;
        _titleLabel.frame = CGRectInset(self.bounds, 2, hasSubtitle ? 8 : 0);
    }

    if (hasSubtitle) {
        _subtitleLabel.hidden = NO;
        _subtitleLabel.frame = CGRectMake(2, CGRectGetMaxY(_titleLabel.frame) - 2, w - 4, 14);
    } else {
        _subtitleLabel.hidden = YES;
    }

    if (!_badgeLabel.hidden) {
        // reminder count sits as a superscript in the top-right corner
        _badgeLabel.frame = CGRectMake(w - 24.0, 3.0, 20.0, 10.0);
    }
}

#pragma mark Touch

- (void)setPressed:(BOOL)pressed {
    _pressed = pressed;
    [UIView animateWithDuration:pressed ? 0.10 : 0.20
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.transform = pressed ? CGAffineTransformMakeScale(0.93, 0.93) : CGAffineTransformIdentity;
        self->_glass.highlightBoost = pressed ? 0.75 : 0.0;
    } completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.enabled) return;
    [self setPressed:YES];
    [SDKTheme impact:UIImpactFeedbackStyleLight];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.enabled) return;
    UITouch *t = touches.anyObject;
    BOOL inside = CGRectContainsPoint(CGRectInset(self.bounds, -8, -8), [t locationInView:self]);
    if (!inside && _pressed) [self setPressed:NO];
    if (inside && !_pressed) [self setPressed:YES];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    BOOL wasEnabled = self.enabled;
    UITouch *t = touches.anyObject;
    BOOL inside = CGRectContainsPoint(CGRectInset(self.bounds, -8, -8), [t locationInView:self]);
    [self setPressed:NO];   // always clear, even if we were disabled mid-touch
    if (wasEnabled && inside) {
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
        if (self.onTap) self.onTap();
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self setPressed:NO];
}

@end

#pragma mark - Pill label

@implementation SDKPillView {
    UILabel *_label;
    UIView *_dot;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _fontSize = 12;
        _horizontalPadding = 10;
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.09];
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.16].CGColor;
        self.layer.borderWidth = 1.0;
        self.userInteractionEnabled = NO;

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [SDKTheme roundedFont:_fontSize weight:UIFontWeightSemibold];
        _label.textColor = [SDKTheme textPrimary];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];

        _dot = [[UIView alloc] initWithFrame:CGRectZero];
        _dot.backgroundColor = [SDKTheme accent];
        _dot.layer.cornerRadius = 2.5;
        _dot.hidden = YES;
        [self addSubview:_dot];
    }
    return self;
}

- (void)setText:(NSString *)text {
    _text = [text copy];
    _label.text = text;
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    _label.textColor = textColor ?: [SDKTheme textPrimary];
}

- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    self.backgroundColor = fillColor ?: [UIColor colorWithWhite:1.0 alpha:0.09];
}

- (void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
    _label.font = [SDKTheme roundedFont:fontSize weight:UIFontWeightSemibold];
    [self setNeedsLayout];
}

- (void)setHorizontalPadding:(CGFloat)horizontalPadding {
    _horizontalPadding = horizontalPadding;
    [self setNeedsLayout];
}

- (void)setShowsDot:(BOOL)showsDot {
    _showsDot = showsDot;
    _dot.hidden = !showsDot;
    [self setNeedsLayout];
}

- (void)sizeToFitContent {
    CGSize fit = [_label sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    CGFloat dotWidth = self.showsDot ? 12.0 : 0.0;
    CGFloat width = ceil(fit.width) + self.horizontalPadding * 2 + dotWidth;
    CGFloat height = ceil(fit.height) + 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, MAX(height, 24));
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = CGRectGetHeight(self.bounds);
    self.layer.cornerRadius = h / 2.0;
    CGFloat dotWidth = self.showsDot ? 12.0 : 0.0;
    _dot.frame = CGRectMake(self.horizontalPadding, h / 2.0 - 2.5, 5, 5);
    _dot.layer.cornerRadius = 2.5;
    _label.frame = CGRectMake(self.horizontalPadding + dotWidth,
                              0,
                              CGRectGetWidth(self.bounds) - self.horizontalPadding * 2 - dotWidth,
                              h);
}

@end

#pragma mark - Switch

@implementation SDKGlassSwitch {
    UIView *_track;
    UIView *_knob;
    BOOL _on;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 52, 31)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _track = [[UIView alloc] initWithFrame:self.bounds];
        _track.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.13];
        _track.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
        _track.layer.borderWidth = 1.0;
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];

        _knob = [[UIView alloc] initWithFrame:CGRectZero];
        _knob.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
        _knob.layer.shadowColor = [UIColor blackColor].CGColor;
        _knob.layer.shadowOpacity = 0.35;
        _knob.layer.shadowRadius = 3;
        _knob.layer.shadowOffset = CGSizeMake(0, 1.5);
        _knob.userInteractionEnabled = NO;
        [self addSubview:_knob];
    }
    return self;
}

- (CGSize)intrinsicContentSize { return CGSizeMake(52, 31); }

- (void)layoutSubviews {
    [super layoutSubviews];
    _track.frame = self.bounds;
    _track.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2.0;
    CGFloat knobSize = CGRectGetHeight(self.bounds) - 6.0;
    CGFloat x = _on ? CGRectGetWidth(self.bounds) - knobSize - 3.0 : 3.0;
    _knob.frame = CGRectMake(x, 3.0, knobSize, knobSize);
    _knob.layer.cornerRadius = knobSize / 2.0;
    _track.backgroundColor = _on ? [[SDKTheme accent] colorWithAlphaComponent:0.85]
                                 : [UIColor colorWithWhite:1.0 alpha:0.13];
}

- (BOOL)isOn { return _on; }

- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    if (animated) {
        [UIView animateWithDuration:0.26 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.4
                            options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self layoutIfNeeded];
        } completion:nil];
        [self setNeedsLayout];
    } else {
        [self setNeedsLayout];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.enabled) return;
    UITouch *t = touches.anyObject;
    if (t && !CGRectContainsPoint(CGRectInset(self.bounds, -4, -4), [t locationInView:self])) return;
    _on = !_on;
    [self setOn:_on animated:YES];
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    if (self.onChange) self.onChange(_on);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}

@end
