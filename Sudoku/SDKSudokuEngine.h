//
//  SDKSudokuEngine.h
//  Sudoku — Liquid Glass Edition
//
//  Puzzle generation + solving. Pure C inside, no UIKit dependency.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDKDifficulty) {
    SDKDifficultyEasy = 0,
    SDKDifficultyMedium = 1,
    SDKDifficultyHard = 2
};

NSString *SDKDifficultyTitle(SDKDifficulty difficulty);

@interface SDKSudokuPuzzle : NSObject

/// 81 numbers, 0 = empty.
@property (nonatomic, copy) NSArray<NSNumber *> *puzzle;
/// 81 numbers, the complete solution.
@property (nonatomic, copy) NSArray<NSNumber *> *solution;
@property (nonatomic, assign) SDKDifficulty difficulty;
@property (nonatomic, assign) NSInteger clueCount;

@end

@interface SDKSudokuEngine : NSObject

/// Generates a puzzle with a guaranteed unique solution.
+ (SDKSudokuPuzzle *)generatePuzzle:(SDKDifficulty)difficulty;

/// Number of solutions of the given board, counting no further than `limit`.
+ (NSInteger)countSolutions:(NSArray<NSNumber *> *)board limit:(NSInteger)limit;

/// Whether `value` can be placed at `index` without repeating in row / column / box.
+ (BOOL)isPlacementValid:(NSArray<NSNumber *> *)board index:(NSInteger)index value:(NSInteger)value;

/// Bitmask (bit d-1) of digits that may legally be placed at `index`.
+ (NSUInteger)candidateMask:(NSArray<NSNumber *> *)board index:(NSInteger)index;

/// Solves a board in place; returns nil when unsolvable.
+ (nullable NSArray<NSNumber *> *)solveBoard:(NSArray<NSNumber *> *)board;

@end

NS_ASSUME_NONNULL_END
