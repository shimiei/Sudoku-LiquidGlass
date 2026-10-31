//
//  SDKHistoryViewController.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKHistoryViewController.h"
#import "SDKTheme.h"
#import "SDKGlass.h"
#import "SDKAuroraView.h"
#import "SDKBarChartView.h"
#import "SDKStore.h"

#pragma mark - Record cell

@interface SDKHistoryCell : UITableViewCell
@property (nonatomic, strong) SDKGlassView *card;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *statusLabel;
- (void)configureWithRecord:(NSDictionary *)record;
@end

@implementation SDKHistoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _card = [[SDKGlassView alloc] initWithCornerRadius:20];
        _card.tintAlpha = 0.06;
        _card.showsShadow = NO;
        [self.contentView addSubview:_card];

        _badgeLabel = [UILabel sdk_label:nil font:[SDKTheme roundedFont:12 weight:UIFontWeightBold]
                                  color:[SDKTheme accent] alignment:NSTextAlignmentCenter];
        _badgeLabel.backgroundColor = [[SDKTheme accent] colorWithAlphaComponent:0.14];
        _badgeLabel.layer.cornerRadius = 9;
        _badgeLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:_badgeLabel];

        _dateLabel = [UILabel sdk_label:nil font:[SDKTheme roundedFont:12 weight:UIFontWeightMedium]
                                 color:[SDKTheme textSecondary] alignment:NSTextAlignmentLeft];
        [self.contentView addSubview:_dateLabel];

        _durationLabel = [UILabel sdk_label:nil font:[SDKTheme monoDigitFont:20 weight:UIFontWeightBold]
                                     color:[SDKTheme textPrimary] alignment:NSTextAlignmentLeft];
        [self.contentView addSubview:_durationLabel];

        _statusLabel = [UILabel sdk_label:nil font:[SDKTheme roundedFont:12 weight:UIFontWeightSemibold]
                                   color:[SDKTheme success] alignment:NSTextAlignmentRight];
        [self.contentView addSubview:_statusLabel];
    }
    return self;
}

- (void)configureWithRecord:(NSDictionary *)record {
    NSInteger difficulty = [record[@"difficulty"] integerValue];
    NSString *title = SDKDifficultyTitle((SDKDifficulty)difficulty);
    self.badgeLabel.text = title;

    UIColor *tint = [SDKTheme accent];
    if (difficulty == SDKDifficultyMedium) tint = [SDKTheme accentAlt];
    if (difficulty == SDKDifficultyHard) tint = [SDKTheme accentWarm];
    self.badgeLabel.textColor = tint;
    self.badgeLabel.backgroundColor = [tint colorWithAlphaComponent:0.15];

    NSTimeInterval ts = [record[@"date"] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MM月dd日 HH:mm";
    self.dateLabel.text = [fmt stringFromDate:date];

    self.durationLabel.text = [SDKTheme timeString:[record[@"seconds"] integerValue]];

    BOOL completed = [record[@"completed"] boolValue];
    if (completed) {
        NSInteger mistakes = [record[@"mistakes"] integerValue];
        self.statusLabel.text = mistakes > 0
            ? [NSString stringWithFormat:@"完成 · 失误 %ld", (long)mistakes]
            : @"完成 · 完美";
        self.statusLabel.textColor = [SDKTheme success];
    } else {
        double progress = [record[@"progress"] doubleValue];
        self.statusLabel.text = [NSString stringWithFormat:@"未完成 %ld%%", (long)lround(progress * 100.0)];
        self.statusLabel.textColor = [SDKTheme textTertiary];
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.contentView.bounds);
    CGFloat h = CGRectGetHeight(self.contentView.bounds);
    self.card.frame = CGRectMake(0, 5, w, h - 10);

    [self.badgeLabel sizeToFit];
    CGFloat badgeWidth = CGRectGetWidth(self.badgeLabel.bounds) + 18.0;
    self.badgeLabel.frame = CGRectMake(16, 20, badgeWidth, 20);
    self.dateLabel.frame = CGRectMake(CGRectGetMaxX(self.badgeLabel.frame) + 10, 20, 140, 20);
    self.durationLabel.frame = CGRectMake(16, CGRectGetMaxY(self.badgeLabel.frame) + 4, 150, 26);
    self.statusLabel.frame = CGRectMake(w - 176, CGRectGetMinY(self.durationLabel.frame), 160, 26);
}

@end

#pragma mark - Controller

@interface SDKHistoryViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) SDKHistorySection section;
@property (nonatomic, strong) SDKAuroraView *aurora;
@property (nonatomic, strong) SDKGlassButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) SDKGlassView *segmentGlass;
@property (nonatomic, strong) SDKGlassButton *recordsTab;
@property (nonatomic, strong) SDKGlassButton *statsTab;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIScrollView *statsScroll;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSArray<NSDictionary *> *records;

@end

@implementation SDKHistoryViewController

- (instancetype)initWithSection:(SDKHistorySection)section {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _section = section;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [SDKTheme bgBottom];

    self.aurora = [[SDKAuroraView alloc] initWithFrame:self.view.bounds];
    self.aurora.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.aurora];
    [self.aurora startAnimating];

    __weak typeof(self) weakSelf = self;
    self.backButton = [SDKGlassButton circleButtonWithSymbol:@"chevron.left" diameter:42];
    self.backButton.symbolPointSize = 17;
    self.backButton.onTap = ^{ [weakSelf.navigationController popViewControllerAnimated:YES]; };
    [self.view addSubview:self.backButton];

    self.titleLabel = [UILabel sdk_label:@"历史与统计"
                                    font:[SDKTheme roundedFont:20 weight:UIFontWeightBold]
                                   color:[SDKTheme textPrimary]
                               alignment:NSTextAlignmentCenter];
    [self.view addSubview:self.titleLabel];

    self.segmentGlass = [[SDKGlassView alloc] initWithCornerRadius:16];
    self.segmentGlass.tintAlpha = 0.05;
    self.segmentGlass.showsShadow = NO;
    [self.view addSubview:self.segmentGlass];

    self.recordsTab = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
    self.recordsTab.titleText = @"对局记录";
    self.recordsTab.cornerRadius = 13;
    self.recordsTab.titlePointSize = 13;
    self.recordsTab.onTap = ^{ [weakSelf switchToSection:SDKHistorySectionRecords]; };
    [self.segmentGlass addSubview:self.recordsTab];
    self.segmentGlass.userInteractionEnabled = YES;

    self.statsTab = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
    self.statsTab.titleText = @"数据统计";
    self.statsTab.cornerRadius = 13;
    self.statsTab.titlePointSize = 13;
    self.statsTab.onTap = ^{ [weakSelf switchToSection:SDKHistorySectionStats]; };
    [self.segmentGlass addSubview:self.statsTab];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 86.0;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(6, 0, 24, 0);
    [self.tableView registerClass:[SDKHistoryCell class] forCellReuseIdentifier:@"record"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [UILabel sdk_label:@"还没有对局记录\n完成一局后就会出现在这里"
                                    font:[SDKTheme roundedFont:14 weight:UIFontWeightMedium]
                                   color:[SDKTheme textTertiary]
                               alignment:NSTextAlignmentCenter];
    self.emptyLabel.numberOfLines = 0;
    [self.view addSubview:self.emptyLabel];

    self.statsScroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.statsScroll.backgroundColor = [UIColor clearColor];
    self.statsScroll.showsVerticalScrollIndicator = NO;
    self.statsScroll.hidden = YES;
    [self.view addSubview:self.statsScroll];

    [self updateTabsAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)reloadData {
    self.records = [[SDKStore shared] history];
    [self.tableView reloadData];
    self.emptyLabel.hidden = (self.records.count > 0) || (self.section != SDKHistorySectionRecords);
    [self buildStatsContent];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = self.view.safeAreaInsets;
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = CGRectGetHeight(self.view.bounds);
    CGFloat margin = (w > 480.0) ? 28.0 : 16.0;

    self.backButton.frame = CGRectMake(margin, safe.top + 6, 42, 42);
    self.titleLabel.frame = CGRectMake(w / 2 - 100, safe.top + 12, 200, 30);

    CGFloat segWidth = MIN(260.0, w - margin * 2 - 60.0);
    self.segmentGlass.frame = CGRectMake((w - segWidth) / 2.0, safe.top + 60.0, segWidth, 46.0);
    CGFloat tabWidth = (segWidth - 8.0) / 2.0;
    self.recordsTab.frame = CGRectMake(4, 4, tabWidth, 38);
    self.statsTab.frame = CGRectMake(4 + tabWidth, 4, tabWidth, 38);

    CGFloat contentTop = safe.top + 118.0;
    CGFloat contentHeight = h - contentTop - safe.bottom - 8.0;
    self.tableView.frame = CGRectMake(margin, contentTop, w - margin * 2.0, contentHeight);
    self.emptyLabel.frame = CGRectMake(margin, contentTop + contentHeight / 2.0 - 40.0, w - margin * 2.0, 60);
    self.statsScroll.frame = CGRectMake(margin, contentTop, w - margin * 2.0, contentHeight);
    [self layoutStatsCards];
}

#pragma mark - Tabs

- (void)switchToSection:(SDKHistorySection)section {
    if (self.section == section) return;
    self.section = section;
    [SDKTheme impact:UIImpactFeedbackStyleLight];
    [self updateTabsAnimated:YES];
    [SDKTheme selectionTick];
}

- (void)updateTabsAnimated:(BOOL)animated {
    self.recordsTab.accentStyle = (self.section == SDKHistorySectionRecords);
    self.statsTab.accentStyle = (self.section == SDKHistorySectionStats);

    BOOL showRecords = (self.section == SDKHistorySectionRecords);
    self.tableView.hidden = !showRecords;
    self.statsScroll.hidden = showRecords;
    self.emptyLabel.hidden = !(showRecords && self.records.count == 0);

    if (animated) {
        UIView *shown = showRecords ? self.tableView : self.statsScroll;
        shown.alpha = 0.0;
        [UIView animateWithDuration:0.22 animations:^{
            shown.alpha = 1.0;
        }];
    }
    if (!showRecords) [self buildStatsContent];
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SDKHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"record" forIndexPath:indexPath];
    [cell configureWithRecord:self.records[(NSUInteger)indexPath.row]];
    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
        trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    NSDictionary *record = self.records[(NSUInteger)indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *delete =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:@"删除"
                                              handler:^(UIContextualAction *action, UIView *sourceView, void (^completion)(BOOL)) {
        [[SDKStore shared] deleteHistoryEntryWithDate:[record[@"date"] doubleValue]];
        [weakSelf reloadData];
        completion(YES);
    }];
    delete.backgroundColor = [SDKTheme danger];
    return [UISwipeActionsConfiguration configurationWithActions:@[ delete ]];
}

#pragma mark - Statistics

- (void)buildStatsContent {
    for (UIView *v in self.statsScroll.subviews) [v removeFromSuperview];

    SDKStore *store = [SDKStore shared];
    NSDictionary *overall = [store overallStats];

    CGFloat width = CGRectGetWidth(self.statsScroll.bounds);
    if (width < 10) width = CGRectGetWidth(self.view.bounds) - 32.0;
    CGFloat y = 0.0;

    // ---- summary card
    SDKGlassView *summary = [[SDKGlassView alloc] initWithCornerRadius:22];
    summary.tintAlpha = 0.07;
    summary.showsShadow = NO;
    summary.frame = CGRectMake(0, y, width, 108);
    [self.statsScroll addSubview:summary];

    NSArray<NSString *> *titles = @[ @"总对局", @"完成率", @"最佳用时" ];
    NSInteger played = [overall[@"played"] integerValue];
    NSInteger best = [overall[@"best"] integerValue];
    NSArray<NSString *> *values = @[
        [NSString stringWithFormat:@"%ld", (long)played],
        played > 0 ? [NSString stringWithFormat:@"%ld%%", (long)lround([overall[@"winRate"] doubleValue] * 100)] : @"--",
        best > 0 ? [SDKTheme timeString:best] : @"--"
    ];
    CGFloat colWidth = width / 3.0;
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *value = [UILabel sdk_label:values[(NSUInteger)i]
                                       font:[SDKTheme monoDigitFont:26 weight:UIFontWeightBold]
                                      color:[SDKTheme textPrimary]
                                  alignment:NSTextAlignmentCenter];
        value.frame = CGRectMake(colWidth * i, 26, colWidth, 34);
        [summary addSubview:value];
        UILabel *caption = [UILabel sdk_label:titles[(NSUInteger)i]
                                        font:[SDKTheme roundedFont:11 weight:UIFontWeightMedium]
                                       color:[SDKTheme textTertiary]
                                   alignment:NSTextAlignmentCenter];
        caption.frame = CGRectMake(colWidth * i, 62, colWidth, 16);
        [summary addSubview:caption];
    }
    y += 108 + 14;

    // ---- per difficulty cards
    for (NSInteger d = 0; d < 3; d++) {
        NSDictionary *stats = [store statsForDifficulty:(SDKDifficulty)d];
        SDKGlassView *card = [[SDKGlassView alloc] initWithCornerRadius:20];
        card.tintAlpha = 0.06;
        card.showsShadow = NO;
        card.frame = CGRectMake(0, y, width, 74);
        [self.statsScroll addSubview:card];

        UIColor *tint = [SDKTheme accent];
        if (d == SDKDifficultyMedium) tint = [SDKTheme accentAlt];
        if (d == SDKDifficultyHard) tint = [SDKTheme accentWarm];

        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(18, 30, 8, 8)];
        dot.backgroundColor = tint;
        dot.layer.cornerRadius = 4;
        [card addSubview:dot];

        UILabel *name = [UILabel sdk_label:SDKDifficultyTitle((SDKDifficulty)d)
                                      font:[SDKTheme roundedFont:15 weight:UIFontWeightSemibold]
                                     color:[SDKTheme textPrimary]
                                 alignment:NSTextAlignmentLeft];
        name.frame = CGRectMake(34, 24, 90, 20);
        [card addSubview:name];

        NSInteger c = [stats[@"completed"] integerValue];
        NSInteger p = [stats[@"played"] integerValue];
        UILabel *detail = [UILabel sdk_label:[NSString stringWithFormat:@"完成 %ld / 对局 %ld", (long)c, (long)p]
                                        font:[SDKTheme roundedFont:11 weight:UIFontWeightMedium]
                                       color:[SDKTheme textTertiary]
                                   alignment:NSTextAlignmentLeft];
        detail.frame = CGRectMake(34, 44, 160, 16);
        [card addSubview:detail];

        NSInteger cardBest = [stats[@"best"] integerValue];
        UILabel *bestLabel = [UILabel sdk_label:(cardBest > 0 ? [SDKTheme timeString:cardBest] : @"--")
                                           font:[SDKTheme monoDigitFont:19 weight:UIFontWeightBold]
                                          color:tint
                                      alignment:NSTextAlignmentRight];
        bestLabel.frame = CGRectMake(width - 130, 20, 112, 24);
        [card addSubview:bestLabel];

        UILabel *bestCaption = [UILabel sdk_label:@"最佳"
                                             font:[SDKTheme roundedFont:10 weight:UIFontWeightMedium]
                                            color:[SDKTheme textTertiary]
                                        alignment:NSTextAlignmentRight];
        bestCaption.frame = CGRectMake(width - 130, 44, 112, 14);
        [card addSubview:bestCaption];

        y += 74 + 10;
    }

    // ---- 7 day chart
    SDKGlassView *chartCard = [[SDKGlassView alloc] initWithCornerRadius:22];
    chartCard.tintAlpha = 0.06;
    chartCard.showsShadow = NO;
    chartCard.frame = CGRectMake(0, y, width, 150);
    [self.statsScroll addSubview:chartCard];

    UILabel *chartTitle = [UILabel sdk_label:@"最近 7 天完成数"
                                        font:[SDKTheme roundedFont:13 weight:UIFontWeightSemibold]
                                       color:[SDKTheme textSecondary]
                                   alignment:NSTextAlignmentLeft];
    chartTitle.frame = CGRectMake(18, 14, 200, 18);
    [chartCard addSubview:chartTitle];

    SDKBarChartView *chart = [[SDKBarChartView alloc] initWithFrame:CGRectMake(16, 40, width - 32, 96)];
    chart.values = [store completionsForLastDays:7];
    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [cal startOfDayForDate:[NSDate date]];
    for (NSInteger i = 6; i >= 0; i--) {
        NSDate *day = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:today options:0];
        NSDateComponents *comp = [cal components:NSCalendarUnitDay fromDate:day];
        [labels addObject:[NSString stringWithFormat:@"%ld", (long)comp.day]];
    }
    chart.labels = labels;
    [chartCard addSubview:chart];

    y += 150 + 20;
    self.statsScroll.contentSize = CGSizeMake(width, y);
}

- (void)layoutStatsCards {
    if (self.statsScroll.hidden) return;
    [self buildStatsContent];
}

@end
