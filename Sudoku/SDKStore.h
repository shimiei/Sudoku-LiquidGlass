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
- (NSArray<NSDictionary *> *)history;
- (void)clearHistory;
- (void)deleteHistoryEntryWithDate:(NSTimeInterval)timestamp;

#pragma mark - Statistics

- (NSDictionary *)statsForDifficulty:(SDKDifficulty)difficulty;
- (NSDictionary *)overallStats;
- (NSArray<NSNumber *> *)completionsForLastDays:(NSInteger)days;

#pragma mark - Reset

- (void)resetAllData;

@end

NS_ASSUME_NONNULL_END
