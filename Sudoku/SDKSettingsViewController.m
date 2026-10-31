//
//  SDKSettingsViewController.m
//  Sudoku — Apple HIG rebuild
//
//  A settings screen shaped exactly like the system Settings app:
//  inset-grouped sections, a switch in the accessory slot, a destructive row.
//

#import "SDKSettingsViewController.h"
#import "SDKStore.h"
#import "SDKTheme.h"
#import "SDKDiagnostics.h"

NSString * const kSDKRepositoryURL = @"https://github.com/shimiei/Sudoku-LiquidGlass";

typedef NS_ENUM(NSInteger, SDKSettingsItem) {
    SDKSettingsItemPeers = 0,
    SDKSettingsItemSameNumbers,
    SDKSettingsItemConflicts,
    SDKSettingsItemAutoCheck,
    SDKSettingsItemAutoClearNotes,
    SDKSettingsItemLoupe,
    SDKSettingsItemHaptics,
    SDKSettingsItemCount
};

@interface SDKSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *assistTitles;
@property (nonatomic, copy) NSArray<NSString *> *assistFootnotes;
@end

@implementation SDKSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"设置";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.assistTitles = @[ @"高亮同行同列同宫",
                           @"高亮相同数字",
                           @"标记重复数字",
                           @"即时判错",
                           @"自动清除笔记",
                           @"拖动时显示放大镜",
                           @"触感反馈" ];
    self.assistFootnotes = @[ @"选中格子时，淡化与它同行、同列、同宫的格子。",
                              @"选中格子里的数字在其他位置也会高亮。",
                              @"同一行、列或宫里出现重复数字时标红。",
                              @"填入与答案不符时立刻标红并计入失误。",
                              @"填入数字后，相关格子中该数字的笔记会被清除。",
                              @"按住棋盘并移动手指，会浮起放大镜显示当前格子。",
                              @"点按和完成时使用轻触反馈。" ];

    UITableView *table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    table.dataSource = self;
    table.delegate = self;
    table.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self.view addSubview:table];
    self.tableView = table;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return (NSInteger)SDKSettingsItemCount;
    if (section == 1) return 1;
    return [self crashStep] ? 3 : 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"游戏辅助";
    if (section == 1) return @"数据";
    return @"关于";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"所有设置都可以随时修改，正在进行的对局不受影响。";
    if (section == 1) return @"清空后，历史记录与统计数据都会删除，且无法恢复。";
    return @"数独完全离线运行：没有账号，没有网络请求，对局只保存在这台设备上。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"settings.cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    if (indexPath.section == 0) {
        NSInteger item = indexPath.row;
        UIListContentConfiguration *content = [UIListContentConfiguration cellConfiguration];
        content.text = self.assistTitles[(NSUInteger)item];
        content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.contentConfiguration = content;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
        sw.onTintColor = [UIColor systemBlueColor];
        sw.tag = item;
        sw.on = [self isOnForItem:(SDKSettingsItem)item];
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return cell;
    }

    if (indexPath.section == 1) {
        UIListContentConfiguration *content = [UIListContentConfiguration cellConfiguration];
        content.text = @"清空所有记录";
        content.textProperties.color = [UIColor systemRedColor];
        content.textProperties.alignment = UIListContentTextAlignmentCenter;
        cell.contentConfiguration = content;
        return cell;
    }

    UIListContentConfiguration *content = [UIListContentConfiguration valueCellConfiguration];
    if (indexPath.row == 0) {
        content.text = @"版本";
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        content.secondaryText = [NSString stringWithFormat:@"%@ (%@)",
                                 version.length ? version : @"1.0.0", build.length ? build : @"1"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.row == 1) {
        content.text = @"开源地址";
        content.secondaryText = @"GitHub";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        content.text = @"上次异常退出";
        content.secondaryText = @"查看详情";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.contentConfiguration = content;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [self confirmReset];
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        NSURL *url = [NSURL URLWithString:kSDKRepositoryURL];
        if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    } else if (indexPath.section == 2 && indexPath.row == 2) {
        [self showDiagnostics];
    }
}

#pragma mark - Diagnostics

- (NSString *)crashStep {
    NSString *step = SDKLastCrashStep();
    return step.length > 0 ? step : nil;
}

- (void)showDiagnostics {
    NSString *step = [self crashStep];
    if (!step) return;
    NSString *message = [NSString stringWithFormat:@"上次异常退出时停在：\n%@\n\n把这一行发给我就能定位。",
                         step];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"诊断信息"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"清除" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *a) {
        SDKClearCrashStep();
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Switch state

- (BOOL)isOnForItem:(SDKSettingsItem)item {
    SDKStore *store = [SDKStore shared];
    switch (item) {
        case SDKSettingsItemPeers:          return store.highlightPeers;
        case SDKSettingsItemSameNumbers:    return store.highlightSameNumbers;
        case SDKSettingsItemConflicts:      return store.showConflicts;
        case SDKSettingsItemAutoCheck:      return store.autoCheck;
        case SDKSettingsItemAutoClearNotes: return store.autoClearNotes;
        case SDKSettingsItemLoupe:          return store.loupeEnabled;
        case SDKSettingsItemHaptics:        return store.hapticsEnabled;
        default: return NO;
    }
}

- (void)switchChanged:(UISwitch *)sender {
    SDKStore *store = [SDKStore shared];
    BOOL on = sender.isOn;
    switch ((SDKSettingsItem)sender.tag) {
        case SDKSettingsItemPeers:          store.highlightPeers = on; break;
        case SDKSettingsItemSameNumbers:    store.highlightSameNumbers = on; break;
        case SDKSettingsItemConflicts:      store.showConflicts = on; break;
        case SDKSettingsItemAutoCheck:      store.autoCheck = on; break;
        case SDKSettingsItemAutoClearNotes: store.autoClearNotes = on; break;
        case SDKSettingsItemLoupe:          store.loupeEnabled = on; break;
        case SDKSettingsItemHaptics:
            store.hapticsEnabled = on;
            [SDKTheme setHapticsEnabled:on];
            break;
        default: break;
    }
    [store applyGlobalSideEffects];
    if (on) [SDKTheme selection];
}

#pragma mark - Reset

- (void)confirmReset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清空所有记录？"
                                                                  message:@"历史记录与统计数据都会被删除，正在进行的对局也会结束。"
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [[SDKStore shared] resetAllData];
        [weakSelf.tableView reloadData];
        [SDKTheme notify:UINotificationFeedbackTypeSuccess];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
                                                               CGRectGetMidY(self.view.bounds), 1, 1);
    [self presentViewController:alert animated:YES completion:nil];
}

@end
