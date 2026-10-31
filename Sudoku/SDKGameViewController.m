//
//  SDKGameViewController.m
//  Sudoku — Apple HIG rebuild
//
//  Standard pieces only: navigation bar, a rounded card for the grid,
//  UIButton.Configuration controls and UIAlertController for pause / results.
//

#import "SDKGameViewController.h"
#import "SDKBoardView.h"
#import "SDKLoupeView.h"
#import "SDKStore.h"
#import "SDKTheme.h"

@interface SDKGameViewController () <SDKBoardViewDelegate>

@property (nonatomic, strong) SDKGameState *game;
@property (nonatomic, strong) SDKBoardView *board;
@property (nonatomic, strong, nullable) SDKLoupeView *loupe;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, copy) NSArray<UIButton *> *numberButtons;
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
    UIView *boardContainer = [UIView new];
    boardContainer.translatesAutoresizingMaskIntoConstraints = NO;

    self.board = [[SDKBoardView alloc] initWithFrame:CGRectZero];
    self.board.translatesAutoresizingMaskIntoConstraints = NO;
    self.board.delegate = self;
    self.board.game = self.game;
    [boardContainer addSubview:self.board];

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

    UIStackView *actionRow = [[UIStackView alloc] initWithArrangedSubviews:actions];
    actionRow.axis = UILayoutConstraintAxisHorizontal;
    actionRow.distribution = UIStackViewDistributionFillEqually;
    actionRow.spacing = 8.0;
    actionRow.translatesAutoresizingMaskIntoConstraints = NO;
    [actionRow.heightAnchor constraintEqualToConstant:52.0].active = YES;

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
    [numberRow.heightAnchor constraintEqualToConstant:54.0].active = YES;

    UIStackView *root = [[UIStackView alloc] initWithArrangedSubviews:@[ boardContainer, actionRow, numberRow ]];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 14.0;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    [boardContainer setContentHuggingPriority:UILayoutPriorityDefaultLow - 1
                               forAxis:UILayoutConstraintAxisVertical];
    [self.view addSubview:root];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    // Readable width: fill the screen, but never wider than 520pt on iPad.
    NSLayoutConstraint *fullWidth = [root.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-32.0];
    fullWidth.priority = UILayoutPriorityRequired - 1;
    [NSLayoutConstraint activateConstraints:@[
        [root.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10.0],
        [root.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12.0],
        [root.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [root.widthAnchor constraintLessThanOrEqualToConstant:520.0],
        fullWidth,
    ]];
}

- (UIButton *)actionButtonWithTitle:(NSString *)title symbol:(NSString *)symbol {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *c = [UIButtonConfiguration tintedButtonConfiguration];
    c.image = [UIImage systemImageNamed:symbol];
    c.preferredSymbolConfigurationForImage =
        [UIImageSymbolConfiguration configurationWithPointSize:15.0 weight:UIImageSymbolWeightSemibold];
    c.imagePlacement = NSDirectionalRectEdgeTop;
    c.imagePadding = 3.0;
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    c.attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                       attributes:@{ NSFontAttributeName : font }];
    c.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    c.contentInsets = NSDirectionalEdgeInsetsMake(5.0, 1.0, 5.0, 1.0);
    b.configuration = c;
    return b;
}

- (UIButtonConfiguration *)digitConfigurationForDigit:(NSInteger)digit remaining:(NSInteger)remaining {
    UIButtonConfiguration *c = [UIButtonConfiguration grayButtonConfiguration];
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:21.0 weight:UIFontWeightMedium];
    c.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)digit]
                                                        attributes:@{ NSFontAttributeName : font }];
    if (remaining > 0 && remaining < 9) {
        UIFont *small = [UIFont monospacedDigitSystemFontOfSize:9.0 weight:UIFontWeightRegular];
        NSMutableParagraphStyle *p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        c.attributedSubtitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)remaining]
                                                                attributes:@{ NSFontAttributeName : small,
                                                                              NSForegroundColorAttributeName : [UIColor secondaryLabelColor],
                                                                              NSParagraphStyleAttributeName : p }];
    }
    c.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    c.contentInsets = NSDirectionalEdgeInsetsMake(3.0, 0.0, 3.0, 0.0);
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
        NSInteger remaining = [self.game remainingForValue:digit];
        UIButton *b = self.numberButtons[i];
        b.configuration = [self digitConfigurationForDigit:digit remaining:remaining];
        b.enabled = (remaining > 0);
    }

    self.undoButton.enabled = self.game.canUndo;
    self.redoButton.enabled = self.game.canRedo;

    UIButtonConfiguration *note = self.noteButton.configuration;
    note = self.game.noteMode ? [UIButtonConfiguration filledButtonConfiguration]
                              : [UIButtonConfiguration tintedButtonConfiguration];
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    note.attributedTitle = [[NSAttributedString alloc] initWithString:(self.game.noteMode ? @"笔记中" : @"笔记")
                                                          attributes:@{ NSFontAttributeName : font }];
    note.image = [UIImage systemImageNamed:(self.game.noteMode ? @"pencil.circle.fill" : @"pencil")];
    note.preferredSymbolConfigurationForImage =
        [UIImageSymbolConfiguration configurationWithPointSize:15.0 weight:UIImageSymbolWeightSemibold];
    note.imagePlacement = NSDirectionalRectEdgeTop;
    note.imagePadding = 2.0;
    note.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    note.contentInsets = NSDirectionalEdgeInsetsMake(5.0, 1.0, 5.0, 1.0);
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
    [self presentViewController:alert animated:YES completion:nil];
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
    [self stopTimer];
    [self.board celebrateCompletion];
    [SDKTheme notify:UINotificationFeedbackTypeSuccess];

    [[SDKStore shared] recordGame:self.game];
    [[SDKStore shared] saveCurrentGame:nil];

    NSString *message = [NSString stringWithFormat:@"用时 %@，失误 %ld 次，提示 %ld 次。\n%@",
                         [SDKTheme timeString:self.game.elapsedSeconds],
                         (long)self.game.mistakes, (long)self.game.hintsUsed,
                         [SDKTheme randomPraise]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"完成啦"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"再来一局" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        [weakSelf restartGame];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"返回首页" style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a) {
        [weakSelf.navigationController popToRootViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentSimpleAlertWithTitle:(NSString *)title message:(NSString *)message {
    if (self.presentedViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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
    if (!self.loupe.superview) {
        CGFloat dx = p.x - self.downPoint.x;
        CGFloat dy = p.y - self.downPoint.y;
        if (dx * dx + dy * dy < 100.0) return;   // wait until the finger really moves
    }
    if (index < 0 || !inside) {
        [self.loupe hide];
        return;
    }

    if (!self.loupe) self.loupe = [SDKLoupeView new];
    CGFloat radius = self.loupe.diameter / 2.0;
    CGFloat gap = 26.0;
    CGFloat minY = self.view.safeAreaInsets.top + 8.0;
    CGFloat targetY = p.y - radius - gap;
    if (targetY - radius < minY) targetY = p.y + radius + gap;
    CGPoint target = CGPointMake(p.x, targetY);

    if (!self.loupe.superview) {
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
