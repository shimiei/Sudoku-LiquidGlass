//
//  SDKCompletionOverlay.m
//  Sudoku
//

#import "SDKCompletionOverlay.h"
#import "SDKMaterial.h"
#import "SDKTheme.h"
#import "SDKSudokuEngine.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface SDKCompletionOverlay ()
@property (nonatomic) NSInteger difficulty;
@property (nonatomic) NSInteger seconds;
@property (nonatomic) NSInteger mistakes;
@property (nonatomic) NSInteger hints;
@property (nonatomic) BOOL isBest;
@property (nonatomic) NSInteger stars;

@property (nonatomic, strong) UIView *scrim;
@property (nonatomic, strong) UIView *confettiHost;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIImageView *mascotView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *starsRow;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong, nullable) NSArray<UIView *> *animatedPieces;
@property (nonatomic, copy, nullable) void (^finishHandler)(SDKCompletionAction action);
@property (nonatomic) BOOL dismissed;
@property (nonatomic, strong, nullable) CAEmitterLayer *emitter;
@end

@implementation SDKCompletionOverlay

- (instancetype)initWithDifficulty:(NSInteger)difficulty
                           seconds:(NSInteger)seconds
                          mistakes:(NSInteger)mistakes
                             hints:(NSInteger)hints
                            isBest:(BOOL)isBest {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    _difficulty = difficulty;
    _seconds = seconds;
    _mistakes = mistakes;
    _hints = hints;
    _isBest = isBest;
    _stars = [self starsForMistakes:mistakes hints:hints];

    self.backgroundColor = UIColor.clearColor;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self buildSubviews];
    return self;
}

/// 3 星：零失误零提示；2 星：失误 ≤2 且提示 ≤1；其余 1 星。
- (NSInteger)starsForMistakes:(NSInteger)mistakes hints:(NSInteger)hints {
    if (mistakes == 0 && hints == 0) return 3;
    if (mistakes <= 2 && hints <= 1) return 2;
    return 1;
}

#pragma mark - Build

- (void)buildSubviews {
    // 1 — 遮罩
    self.scrim = [[UIView alloc] initWithFrame:CGRectZero];
    self.scrim.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.28];
    self.scrim.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.scrim];

    // 2 — 彩纸层（在卡片后面）
    self.confettiHost = [[UIView alloc] initWithFrame:CGRectZero];
    self.confettiHost.userInteractionEnabled = NO;
    self.confettiHost.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.confettiHost];

    // 3 — 卡片
    self.card = [SDKMaterial panelWithCornerRadius:30.0];
    self.card.translatesAutoresizingMaskIntoConstraints = NO;
    self.card.accessibilityViewIsModal = YES;
    [self addSubview:self.card];

    // 角色
    self.mascotView = [[UIImageView alloc] initWithImage:[SDKTheme mascotForDifficulty:self.difficulty]];
    self.mascotView.contentMode = UIViewContentModeScaleAspectFill;
    self.mascotView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mascotView.layer.cornerRadius = 52.0;
    self.mascotView.clipsToBounds = YES;
    self.mascotView.isAccessibilityElement = NO;

    // 标题
    self.titleLabel = [UILabel new];
    self.titleLabel.text = [self headlineText];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;

    self.subtitleLabel = [UILabel new];
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ · 用时 %@",
                               SDKDifficultyTitle(self.difficulty),
                               [SDKTheme timeString:self.seconds]];
    self.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.subtitleLabel.adjustsFontForContentSizeCategory = YES;
    self.subtitleLabel.textColor = [UIColor secondaryLabelColor];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;

    // 星级
    self.starsRow = [[UIStackView alloc] init];
    self.starsRow.axis = UILayoutConstraintAxisHorizontal;
    self.starsRow.spacing = 8.0;
    self.starsRow.alignment = UIStackViewAlignmentCenter;
    for (NSInteger i = 0; i < 3; i++) {
        UIImageView *star = [[UIImageView alloc] initWithImage:[self starImageFilled:(i < self.stars)]];
        star.contentMode = UIViewContentModeScaleAspectFit;
        star.translatesAutoresizingMaskIntoConstraints = NO;
        [star.widthAnchor constraintEqualToConstant:34.0].active = YES;
        [star.heightAnchor constraintEqualToConstant:34.0].active = YES;
        star.alpha = (i < self.stars) ? 0.0 : 0.35;
        [self.starsRow addArrangedSubview:star];
    }
    UIView *starWrap = [[UIView alloc] init];
    [starWrap addSubview:self.starsRow];
    self.starsRow.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.starsRow.centerXAnchor constraintEqualToAnchor:starWrap.centerXAnchor],
        [self.starsRow.topAnchor constraintEqualToAnchor:starWrap.topAnchor],
        [self.starsRow.bottomAnchor constraintEqualToAnchor:starWrap.bottomAnchor],
    ]];

    // 数据
    UIStackView *statsRow = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self statColumnWithValue:[SDKTheme timeString:self.seconds] caption:@"用时"],
        [self statColumnWithValue:[NSString stringWithFormat:@"%ld", (long)self.mistakes] caption:@"失误"],
        [self statColumnWithValue:[NSString stringWithFormat:@"%ld", (long)self.hints] caption:@"提示"],
    ]];
    statsRow.axis = UILayoutConstraintAxisHorizontal;
    statsRow.distribution = UIStackViewDistributionFillEqually;
    statsRow.alignment = UIStackViewAlignmentTop;

    // 新纪录
    UIView *bestPill = nil;
    if (self.isBest) {
        UILabel *label = [UILabel new];
        label.text = @"本档新纪录";
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        label.adjustsFontForContentSizeCategory = YES;
        label.textColor = [UIColor whiteColor];
        UIView *pill = [UIView new];
        pill.backgroundColor = [UIColor systemOrangeColor];
        pill.layer.cornerRadius = 11.0;
        pill.layer.cornerCurve = kCACornerCurveContinuous;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [pill addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:10.0],
            [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-10.0],
            [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:3.0],
            [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-3.0],
        ]];
        UIView *wrap = [[UIView alloc] init];
        pill.translatesAutoresizingMaskIntoConstraints = NO;
        [wrap addSubview:pill];
        [NSLayoutConstraint activateConstraints:@[
            [pill.centerXAnchor constraintEqualToAnchor:wrap.centerXAnchor],
            [pill.topAnchor constraintEqualToAnchor:wrap.topAnchor],
            [pill.bottomAnchor constraintEqualToAnchor:wrap.bottomAnchor],
        ]];
        bestPill = wrap;
    }

    // 按钮
    UIButton *replay = [self buttonWithTitle:@"再来一局" symbol:@"arrow.clockwise" prominent:YES];
    [replay addTarget:self action:@selector(replayTapped) forControlEvents:UIControlEventTouchUpInside];
    UIButton *home = [self buttonWithTitle:@"返回首页" symbol:@"house" prominent:NO];
    [home addTarget:self action:@selector(homeTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[ replay, home ]];
    buttons.axis = UILayoutConstraintAxisVertical;
    buttons.spacing = 10.0;
    buttons.distribution = UIStackViewDistributionFillEqually;

    NSMutableArray<UIView *> *pieces = [NSMutableArray arrayWithObjects:
                                        self.mascotView, self.titleLabel, self.subtitleLabel, starWrap, statsRow, nil];
    if (bestPill) [pieces addObject:bestPill];
    [pieces addObject:buttons];
    self.animatedPieces = pieces;

    self.contentStack = [[UIStackView alloc] initWithArrangedSubviews:pieces];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 12.0;
    self.contentStack.alignment = UIStackViewAlignmentFill;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.card addSubview:self.contentStack];

    // 角色固定尺寸、居中
    UIView *mascotWrap = [[UIView alloc] init];
    [self.contentStack removeArrangedSubview:self.mascotView];
    [self.mascotView removeFromSuperview];
    [mascotWrap addSubview:self.mascotView];
    [self.contentStack insertArrangedSubview:mascotWrap atIndex:0];
    // 尺寸可压缩：矮屏（iPad 横屏分屏）时角色先缩，不会撑爆卡片
    NSLayoutConstraint *mascotWide = [self.mascotView.widthAnchor constraintEqualToConstant:104.0];
    mascotWide.priority = 750;
    NSLayoutConstraint *mascotSquare = [self.mascotView.widthAnchor constraintEqualToAnchor:self.mascotView.heightAnchor];
    mascotSquare.priority = 999;
    [NSLayoutConstraint activateConstraints:@[
        mascotWide,
        mascotSquare,
        [self.mascotView.widthAnchor constraintGreaterThanOrEqualToConstant:60.0],
        [self.mascotView.centerXAnchor constraintEqualToAnchor:mascotWrap.centerXAnchor],
        [self.mascotView.topAnchor constraintEqualToAnchor:mascotWrap.topAnchor],
        [self.mascotView.bottomAnchor constraintEqualToAnchor:mascotWrap.bottomAnchor],
    ]];

    // 布局
    UILayoutGuide *safe = self.safeAreaLayoutGuide;
    NSLayoutConstraint *verticalTop =
        [self.card.topAnchor constraintGreaterThanOrEqualToAnchor:safe.topAnchor constant:16.0];
    NSLayoutConstraint *verticalBottom =
        [self.card.bottomAnchor constraintLessThanOrEqualToAnchor:safe.bottomAnchor constant:-16.0];
    // 高度不足时让卡片轻微溢出，而不是打出约束冲突
    verticalTop.priority = 999;
    verticalBottom.priority = 999;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrim.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrim.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrim.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.scrim.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [self.confettiHost.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.confettiHost.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.confettiHost.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.confettiHost.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [self.card.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.card.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.card.widthAnchor constraintLessThanOrEqualToConstant:330.0],
        [self.card.widthAnchor constraintGreaterThanOrEqualToConstant:272.0],
        [self.card.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:24.0],
        [self.card.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-24.0],
        verticalTop,
        verticalBottom,

        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor constant:24.0],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-24.0],
        [self.contentStack.topAnchor constraintEqualToAnchor:self.card.topAnchor constant:24.0],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.card.bottomAnchor constant:-22.0],
    ]];

    self.accessibilityElements = @[ self.card ];
}

- (NSString *)headlineText {
    switch (self.stars) {
        case 3: return @"完美！";
        case 2: return @"完成了";
        default: return @"完成了";
    }
}

- (UIImage *)starImageFilled:(BOOL)filled {
    UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:30.0
                                                                                  weight:UIImageSymbolWeightSemibold];
    UIImage *image = [UIImage systemImageNamed:(filled ? @"star.fill" : @"star") withConfiguration:config];
    return [image imageWithTintColor:(filled ? [UIColor systemYellowColor] : [UIColor tertiaryLabelColor])
                      renderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIStackView *)statColumnWithValue:(NSString *)value caption:(NSString *)caption {
    UILabel *valueLabel = [UILabel new];
    valueLabel.text = value;
    valueLabel.font = [SDKTheme digitsFontOfSize:17.0 weight:UIFontWeightSemibold];
    valueLabel.textColor = [UIColor labelColor];
    valueLabel.textAlignment = NSTextAlignmentCenter;

    UILabel *captionLabel = [UILabel new];
    captionLabel.text = caption;
    captionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    captionLabel.adjustsFontForContentSizeCategory = YES;
    captionLabel.textColor = [UIColor secondaryLabelColor];
    captionLabel.textAlignment = NSTextAlignmentCenter;

    UIStackView *column = [[UIStackView alloc] initWithArrangedSubviews:@[ valueLabel, captionLabel ]];
    column.axis = UILayoutConstraintAxisVertical;
    column.spacing = 2.0;
    column.alignment = UIStackViewAlignmentFill;
    return column;
}

- (UIButton *)buttonWithTitle:(NSString *)title symbol:(NSString *)symbol prominent:(BOOL)prominent {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *config = [SDKMaterial glassButtonConfigurationProminent:prominent];
    if (!config) {
        config = prominent ? [UIButtonConfiguration filledButtonConfiguration]
                           : [UIButtonConfiguration grayButtonConfiguration];
        config.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    }
    config.title = title;
    config.image = [UIImage systemImageNamed:symbol];
    config.imagePadding = 8.0;
    config.preferredSymbolConfigurationForImage =
        [UIImageSymbolConfiguration configurationWithPointSize:15.0 weight:UIImageSymbolWeightSemibold];
    button.configuration = config;
    NSLayoutConstraint *tall = [button.heightAnchor constraintGreaterThanOrEqualToConstant:46.0];
    tall.priority = 750;
    tall.active = YES;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:40.0].active = YES;
    return button;
}

#pragma mark - Present

- (void)presentInView:(UIView *)host completion:(void (^)(SDKCompletionAction))completion {
    if (!host) return;
    self.finishHandler = completion;
    self.frame = host.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [host addSubview:self];

    BOOL reduceMotion = UIAccessibilityIsReduceMotionEnabled();

    self.scrim.alpha = 0.0;
    self.card.alpha = reduceMotion ? 0.0 : 1.0;
    if (!reduceMotion) {
        self.card.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.86, 0.86),
                                                      CGAffineTransformMakeTranslation(0, 18));
    }
    for (UIView *piece in self.animatedPieces) piece.alpha = 0.0;

    [UIView animateWithDuration:0.25 animations:^{
        self.scrim.alpha = 1.0;
    }];

    if (reduceMotion) {
        for (NSInteger i = 0; i < (NSInteger)self.starsRow.arrangedSubviews.count; i++) {
            if (i < self.stars) {
                ((UIView *)self.starsRow.arrangedSubviews[(NSUInteger)i]).alpha = 1.0;
            }
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.card.alpha = 1.0;
            for (UIView *piece in self.animatedPieces) piece.alpha = 1.0;
        }];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.titleLabel);
        return;
    }

    // 卡片：弹簧入场
    [UIView animateWithDuration:0.62 delay:0.04
         usingSpringWithDamping:0.72 initialSpringVelocity:0.4
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.card.transform = CGAffineTransformIdentity;
    } completion:nil];

    // 内容：逐项浮起
    NSTimeInterval delay = 0.14;
    for (UIView *piece in self.animatedPieces) {
        piece.transform = CGAffineTransformMakeTranslation(0, 10);
        [UIView animateWithDuration:0.42 delay:delay
             usingSpringWithDamping:0.86 initialSpringVelocity:0.2
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            piece.alpha = 1.0;
            piece.transform = CGAffineTransformIdentity;
        } completion:nil];
        delay += 0.055;
    }

    // 星星逐颗弹出来
    [self animateStars];

    // 彩纸（先跑一次布局，否则 confettiHost 还是零尺寸）
    [self layoutIfNeeded];
    [self emitConfetti];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self stopConfetti];
    });

    // 角色轻轻呼吸
    [self startMascotBreathing];

    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.titleLabel);
}

- (void)animateStars {
    NSTimeInterval delay = 0.5;
    for (NSInteger i = 0; i < (NSInteger)self.starsRow.arrangedSubviews.count; i++) {
        UIImageView *star = (UIImageView *)self.starsRow.arrangedSubviews[(NSUInteger)i];
        if (i >= self.stars) continue;
        star.transform = CGAffineTransformMakeScale(0.2, 0.2);
        [UIView animateWithDuration:0.5 delay:delay
             usingSpringWithDamping:0.55 initialSpringVelocity:0.9
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            star.alpha = 1.0;
            star.transform = CGAffineTransformIdentity;
        } completion:nil];
        delay += 0.13;
    }
}

- (void)startMascotBreathing {
    CABasicAnimation *bob = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    bob.fromValue = @0.0;
    bob.toValue = @(-3.0);
    bob.duration = 1.6;
    bob.autoreverses = YES;
    bob.repeatCount = HUGE_VALF;
    bob.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.mascotView.layer addAnimation:bob forKey:@"breathing"];
}

#pragma mark - Confetti

- (void)emitConfetti {
    [self removeEmitters];
    CGRect bounds = self.confettiHost.bounds;
    if (CGRectGetWidth(bounds) < 40.0) return;

    NSArray<UIColor *> *palette = @[
        [UIColor systemPinkColor], [UIColor systemTealColor], [UIColor systemIndigoColor],
        [UIColor systemOrangeColor], [UIColor systemYellowColor],
        [UIColor colorWithRed:0.55 green:0.80 blue:0.62 alpha:1.0]
    ];

    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.frame = self.confettiHost.bounds;
    emitter.emitterShape = kCAEmitterLayerLine;
    emitter.emitterMode = kCAEmitterLayerSurface;
    emitter.emitterPosition = CGPointMake(CGRectGetMidX(bounds), -24.0);
    emitter.emitterSize = CGSizeMake(CGRectGetWidth(bounds) * 0.95, 1.0);
    emitter.renderMode = kCAEmitterLayerUnordered;

    NSMutableArray<CAEmitterCell *> *cells = [NSMutableArray array];
    for (NSUInteger i = 0; i < palette.count; i++) {
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        UIImage *chip = [self confettiImageWithColor:palette[i] round:(i % 3 == 0)];
        cell.contents = (__bridge id)chip.CGImage;
        cell.birthRate = 1.7;
        cell.lifetime = 3.4;
        cell.lifetimeRange = 0.8;
        cell.velocity = 300.0;
        cell.velocityRange = 130.0;
        cell.emissionLongitude = M_PI_2;
        cell.emissionRange = M_PI / 5.0;
        cell.yAcceleration = 210.0;
        cell.scale = 0.11;
        cell.scaleRange = 0.045;
        cell.spin = 3.2;
        cell.spinRange = 5.0;
        cell.alphaSpeed = -0.12;
        [cells addObject:cell];
    }
    emitter.emitterCells = cells;
    emitter.name = @"confetti";
    [self.confettiHost.layer addSublayer:emitter];
    self.emitter = emitter;

    // 粒子落完之后整体移除，别留在图层里
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weakSelf removeEmitters];
    });
}

- (void)stopConfetti {
    self.emitter.birthRate = 0.0;
}

- (void)removeEmitters {
    for (CALayer *layer in [self.confettiHost.layer.sublayers copy]) {
        if ([layer isKindOfClass:[CAEmitterLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    self.emitter = nil;
}

/// 彩纸小碎片：方形 / 圆形两种，避免用 emoji 造成风格不一。
- (UIImage *)confettiImageWithColor:(UIColor *)color round:(BOOL)round {
    CGSize size = CGSizeMake(24.0, 24.0);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [color setFill];
        if (round) {
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 24, 24)] fill];
        } else {
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(2, 6, 20, 12) cornerRadius:3.0] fill];
        }
        (void)ctx;
    }];
}

#pragma mark - Actions

- (void)replayTapped {
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self dismissWithAction:SDKCompletionActionReplay];
}

- (void)homeTapped {
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self dismissWithAction:SDKCompletionActionHome];
}

- (void)dismissWithAction:(SDKCompletionAction)action {
    if (self.dismissed) return;
    self.dismissed = YES;
    void (^handler)(SDKCompletionAction) = self.finishHandler;
    self.finishHandler = nil;

    void (^finish)(void) = ^{
        [self.layer removeAllAnimations];
        [self removeFromSuperview];
        if (handler) handler(action);
    };

    if (UIAccessibilityIsReduceMotionEnabled()) {
        [self stopConfetti];
        [UIView animateWithDuration:0.18 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) { finish(); }];
        return;
    }
    [self stopConfetti];
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.card.transform = CGAffineTransformMakeScale(0.92, 0.92);
        self.card.alpha = 0.0;
        self.scrim.alpha = 0.0;
        self.confettiHost.alpha = 0.0;
    } completion:^(BOOL finished) { finish(); }];
}

@end
