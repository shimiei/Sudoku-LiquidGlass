//
//  SDKHomeViewController.m
//  Sudoku — Apple HIG rebuild
//
//  A plain inset-grouped list: the most native way to present a small menu.
//

#import "SDKHomeViewController.h"
#import "SDKStore.h"
#import "SDKTheme.h"
#import "SDKGameViewController.h"
#import "SDKHistoryViewController.h"
#import "SDKSettingsViewController.h"

typedef NS_ENUM(NSInteger, SDKHomeRowKind) {
    SDKHomeRowKindResume = 0,
    SDKHomeRowKindDifficulty,
    SDKHomeRowKindHistory
};

@interface SDKHomeRow : NSObject
@property (nonatomic) SDKHomeRowKind kind;
@property (nonatomic) SDKDifficulty difficulty;
@end

@implementation SDKHomeRow
@end

@interface SDKHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<SDKHomeRow *> *resumeRows;
@property (nonatomic, copy) NSArray<SDKHomeRow *> *difficultyRows;
@property (nonatomic, copy) NSArray<SDKHomeRow *> *moreRows;
@end

@implementation SDKHomeViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) [self buildModel];
    return self;
}

- (void)buildModel {
    NSMutableArray<SDKHomeRow *> *difficulties = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        SDKHomeRow *row = [SDKHomeRow new];
        row.kind = SDKHomeRowKindDifficulty;
        row.difficulty = (SDKDifficulty)i;
        [difficulties addObject:row];
    }
    self.difficultyRows = difficulties;

    SDKHomeRow *history = [SDKHomeRow new];
    history.kind = SDKHomeRowKindHistory;
    self.moreRows = @[ history ];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"数独";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gearshape"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(openSettings)];

    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    UITableView *table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    table.dataSource = self;
    table.delegate = self;
    table.backgroundColor = [UIColor systemGroupedBackgroundColor];
    table.rowHeight = UITableViewAutomaticDimension;
    table.estimatedRowHeight = 56.0;
    [self.view addSubview:table];
    self.tableView = table;

    [self refreshContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshContent];
}

- (void)refreshContent {
    SDKGameState *current = [[SDKStore shared] currentGame];
    NSMutableArray<SDKHomeRow *> *rows = [NSMutableArray array];
    if (current && !current.finished) {
        SDKHomeRow *resume = [SDKHomeRow new];
        resume.kind = SDKHomeRowKindResume;
        resume.difficulty = current.difficulty;
        [rows addObject:resume];
    }
    self.resumeRows = rows;
    [self.tableView reloadData];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return (NSInteger)self.resumeRows.count;
        case 1: return (NSInteger)self.difficultyRows.count;
        default: return (NSInteger)self.moreRows.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return self.resumeRows.count ? @"上一局" : nil;
    if (section == 1) return @"新对局";
    return @"更多";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section != 1) return nil;
    return @"每局都保证唯一解。对局进度会自动保存，数据只留在这台设备上。";
}

- (SDKHomeRow *)rowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: return self.resumeRows[(NSUInteger)indexPath.row];
        case 1: return self.difficultyRows[(NSUInteger)indexPath.row];
        default: return self.moreRows[(NSUInteger)indexPath.row];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"home.cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    SDKHomeRow *row = [self rowAtIndexPath:indexPath];
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];

    switch (row.kind) {
        case SDKHomeRowKindResume: {
            SDKGameState *game = [[SDKStore shared] currentGame];
            content.text = @"继续对局";
            if (game) {
                content.secondaryText = [NSString stringWithFormat:@"%@ · %@ · 已完成 %ld/81",
                                         SDKDifficultyTitle(game.difficulty),
                                         [SDKTheme timeString:game.elapsedSeconds],
                                         (long)[game filledCount]];
            }
            content.image = [UIImage systemImageNamed:@"play.circle.fill"];
            content.imageProperties.tintColor = [UIColor systemBlueColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case SDKHomeRowKindDifficulty: {
            NSDictionary *stats = [[SDKStore shared] statsForDifficulty:row.difficulty];
            NSInteger played = [stats[@"played"] integerValue];
            NSInteger best = [stats[@"best"] integerValue];
            content.text = SDKDifficultyTitle(row.difficulty);
            if (played > 0 && best > 0) {
                content.secondaryText = [NSString stringWithFormat:@"最佳 %@ · 已玩 %ld 局",
                                         [SDKTheme timeString:best], (long)played];
            } else {
                content.secondaryText = @"还没玩过，开始第一局";
            }
            content.image = [UIImage systemImageNamed:@"circle.fill"];
            content.imageProperties.tintColor = [SDKTheme colorForDifficulty:row.difficulty];
            content.imageProperties.maximumSize = CGSizeMake(12, 12);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case SDKHomeRowKindHistory: {
            content.text = @"历史与统计";
            content.secondaryText = @"对局记录、最佳用时和最近七天";
            content.image = [UIImage systemImageNamed:@"clock.arrow.circlepath"];
            content.imageProperties.tintColor = [UIColor secondaryLabelColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }

    cell.contentConfiguration = content;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.navigationController.topViewController != self) return;

    SDKHomeRow *row = [self rowAtIndexPath:indexPath];
    switch (row.kind) {
        case SDKHomeRowKindResume: {
            SDKGameState *game = [[SDKStore shared] currentGame];
            if (!game) {
                [self refreshContent];
                return;
            }
            SDKGameViewController *vc = [[SDKGameViewController alloc] initWithSavedGame:game];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case SDKHomeRowKindDifficulty: {
            [self archiveCurrentGameIfNeeded];
            SDKGameViewController *vc = [[SDKGameViewController alloc] initWithDifficulty:row.difficulty];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case SDKHomeRowKindHistory: {
            SDKHistoryViewController *vc = [[SDKHistoryViewController alloc] initWithSection:0];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

/// Keeps the abandoned game in the history instead of throwing it away.
- (void)archiveCurrentGameIfNeeded {
    SDKGameState *current = [[SDKStore shared] currentGame];
    if (current && !current.finished && [self hasUserProgress:current]) {
        [[SDKStore shared] recordGame:current];
    }
    [[SDKStore shared] saveCurrentGame:nil];
}

- (BOOL)hasUserProgress:(SDKGameState *)game {
    NSInteger givens = 0;
    for (NSNumber *n in game.puzzle) if (n.integerValue != 0) givens++;
    return [game filledCount] > givens;
}

#pragma mark - Actions

- (void)openSettings {
    if (self.navigationController.topViewController != self) return;
    SDKSettingsViewController *vc = [SDKSettingsViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
