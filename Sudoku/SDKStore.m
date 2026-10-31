//
//  SDKStore.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKStore.h"
#import "SDKTheme.h"

static NSString * const kSDKKeyHighlightSame   = @"sdk.settings.highlightSame";
static NSString * const kSDKKeyHighlightPeers  = @"sdk.settings.highlightPeers";
static NSString * const kSDKKeyShowConflicts   = @"sdk.settings.showConflicts";
static NSString * const kSDKKeyAutoCheck       = @"sdk.settings.autoCheck";
static NSString * const kSDKKeyAutoClearNotes  = @"sdk.settings.autoClearNotes";
static NSString * const kSDKKeyLoupe           = @"sdk.settings.loupe";
static NSString * const kSDKKeyHaptics         = @"sdk.settings.haptics";
static NSString * const kSDKKeyCurrentGame     = @"sdk.currentGame";
static NSString * const kSDKKeyHistory         = @"sdk.history";

static const NSInteger kSDKHistoryLimit = 200;

@interface SDKStore ()
- (BOOL)readBool:(NSString *)key;
- (void)writeBool:(BOOL)value forKey:(NSString *)key;
- (nullable id)jsonObjectForKey:(NSString *)key;
- (void)setJSONObject:(nullable id)object forKey:(NSString *)key;
- (NSArray<NSDictionary *> *)rawHistory;
@end

@implementation SDKStore

+ (instancetype)shared {
    static SDKStore *store = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ store = [SDKStore new]; });
    return store;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d registerDefaults:@{
            kSDKKeyHighlightSame: @YES,
            kSDKKeyHighlightPeers: @YES,
            kSDKKeyShowConflicts: @YES,
            kSDKKeyAutoCheck: @NO,
            kSDKKeyAutoClearNotes: @YES,
            kSDKKeyLoupe: @YES,
            kSDKKeyHaptics: @YES
        }];
        [self applyGlobalSideEffects];
    }
    return self;
}

#pragma mark - Settings

- (BOOL)readBool:(NSString *)key { return [[NSUserDefaults standardUserDefaults] boolForKey:key]; }

- (void)writeBool:(BOOL)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    [self applyGlobalSideEffects];
}

- (BOOL)highlightSameNumbers { return [self readBool:kSDKKeyHighlightSame]; }
- (void)setHighlightSameNumbers:(BOOL)v { [self writeBool:v forKey:kSDKKeyHighlightSame]; }

- (BOOL)highlightPeers { return [self readBool:kSDKKeyHighlightPeers]; }
- (void)setHighlightPeers:(BOOL)v { [self writeBool:v forKey:kSDKKeyHighlightPeers]; }

- (BOOL)showConflicts { return [self readBool:kSDKKeyShowConflicts]; }
- (void)setShowConflicts:(BOOL)v { [self writeBool:v forKey:kSDKKeyShowConflicts]; }

- (BOOL)autoCheck { return [self readBool:kSDKKeyAutoCheck]; }
- (void)setAutoCheck:(BOOL)v { [self writeBool:v forKey:kSDKKeyAutoCheck]; }

- (BOOL)autoClearNotes { return [self readBool:kSDKKeyAutoClearNotes]; }
- (void)setAutoClearNotes:(BOOL)v { [self writeBool:v forKey:kSDKKeyAutoClearNotes]; }

- (BOOL)loupeEnabled { return [self readBool:kSDKKeyLoupe]; }
- (void)setLoupeEnabled:(BOOL)v { [self writeBool:v forKey:kSDKKeyLoupe]; }

- (BOOL)hapticsEnabled { return [self readBool:kSDKKeyHaptics]; }
- (void)setHapticsEnabled:(BOOL)v { [self writeBool:v forKey:kSDKKeyHaptics]; }

- (void)applyGlobalSideEffects {
    [SDKTheme setHapticsEnabled:[self readBool:kSDKKeyHaptics]];
}

#pragma mark - JSON helpers

- (nullable id)jsonObjectForKey:(NSString *)key {
    NSString *json = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if (json.length == 0) return nil;
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    return obj;
}

- (void)setJSONObject:(nullable id)object forKey:(NSString *)key {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (!object) { [d removeObjectForKey:key]; return; }
    if (![NSJSONSerialization isValidJSONObject:object]) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:NULL];
    if (!data) return;
    [d setObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] forKey:key];
}

#pragma mark - Current game

- (SDKGameState *)currentGame {
    NSDictionary *dict = [self jsonObjectForKey:kSDKKeyCurrentGame];
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    SDKGameState *game = [SDKGameState gameFromDictionary:dict];
    if (!game || game.finished) return nil;
    return game;
}

- (void)saveCurrentGame:(SDKGameState *)game {
    if (!game || game.finished) {
        [self setJSONObject:nil forKey:kSDKKeyCurrentGame];
        return;
    }
    [self setJSONObject:[game dictionaryRepresentation] forKey:kSDKKeyCurrentGame];
}

#pragma mark - History

- (void)recordGame:(SDKGameState *)game {
    if (!game) return;
    NSMutableArray *list = [[self rawHistory] mutableCopy];
    NSDictionary *entry = @{
        @"date": @([[NSDate date] timeIntervalSince1970]),
        @"difficulty": @(game.difficulty),
        @"seconds": @(game.elapsedSeconds),
        @"mistakes": @(game.mistakes),
        @"hints": @(game.hintsUsed),
        @"completed": @(game.finished),
        @"progress": @(game.progress)
    };
    [list insertObject:entry atIndex:0];
    while (list.count > (NSUInteger)kSDKHistoryLimit) [list removeLastObject];
    [self setJSONObject:list forKey:kSDKKeyHistory];
}

- (NSArray<NSDictionary *> *)rawHistory {
    id obj = [self jsonObjectForKey:kSDKKeyHistory];
    if (![obj isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *clean = [NSMutableArray array];
    for (id item in (NSArray *)obj) {
        if ([item isKindOfClass:[NSDictionary class]]) [clean addObject:item];
    }
    return clean;
}

- (NSArray<NSDictionary *> *)history {
    return [self rawHistory];
}

- (void)clearHistory {
    [self setJSONObject:nil forKey:kSDKKeyHistory];
}

- (void)deleteHistoryEntryWithDate:(NSTimeInterval)timestamp {
    NSMutableArray *keep = [NSMutableArray array];
    for (NSDictionary *e in [self rawHistory]) {
        if (fabs([e[@"date"] doubleValue] - timestamp) > 0.5) [keep addObject:e];
    }
    [self setJSONObject:keep forKey:kSDKKeyHistory];
}

#pragma mark - Statistics

- (NSDictionary *)statsForDifficulty:(SDKDifficulty)difficulty {
    NSInteger played = 0, completed = 0, best = 0;
    double totalSeconds = 0;
    NSInteger totalMistakes = 0;

    for (NSDictionary *e in [self rawHistory]) {
        if ([e[@"difficulty"] integerValue] != difficulty) continue;
        played += 1;
        NSInteger seconds = [e[@"seconds"] integerValue];
        totalSeconds += seconds;
        totalMistakes += [e[@"mistakes"] integerValue];
        if ([e[@"completed"] boolValue]) {
            completed += 1;
            if (best == 0 || (seconds > 0 && seconds < best)) best = seconds;
        }
    }

    return @{
        @"played": @(played),
        @"completed": @(completed),
        @"best": @(best),
        @"average": @(played > 0 ? (NSInteger)lround(totalSeconds / played) : 0),
        @"mistakes": @(totalMistakes)
    };
}

- (NSDictionary *)overallStats {
    NSArray *history = [self rawHistory];
    NSInteger played = (NSInteger)history.count;
    NSInteger completed = 0, best = 0;
    double totalSeconds = 0;
    NSInteger totalMistakes = 0;
    NSInteger totalHints = 0;

    for (NSDictionary *e in history) {
        NSInteger seconds = [e[@"seconds"] integerValue];
        totalSeconds += seconds;
        totalMistakes += [e[@"mistakes"] integerValue];
        totalHints += [e[@"hints"] integerValue];
        if ([e[@"completed"] boolValue]) {
            completed += 1;
            if (best == 0 || (seconds > 0 && seconds < best)) best = seconds;
        }
    }

    return @{
        @"played": @(played),
        @"completed": @(completed),
        @"best": @(best),
        @"average": @(played > 0 ? (NSInteger)lround(totalSeconds / played) : 0),
        @"mistakes": @(totalMistakes),
        @"hints": @(totalHints),
        @"winRate": @(played > 0 ? (double)completed / (double)played : 0.0)
    };
}

- (NSArray<NSNumber *> *)completionsForLastDays:(NSInteger)days {
    NSMutableArray<NSNumber *> *counts = [NSMutableArray array];
    for (NSInteger i = 0; i < MAX(days, 1); i++) [counts addObject:@(0)];

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [cal startOfDayForDate:[NSDate date]];

    for (NSDictionary *e in [self rawHistory]) {
        if (![e[@"completed"] boolValue]) continue;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[e[@"date"] doubleValue]];
        NSDate *day = [cal startOfDayForDate:date];
        NSInteger diff = (NSInteger)[cal components:NSCalendarUnitDay
                                           fromDate:day toDate:today options:0].day;
        if (diff >= 0 && diff < days) {
            NSInteger idx = days - 1 - diff;
            counts[(NSUInteger)idx] = @(counts[(NSUInteger)idx].integerValue + 1);
        }
    }
    return counts;
}

#pragma mark - Reset

- (void)resetAllData {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    for (NSString *key in @[kSDKKeyCurrentGame, kSDKKeyHistory]) [d removeObjectForKey:key];
}

@end
