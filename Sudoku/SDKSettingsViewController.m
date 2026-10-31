//
//  SDKSettingsViewController.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKSettingsViewController.h"
#import "SDKTheme.h"
#import "SDKGlass.h"
#import "SDKAuroraView.h"
#import "SDKStore.h"

NSString * const kSDKRepositoryURL = @"https://github.com/shimiei/Sudoku-LiquidGlass";

@interface SDKSettingsViewController ()

@property (nonatomic, strong) SDKAuroraView *aurora;
@property (nonatomic, strong) SDKGlassButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray<NSDictionary *> *rows;

@end

@implementation SDKSettingsViewController

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

    self.titleLabel = [UILabel sdk_label:@"设置"
                                    font:[SDKTheme roundedFont:20 weight:UIFontWeightBold]
                                   color:[SDKTheme textPrimary]
                               alignment:NSTextAlignmentCenter];
    [self.view addSubview:self.titleLabel];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    self.rows = @[
        @{ @"title": @"高亮相同数字", @"sub": @"选中格子后点亮所有相同数字", @"key": @"highlightSameNumbers" },
        @{ @"title": @"高亮关联区域", @"sub": @"同行、同列、同宫淡淡提示", @"key": @"highlightPeers" },
        @{ @"title": @"标记重复", @"sub": @"同区重复的数字会标红", @"key": @"showConflicts" },
        @{ @"title": @"即时判错", @"sub": @"填错立即提示（关闭后只查重复）", @"key": @"autoCheck" },
        @{ @"title": @"自动清理笔记", @"sub": @"填入数字后移除关联格中的笔记", @"key": @"autoClearNotes" },
        @{ @"title": @"拖动放大镜", @"sub": @"按住棋盘时放大手指下的格子", @"key": @"loupeEnabled" },
        @{ @"title": @"触感反馈", @"sub": @"按钮与落子时的震动", @"key": @"hapticsEnabled" }
    ];

    [self buildContent];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = self.view.safeAreaInsets;
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = CGRectGetHeight(self.view.bounds);
    CGFloat margin = (w > 480.0) ? 28.0 : 16.0;

    self.backButton.frame = CGRectMake(margin, safe.top + 6, 42, 42);
    self.titleLabel.frame = CGRectMake(w / 2 - 100, safe.top + 12, 200, 30);
    self.scrollView.frame = CGRectMake(margin, safe.top + 62, w - margin * 2.0, h - safe.top - 62 - safe.bottom);
    [self layoutContent];
}

#pragma mark - Content

- (void)buildContent {
    for (UIView *v in self.scrollView.subviews) [v removeFromSuperview];

    // ---- section header: 游戏辅助
    UILabel *header = [UILabel sdk_label:@"游戏辅助"
                                    font:[SDKTheme roundedFont:12 weight:UIFontWeightSemibold]
                                   color:[SDKTheme textTertiary]
                               alignment:NSTextAlignmentLeft];
    header.tag = 9001;
    [self.scrollView addSubview:header];

    for (NSInteger i = 0; i < (NSInteger)self.rows.count; i++) {
        NSDictionary *row = self.rows[(NSUInteger)i];
        SDKGlassView *card = [[SDKGlassView alloc] initWithCornerRadius:18];
        card.tintAlpha = 0.055;
        card.showsShadow = NO;
        card.userInteractionEnabled = YES;
        card.tag = 1000 + i;
        [self.scrollView addSubview:card];

        UILabel *title = [UILabel sdk_label:row[@"title"]
                                       font:[SDKTheme roundedFont:15 weight:UIFontWeightSemibold]
                                      color:[SDKTheme textPrimary]
                                  alignment:NSTextAlignmentLeft];
        title.tag = 100;
        [card addSubview:title];

        UILabel *sub = [UILabel sdk_label:row[@"sub"]
                                     font:[SDKTheme roundedFont:11 weight:UIFontWeightRegular]
                                    color:[SDKTheme textTertiary]
                                alignment:NSTextAlignmentLeft];
        sub.tag = 101;
        [card addSubview:sub];

        SDKGlassSwitch *toggle = [[SDKGlassSwitch alloc] initWithFrame:CGRectZero];
        NSString *key = row[@"key"];
        toggle.tag = 102;
        toggle.on = [self boolForKey:key];
        __weak typeof(self) weakSelf = self;
        toggle.onChange = ^(BOOL isOn) {
            [weakSelf setBool:isOn forKey:key];
        };
        [card addSubview:toggle];
    }

    // ---- about section
    UILabel *aboutHeader = [UILabel sdk_label:@"关于"
                                         font:[SDKTheme roundedFont:12 weight:UIFontWeightSemibold]
                                        color:[SDKTheme textTertiary]
                                    alignment:NSTextAlignmentLeft];
    aboutHeader.tag = 9002;
    [self.scrollView addSubview:aboutHeader];

    SDKGlassView *aboutCard = [[SDKGlassView alloc] initWithCornerRadius:18];
    aboutCard.tintAlpha = 0.055;
    aboutCard.showsShadow = NO;
    aboutCard.userInteractionEnabled = YES;
    aboutCard.tag = 2000;
    [self.scrollView addSubview:aboutCard];

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";
    UILabel *versionLabel = [UILabel sdk_label:[NSString stringWithFormat:@"数独 · 液态玻璃版 v%@", version]
                                         font:[SDKTheme roundedFont:14 weight:UIFontWeightSemibold]
                                        color:[SDKTheme textPrimary]
                                    alignment:NSTextAlignmentLeft];
    versionLabel.tag = 100;
    [aboutCard addSubview:versionLabel];

    UILabel *engineLabel = [UILabel sdk_label:@"Objective-C / UIKit · 无需联网 · 完全开源"
                                        font:[SDKTheme roundedFont:11 weight:UIFontWeightRegular]
                                       color:[SDKTheme textTertiary]
                                   alignment:NSTextAlignmentLeft];
    engineLabel.tag = 101;
    [aboutCard addSubview:engineLabel];

    SDKGlassButton *repo = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
    repo.titleText = @"开源地址";
    repo.symbolName = @"chevron.left.forwardslash.chevron.right";
    repo.cornerRadius = 14;
    repo.titlePointSize = 13;
    repo.symbolPointSize = 12;
    repo.tag = 201;
    __weak typeof(self) weakSelf2 = self;
    repo.onTap = ^{
        NSURL *url = [NSURL URLWithString:kSDKRepositoryURL];
        if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        (void)weakSelf2;
    };
    [aboutCard addSubview:repo];

    SDKGlassButton *clear = [[SDKGlassButton alloc] initWithFrame:CGRectZero];
    clear.titleText = @"清空所有记录";
    clear.symbolName = @"trash";
    clear.cornerRadius = 14;
    clear.titlePointSize = 13;
    clear.symbolPointSize = 12;
    clear.contentColor = [SDKTheme danger];
    clear.tag = 202;
    __weak typeof(self) weakSelf3 = self;
    clear.onTap = ^{ [weakSelf3 confirmReset]; };
    [aboutCard addSubview:clear];
}

- (void)layoutContent {
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    if (width < 10) return;
    CGFloat y = 4.0;

    UILabel *header = (UILabel *)[self.scrollView viewWithTag:9001];
    header.frame = CGRectMake(6, y, width - 12, 18);
    y += 24;

    for (NSInteger i = 0; i < (NSInteger)self.rows.count; i++) {
        SDKGlassView *card = (SDKGlassView *)[self.scrollView viewWithTag:1000 + i];
        card.frame = CGRectMake(0, y, width, 64);
        UILabel *title = (UILabel *)[card viewWithTag:100];
        UILabel *sub = (UILabel *)[card viewWithTag:101];
        SDKGlassSwitch *toggle = (SDKGlassSwitch *)[card viewWithTag:102];

        CGFloat switchWidth = 52.0;
        title.frame = CGRectMake(18, 14, width - 18 - switchWidth - 24, 19);
        sub.frame = CGRectMake(18, 34, width - 18 - switchWidth - 24, 15);
        toggle.frame = CGRectMake(width - switchWidth - 18, 16.5, switchWidth, 31);
        y += 64 + 8;
    }

    y += 12;
    UILabel *aboutHeader = (UILabel *)[self.scrollView viewWithTag:9002];
    aboutHeader.frame = CGRectMake(6, y, width - 12, 18);
    y += 24;

    SDKGlassView *aboutCard = (SDKGlassView *)[self.scrollView viewWithTag:2000];
    aboutCard.frame = CGRectMake(0, y, width, 148);
    UILabel *versionLabel = (UILabel *)[aboutCard viewWithTag:100];
    UILabel *engineLabel = (UILabel *)[aboutCard viewWithTag:101];
    SDKGlassButton *repo = (SDKGlassButton *)[aboutCard viewWithTag:201];
    SDKGlassButton *clear = (SDKGlassButton *)[aboutCard viewWithTag:202];

    versionLabel.frame = CGRectMake(18, 16, width - 36, 19);
    engineLabel.frame = CGRectMake(18, 36, width - 36, 15);
    CGFloat halfWidth = (width - 36 - 10) / 2.0;
    repo.frame = CGRectMake(18, 68, halfWidth, 44);
    clear.frame = CGRectMake(18 + halfWidth + 10, 68, halfWidth, 44);
    y += 148 + 24;

    self.scrollView.contentSize = CGSizeMake(width, MAX(y, CGRectGetHeight(self.scrollView.bounds)));
}

#pragma mark - Settings plumbing

- (BOOL)boolForKey:(NSString *)key {
    SDKStore *store = [SDKStore shared];
    if ([key isEqualToString:@"highlightSameNumbers"]) return store.highlightSameNumbers;
    if ([key isEqualToString:@"highlightPeers"]) return store.highlightPeers;
    if ([key isEqualToString:@"showConflicts"]) return store.showConflicts;
    if ([key isEqualToString:@"autoCheck"]) return store.autoCheck;
    if ([key isEqualToString:@"autoClearNotes"]) return store.autoClearNotes;
    if ([key isEqualToString:@"loupeEnabled"]) return store.loupeEnabled;
    if ([key isEqualToString:@"hapticsEnabled"]) return store.hapticsEnabled;
    return NO;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    SDKStore *store = [SDKStore shared];
    if ([key isEqualToString:@"highlightSameNumbers"]) { store.highlightSameNumbers = value; return; }
    if ([key isEqualToString:@"highlightPeers"]) { store.highlightPeers = value; return; }
    if ([key isEqualToString:@"showConflicts"]) { store.showConflicts = value; return; }
    if ([key isEqualToString:@"autoCheck"]) { store.autoCheck = value; return; }
    if ([key isEqualToString:@"autoClearNotes"]) { store.autoClearNotes = value; return; }
    if ([key isEqualToString:@"loupeEnabled"]) { store.loupeEnabled = value; return; }
    if ([key isEqualToString:@"hapticsEnabled"]) { store.hapticsEnabled = value; return; }
}

- (void)confirmReset {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"清空所有记录"
                                            message:@"对局历史、统计数据以及当前未完成的对局都会被删除。"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [[SDKStore shared] resetAllData];
        [SDKTheme notify:UINotificationFeedbackTypeSuccess];
        [weakSelf buildContent];
        [weakSelf layoutContent];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
