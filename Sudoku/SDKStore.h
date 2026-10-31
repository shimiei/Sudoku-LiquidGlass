//
//  SDKStore.h
//  Sudoku — Liquid Glass Edition
//
//  Settings, autosaved game, match history and statistics.
//

#import <Foundation/Foundation.h>
#import "SDKGameState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDKStore : NSObject

+ (instancetype)shared;

#pragma mark - Settings (persisted)

@property (nonatomic, assign) BOOL highlightSameNumbers;
@property (nonatomic, assign) BOOL highlightPeers;
@property (nonatomic, assign) BOOL showConflicts;     // duplicate digits in row/col/box
@property (nonatomic, assign) BOOL autoCheck;         // flag digits that break the solution
@property (nonatomic, assign) BOOL autoClearNotes;    // remove notes of placed digits
@property (nonatomic, assign) BOOL loupeEnabled;      // magnifier while dragging
@property (nonatomic, assign) BOOL hapticsEnabled;

- (void)applyGlobalSideEffects;

#pragma mark - Autosaved game

- (nullable SDKGameState *)currentGame;
- (void)saveCurrentGame:(nullable SDKGameState *)game;

#pragma mark - History

/// Records a game in the history list (and therefore in the statistics).
- (void)recordGame:(SDKGameState *)game;

/// 把一局未完成的进度存进历史，之后可以从历史里接着玩。
/// 只保留最近若干局未完成的，避免存档无限膨胀。
- (void)archiveUnfinishedGame:(SDKGameState *)game;

/// 取回某条历史里未完成的对局（没有则为 nil）。
- (nullable SDKGameState *)gameForHistoryTimestamp:(NSTimeInterval)timestamp;

/// 未完成且可续玩的对局数量。
- (NSInteger)resumableCount;
- (NSArray<NSDictionary *> *)history;
- (void)clearHistory;
- (void)deleteHistoryEntryWithDate:(NSTimeInterval)timestamp;

/// 记录的唯一 id（时间戳精确到毫秒也可能撞车，续玩/删除都按 id 认人）
- (nullable SDKGameState *)gameForHistoryIdentifier:(NSString *)identifier;
- (void)deleteHistoryEntryWithIdentifier:(NSString *)identifier;

#pragma mark - Statistics

- (NSDictionary *)statsForDifficulty:(SDKDifficulty)difficulty;
- (NSDictionary *)overallStats;
- (NSArray<NSNumber *> *)completionsForLastDays:(NSInteger)days;

#pragma mark - Reset

- (void)resetAllData;

@end

NS_ASSUME_NONNULL_END
