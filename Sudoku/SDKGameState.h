//
//  SDKGameState.h
//  Sudoku — Liquid Glass Edition
//
//  One playable game: values, pencil notes, undo history, timer.
//

#import <Foundation/Foundation.h>
#import "SDKSudokuEngine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDKPlaceResult) {
    SDKPlaceResultInvalid = 0,   // nothing changed
    SDKPlaceResultCorrect,       // digit placed and matches the solution
    SDKPlaceResultWrong,         // digit placed but wrong
    SDKPlaceResultCleared,       // digit removed
    SDKPlaceResultNoteToggled,   // pencil mark toggled
    SDKPlaceResultCompleted      // digit placed and the board is finished
};

@interface SDKGameState : NSObject

@property (nonatomic, assign) SDKDifficulty difficulty;
@property (nonatomic, copy) NSArray<NSNumber *> *puzzle;    // givens, 0 = empty
@property (nonatomic, copy) NSArray<NSNumber *> *solution;  // solved grid
@property (nonatomic, strong) NSMutableArray<NSNumber *> *values;  // 81 values
@property (nonatomic, strong) NSMutableArray<NSNumber *> *notes;   // 81 bitmasks
@property (nonatomic, assign) NSInteger selectedIndex;             // -1 = none
@property (nonatomic, assign) BOOL noteMode;
@property (nonatomic, assign) NSInteger elapsedSeconds;
@property (nonatomic, assign) NSInteger mistakes;
@property (nonatomic, assign) NSInteger hintsUsed;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, strong) NSDate *startDate;

+ (instancetype)gameWithPuzzle:(SDKSudokuPuzzle *)puzzle;

#pragma mark - Board queries

- (BOOL)isGivenAtIndex:(NSInteger)index;
- (BOOL)isEditableAtIndex:(NSInteger)index;
- (NSInteger)valueAtIndex:(NSInteger)index;
- (NSUInteger)noteMaskAtIndex:(NSInteger)index;
- (BOOL)isWrongAtIndex:(NSInteger)index;
- (BOOL)hasConflictAtIndex:(NSInteger)index;
- (BOOL)isPeerRowOfIndex:(NSInteger)a andIndex:(NSInteger)b;
- (NSInteger)remainingForValue:(NSInteger)value;
- (NSInteger)filledCount;
- (CGFloat)progress;
- (NSInteger)emptyCount;

#pragma mark - Mutations

- (SDKPlaceResult)placeValue:(NSInteger)value atIndex:(NSInteger)index;
- (SDKPlaceResult)toggleNote:(NSInteger)value atIndex:(NSInteger)index;
- (SDKPlaceResult)eraseAtIndex:(NSInteger)index;
- (nullable NSNumber *)applyHintAtIndex:(NSInteger)preferredIndex;
- (void)fillAllNotes;
- (void)clearAllNotes;

#pragma mark - Undo

@property (nonatomic, readonly) BOOL canUndo;
@property (nonatomic, readonly) BOOL canRedo;
- (BOOL)undo;
- (BOOL)redo;
- (void)resetUndoStacks;

#pragma mark - Persistence

- (NSDictionary *)dictionaryRepresentation;
+ (nullable instancetype)gameFromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
