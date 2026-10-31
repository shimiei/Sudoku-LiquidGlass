//
//  SDKGameViewController.m
//  Sudoku — Apple HIG rebuild
//
//  Standard pieces only: navigation bar, a rounded card for the grid,
//  UIButton.Configuration controls and UIAlertController for pause / results.
//

#import "SDKGameViewController.h"
#import "SDKBoardView.h"
#import "SDKCompletionOverlay.h"
#import "SDKBackdropView.h"
#import "SDKMaterial.h"
#import "SDKLoupeView.h"
#import "SDKStore.h"
#import "SDKDiagnostics.h"
#import "SDKTheme.h"

@interface SDKGameViewController () <SDKBoardViewDelegate>

@property (nonatomic, strong) SDKGameState *game;
@property (nonatomic, strong) SDKBoardView *board;
@property (nonatomic, strong, nullable) SDKLoupeView *loupe;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, copy) NSArray<UIButton *> *numberButtons;
@property (nonatomic, copy) NSArray<UIButton *> *actionButtons;

@property (nonatomic, strong) UIView *boardContainer;
@property (nonatomic, strong) UIStackView *actionRow;
@property (nonatomic, strong) UIStackView *numberRow;
@property (nonatomic, strong) UIStackView *controlsCompact;
@property (nonatomic, strong) UIStackView *controlsWide;
@property (nonatomic, strong) UIStackView *rootStack;
@property (nonatomic, strong) NSLayoutConstraint *rootMaxWidth;
@property (nonatomic, strong) NSLayoutConstraint *controlsWidth;
@property (nonatomic, strong) NSLayoutConstraint *boardPaneSquare;
@property (nonatomic) BOOL wideLayout;
@property (nonatomic) BOOL didApplyLayout;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *redoButton;
@property (nonatomic, strong) UIButton *noteButton;
@property (nonatomic, strong) UIButton *hintButton;

@property (nonatomic, strong, nullable) NSTimer *timer;
@property (nonatomic) BOOL resultRecorded;
@property (nonatomic) BOOL gestureActive;
@property (nonatomic) CGPoint downPoint;
@property (nonatomic) NSInteger autosaveTick;
@property (nonatomic) BOOL suppressAutosave;

@end

@implementation SDKGameViewController

#pragma mark - Init

- (instancetype)initWithDifficulty:(SDKDifficulty)difficulty {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        SDKSudokuPuzzle *puzzle = [SDKSudokuEngine generatePuzzle:difficulty];
        _game = [SDKGameState gameWithPuzzle:puzzle];
        [[SDKStore shared] saveCurrentGame:_game];
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

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithDifficulty:SDKDifficultyEasy];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildNavigationBar];
    [self buildContent];

    self.game.selectedIndex = -1;
    [self applySettings];
    [self refreshUI];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applySettings];
    [self refreshUI];
    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
    [self saveGame];
}

- (void)saveGame {
    if (!self.game || self.game.finished || self.suppressAutosave) return;
    [[SDKStore shared] saveCurrentGame:self.game];
}

#pragma mark - Navigation bar

- (void)buildNavigationBar {
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [SDKTheme timerFont];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ self.titleLabel, self.statusLabel ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 0;
    self.navigationItem.titleView = stack;

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"pause.fill"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(pauseTapped)];
}

#pragma mark - Content

- (void)buildContent {
    // 玻璃要有东西可折射，垫一层极淡的系统色光晕（不抢注意力）
    SDKBackdropView *backdrop = [[SDKBackdropView alloc] initWithFrame:self.view.bounds];
    backdrop.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:backdrop];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    UIView *boardContainer = [UIView new];
    boardContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardContainer = boardContainer;

    self.board = [[SDKBoardView alloc] initWithFrame:CGRectZero];
    self.board.translatesAutoresizingMaskIntoConstraints = NO;
    self.board.delegate = self;
    self.board.game = self.game;
    self.board.contentInset = 12.0;

    // iOS 26：真正的液态玻璃板；旧系统：语义色卡片
    BOOL glass = [SDKMaterial glassAvailable];
    UIView *panel = [SDKMaterial panelWithCornerRadius:26.0];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    [boardContainer addSubview:panel];
    [boardContainer addSubview:self.board];
    [self.board useGlassPanel:glass];
    [NSLayoutConstraint activateConstraints:@[
        [panel.leadingAnchor constraintEqualToAnchor:self.board.leadingAnchor],
        [panel.trailingAnchor constraintEqualToAnchor:self.board.trailingAnchor],
        [panel.topAnchor constraintEqualToAnchor:self.board.topAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:self.board.bottomAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.board.centerXAnchor constraintEqualToAnchor:boardContainer.centerXAnchor],
        [self.board.centerYAnchor constraintEqualToAnchor:boardContainer.centerYAnchor],
        [self.board.widthAnchor constraintEqualToAnchor:self.board.heightAnchor],
        [self.board.widthAnchor constraintLessThanOrEqualToAnchor:boardContainer.widthAnchor],
        [self.board.widthAnchor constraintLessThanOrEqualToAnchor:boardContainer.heightAnchor],
    ]];
    NSLayoutConstraint *fill = [self.board.widthAnchor constraintEqualToAnchor:boardContainer.widthAnchor];
    fill.priority = 750;
    fill.active = YES;

    NSArray<NSString *> *titles = @[ @"撤销", @"重做", @"擦除", @"笔记", @"全笔记", @"提示" ];
    NSArray<NSString *> *symbols = @[ @"arrow.uturn.backward", @"arrow.uturn.forward", @"delete.left",
                                      @"pencil", @"square.grid.3x3", @"lightbulb" ];
    NSMutableArray<UIButton *> *actions = [NSMutableArray array];
    for (NSUInteger i = 0; i < titles.count; i++) {
        UIButton *b = [self actionButtonWithTitle:titles[i] symbol:symbols[i]];
        b.tag = (NSInteger)i;
        [b addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [actions addObject:b];
    }
    self.undoButton = actions[0];
    self.redoButton = actions[1];
    self.noteButton = actions[3];
    self.hintButton = actions[5];

    self.actionButtons = actions;
    UIStackView *actionRow = [[UIStackView alloc] initWithArrangedSubviews:actions];
    actionRow.axis = UILayoutConstraintAxisHorizontal;
    actionRow.distribution = UIStackViewDistributionFillEqually;
    actionRow.spacing = 8.0;
    actionRow.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionRow = actionRow;
    for (UIButton *b in actions) {
        [b.heightAnchor constraintGreaterThanOrEqualToConstant:50.0].active = YES;
    }

    NSMutableArray<UIButton *> *numbers = [NSMutableArray array];
    for (NSInteger digit = 1; digit <= 9; digit++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.tag = digit;
        b.configuration = [self digitConfigurationForDigit:digit remaining:9];
        [b addTarget:self action:@selector(digitTapped:) forControlEvents:UIControlEventTouchUpInside];
        [numbers addObject:b];
    }
    self.numberButtons = numbers;

    UIStackView *numberRow = [[UIStackView alloc] initWithArrangedSubviews:numbers];
    numberRow.axis = UILayoutConstraintAxisHorizontal;
    numberRow.distribution = UIStackViewDistributionFillEqually;
    numberRow.spacing = 5.0;
    numberRow.translatesAutoresizingMaskIntoConstraints = NO;
    for (UIButton *b in numbers) {
        [b.heightAnchor constraintGreaterThanOrEqualToConstant:54.0].active = YES;
    }
    self.numberRow = numberRow;

    // 两套控制区容器：竖排（手机 / 分屏）与右栏（iPad 横屏），运行时切换
    UIStackView *controlsCompact = [[UIStackView alloc] initWithArrangedSubviews:@[ actionRow, numberRow ]];
    controlsCompact.axis = UILayoutConstraintAxisVertical;
    controlsCompact.spacing = 14.0;
    controlsCompact.translatesAutoresizingMaskIntoConstraints = NO;
    self.controlsCompact = controlsCompact;

    UIStackView *controlsWide = [[UIStackView alloc] init];
    controlsWide.axis = UILayoutConstraintAxisVertical;
    controlsWide.spacing = 18.0;
    controlsWide.translatesAutoresizingMaskIntoConstraints = NO;
    self.controlsWide = controlsWide;

    UIStackView *root = [[UIStackView alloc] initWithArrangedSubviews:@[ boardContainer, controlsCompact ]];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 14.0;
    root.alignment = UIStackViewAlignmentFill;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    self.rootStack = root;
    [boardContainer setContentHuggingPriority:UILayoutPriorityDefaultLow - 1
                               forAxis:UILayoutConstraintAxisVertical];
    [self.view addSubview:root];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    NSLayoutConstraint *fullWidth = [root.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-32.0];
    fullWidth.priority = UILayoutPriorityRequired - 1;
    self.rootMaxWidth = [root.widthAnchor constraintLessThanOrEqualToConstant:520.0];
    self.controlsWidth = [controlsWide.widthAnchor constraintEqualToConstant:368.0];
    // 只是观感约束：宽屏时让棋盘面板尽量方，但优先服从安全区宽度
    self.boardPaneSquare = [boardContainer.widthAnchor constraintEqualToAnchor:boardContainer.heightAnchor];
    self.boardPaneSquare.priority = 750;
    [NSLayoutConstraint activateConstraints:@[
        [root.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10.0],
        [root.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12.0],
        [root.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        self.rootMaxWidth,
        fullWidth,
    ]];

    [self arrangeButtonsForColumns:0];
}

#pragma mark - Adaptive layout (iPhone / iPad)

/// iPad 横屏（或够宽的 regular 宽度）时，棋盘在左、控制区在右。
- (BOOL)shouldUseWideLayout {
    if (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) return NO;
    CGSize size = self.view.bounds.size;
    if (size.width < 700.0) return NO;
    return size.width > size.height * 0.82;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self applyAdaptiveLayout];
}

- (void)applyAdaptiveLayout {
    BOOL wide = [self shouldUseWideLayout];
    if (self.didApplyLayout && wide == self.wideLayout) return;
    self.didApplyLayout = YES;
    self.wideLayout = wide;

    // UIView 只能有一个父视图：先全部摘下来，再挂到目标容器
    [self.actionRow removeFromSuperview];
    [self.numberRow removeFromSuperview];
    for (UIView *v in [self.controlsCompact.arrangedSubviews copy]) [v removeFromSuperview];
    for (UIView *v in [self.controlsWide.arrangedSubviews copy]) [v removeFromSuperview];
    for (UIView *v in [self.rootStack.arrangedSubviews copy]) {
        if (v != self.boardContainer) [v removeFromSuperview];
    }

    self.rootMaxWidth.constant = wide ? 1120.0 : 520.0;
    self.rootStack.axis = wide ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    self.rootStack.spacing = wide ? 30.0 : 14.0;

    if (wide) {
        [self.controlsWide addArrangedSubview:self.actionRow];
        [self.controlsWide addArrangedSubview:self.numberRow];
        [self.rootStack addArrangedSubview:self.controlsWide];
        self.controlsWidth.active = YES;
        self.boardPaneSquare.active = YES;
        [self arrangeButtonsForColumns:3];
    } else {
        [self.controlsCompact addArrangedSubview:self.actionRow];
        [self.controlsCompact addArrangedSubview:self.numberRow];
        [self.rootStack addArrangedSubview:self.controlsCompact];
        self.controlsWidth.active = NO;
        self.boardPaneSquare.active = NO;
        [self arrangeButtonsForColumns:0];
    }
    [self.view setNeedsLayout];
}

/// columns == 0 为单行铺满，3 为三列网格。
- (void)arrangeButtonsForColumns:(NSInteger)columns {
    [self arrangeLane:self.actionRow buttons:self.actionButtons columns:columns spacing:8.0];
    [self arrangeLane:self.numberRow buttons:self.numberButtons columns:columns spacing:6.0];
}

- (void)arrangeLane:(UIStackView *)lane
            buttons:(NSArray<UIButton *> *)buttons
            columns:(NSInteger)columns
            spacing:(CGFloat)spacing {
    if (!lane || buttons.count == 0) return;
    for (UIView *v in [lane.arrangedSubviews copy]) [v removeFromSuperview];

    if (columns <= 1) {
        lane.axis = UILayoutConstraintAxisHorizontal;
        lane.distribution = UIStackViewDistributionFillEqually;
        lane.spacing = spacing;
        for (UIButton *b in buttons) [lane addArrangedSubview:b];
        return;
    }

    lane.axis = UILayoutConstraintAxisVertical;
    lane.distribution = UIStackViewDistributionFillEqually;
    lane.spacing = 10.0;
    NSInteger count = (NSInteger)buttons.count;
    for (NSInteger i = 0; i < count; i += columns) {
        NSInteger limit = MIN(i + columns, count);
        NSMutableArray<UIButton *> *rowButtons = [NSMutableArray array];
        for (NSInteger j = i; j < limit; j++) [rowButtons addObject:buttons[(NSUInteger)j]];
        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:rowButtons];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.distribution = UIStackViewDistributionFillEqually;
        row.spacing = 10.0;
        [lane addArrangedSubview:row];
    }
}

- (UIButton *)actionButtonWithTitle:(NSString *)title symbol:(NSString *)symbol {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *c = [SDKMaterial glassButtonConfigurationProminent:NO];
    if (!c) {
        c = [UIButtonConfiguration tintedButtonConfiguration];
        c.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        c.contentInsets = NSDirectionalEdgeInsetsMake(5.0, 1.0, 5.0, 1.0);
    }
    c.image = [UIImage systemImageNamed:symbol];
    c.preferredSymbolConfigurationForImage =
        [UIImageSymbolConfiguration configurationWithPointSize:15.0 weight:UIImageSymbolWeightSemibold];
    c.imagePlacement = NSDirectionalRectEdgeTop;
    c.imagePadding = 3.0;
    // Fixed size: these sit in a fixed-height toolbar, so they must not grow.
    UIFont *font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium];
    c.attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                       attributes:@{ NSFontAttributeName : font,
                                                                     NSForegroundColorAttributeName : [UIColor labelColor] }];
    b.configuration = c;
    return b;
}

- (UIButtonConfiguration *)digitConfigurationForDigit:(NSInteger)digit remaining:(NSInteger)remaining {
    UIButtonConfiguration *c = [SDKMaterial glassButtonConfigurationProminent:NO];
    if (!c) {
        c = [UIButtonConfiguration grayButtonConfiguration];
        c.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        c.contentInsets = NSDirectionalEdgeInsetsMake(3.0, 0.0, 3.0, 0.0);
    }
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:21.0 weight:UIFontWeightMedium];
    c.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)digit]
                                                        attributes:@{ NSFontAttributeName : font,
                                                                      NSForegroundColorAttributeName : [UIColor labelColor] }];
    if (remaining > 0 && remaining < 9) {
        UIFont *small = [UIFont monospacedDigitSystemFontOfSize:9.0 weight:UIFontWeightRegular];
        NSMutableParagraphStyle *p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        c.attributedSubtitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)remaining]
                                                                attributes:@{ NSFontAttributeName : small,
                                                                              NSForegroundColorAttributeName : [UIColor secondaryLabelColor],
                                                                              NSParagraphStyleAttributeName : p }];
    }
    return c;
}

#pragma mark - Settings / refresh

- (void)applySettings {
    SDKStore *store = [SDKStore shared];
    self.board.highlightPeers = store.highlightPeers;
    self.board.highlightSameNumbers = store.highlightSameNumbers;
    self.board.showConflicts = store.showConflicts;
    self.board.autoCheck = store.autoCheck;
    self.board.game = self.game;
}

- (void)refreshUI {
    self.titleLabel.text = SDKDifficultyTitle(self.game.difficulty);
    [self refreshStatus];

    self.board.selectedIndex = self.game.selectedIndex;
    [self.board reloadData];

    for (NSUInteger i = 0; i < self.numberButtons.count; i++) {
        NSInteger digit = (NSInteger)i + 1;
        NSInteger placedCorrectly = 0;
        for (NSInteger cell = 0; cell < 81; cell++) {
            if ([self.game valueAtIndex:cell] == digit && ![self.game isWrongAtIndex:cell]) {
                placedCorrectly++;
            }
        }
        NSInteger needed = MAX(0, 9 - placedCorrectly);
        UIButton *b = self.numberButtons[i];
        b.configuration = [self digitConfigurationForDigit:digit remaining:needed];
        b.enabled = (needed > 0);
    }

    self.undoButton.enabled = self.game.canUndo;
    self.redoButton.enabled = self.game.canRedo;

    UIButtonConfiguration *note = nil;
    if (self.game.noteMode) {
        note = [SDKMaterial glassButtonConfigurationProminent:YES];
        if (!note) note = [UIButtonConfiguration filledButtonConfiguration];
    } else {
        note = [SDKMaterial glassButtonConfigurationProminent:NO];
        if (!note) note = [UIButtonConfiguration tintedButtonConfiguration];
    }
    UIFont *font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium];
    note.attributedTitle = [[NSAttributedString alloc] initWithString:(self.game.noteMode ? @"笔记中" : @"笔记")
                                                          attributes:@{ NSFontAttributeName : font,
                                                                        NSForegroundColorAttributeName :
                                                                            (self.game.noteMode ? [UIColor whiteColor] : [UIColor labelColor]) }];
    note.image = [UIImage systemImageNamed:(self.game.noteMode ? @"pencil.circle.fill" : @"pencil")];
    note.preferredSymbolConfigurationForImage =
        [UIImageSymbolConfiguration configurationWithPointSize:15.0 weight:UIImageSymbolWeightSemibold];
    note.imagePlacement = NSDirectionalRectEdgeTop;
    note.imagePadding = 3.0;
    self.noteButton.configuration = note;
}

- (void)refreshStatus {
    self.statusLabel.text = [SDKTheme statusLineWithSeconds:self.game.elapsedSeconds
                                                  mistakes:self.game.mistakes];
    self.titleLabel.text = SDKDifficultyTitle(self.game.difficulty);
    UIView *titleView = self.navigationItem.titleView;
    [titleView invalidateIntrinsicContentSize];
    [titleView setNeedsLayout];
}

#pragma mark - Timer

- (void)startTimer {
    if (self.timer || self.game.finished) return;
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(tick)
                                      userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick {
    if (self.game.finished) {
        [self stopTimer];
        return;
    }
    self.game.elapsedSeconds += 1;
    [self refreshStatus];

    self.autosaveTick += 1;
    if (self.autosaveTick >= 10) {
        self.autosaveTick = 0;
        [self saveGame];
    }
}

#pragma mark - Actions

- (void)actionTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 0: [self undo]; break;
        case 1: [self redo]; break;
        case 2: [self erase]; break;
        case 3: [self toggleNoteMode]; break;
        case 4: [self fillAllNotes]; break;
        case 5: [self applyHint]; break;
        default: break;
    }
}

- (void)digitTapped:(UIButton *)sender {
    if (self.game.finished) return;
    NSInteger digit = sender.tag;
    NSInteger index = self.game.selectedIndex;
    if (index < 0) {
        [self requireSelection];
        return;
    }

    SDKPlaceResult result;
    if (self.game.noteMode) {
        result = [self.game toggleNote:digit atIndex:index];
        [SDKTheme impact:UIImpactFeedbackStyleLight];
        [self refreshUI];
        return;
    }

    result = [self.game placeValue:digit atIndex:index];
    switch (result) {
        case SDKPlaceResultCorrect:
            [SDKTheme impact:UIImpactFeedbackStyleLight];
            [self.board pulseAtIndex:index color:[SDKTheme userColor]];
            break;
        case SDKPlaceResultWrong:
            [SDKTheme notify:UINotificationFeedbackTypeError];
            [self.board flashIndex:index color:[SDKTheme errorFill]];
            break;
        case SDKPlaceResultCompleted:
            [self refreshUI];
            [self handleCompletion];
            return;
        default:
            break;
    }
    [self refreshUI];
    [self autoAdvanceIfNeeded];
}

- (void)undo {
    if (![self.game undo]) return;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self refreshUI];
}

- (void)redo {
    if (![self.game redo]) return;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self refreshUI];
}

- (void)erase {
    NSInteger index = self.game.selectedIndex;
    if (index < 0) {
        [self requireSelection];
        return;
    }
    if ([self.game eraseAtIndex:index] == SDKPlaceResultInvalid) return;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self refreshUI];
}

- (void)toggleNoteMode {
    self.game.noteMode = !self.game.noteMode;
    [SDKTheme selection];
    [self refreshUI];
}

- (void)fillAllNotes {
    [self.game fillAllNotes];
    [SDKTheme impact:UIImpactFeedbackStyleMedium];
    [self refreshUI];
}

- (void)applyHint {
    if (self.game.finished) return;
    NSNumber *filled = [self.game applyHintAtIndex:self.game.selectedIndex];
    if (!filled) {
        [self presentSimpleAlertWithTitle:@"没有可提示的格子" message:@"棋盘已经填满了。"];
        return;
    }
    NSInteger index = filled.integerValue;
    self.game.selectedIndex = index;
    [SDKTheme notify:UINotificationFeedbackTypeSuccess];
    [self refreshUI];
    [self.board flashIndex:index color:[SDKTheme selectFill]];
    if (self.game.finished) [self handleCompletion];
}

- (void)requireSelection {
    [SDKTheme notify:UINotificationFeedbackTypeWarning];
    [self presentSimpleAlertWithTitle:@"先选一个格子" message:@"点一下棋盘上的空格，或按住拖动查看放大镜。"];
}

- (void)autoAdvanceIfNeeded {
    // keep the current selection; the player chooses where to go next
}

#pragma mark - Pause

- (void)pauseTapped {
    if (self.game.finished) return;
    if (self.presentedViewController) return;
    [self stopTimer];
    [self saveGame];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已暂停"
                                                                  message:@"计时已经停止。"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"继续游戏" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        [weakSelf startTimer];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"重新开始" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *a) {
        [weakSelf restartGame];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"结束本局" style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a) {
        [weakSelf endCurrentGame];
    }]];
    [self presentAlert:alert];
}

- (void)restartGame {
    SDKSudokuPuzzle *puzzle = [SDKSudokuEngine generatePuzzle:self.game.difficulty];
    SDKGameState *fresh = [SDKGameState gameWithPuzzle:puzzle];
    self.game = fresh;
    self.resultRecorded = NO;
    self.game.selectedIndex = -1;
    [self applySettings];
    [self refreshUI];
    [self startTimer];
    [[SDKStore shared] saveCurrentGame:fresh];

    // 新的一局：棋盘轻轻落下来，接上庆祝层的节奏
    if (!UIAccessibilityIsReduceMotionEnabled()) {
        self.board.transform = CGAffineTransformMakeScale(0.97, 0.97);
        self.board.alpha = 0.0;
        [UIView animateWithDuration:0.45 delay:0
             usingSpringWithDamping:0.86 initialSpringVelocity:0.2
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.board.transform = CGAffineTransformIdentity;
            self.board.alpha = 1.0;
        } completion:nil];
    }
}

- (void)endCurrentGame {
    self.suppressAutosave = YES;
    if (!self.game.finished && self.game.filledCount > 0) {
        NSInteger givens = 0;
        for (NSNumber *n in self.game.puzzle) if (n.integerValue != 0) givens++;
        if (self.game.filledCount > givens) [[SDKStore shared] recordGame:self.game];
    }
    [[SDKStore shared] saveCurrentGame:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleAppBackground {
    [self stopTimer];
    [self saveGame];
    self.game.paused = YES;
}

- (void)handleAppForeground {
    if (self.game.finished) return;
    if (self.presentedViewController) return;
    self.game.paused = YES;
    [self pauseTapped];
}

#pragma mark - Completion

- (void)handleCompletion {
    if (self.resultRecorded) return;
    self.resultRecorded = YES;
    SDKStep(@"completion.begin");
    [self stopTimer];
    // 庆祝效果再花哨也不能把刚打完的一局带崩：每一步都留面包屑，出错只降级不闪退
    @try {
        [self.board playCompletionWave];
    } @catch (NSException *exception) {
        SDKStep([NSString stringWithFormat:@"completion.wave:%@", exception.name ?: @"?"]);
    }
    [SDKTheme notify:UINotificationFeedbackTypeSuccess];

    // 先看历史最佳，再写入，才能判断这一局是不是新纪录
    NSDictionary *before = [[SDKStore shared] statsForDifficulty:self.game.difficulty];
    NSInteger previousBest = [before[@"best"] integerValue];
    BOOL isBest = (previousBest == 0 || (self.game.elapsedSeconds > 0 &&
                                         self.game.elapsedSeconds < previousBest));

    SDKStep(@"completion.stats");
    [[SDKStore shared] recordGame:self.game];
    [[SDKStore shared] saveCurrentGame:nil];
    SDKStep(@"completion.saved");

    __weak typeof(self) weakSelf = self;
    @try {
        SDKCompletionOverlay *overlay =
            [[SDKCompletionOverlay alloc] initWithDifficulty:self.game.difficulty
                                                     seconds:self.game.elapsedSeconds
                                                    mistakes:self.game.mistakes
                                                       hints:self.game.hintsUsed
                                                      isBest:isBest];
        UIView *host = self.navigationController.view ?: self.view;
        [overlay presentInView:host completion:^(SDKCompletionAction action) {
            SDKStep(@"completion.action");
            if (action == SDKCompletionActionReplay) {
                [weakSelf restartGame];
            } else {
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    } @catch (NSException *exception) {
        SDKStep([NSString stringWithFormat:@"completion.overlay:%@:%@",
                 exception.name ?: @"?", exception.reason ?: @""]);
        // 庆祝层出问题就退回最朴素的提示，至少让这一局有始有终
        NSString *message = [NSString stringWithFormat:@"用时 %@，失误 %ld 次，提示 %ld 次。",
                             [SDKTheme timeString:self.game.elapsedSeconds],
                             (long)self.game.mistakes, (long)self.game.hintsUsed];
        [self presentSimpleAlertWithTitle:@"完成啦" message:message];
    }
    SDKStep(@"completion.done");
}

/// Presents an alert safely: never while another presentation is in flight.
- (void)presentAlert:(UIAlertController *)alert {
    if (self.presentedViewController) {
        __weak typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:NO completion:^{
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
        return;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentSimpleAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentAlert:alert];
}

#pragma mark - SDKBoardViewDelegate

- (void)boardView:(SDKBoardView *)boardView didSelectIndex:(NSInteger)index {
    self.game.selectedIndex = index;
    [self refreshUI];
}

- (void)boardView:(SDKBoardView *)boardView
   didMoveFingerTo:(CGPoint)point
        cellIndex:(NSInteger)index
      insideBoard:(BOOL)inside {
    if (![SDKStore shared].loupeEnabled) return;

    CGPoint p = [self.view convertPoint:point fromView:boardView];
    if (!self.gestureActive) {
        self.gestureActive = YES;
        self.downPoint = p;
        return;
    }
    if (!self.loupe) self.loupe = [SDKLoupeView new];
    if (!self.loupe.isVisible) {
        CGFloat dx = p.x - self.downPoint.x;
        CGFloat dy = p.y - self.downPoint.y;
        if (dx * dx + dy * dy < 100.0) return;   // wait until the finger really moves
    }
    if (index < 0 || !inside) {
        [self.loupe hide];
        return;
    }
    CGFloat radius = self.loupe.diameter / 2.0;
    CGFloat gap = 26.0;
    CGFloat minY = self.view.safeAreaInsets.top + 8.0;
    CGFloat targetY = p.y - radius - gap;
    if (targetY - radius < minY) targetY = p.y + radius + gap;
    CGPoint target = CGPointMake(p.x, targetY);

    if (!self.loupe.isVisible) {
        [self.loupe showInHost:self.view atCenter:target board:self.board focusIndex:index];
    } else {
        [self.loupe moveToCenter:target board:self.board focusIndex:index];
    }
}

- (void)boardViewDidEndTracking:(SDKBoardView *)boardView {
    self.gestureActive = NO;
    [self.loupe hide];
}

@end
