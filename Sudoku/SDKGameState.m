//
//  SDKGameState.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKGameState.h"
#import "SDKStore.h"

@interface SDKGameState ()
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *undoStack;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *redoStack;
- (NSInteger)solutionAt:(NSInteger)index;
- (void)refreshFinishedFlag;
- (void)clearPeerNotes:(NSInteger)value atIndex:(NSInteger)index;
- (NSDictionary *)snapshot;
- (void)pushUndoSnapshot;
- (void)restoreSnapshot:(NSDictionary *)snap;
@end

@implementation SDKGameState

+ (instancetype)gameWithPuzzle:(SDKSudokuPuzzle *)puzzle {
    SDKGameState *g = [SDKGameState new];
    g.difficulty = puzzle.difficulty;
    g.puzzle = puzzle.puzzle;
    g.solution = puzzle.solution;
    g.values = [puzzle.puzzle mutableCopy];
    g.notes = [NSMutableArray arrayWithCapacity:81];
    for (NSInteger i = 0; i < 81; i++) [g.notes addObject:@(0)];
    g.selectedIndex = -1;
    g.noteMode = NO;
    g.elapsedSeconds = 0;
    g.mistakes = 0;
    g.hintsUsed = 0;
    g.finished = NO;
    g.paused = NO;
    g.startDate = [NSDate date];
    g.undoStack = [NSMutableArray array];
    g.redoStack = [NSMutableArray array];
    return g;
}

#pragma mark - Board queries

- (BOOL)isGivenAtIndex:(NSInteger)index {
    if (index < 0 || index > 80 || index >= (NSInteger)self.puzzle.count) return NO;
    return self.puzzle[(NSUInteger)index].integerValue != 0;
}

- (BOOL)isEditableAtIndex:(NSInteger)index {
    return (index >= 0 && index <= 80) && ![self isGivenAtIndex:index];
}

- (NSInteger)valueAtIndex:(NSInteger)index {
    if (index < 0 || index > 80 || index >= (NSInteger)self.values.count) return 0;
    return self.values[(NSUInteger)index].integerValue;
}

- (NSUInteger)noteMaskAtIndex:(NSInteger)index {
    if (index < 0 || index > 80 || index >= (NSInteger)self.notes.count) return 0;
    return (NSUInteger)self.notes[(NSUInteger)index].unsignedIntegerValue;
}

- (BOOL)isWrongAtIndex:(NSInteger)index {
    NSInteger v = [self valueAtIndex:index];
    if (v == 0) return NO;
    if (index >= (NSInteger)self.solution.count) return NO;
    return self.solution[(NSUInteger)index].integerValue != v;
}

- (BOOL)hasConflictAtIndex:(NSInteger)index {
    NSInteger v = [self valueAtIndex:index];
    if (v == 0) return NO;
    NSInteger row = index / 9, col = index % 9;
    NSInteger boxRow = (row / 3) * 3, boxCol = (col / 3) * 3;
    for (NSInteger i = 0; i < 9; i++) {
        NSInteger idxs[3] = { row * 9 + i, i * 9 + col, (boxRow + i / 3) * 9 + (boxCol + i % 3) };
        for (int k = 0; k < 3; k++) {
            NSInteger other = idxs[k];
            if (other == index) continue;
            if ([self valueAtIndex:other] == v) return YES;
        }
    }
    return NO;
}

- (BOOL)isPeerRowOfIndex:(NSInteger)a andIndex:(NSInteger)b {
    if (a < 0 || b < 0) return NO;
    NSInteger ra = a / 9, ca = a % 9, rb = b / 9, cb = b % 9;
    if (ra == rb || ca == cb) return YES;
    return ((ra / 3) == (rb / 3)) && ((ca / 3) == (cb / 3));
}

- (NSInteger)remainingForValue:(NSInteger)value {
    NSInteger count = 0;
    for (NSInteger i = 0; i < 81; i++) if ([self valueAtIndex:i] == value) count++;
    return MAX(0, 9 - count);
}

- (NSInteger)filledCount {
    NSInteger n = 0;
    for (NSInteger i = 0; i < 81; i++) if ([self valueAtIndex:i] != 0) n++;
    return n;
}

- (NSInteger)emptyCount {
    return 81 - [self filledCount];
}

- (CGFloat)progress {
    return (CGFloat)[self filledCount] / 81.0;
}

#pragma mark - Undo bookkeeping

- (NSDictionary *)snapshot {
    return @{ @"values": [self.values copy],
              @"notes": [self.notes copy],
              @"mistakes": @(self.mistakes),
              @"hints": @(self.hintsUsed) };
}

- (void)pushUndoSnapshot {
    if (!self.undoStack) self.undoStack = [NSMutableArray array];
    [self.undoStack addObject:[self snapshot]];
    if (self.undoStack.count > 120) [self.undoStack removeObjectAtIndex:0];
    [self.redoStack removeAllObjects];
}

- (void)restoreSnapshot:(NSDictionary *)snap {
    NSArray *v = snap[@"values"];
    NSArray *n = snap[@"notes"];
    if (v.count == 81) self.values = [v mutableCopy];
    if (n.count == 81) self.notes = [n mutableCopy];
    self.mistakes = [snap[@"mistakes"] integerValue];
    self.hintsUsed = [snap[@"hints"] integerValue];
}

- (BOOL)canUndo { return self.undoStack.count > 0; }
- (BOOL)canRedo { return self.redoStack.count > 0; }

- (BOOL)undo {
    if (self.undoStack.count == 0) return NO;
    NSDictionary *current = [self snapshot];
    NSDictionary *snap = self.undoStack.lastObject;
    [self.undoStack removeLastObject];
    [self.redoStack addObject:current];
    [self restoreSnapshot:snap];
    [self refreshFinishedFlag];
    return YES;
}

- (BOOL)redo {
    if (self.redoStack.count == 0) return NO;
    NSDictionary *current = [self snapshot];
    NSDictionary *snap = self.redoStack.lastObject;
    [self.redoStack removeLastObject];
    [self.undoStack addObject:current];
    [self restoreSnapshot:snap];
    [self refreshFinishedFlag];
    return YES;
}

- (void)resetUndoStacks {
    [self.undoStack removeAllObjects];
    [self.redoStack removeAllObjects];
}

#pragma mark - Mutations

- (void)refreshFinishedFlag {
    BOOL done = YES;
    for (NSInteger i = 0; i < 81; i++) {
        if (self.solution.count < 81) { done = NO; break; }
        if ([self valueAtIndex:i] != self.solution[(NSUInteger)i].integerValue) { done = NO; break; }
    }
    self.finished = done;
}

- (void)clearPeerNotes:(NSInteger)value atIndex:(NSInteger)index {
    if (value < 1 || value > 9) return;
    NSUInteger bit = 1u << (NSUInteger)(value - 1);
    for (NSInteger i = 0; i < 81; i++) {
        if (i == index) continue;
        if (![self isPeerRowOfIndex:index andIndex:i]) continue;
        NSUInteger mask = [self noteMaskAtIndex:i];
        if (mask & bit) self.notes[(NSUInteger)i] = @(mask & ~bit);
    }
}

- (SDKPlaceResult)placeValue:(NSInteger)value atIndex:(NSInteger)index {
    if (value < 1 || value > 9) return SDKPlaceResultInvalid;
    if (![self isEditableAtIndex:index]) return SDKPlaceResultInvalid;

    if ([self valueAtIndex:index] == value) {
        // Tapping the same digit clears it — a familiar, forgiving gesture.
        return [self eraseAtIndex:index];
    }

    [self pushUndoSnapshot];
    self.values[(NSUInteger)index] = @(value);
    self.notes[(NSUInteger)index] = @(0);

    BOOL correct = [self isWrongAtIndex:index] == NO;
    if (!correct) self.mistakes += 1;

    if ([SDKStore shared].autoClearNotes) {
        [self clearPeerNotes:value atIndex:index];
    }

    [self refreshFinishedFlag];
    if (self.finished) return SDKPlaceResultCompleted;
    return correct ? SDKPlaceResultCorrect : SDKPlaceResultWrong;
}

- (SDKPlaceResult)toggleNote:(NSInteger)value atIndex:(NSInteger)index {
    if (value < 1 || value > 9) return SDKPlaceResultInvalid;
    if (![self isEditableAtIndex:index]) return SDKPlaceResultInvalid;
    if ([self valueAtIndex:index] != 0) return SDKPlaceResultInvalid;

    [self pushUndoSnapshot];
    NSUInteger mask = [self noteMaskAtIndex:index];
    NSUInteger bit = 1u << (NSUInteger)(value - 1);
    mask = (mask & bit) ? (mask & ~bit) : (mask | bit);
    self.notes[(NSUInteger)index] = @(mask);
    return SDKPlaceResultNoteToggled;
}

- (SDKPlaceResult)eraseAtIndex:(NSInteger)index {
    if (![self isEditableAtIndex:index]) return SDKPlaceResultInvalid;
    BOOL hadValue = [self valueAtIndex:index] != 0;
    BOOL hadNotes = [self noteMaskAtIndex:index] != 0;
    if (!hadValue && !hadNotes) return SDKPlaceResultInvalid;
    [self pushUndoSnapshot];
    self.values[(NSUInteger)index] = @(0);
    self.notes[(NSUInteger)index] = @(0);
    [self refreshFinishedFlag];
    return SDKPlaceResultCleared;
}

- (NSNumber *)applyHintAtIndex:(NSInteger)preferredIndex {
    NSInteger target = -1;
    if (preferredIndex >= 0 && preferredIndex <= 80) {
        if ([self isEditableAtIndex:preferredIndex] &&
            ([self valueAtIndex:preferredIndex] == 0 || [self isWrongAtIndex:preferredIndex])) {
            target = preferredIndex;
        }
    }
    if (target < 0) {
        for (NSInteger i = 0; i < 81; i++) {
            if ([self isEditableAtIndex:i] && [self valueAtIndex:i] != [self solutionAt:i]) { target = i; break; }
        }
    }
    if (target < 0) return nil;

    [self pushUndoSnapshot];
    NSInteger answer = [self solutionAt:target];
    self.values[(NSUInteger)target] = @(answer);
    self.notes[(NSUInteger)target] = @(0);
    self.hintsUsed += 1;
    [self clearPeerNotes:answer atIndex:target];
    [self refreshFinishedFlag];
    return @(target);
}

- (NSInteger)solutionAt:(NSInteger)index {
    if (index < 0 || index > 80 || index >= (NSInteger)self.solution.count) return 0;
    return self.solution[(NSUInteger)index].integerValue;
}

- (void)fillAllNotes {
    [self pushUndoSnapshot];
    for (NSInteger i = 0; i < 81; i++) {
        if (![self isEditableAtIndex:i]) continue;
        if ([self valueAtIndex:i] != 0) continue;
        NSUInteger mask = [SDKSudokuEngine candidateMask:self.values index:i];
        self.notes[(NSUInteger)i] = @(mask);
    }
}

- (void)clearAllNotes {
    [self pushUndoSnapshot];
    for (NSInteger i = 0; i < 81; i++) self.notes[(NSUInteger)i] = @(0);
}

#pragma mark - Persistence

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"difficulty": @(self.difficulty),
        @"puzzle": self.puzzle ?: @[],
        @"solution": self.solution ?: @[],
        @"values": self.values ?: @[],
        @"notes": self.notes ?: @[],
        @"elapsed": @(self.elapsedSeconds),
        @"mistakes": @(self.mistakes),
        @"hints": @(self.hintsUsed),
        @"finished": @(self.finished),
        @"startedAt": @([(self.startDate ?: [NSDate date]) timeIntervalSince1970])
    };
}

+ (instancetype)gameFromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    NSArray *puzzle = dict[@"puzzle"];
    NSArray *solution = dict[@"solution"];
    NSArray *values = dict[@"values"];
    if (puzzle.count != 81 || solution.count != 81 || values.count != 81) return nil;

    SDKGameState *g = [SDKGameState new];
    g.difficulty = (SDKDifficulty)[dict[@"difficulty"] integerValue];
    g.puzzle = puzzle;
    g.solution = solution;
    g.values = [values mutableCopy];
    NSArray *notes = dict[@"notes"];
    g.notes = [NSMutableArray arrayWithCapacity:81];
    for (NSInteger i = 0; i < 81; i++) {
        NSNumber *n = (i < (NSInteger)notes.count) ? notes[(NSUInteger)i] : @(0);
        [g.notes addObject:@(n.unsignedIntegerValue)];
    }
    g.elapsedSeconds = [dict[@"elapsed"] integerValue];
    g.mistakes = [dict[@"mistakes"] integerValue];
    g.hintsUsed = [dict[@"hints"] integerValue];
    g.finished = [dict[@"finished"] boolValue];
    g.selectedIndex = -1;
    g.noteMode = NO;
    g.paused = NO;
    NSTimeInterval ts = [dict[@"startedAt"] doubleValue];
    g.startDate = ts > 0 ? [NSDate dateWithTimeIntervalSince1970:ts] : [NSDate date];
    g.undoStack = [NSMutableArray array];
    g.redoStack = [NSMutableArray array];
    return g;
}

@end
