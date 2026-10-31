//
//  SDKHistoryViewController.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKHistoryViewController.h"
#import "SDKStore.h"
#import "SDKTheme.h"
#import "SDKBarChartView.h"

@interface SDKHistoryViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITableView *recordsTable;
@property (nonatomic, strong) UITableView *statsTable;
@property (nonatomic, copy) NSArray<NSDictionary *> *records;
@property (nonatomic) NSInteger initialSection;

@end

@implementation SDKHistoryViewController

- (instancetype)initWithSection:(NSInteger)section {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _initialSection = (section == 1) ? 1 : 0;
        self.title = @"历史与统计";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[ @"对局记录", @"数据统计" ]];
    self.segmentedControl.selectedSegmentIndex = self.initialSection;
    self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.segmentedControl addTarget:self action:@selector(sectionChanged)
                    forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];

    self.recordsTable = [self makeTable];
    self.statsTable = [self makeTable];
    [self.view addSubview:self.recordsTable];
    [self.view addSubview:self.statsTable];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.segmentedControl.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12.0],
        [self.segmentedControl.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16.0],
        [self.segmentedControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16.0],

        [self.recordsTable.topAnchor constraintEqualToAnchor:self.segmentedControl.bottomAnchor constant:8.0],
        [self.recordsTable.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.recordsTable.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.recordsTable.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.statsTable.topAnchor constraintEqualToAnchor:self.segmentedControl.bottomAnchor constant:8.0],
        [self.statsTable.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.statsTable.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.statsTable.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self reloadAll];
    [self updateVisibility];
}

- (UITableView *)makeTable {
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    table.translatesAutoresizingMaskIntoConstraints = NO;
    table.dataSource = self;
    table.delegate = self;
    table.backgroundColor = [UIColor systemGroupedBackgroundColor];
    table.rowHeight = UITableViewAutomaticDimension;
    table.estimatedRowHeight = 60.0;
    return table;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadAll];
}

- (void)reloadAll {
    NSArray<NSDictionary *> *history = [[SDKStore shared] history];
    self.records = [history sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [b[@"date"] compare:a[@"date"]];
    }];
    [self.recordsTable reloadData];
    [self.statsTable reloadData];
    [self updateEmptyState];
}

- (void)updateEmptyState {
    if (self.records.count > 0) {
        self.recordsTable.backgroundView = nil;
        return;
    }
    UILabel *label = [UILabel new];
    label.text = @"还没有对局记录";
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.textColor = [UIColor secondaryLabelColor];
    label.textAlignment = NSTextAlignmentCenter;
    self.recordsTable.backgroundView = label;
}

- (void)sectionChanged {
    [self updateVisibility];
}

- (void)updateVisibility {
    BOOL stats = (self.segmentedControl.selectedSegmentIndex == 1);
    self.recordsTable.hidden = stats;
    self.statsTable.hidden = !stats;
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return tableView == self.statsTable ? 3 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.recordsTable) return (NSInteger)self.records.count;
    if (section == 0) return 4;
    if (section == 1) return 3;
    return 1;   // chart
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.recordsTable) return @"最近的对局";
    if (section == 0) return @"总览";
    if (section == 1) return @"分难度";
    return @"最近七天完成的局数";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.statsTable && indexPath.section == 2) return 170.0;
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.recordsTable) return [self recordCellForRow:indexPath.row];
    if (indexPath.section == 2) return [self chartCell];
    return [self statCellForIndexPath:indexPath tableView:tableView];
}

- (UITableViewCell *)recordCellForRow:(NSInteger)row {
    static NSString *identifier = @"history.record";
    UITableViewCell *cell = [self.recordsTable dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSDictionary *record = self.records[(NSUInteger)row];
    SDKDifficulty difficulty = (SDKDifficulty)[record[@"difficulty"] integerValue];
    NSInteger seconds = [record[@"seconds"] integerValue];
    NSInteger mistakes = [record[@"mistakes"] integerValue];
    BOOL completed = [record[@"completed"] boolValue];
    double progress = [record[@"progress"] doubleValue];

    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = [NSString stringWithFormat:@"%@ · %@", SDKDifficultyTitle(difficulty),
                    [SDKTheme timeString:seconds]];

    static NSDateFormatter *formatter = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    });
    NSString *when = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[record[@"date"] doubleValue]]];

    NSString *status = completed ? @"已完成"
                                 : [NSString stringWithFormat:@"未完成 %ld%%", (long)lround(progress * 100.0)];
    content.secondaryText = [NSString stringWithFormat:@"%@ · %@ · 失误 %ld", when, status, (long)mistakes];
    content.image = [UIImage systemImageNamed:completed ? @"checkmark.circle.fill" : @"circle.dashed"];
    content.imageProperties.tintColor = completed ? [SDKTheme colorForDifficulty:difficulty]
                                                  : [UIColor tertiaryLabelColor];
    cell.contentConfiguration = content;
    return cell;
}

- (UITableViewCell *)statCellForIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    static NSString *identifier = @"history.stat";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    UIListContentConfiguration *content = [UIListContentConfiguration valueCellConfiguration];
    NSDictionary *overall = [[SDKStore shared] overallStats];

    if (indexPath.section == 0) {
        NSInteger played = [overall[@"played"] integerValue];
        NSInteger completed = [overall[@"completed"] integerValue];
        NSInteger best = [overall[@"best"] integerValue];
        NSInteger average = [overall[@"average"] integerValue];
        switch (indexPath.row) {
            case 0:
                content.text = @"总对局";
                content.secondaryText = [NSString stringWithFormat:@"%ld 局", (long)played];
                break;
            case 1:
                content.text = @"完成";
                content.secondaryText = played > 0
                    ? [NSString stringWithFormat:@"%ld 局（%ld%%）", (long)completed,
                       (long)lround((double)completed / (double)played * 100.0)]
                    : @"—";
                break;
            case 2:
                content.text = @"最佳用时";
                content.secondaryText = best > 0 ? [SDKTheme timeString:best] : @"—";
                break;
            default:
                content.text = @"平均用时";
                content.secondaryText = average > 0 ? [SDKTheme timeString:average] : @"—";
                break;
        }
    } else {
        SDKDifficulty difficulty = (SDKDifficulty)indexPath.row;
        NSDictionary *stats = [[SDKStore shared] statsForDifficulty:difficulty];
        NSInteger played = [stats[@"played"] integerValue];
        NSInteger best = [stats[@"best"] integerValue];
        content.text = SDKDifficultyTitle(difficulty);
        if (played == 0) {
            content.secondaryText = @"还没玩过";
        } else if (best > 0) {
            content.secondaryText = [NSString stringWithFormat:@"最佳 %@ · %ld 局",
                                     [SDKTheme timeString:best], (long)played];
        } else {
            content.secondaryText = [NSString stringWithFormat:@"%ld 局", (long)played];
        }
    }

    cell.contentConfiguration = content;
    return cell;
}

- (UITableViewCell *)chartCell {
    static NSString *identifier = @"history.chart";
    UITableViewCell *cell = [self.statsTable dequeueReusableCellWithIdentifier:identifier];
    SDKBarChartView *chart = nil;
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        chart = [[SDKBarChartView alloc] initWithFrame:CGRectZero];
        chart.translatesAutoresizingMaskIntoConstraints = NO;
        chart.tag = 4242;
        [cell.contentView addSubview:chart];
        [NSLayoutConstraint activateConstraints:@[
            [chart.leadingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leadingAnchor],
            [chart.trailingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.trailingAnchor],
            [chart.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:10.0],
            [chart.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-10.0],
        ]];
    } else {
        chart = (SDKBarChartView *)[cell.contentView viewWithTag:4242];
    }

    NSArray<NSNumber *> *values = [[SDKStore shared] completionsForLastDays:7];
    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    NSDateFormatter *weekday = [NSDateFormatter new];
    weekday.dateFormat = @"EEEEE";
    NSCalendar *calendar = [NSCalendar currentCalendar];
    for (NSInteger i = 6; i >= 0; i--) {
        NSDate *day = [calendar dateByAddingUnit:NSCalendarUnitDay value:-i toDate:[NSDate date] options:0];
        [labels addObject:day ? [weekday stringFromDate:day] : @""];
    }
    chart.values = values;
    chart.labels = labels;
    chart.barColor = [UIColor systemBlueColor];
    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    if (tableView != self.recordsTable) return nil;
    __weak typeof(self) weakSelf = self;
    UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                         title:@"删除"
                                                                       handler:^(UIContextualAction *action,
                                                                                 UIView *sourceView,
                                                                                 void (^completion)(BOOL)) {
        NSDictionary *record = weakSelf.records[(NSUInteger)indexPath.row];
        [[SDKStore shared] deleteHistoryEntryWithDate:[record[@"date"] doubleValue]];
        [weakSelf reloadAll];
        completion(YES);
    }];
    delete.image = [UIImage systemImageNamed:@"trash"];
    return [UISwipeActionsConfiguration configurationWithActions:@[ delete ]];
}

@end
