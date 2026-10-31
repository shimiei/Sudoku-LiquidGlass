//
//  SDKHomeViewController.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKHomeViewController.h"
#import "SDKTheme.h"
#import "SDKGlass.h"
#import "SDKAuroraView.h"
#import "SDKStore.h"
#import "SDKGameViewController.h"
#import "SDKHistoryViewController.h"
#import "SDKSettingsViewController.h"

@interface SDKHomeViewController ()

@property (nonatomic, strong) SDKAuroraView *aurora;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) SDKPillView *glassPill;

@property (nonatomic, strong) SDKGlassView *resumeCard;
@property (nonatomic, strong) UILabel *resumeTitleLabel;
@property (nonatomic, strong) UILabel *resumeDetailLabel;
@property (nonatomic, strong) UILabel *resumeTimeLabel;
@property (nonatomic, strong) UIView *resumeTrack;
@property (nonatomic, strong) UIView *resumeFill;
@property (nonatomic, strong) SDKGlassButton *resumePlayButton;

@property (nonatomic, strong) NSMutableArray<SDKGlassView *> *difficultyCards;
@property (nonatomic, strong) NSMutableArray<UILabel *> *difficultyDetailLabels;

@property (nonatomic, strong) NSMutableArray<SDKGlassButton *> *bottomButtons;

@end

@implementation SDKHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [SDKTheme bgBottom];
    [self buildBackground];
    [self buildHeader];
    [self buildResumeCard];
    [self buildDifficultyCards];
    [self buildBottomBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshContent];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

#pragma mark - Build

- (void)buildBackground {
    self.aurora = [[SDKAuroraView alloc] initWithFrame:self.view.bounds];
    self.aurora.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.aurora];
    [self.aurora startAnimating];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
}

- (void)buildHeader {
    self.titleLabel = [UILabel sdk_label:@"数独"
                                    font:[SDKTheme roundedFont:42 weight:UIFontWeightBold]
                                   color:[SDKTheme textPrimary]
                               alignment:NSTextAlignmentLeft];
    [self.scrollView addSubview:self.titleLabel];

    self.subtitleLabel = [UILabel sdk_label:@"SUDOKU · LIQUID GLASS"
                                       font:[SDKTheme roundedFont:12 weight:UIFontWeightSemibold]
                                      color:[SDKTheme textTertiary]
                                  alignment:NSTextAlignmentLeft];
    self.subtitleLabel.attributedText = [[NSAttributedString alloc]
        initWithString:@"SUDOKU  ·  LIQUID GLASS"
            attributes:@{ NSFontAttributeName: [SDKTheme roundedFont:11 weight:UIFontWeightSemibold],
                          NSForegroundColorAttributeName: [SDKTheme textTertiary],
                          NSKernAttributeName: @(2.2) }];
    [self.scrollView addSubview:self.subtitleLabel];

    self.glassPill = [[SDKPillView alloc] initWithFrame:CGRectZero];
    self.glassPill.text = @"液态玻璃";
    self.glassPill.fontSize = 11;
    self.glassPill.showsDot = YES;
    self.glassPill.textColor = [SDKTheme accent];
    [self.scrollView addSubview:self.glassPill];
}

- (void)buildResumeCard {
    self.resumeCard = [[SDKGlassView alloc] initWithCornerRadius:24];
    self.resumeCard.tintAlpha = 0.08;
    self.resumeCard.ambientSheen = YES;
    self.resumeCard.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.resumeCard];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resumeGame)];
    [self.resumeCard addGestureRecognizer:tap];

    self.resumeTitleLabel = [UILabel sdk_label:@"继续对局"
                                          font:[SDKTheme roundedFont:13 weight:UIFontWeightBold]
                                         color:[SDKTheme accent]
                                     alignment:NSTextAlignmentLeft];
    [self.resumeCard addSubview:self.resumeTitleLabel];

    self.resumeDetailLabel = [UILabel sdk_label:nil
                                           font:[SDKTheme roundedFont:12 weight:UIFontWeightMedium]
                                          color:[SDKTheme textSecondary]
                                      alignment:NSTextAlignmentLeft];
    [self.resumeCard addSubview:self.resumeDetailLabel];

    self.resumeTimeLabel = [UILabel sdk_label:nil
                                         font:[SDKTheme monoDigitFont:26 weight:UIFontWeightBold]
                                        color:[SDKTheme textPrimary]
                                    alignment:NSTextAlignmentRight];
    [self.resumeCard addSubview:self.resumeTimeLabel];

    self.resumeTrack = [[UIView alloc] initWithFrame:CGRectZero];
    self.resumeTrack.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    self.resumeTrack.layer.cornerRadius = 2.0;
    [self.resumeCard addSubview:self.resumeTrack];

    self.resumeFill = [[UIView alloc] initWithFrame:CGRectZero];
    self.resumeFill.backgroundColor = [SDKTheme accent];
    self.resumeFill.layer.cornerRadius = 2.0;
    [self.resumeTrack addSubview:self.resumeFill];

    __weak typeof(self) weakSelf = self;
    self.resumePlayButton = [SDKGlassButton circleButtonWithSymbol:@"play.fill" diameter:44];
    self.resumePlayButton.symbolPointSize = 16;
    self.resumePlayButton.accentStyle = YES;
    self.resumePlayButton.onTap = ^{ [weakSelf resumeGame]; };
    [self.resumeCard addSubview:self.resumePlayButton];
}

- (void)buildDifficultyCards {
    self.difficultyCards = [NSMutableArray array];
    self.difficultyDetailLabels = [NSMutableArray array];

    NSArray<NSString *> *titles = @[ @"简单", @"中等", @"困难" ];
    NSArray<NSString *> *hints = @[ @"轻松热身 · 44 个提示数",
                                    @"经典难度 · 32 个提示数",
                                    @"极简线索 · 24 个提示数" ];
    NSArray<UIColor *> *tints = @[ [SDKTheme accent], [SDKTheme accentAlt], [SDKTheme accentWarm] ];

    for (NSInteger i = 0; i < 3; i++) {
        SDKGlassView *card = [[SDKGlassView alloc] initWithCornerRadius:22];
        card.tintAlpha = 0.06;
        card.userInteractionEnabled = YES;
        [self.scrollView addSubview:card];
        [self.difficultyCards addObject:card];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(handleDifficultyTap:)];
        [card addGestureRecognizer:tap];

        UIView *dot = [[UIView alloc] initWithFrame:CGRectZero];
        dot.backgroundColor = tints[(NSUInteger)i];
        dot.layer.cornerRadius = 5.0;
        dot.layer.shadowColor = tints[(NSUInteger)i].CGColor;
        dot.layer.shadowOpacity = 0.9;
        dot.layer.shadowRadius = 6.0;
        dot.layer.shadowOffset = CGSizeZero;
        dot.tag = 10;
        [card addSubview:dot];

        UILabel *name = [UILabel sdk_label:titles[(NSUInteger)i]
                                      font:[SDKTheme roundedFont:18 weight:UIFontWeightBold]
                                     color:[SDKTheme textPrimary]
                                 alignment:NSTextAlignmentLeft];
        name.tag = 11;
        [card addSubview:name];

        UILabel *hint = [UILabel sdk_label:hints[(NSUInteger)i]
                                      font:[SDKTheme roundedFont:11 weight:UIFontWeightRegular]
                                     color:[SDKTheme textTertiary]
                                 alignment:NSTextAlignmentLeft];
        hint.tag = 12;
        [card addSubview:hint];

        UILabel *detail = [UILabel sdk_label:@"尚未挑战"
                                        font:[SDKTheme roundedFont:11 weight:UIFontWeightSemibold]
                                       color:[SDKTheme textSecondary]
                                   alignment:NSTextAlignmentRight];
        detail.tag = 13;
        [card addSubview:detail];
        [self.difficultyDetailLabels addObject:detail];

        UIImageView *chevron = [[UIImageView alloc] initWithFrame:CGRectZero];
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:13
                                                                                          weight:UIImageSymbolWeightSemibold];
        chevron.image = [[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg]
                         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        chevron.tintColor = [SDKTheme textTertiary];
        chevron.contentMode = UIViewContentModeCenter;
        chevron.tag = 14;
        [card addSubview:chevron];
    }
}

- (void)buildBottomBar {
    self.bottomButtons = [NSMutableArray array];
    NSArray<NSString *> *titles = @[ @"历史", @"统计", @"设置" ];
    NSArray<NSString *> *symbols = @[ @"clock.arrow.circlepath", @"chart.bar.fill", @"gearshape" ];
    __weak typeof(self) weakSelf = self;

    for (NSInteger i = 0; i < 3; i++) {
        SDKGlassButton *b = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
        b.symbolName = symbols[(NSUInteger)i];
        b.titleText = titles[(NSUInteger)i];
        b.verticalLayout = YES;
        b.symbolPointSize = 19;
        b.titlePointSize = 11;
        b.cornerRadius = 20;
        NSInteger index = i;
        b.onTap = ^{ [weakSelf handleBottomBarTapAtIndex:index]; };
        [self.scrollView addSubview:b];
        [self.bottomButtons addObject:b];
    }
}

- (void)handleBottomBarTapAtIndex:(NSInteger)index {
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    switch (index) {
        case 0: [self openHistory]; break;
        case 1: [self openStats]; break;
        default: [self openSettings]; break;
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = self.view.safeAreaInsets;
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = CGRectGetHeight(self.view.bounds);
    CGFloat margin = (w > 520.0) ? (w - 460.0) / 2.0 : 20.0;
    CGFloat contentWidth = w - margin * 2.0;

    self.scrollView.frame = self.view.bounds;

    CGFloat y = safe.top + 26.0;

    self.titleLabel.frame = CGRectMake(margin, y, contentWidth, 52);
    y += 56;
    self.subtitleLabel.frame = CGRectMake(margin, y, contentWidth - 110, 16);
    [self.glassPill sizeToFitContent];
    CGRect pillFrame = self.glassPill.frame;
    pillFrame.origin = CGPointMake(w - margin - CGRectGetWidth(pillFrame), y - 2.0);
    self.glassPill.frame = pillFrame;
    y += 30;

    // resume card
    BOOL hasResume = (self.resumeCard.hidden == NO);
    if (hasResume) {
        self.resumeCard.frame = CGRectMake(margin, y, contentWidth, 96);
        self.resumeTitleLabel.frame = CGRectMake(20, 16, 200, 18);
        self.resumeDetailLabel.frame = CGRectMake(20, 38, contentWidth - 120, 18);
        self.resumeTimeLabel.frame = CGRectMake(contentWidth - 170, 24, 110, 30);
        self.resumePlayButton.frame = CGRectMake(contentWidth - 62, 26, 44, 44);
        self.resumeTrack.frame = CGRectMake(20, 70, contentWidth - 40, 4);
        CGFloat progress = 0.0;
        SDKGameState *game = [[SDKStore shared] currentGame];
        if (game) progress = [game progress];
        self.resumeFill.frame = CGRectMake(0, 0, (contentWidth - 40) * MAX(0.02, progress), 4);
        y += 96 + 16;
    }

    for (NSInteger i = 0; i < (NSInteger)self.difficultyCards.count; i++) {
        SDKGlassView *card = self.difficultyCards[(NSUInteger)i];
        card.frame = CGRectMake(margin, y, contentWidth, 80);

        UIView *dot = [card viewWithTag:10];
        UILabel *name = (UILabel *)[card viewWithTag:11];
        UILabel *hint = (UILabel *)[card viewWithTag:12];
        UILabel *detail = (UILabel *)[card viewWithTag:13];
        UIImageView *chevron = (UIImageView *)[card viewWithTag:14];

        dot.frame = CGRectMake(20, 37, 10, 10);
        name.frame = CGRectMake(42, 20, 160, 22);
        hint.frame = CGRectMake(42, 44, contentWidth - 150, 16);
        detail.frame = CGRectMake(contentWidth - 168, 24, 130, 16);
        chevron.frame = CGRectMake(contentWidth - 28, 33, 14, 14);
        y += 80 + 12;
    }

    y += 6;
    CGFloat buttonGap = 12.0;
    CGFloat buttonWidth = (contentWidth - buttonGap * 2.0) / 3.0;
    for (NSInteger i = 0; i < (NSInteger)self.bottomButtons.count; i++) {
        self.bottomButtons[(NSUInteger)i].frame = CGRectMake(margin + i * (buttonWidth + buttonGap), y, buttonWidth, 66);
    }
    y += 66 + MAX(safe.bottom, 16.0);

    self.scrollView.contentSize = CGSizeMake(w, MAX(y, h));
}

#pragma mark - Content refresh

- (void)refreshContent {
    SDKStore *store = [SDKStore shared];
    SDKGameState *current = [store currentGame];

    self.resumeCard.hidden = (current == nil);
    self.resumePlayButton.hidden = (current == nil);
    if (current) {
        self.resumeTitleLabel.text = @"继续对局";
        self.resumeDetailLabel.text = [NSString stringWithFormat:@"%@ · 已完成 %ld/81 · 失误 %ld",
                                       SDKDifficultyTitle(current.difficulty),
                                       (long)[current filledCount],
                                       (long)current.mistakes];
        self.resumeTimeLabel.text = [SDKTheme timeString:current.elapsedSeconds];
    }

    for (NSInteger d = 0; d < 3; d++) {
        NSDictionary *stats = [store statsForDifficulty:(SDKDifficulty)d];
        NSInteger played = [stats[@"played"] integerValue];
        NSInteger completed = [stats[@"completed"] integerValue];
        NSInteger best = [stats[@"best"] integerValue];
        UILabel *detail = self.difficultyDetailLabels[(NSUInteger)d];
        if (played == 0) {
            detail.text = @"尚未挑战";
        } else {
            detail.text = [NSString stringWithFormat:@"完成 %ld · 最佳 %@",
                           (long)completed,
                           best > 0 ? [SDKTheme timeString:best] : @"--"];
        }
    }

    [self.view setNeedsLayout];
}

#pragma mark - Actions

/// Guards against double taps pushing the same screen twice.
- (BOOL)isTopOfNavigationStack {
    return (self.navigationController.topViewController == self || self.navigationController == nil);
}

/// True once the player has actually filled something in (not just loaded the puzzle).
- (BOOL)hasUserProgress:(SDKGameState *)game {
    NSInteger givens = 0;
    for (NSNumber *n in game.puzzle) if (n.integerValue != 0) givens++;
    return [game filledCount] > givens;
}

- (void)handleDifficultyTap:(UITapGestureRecognizer *)gesture {
    if (![self isTopOfNavigationStack]) return;
    NSInteger index = (NSInteger)[self.difficultyCards indexOfObject:(SDKGlassView *)gesture.view];
    if (index == NSNotFound || index < 0 || index > 2) return;

    SDKGameState *current = [[SDKStore shared] currentGame];
    if (current && [self hasUserProgress:current]) {
        // The previous game is kept in history as abandoned before switching.
        [[SDKStore shared] recordGame:current];
    }
    [[SDKStore shared] saveCurrentGame:nil];

    [SDKTheme impact:UIImpactFeedbackStyleMedium];
    SDKGameViewController *vc = [[SDKGameViewController alloc] initWithDifficulty:(SDKDifficulty)index];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)resumeGame {
    if (![self isTopOfNavigationStack]) return;
    SDKGameState *current = [[SDKStore shared] currentGame];
    if (!current) return;
    [SDKTheme impact:UIImpactFeedbackStyleMedium];
    SDKGameViewController *vc = [[SDKGameViewController alloc] initWithSavedGame:current];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openHistory {
    if (![self isTopOfNavigationStack]) return;
    SDKHistoryViewController *vc = [[SDKHistoryViewController alloc] initWithSection:SDKHistorySectionRecords];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openStats {
    if (![self isTopOfNavigationStack]) return;
    SDKHistoryViewController *vc = [[SDKHistoryViewController alloc] initWithSection:SDKHistorySectionStats];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openSettings {
    if (![self isTopOfNavigationStack]) return;
    SDKSettingsViewController *vc = [SDKSettingsViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
