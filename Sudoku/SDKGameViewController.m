//
//  SDKGameViewController.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKGameViewController.h"
#import "SDKTheme.h"
#import "SDKGlass.h"
#import "SDKBoardView.h"
#import "SDKLoupeView.h"
#import "SDKAuroraView.h"
#import "SDKStore.h"

static NSString * const kSDKSymbolUndo    = @"arrow.uturn.backward";
static NSString * const kSDKSymbolRedo    = @"arrow.uturn.forward";
static NSString * const kSDKSymbolErase   = @"delete.left";
static NSString * const kSDKSymbolNote    = @"pencil";
static NSString * const kSDKSymbolAuto    = @"wand.and.stars";
static NSString * const kSDKSymbolHint    = @"lightbulb.fill";
static NSString * const kSDKSymbolLoupe   = @"magnifyingglass";
static NSString * const kSDKSymbolPause   = @"pause.fill";
static NSString * const kSDKSymbolBack    = @"chevron.left";

@interface SDKGameViewController () <SDKBoardViewDelegate>

@property (nonatomic, strong) SDKGameState *game;

@property (nonatomic, strong) SDKAuroraView *aurora;
@property (nonatomic, strong) SDKGlassButton *backButton;
@property (nonatomic, strong) SDKGlassButton *loupeButton;
@property (nonatomic, strong) SDKGlassButton *pauseButton;

@property (nonatomic, strong) SDKGlassView *statusGlass;
@property (nonatomic, strong) UILabel *difficultyLabel;
@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, strong) UILabel *mistakesLabel;

@property (nonatomic, strong) SDKGlassView *boardGlass;
@property (nonatomic, strong) SDKBoardView *board;
@property (nonatomic, strong) NSMutableArray<SDKGlassButton *> *quickButtons;
@property (nonatomic, strong) NSMutableArray<SDKGlassButton *> *numberButtons;
@property (nonatomic, strong) SDKLoupeView *loupe;

@property (nonatomic, strong) UIView *pauseOverlay;
@property (nonatomic, strong) UIView *winOverlay;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL loupePinned;
@property (nonatomic, assign) BOOL resultRecorded;

@end

@implementation SDKGameViewController

#pragma mark - Lifecycle

- (instancetype)initWithDifficulty:(SDKDifficulty)difficulty {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        SDKSudokuPuzzle *puzzle = [SDKSudokuEngine generatePuzzle:difficulty];
        _game = [SDKGameState gameWithPuzzle:puzzle];
    }
    return self;
}

- (instancetype)initWithSavedGame:(SDKGameState *)game {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _game = game;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [SDKTheme bgBottom];
    [self buildBackground];
    [self buildTopBar];
    [self buildBoard];
    [self buildQuickActions];
    [self buildNumberPad];
    [self buildLoupe];
    [self refreshFromSettings];
    [self refreshUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.game.paused = NO;
    [self refreshFromSettings];
    [self refreshUI];
    [self startTimer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (!self.game.finished) [[SDKStore shared] saveCurrentGame:self.game];
}

- (void)dealloc {
    [_timer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

#pragma mark - UI construction

- (void)buildBackground {
    self.aurora = [[SDKAuroraView alloc] initWithFrame:self.view.bounds];
    self.aurora.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.aurora];
    [self.aurora startAnimating];
}

- (void)buildTopBar {
    self.backButton = [SDKGlassButton circleButtonWithSymbol:kSDKSymbolBack diameter:42];
    self.backButton.symbolPointSize = 17;
    __weak typeof(self) weakSelf = self;
    self.backButton.onTap = ^{ [weakSelf goBack]; };
    [self.view addSubview:self.backButton];

    self.loupeButton = [SDKGlassButton circleButtonWithSymbol:kSDKSymbolLoupe diameter:42];
    self.loupeButton.symbolPointSize = 17;
    self.loupeButton.onTap = ^{ [weakSelf togglePinnedLoupe]; };
    [self.view addSubview:self.loupeButton];

    self.pauseButton = [SDKGlassButton circleButtonWithSymbol:kSDKSymbolPause diameter:42];
    self.pauseButton.symbolPointSize = 16;
    self.pauseButton.onTap = ^{ [weakSelf pauseGame]; };
    [self.view addSubview:self.pauseButton];

    self.statusGlass = [[SDKGlassView alloc] initWithCornerRadius:21];
    self.statusGlass.tintAlpha = 0.05;
    [self.view addSubview:self.statusGlass];

    self.difficultyLabel = [UILabel sdk_label:SDKDifficultyTitle(self.game.difficulty)
                                          font:[SDKTheme roundedFont:14 weight:UIFontWeightSemibold]
                                         color:[SDKTheme textPrimary]
                                     alignment:NSTextAlignmentCenter];
    self.timerLabel = [UILabel sdk_label:@"00:00"
                                    font:[SDKTheme monoDigitFont:15 weight:UIFontWeightSemibold]
                                   color:[SDKTheme accent]
                               alignment:NSTextAlignmentCenter];
    self.mistakesLabel = [UILabel sdk_label:nil
                                       font:[SDKTheme roundedFont:12 weight:UIFontWeightBold]
                                      color:[SDKTheme danger]
                                  alignment:NSTextAlignmentCenter];
    [self.statusGlass addSubview:self.difficultyLabel];
    [self.statusGlass addSubview:self.timerLabel];
    [self.statusGlass addSubview:self.mistakesLabel];
    self.statusGlass.userInteractionEnabled = NO;
}

- (void)buildBoard {
    self.boardGlass = [[SDKGlassView alloc] initWithCornerRadius:26];
    self.boardGlass.tintAlpha = 0.07;
    self.boardGlass.sheenAlpha = 0.13;
    [self.view addSubview:self.boardGlass];

    self.board = [[SDKBoardView alloc] initWithFrame:CGRectZero];
    self.board.delegate = self;
    self.board.game = self.game;
    [self.view addSubview:self.board];
}

- (SDKGlassButton *)quickButtonWithSymbol:(NSString *)symbol title:(NSString *)title {
    SDKGlassButton *b = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
    b.symbolName = symbol;
    b.titleText = title;
    b.verticalLayout = YES;
    b.cornerRadius = 18;
    b.symbolPointSize = 18;
    b.titlePointSize = 10;
    b.contentColor = [SDKTheme textPrimary];
    [self.view addSubview:b];
    return b;
}

- (void)buildQuickActions {
    self.quickButtons = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    SDKGlassButton *undo = [self quickButtonWithSymbol:kSDKSymbolUndo title:@"撤销"];
    undo.onTap = ^{ [weakSelf performUndo]; };
    [self.quickButtons addObject:undo];

    SDKGlassButton *redo = [self quickButtonWithSymbol:kSDKSymbolRedo title:@"重做"];
    redo.onTap = ^{ [weakSelf performRedo]; };
    [self.quickButtons addObject:redo];

    SDKGlassButton *erase = [self quickButtonWithSymbol:kSDKSymbolErase title:@"擦除"];
    erase.onTap = ^{ [weakSelf performErase]; };
    [self.quickButtons addObject:erase];

    SDKGlassButton *note = [self quickButtonWithSymbol:kSDKSymbolNote title:@"笔记"];
    note.onTap = ^{ [weakSelf toggleNoteMode]; };
    [self.quickButtons addObject:note];

    SDKGlassButton *auto_ = [self quickButtonWithSymbol:kSDKSymbolAuto title:@"全笔记"];
    auto_.onTap = ^{ [weakSelf fillAllNotes]; };
    [self.quickButtons addObject:auto_];

    SDKGlassButton *hint = [self quickButtonWithSymbol:kSDKSymbolHint title:@"提示"];
    hint.onTap = ^{ [weakSelf performHint]; };
    [self.quickButtons addObject:hint];
}

- (void)buildNumberPad {
    self.numberButtons = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    for (NSInteger d = 1; d <= 9; d++) {
        SDKGlassButton *b = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
        b.titleText = [NSString stringWithFormat:@"%ld", (long)d];
        b.titlePointSize = 22;
        b.cornerRadius = 15;
        b.contentColor = [SDKTheme textPrimary];
        NSInteger digit = d;
        b.onTap = ^{ [weakSelf handleDigit:digit]; };
        [self.view addSubview:b];
        [self.numberButtons addObject:b];
    }
}

- (void)buildLoupe {
    self.loupe = [[SDKLoupeView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = self.view.safeAreaInsets;
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = CGRectGetHeight(self.view.bounds);
    CGFloat margin = (w > 480.0) ? 28.0 : 16.0;

    CGFloat topY = safe.top + 6.0;
    CGFloat buttonSize = 42.0;
    self.backButton.frame = CGRectMake(margin, topY, buttonSize, buttonSize);
    self.pauseButton.frame = CGRectMake(w - margin - buttonSize, topY, buttonSize, buttonSize);
    self.loupeButton.frame = CGRectMake(CGRectGetMinX(self.pauseButton.frame) - 8.0 - buttonSize, topY, buttonSize, buttonSize);

    CGFloat statusLeft = CGRectGetMaxX(self.backButton.frame) + 10.0;
    CGFloat statusRight = CGRectGetMinX(self.loupeButton.frame) - 10.0;
    CGFloat statusWidth = MAX(120.0, statusRight - statusLeft);
    self.statusGlass.frame = CGRectMake(statusLeft, topY, statusWidth, 42.0);
    [self layoutStatusContent];

    CGFloat barBottom = topY + buttonSize;

    // number pad pinned to the bottom
    CGFloat padHeight = 56.0;
    CGFloat padBottom = h - safe.bottom - 14.0;
    CGFloat padTop = padBottom - padHeight;
    CGFloat padWidth = MIN(w - margin * 2.0, 560.0);
    CGFloat padLeft = (w - padWidth) / 2.0;
    CGFloat gap = 6.0;
    CGFloat keyWidth = (padWidth - gap * 8.0) / 9.0;
    for (NSInteger i = 0; i < (NSInteger)self.numberButtons.count; i++) {
        SDKGlassButton *b = self.numberButtons[(NSUInteger)i];
        b.frame = CGRectMake(padLeft + i * (keyWidth + gap), padTop, keyWidth, padHeight);
        b.titlePointSize = MIN(26.0, MAX(18.0, keyWidth * 0.66));
    }

    // quick actions above the pad
    CGFloat quickHeight = 56.0;
    CGFloat quickTop = padTop - 14.0 - quickHeight;
    CGFloat quickWidth = MIN(w - margin * 2.0, 560.0);
    CGFloat quickLeft = (w - quickWidth) / 2.0;
    CGFloat qGap = 8.0;
    CGFloat qWidth = (quickWidth - qGap * 5.0) / 6.0;
    for (NSInteger i = 0; i < (NSInteger)self.quickButtons.count; i++) {
        SDKGlassButton *b = self.quickButtons[(NSUInteger)i];
        b.frame = CGRectMake(quickLeft + i * (qWidth + qGap), quickTop, qWidth, quickHeight);
        b.symbolPointSize = MIN(20.0, qWidth * 0.42);
    }

    // board fills the space in between
    CGFloat boardTop = barBottom + 14.0;
    CGFloat boardAvailable = quickTop - 14.0 - boardTop;
    CGFloat boardSide = MIN(boardAvailable, w - margin * 2.0);
    boardSide = MIN(boardSide, 560.0);
    boardSide = MAX(boardSide, 200.0);
    CGFloat boardLeft = (w - boardSide) / 2.0;
    CGFloat boardY = boardTop + MAX(0.0, (boardAvailable - boardSide) / 2.0);
    self.boardGlass.frame = CGRectMake(boardLeft, boardY, boardSide, boardSide);
    self.board.frame = CGRectMake(boardLeft, boardY, boardSide, boardSide);
    [self.board setNeedsDisplay];

    if (self.pauseOverlay.superview) self.pauseOverlay.frame = self.view.bounds;
    if (self.winOverlay.superview) self.winOverlay.frame = self.view.bounds;
    if (self.loupePinned) [self positionPinnedLoupe];
}

- (void)layoutStatusContent {
    CGRect bounds = self.statusGlass.bounds;
    CGFloat h = CGRectGetHeight(bounds);
    CGSize diffSize = [self.difficultyLabel sizeThatFits:CGSizeMake(200, h)];
    CGSize timeSize = [self.timerLabel sizeThatFits:CGSizeMake(200, h)];
    BOOL hasMistakes = (self.mistakesLabel.text.length > 0);
    CGSize missSize = hasMistakes ? [self.mistakesLabel sizeThatFits:CGSizeMake(100, h)] : CGSizeZero;

    CGFloat dotGap = 6.0;
    CGFloat total = diffSize.width + dotGap + timeSize.width + (hasMistakes ? dotGap + missSize.width : 0);
    CGFloat x = (CGRectGetWidth(bounds) - total) / 2.0;

    self.difficultyLabel.frame = CGRectMake(x, 0, diffSize.width, h);
    x += diffSize.width + dotGap;
    self.timerLabel.frame = CGRectMake(x, 0, timeSize.width, h);
    if (hasMistakes) {
        x += timeSize.width + dotGap;
        self.mistakesLabel.frame = CGRectMake(x, 0, missSize.width, h);
    }
}

#pragma mark - Refresh

- (void)refreshFromSettings {
    SDKStore *store = [SDKStore shared];
    self.board.highlightSameNumbers = store.highlightSameNumbers;
    self.board.highlightPeers = store.highlightPeers;
    self.board.showConflicts = store.showConflicts;
    self.board.autoCheck = store.autoCheck;
    self.loupeButton.toggled = self.loupePinned;
    [self.board setNeedsDisplay];
}

- (void)refreshUI {
    [self.board reloadData];

    for (NSInteger i = 0; i < (NSInteger)self.numberButtons.count; i++) {
        SDKGlassButton *b = self.numberButtons[(NSUInteger)i];
        NSInteger remaining = [self.game remainingForValue:i + 1];
        [b setBadgeText:(remaining > 0) ? [NSString stringWithFormat:@"%ld", (long)remaining] : @"✓"];
        b.dimmed = (remaining <= 0);
    }

    SDKGlassButton *undo = self.quickButtons[0];
    SDKGlassButton *redo = self.quickButtons[1];
    undo.dimmed = !self.game.canUndo;
    redo.dimmed = !self.game.canRedo;
    undo.enabled = self.game.canUndo;
    redo.enabled = self.game.canRedo;

    SDKGlassButton *note = self.quickButtons[3];
    note.toggled = self.game.noteMode;

    self.timerLabel.text = [SDKTheme timeString:self.game.elapsedSeconds];
    self.mistakesLabel.text = (self.game.mistakes > 0)
        ? [NSString stringWithFormat:@"✕%ld", (long)self.game.mistakes] : nil;
    [self layoutStatusContent];
}

#pragma mark - Timer

- (void)startTimer {
    if (self.timer || self.game.finished) return;
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick {
    if (self.game.paused || self.game.finished) return;
    self.game.elapsedSeconds += 1;
    self.timerLabel.text = [SDKTheme timeString:self.game.elapsedSeconds];
    [self layoutStatusContent];
    if (self.game.elapsedSeconds % 10 == 0) [self saveGame];
}

- (void)saveGame {
    if (self.game.finished) return;
    [[SDKStore shared] saveCurrentGame:self.game];
}

- (void)handleAppBackground {
    if (!self.game.finished && !self.game.paused) {
        self.game.paused = YES;
        [self showPauseOverlay];
    }
    [self saveGame];
}

#pragma mark - Actions

- (void)goBack {
    [self saveGame];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)toggleNoteMode {
    self.game.noteMode = !self.game.noteMode;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self refreshUI];
}

- (void)performUndo {
    if (![self.game undo]) return;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self refreshUI];
    [self saveGame];
}

- (void)performRedo {
    if (![self.game redo]) return;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self refreshUI];
    [self saveGame];
}

- (void)performErase {
    NSInteger sel = self.board.selectedIndex;
    if (sel < 0) return;
    if ([self.game eraseAtIndex:sel] == SDKPlaceResultInvalid) return;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self.board flashIndex:sel color:[SDKTheme textSecondary]];
    [self refreshUI];
    [self saveGame];
}

- (void)fillAllNotes {
    [self.game fillAllNotes];
    [SDKTheme impact:UIImpactFeedbackStyleMedium];
    [self.board reloadData];
    [self refreshUI];
    [self saveGame];
}

- (void)performHint {
    NSNumber *index = [self.game applyHintAtIndex:self.board.selectedIndex];
    if (!index) {
        [SDKTheme notify:UINotificationFeedbackTypeWarning];
        return;
    }
    [SDKTheme notify:UINotificationFeedbackTypeSuccess];
    [self.board flashIndex:index.integerValue color:[SDKTheme success]];
    [self.board reloadData];
    [self refreshUI];
    if (self.game.finished) [self handleCompletion];
    else [self saveGame];
}

- (void)handleDigit:(NSInteger)digit {
    if (self.game.paused || self.game.finished) return;
    NSInteger sel = self.board.selectedIndex;
    if (sel < 0) {
        [SDKTheme notify:UINotificationFeedbackTypeWarning];
        return;
    }

    if (self.game.noteMode && [self.game valueAtIndex:sel] == 0) {
        if ([self.game toggleNote:digit atIndex:sel] == SDKPlaceResultInvalid) return;
        [SDKTheme impact:UIImpactFeedbackStyleLight];
        [self.board reloadData];
        [self saveGame];
        return;
    }

    SDKPlaceResult result = [self.game placeValue:digit atIndex:sel];
    if (result == SDKPlaceResultInvalid) {
        [SDKTheme notify:UINotificationFeedbackTypeWarning];
        return;
    }

    if (result == SDKPlaceResultWrong) {
        [SDKTheme notify:UINotificationFeedbackTypeError];
        [self.board flashIndex:sel color:[SDKTheme danger]];
    } else if (result == SDKPlaceResultCompleted) {
        [SDKTheme notify:UINotificationFeedbackTypeSuccess];
        [self.board flashIndex:sel color:[SDKTheme success]];
    } else {
        [SDKTheme impact:UIImpactFeedbackStyleMedium];
        [self.board flashIndex:sel color:[SDKTheme accent]];
    }

    [self refreshUI];
    if (result == SDKPlaceResultCompleted) [self handleCompletion];
    else [self saveGame];
}

- (void)togglePinnedLoupe {
    self.loupePinned = !self.loupePinned;
    self.loupeButton.toggled = self.loupePinned;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    if (self.loupePinned) {
        [self positionPinnedLoupe];
        [self.view bringSubviewToFront:self.loupe];
    } else {
        [self.loupe hideAnimated:YES];
    }
}

- (void)positionPinnedLoupe {
    NSInteger sel = self.board.selectedIndex;
    if (sel < 0) { [self.loupe hideAnimated:YES]; return; }
    CGRect cellRect = [self.board rectForCellAtIndex:sel];
    CGPoint cellCenterInBoard = CGPointMake(CGRectGetMidX(cellRect), CGRectGetMidY(cellRect));
    CGPoint cellCenterInView = [self.board convertPoint:cellCenterInBoard toView:self.view];
    CGPoint target = CGPointMake(cellCenterInView.x, CGRectGetMinY(self.board.frame) + 24.0);
    target.y = MAX(74.0 + 74.0, target.y);

    if (self.loupe.isVisible) {
        [self.loupe updateCenter:target boardPoint:cellCenterInBoard
                        cellSize:[self.board cellSize] focusIndex:sel];
    } else {
        [self.loupe presentInHost:self.view center:target boardPoint:cellCenterInBoard
                         cellSize:[self.board cellSize] game:self.game focusIndex:sel];
    }
    [self.view bringSubviewToFront:self.loupe];
}

#pragma mark - Board delegate

- (void)boardView:(SDKBoardView *)board didSelectIndex:(NSInteger)index {
    [self refreshUI];
    if (self.loupePinned) [self positionPinnedLoupe];
}

- (void)boardView:(SDKBoardView *)board didMoveFingerTo:(CGPoint)point insideBoard:(BOOL)inside {
    if (![SDKStore shared].loupeEnabled) return;
    if (self.loupePinned) return;

    if (!inside) {
        [self.loupe hideAnimated:YES];
        return;
    }

    CGPoint pointInView = [board convertPoint:point toView:self.view];
    CGPoint target = CGPointMake(pointInView.x, pointInView.y - 108.0);
    NSInteger index = [board indexForPoint:point];
    CGFloat cellSize = [board cellSize];

    if (self.loupe.isVisible) {
        [self.loupe updateCenter:target boardPoint:point cellSize:cellSize focusIndex:index];
    } else {
        [self.loupe presentInHost:self.view center:target boardPoint:point
                         cellSize:cellSize game:self.game focusIndex:index];
    }
}

- (void)boardViewDidEndTracking:(SDKBoardView *)board {
    if (self.loupePinned) return;
    [self.loupe hideAnimated:YES];
}

#pragma mark - Completion

- (void)handleCompletion {
    if (self.resultRecorded) return;
    self.resultRecorded = YES;
    self.game.finished = YES;
    self.game.paused = NO;
    [self stopTimer];
    [[SDKStore shared] recordGame:self.game];
    [[SDKStore shared] saveCurrentGame:nil];
    if ([SDKStore shared].hapticsEnabled) [SDKTheme notify:UINotificationFeedbackTypeSuccess];
    [self.board celebrateCompletion];
    [self showWinOverlay];
}

#pragma mark - Pause overlay

- (void)pauseGame {
    if (self.game.finished) return;
    self.game.paused = YES;
    [SDKTheme impact:UIImpactFeedbackStyleMedium];
    [self showPauseOverlay];
    [self saveGame];
}

- (void)showPauseOverlay {
    if (self.pauseOverlay) {
        [self.view bringSubviewToFront:self.pauseOverlay];
        return;
    }

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:overlay];
    self.pauseOverlay = overlay;

    CGFloat cardWidth = MIN(300.0, CGRectGetWidth(self.view.bounds) - 60.0);
    CGFloat cardHeight = 268.0;
    SDKGlassView *card = [[SDKGlassView alloc] initWithCornerRadius:28];
    card.tintAlpha = 0.10;
    card.sheenAlpha = 0.20;
    card.frame = CGRectMake((CGRectGetWidth(overlay.bounds) - cardWidth) / 2.0,
                            (CGRectGetHeight(overlay.bounds) - cardHeight) / 2.0,
                            cardWidth, cardHeight);
    card.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                            UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [overlay addSubview:card];
    card.userInteractionEnabled = YES;

    UILabel *title = [UILabel sdk_label:@"已暂停"
                                   font:[SDKTheme roundedFont:26 weight:UIFontWeightBold]
                                  color:[SDKTheme textPrimary]
                              alignment:NSTextAlignmentCenter];
    title.frame = CGRectMake(0, 26, cardWidth, 32);
    [card addSubview:title];

    UILabel *time = [UILabel sdk_label:[SDKTheme timeString:self.game.elapsedSeconds]
                                  font:[SDKTheme monoDigitFont:34 weight:UIFontWeightBold]
                                 color:[SDKTheme accent]
                             alignment:NSTextAlignmentCenter];
    time.frame = CGRectMake(0, 66, cardWidth, 42);
    [card addSubview:time];

    UILabel *sub = [UILabel sdk_label:[NSString stringWithFormat:@"%@ · 已完成 %ld/81",
                                      SDKDifficultyTitle(self.game.difficulty),
                                      (long)[self.game filledCount]]
                                 font:[SDKTheme roundedFont:13 weight:UIFontWeightMedium]
                                color:[SDKTheme textSecondary]
                            alignment:NSTextAlignmentCenter];
    sub.frame = CGRectMake(0, 112, cardWidth, 20);
    [card addSubview:sub];

    __weak typeof(self) weakSelf = self;
    SDKGlassButton *resume = [[SDKGlassButton alloc] initWithFrame:CGRectMake(22, 152, cardWidth - 44, 48)];
    resume.titleText = @"继续游戏";
    resume.symbolName = @"play.fill";
    resume.cornerRadius = 18;
    resume.accentStyle = YES;
    resume.titlePointSize = 16;
    resume.symbolPointSize = 15;
    resume.onTap = ^{ [weakSelf resumeGame]; };
    [card addSubview:resume];

    SDKGlassButton *restart = [[SDKGlassButton alloc] initWithFrame:CGRectMake(22, 208, cardWidth - 44, 44)];
    restart.titleText = @"重新开始";
    restart.symbolName = @"arrow.triangle.2.circlepath";
    restart.cornerRadius = 16;
    restart.titlePointSize = 15;
    restart.symbolPointSize = 14;
    restart.onTap = ^{ [weakSelf confirmRestart]; };
    [card addSubview:restart];

    card.transform = CGAffineTransformMakeScale(0.90, 0.90);
    overlay.alpha = 0.0;
    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.3
                        options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)resumeGame {
    self.game.paused = NO;
    UIView *overlay = self.pauseOverlay;
    self.pauseOverlay = nil;
    [self startTimer];
    [UIView animateWithDuration:0.20 animations:^{
        overlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

- (void)confirmRestart {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"重新开始"
                                            message:@"当前这局的进度会被清空，确定吗？"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [weakSelf restartGame];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)restartGame {
    SDKSudokuPuzzle *puzzle = [SDKSudokuPuzzle new];
    puzzle.puzzle = self.game.puzzle;
    puzzle.solution = self.game.solution;
    puzzle.difficulty = self.game.difficulty;
    puzzle.clueCount = 0;
    self.game = [SDKGameState gameWithPuzzle:puzzle];
    self.resultRecorded = NO;
    self.board.game = self.game;
    self.board.selectedIndex = -1;
    [[SDKStore shared] saveCurrentGame:self.game];

    if (self.pauseOverlay) {
        UIView *overlay = self.pauseOverlay;
        self.pauseOverlay = nil;
        [overlay removeFromSuperview];
    }
    if (self.winOverlay) {
        UIView *overlay = self.winOverlay;
        self.winOverlay = nil;
        [overlay removeFromSuperview];
    }
    [self refreshUI];
    [self startTimer];
}

- (void)startNewPuzzleForDifficulty:(SDKDifficulty)difficulty {
    [self stopTimer];
    SDKSudokuPuzzle *puzzle = [SDKSudokuEngine generatePuzzle:difficulty];
    self.game = [SDKGameState gameWithPuzzle:puzzle];
    self.resultRecorded = NO;
    self.board.game = self.game;
    self.board.selectedIndex = -1;
    self.difficultyLabel.text = SDKDifficultyTitle(difficulty);
    [[SDKStore shared] saveCurrentGame:self.game];
    [self refreshUI];
    [self startTimer];
}

#pragma mark - Win overlay

- (void)showWinOverlay {
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:overlay];
    self.winOverlay = overlay;

    CGFloat cardWidth = MIN(320.0, CGRectGetWidth(self.view.bounds) - 50.0);
    CGFloat cardHeight = 400.0;
    SDKGlassView *card = [[SDKGlassView alloc] initWithCornerRadius:30];
    card.tintAlpha = 0.10;
    card.sheenAlpha = 0.22;
    card.ambientSheen = YES;
    card.frame = CGRectMake((CGRectGetWidth(overlay.bounds) - cardWidth) / 2.0,
                            (CGRectGetHeight(overlay.bounds) - cardHeight) / 2.0,
                            cardWidth, cardHeight);
    card.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                            UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    card.userInteractionEnabled = YES;
    [overlay addSubview:card];

    UIImageView *trophy = [[UIImageView alloc] initWithFrame:CGRectMake(0, 26, cardWidth, 52)];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:44 weight:UIImageSymbolWeightSemibold];
    trophy.image = [[UIImage systemImageNamed:@"trophy.fill" withConfiguration:cfg]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    trophy.contentMode = UIViewContentModeCenter;
    trophy.tintColor = [SDKTheme gold];
    [card addSubview:trophy];

    UILabel *title = [UILabel sdk_label:@"恭喜完成！"
                                   font:[SDKTheme roundedFont:25 weight:UIFontWeightBold]
                                  color:[SDKTheme textPrimary]
                              alignment:NSTextAlignmentCenter];
    title.frame = CGRectMake(0, 84, cardWidth, 32);
    [card addSubview:title];

    UILabel *sub = [UILabel sdk_label:[NSString stringWithFormat:@"%@难度 · 无失误通关更酷",
                                      SDKDifficultyTitle(self.game.difficulty)]
                                 font:[SDKTheme roundedFont:13 weight:UIFontWeightMedium]
                                color:[SDKTheme textSecondary]
                            alignment:NSTextAlignmentCenter];
    sub.frame = CGRectMake(0, 116, cardWidth, 20);
    [card addSubview:sub];

    CGFloat rowY = 152.0;
    NSArray<NSString *> *titles = @[ @"用时", @"失误", @"提示" ];
    NSArray<NSString *> *values = @[ [SDKTheme timeString:self.game.elapsedSeconds],
                                     [NSString stringWithFormat:@"%ld", (long)self.game.mistakes],
                                     [NSString stringWithFormat:@"%ld", (long)self.game.hintsUsed] ];
    CGFloat colWidth = (cardWidth - 32.0) / 3.0;
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *value = [UILabel sdk_label:values[(NSUInteger)i]
                                       font:[SDKTheme monoDigitFont:22 weight:UIFontWeightBold]
                                      color:(i == 0) ? [SDKTheme accent] : [SDKTheme textPrimary]
                                  alignment:NSTextAlignmentCenter];
        value.frame = CGRectMake(16 + colWidth * i, rowY, colWidth, 28);
        [card addSubview:value];

        UILabel *caption = [UILabel sdk_label:titles[(NSUInteger)i]
                                         font:[SDKTheme roundedFont:11 weight:UIFontWeightMedium]
                                        color:[SDKTheme textTertiary]
                                    alignment:NSTextAlignmentCenter];
        caption.frame = CGRectMake(16 + colWidth * i, rowY + 30, colWidth, 16);
        [card addSubview:caption];
    }

    __weak typeof(self) weakSelf = self;
    SDKGlassButton *again = [[SDKGlassButton alloc] initWithFrame:CGRectMake(24, 244, cardWidth - 48, 50)];
    again.titleText = @"再来一局";
    again.symbolName = @"sparkles";
    again.cornerRadius = 18;
    again.accentStyle = YES;
    again.titlePointSize = 16;
    again.symbolPointSize = 16;
    again.onTap = ^{ [weakSelf playAgain]; };
    [card addSubview:again];

    SDKGlassButton *home = [[SDKGlassButton alloc] initWithFrame:CGRectMake(24, 304, cardWidth - 48, 48)];
    home.titleText = @"返回首页";
    home.symbolName = @"house.fill";
    home.cornerRadius = 16;
    home.titlePointSize = 15;
    home.symbolPointSize = 14;
    home.onTap = ^{ [weakSelf goHome]; };
    [card addSubview:home];

    card.transform = CGAffineTransformMakeScale(0.88, 0.88);
    overlay.alpha = 0.0;
    [UIView animateWithDuration:0.34 delay:0 usingSpringWithDamping:0.80 initialSpringVelocity:0.4
                        options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        overlay.alpha = 1.0;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];

    [self emitConfettiInView:overlay];
}

- (void)emitConfettiInView:(UIView *)host {
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = CGPointMake(CGRectGetMidX(host.bounds), -30.0);
    emitter.emitterShape = kCAEmitterLayerLine;
    emitter.emitterSize = CGSizeMake(CGRectGetWidth(host.bounds), 1.0);
    emitter.beginTime = CACurrentMediaTime();

    NSMutableArray *cells = [NSMutableArray array];
    NSArray<UIColor *> *palette = @[ [SDKTheme accent], [SDKTheme accentAlt], [SDKTheme gold], [SDKTheme success] ];
    UIImage *flake = [self confettiImage];
    for (UIColor *color in palette) {
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.contents = (id)flake.CGImage;
        cell.color = color.CGColor;
        cell.birthRate = 3.0;
        cell.lifetime = 7.0;
        cell.lifetimeRange = 2.0;
        cell.velocity = 180.0;
        cell.velocityRange = 90.0;
        cell.emissionLongitude = (CGFloat)M_PI_2;
        cell.emissionRange = (CGFloat)M_PI_4 * 0.6f;
        cell.yAcceleration = 190.0;
        cell.scale = 0.55;
        cell.scaleRange = 0.25;
        cell.spin = 3.0;
        cell.spinRange = 6.0;
        [cells addObject:cell];
    }
    emitter.emitterCells = cells;
    [host.layer addSublayer:emitter];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        emitter.birthRate = 0.0f;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [emitter removeFromSuperlayer];
        });
    });
}

- (UIImage *)confettiImage {
    CGSize size = CGSizeMake(16, 16);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(1, 4, 14, 8) cornerRadius:2.5];
        [[UIColor whiteColor] setFill];
        [path fill];
    }];
}

- (void)playAgain {
    SDKDifficulty difficulty = self.game.difficulty;
    if (self.winOverlay) {
        UIView *overlay = self.winOverlay;
        self.winOverlay = nil;
        [overlay removeFromSuperview];
    }
    [self startNewPuzzleForDifficulty:difficulty];
}

- (void)goHome {
    if (self.winOverlay) {
        UIView *overlay = self.winOverlay;
        self.winOverlay = nil;
        [overlay removeFromSuperview];
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
