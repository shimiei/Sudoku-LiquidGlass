//
//  SDKSudokuEngine.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKSudokuEngine.h"

#include <string.h>
#include <stdlib.h>

NSString *SDKDifficultyTitle(SDKDifficulty difficulty) {
    switch (difficulty) {
        case SDKDifficultyEasy:   return @"简单";
        case SDKDifficultyMedium: return @"中等";
        case SDKDifficultyHard:   return @"困难";
    }
    return @"简单";
}

#pragma mark - Low level board helpers

static inline int SDKPopCount(unsigned m) {
    int c = 0;
    while (m & 0x1FFu) { c += (int)(m & 1u); m >>= 1; }
    return c;
}

static inline void SDKComputeMasks(const int *b, unsigned *rm, unsigned *cm, unsigned *bm) {
    memset(rm, 0, 9 * sizeof(unsigned));
    memset(cm, 0, 9 * sizeof(unsigned));
    memset(bm, 0, 9 * sizeof(unsigned));
    for (int i = 0; i < 81; i++) {
        int d = b[i];
        if (!d) continue;
        int r = i / 9, c = i % 9, bx = (r / 3) * 3 + c / 3;
        unsigned bit = 1u << (unsigned)(d - 1);
        rm[r] |= bit; cm[c] |= bit; bm[bx] |= bit;
    }
}

static int sSDKSolutionBuffer[81];
static int sSDKSolutionFound = 0;

/// Counts solutions (up to `limit`) using MRV ordering. The first solution
/// found is stored in sSDKSolutionBuffer.
static int SDKCountSols(int *b, unsigned *rm, unsigned *cm, unsigned *bm, int limit, int shuffle) {
    int best = -1, bestMask = 0, bestN = 10;
    for (int i = 0; i < 81; i++) {
        if (b[i]) continue;
        int r = i / 9, c = i % 9, bx = (r / 3) * 3 + c / 3;
        unsigned avail = (~(rm[r] | cm[c] | bm[bx])) & 0x1FFu;
        int n = SDKPopCount(avail);
        if (n == 0) return 0;
        if (n < bestN) { bestN = n; best = i; bestMask = (int)avail; if (n == 1) break; }
    }
    if (best < 0) {
        if (!sSDKSolutionFound) {
            memcpy(sSDKSolutionBuffer, b, sizeof(int) * 81);
            sSDKSolutionFound = 1;
        }
        return 1;
    }

    int r = best / 9, c = best % 9, bx = (r / 3) * 3 + c / 3;
    int cand[9], m = 0;
    for (int d = 1; d <= 9; d++) if (bestMask & (1 << (d - 1))) cand[m++] = d;
    if (shuffle) {
        for (int i = m - 1; i > 0; i--) {
            int j = (int)arc4random_uniform((uint32_t)(i + 1));
            int t = cand[i]; cand[i] = cand[j]; cand[j] = t;
        }
    }

    int total = 0;
    for (int k = 0; k < m; k++) {
        int d = cand[k];
        unsigned bit = 1u << (unsigned)(d - 1);
        b[best] = d; rm[r] |= bit; cm[c] |= bit; bm[bx] |= bit;
        total += SDKCountSols(b, rm, cm, bm, limit - total, shuffle);
        b[best] = 0; rm[r] &= ~bit; cm[c] &= ~bit; bm[bx] &= ~bit;
        if (total >= limit) return total;
    }
    return total;
}

static void SDKFillRandomSolution(int *b) {
    unsigned rm[9], cm[9], bm[9];
    SDKComputeMasks(b, rm, cm, bm);
    sSDKSolutionFound = 0;
    SDKCountSols(b, rm, cm, bm, 1, 1);
    memcpy(b, sSDKSolutionBuffer, sizeof(int) * 81);
}

static BOOL SDKHasUniqueSolution(int *b) {
    int copy[81];
    memcpy(copy, b, sizeof(copy));
    unsigned rm[9], cm[9], bm[9];
    SDKComputeMasks(copy, rm, cm, bm);
    return SDKCountSols(copy, rm, cm, bm, 2, 0) == 1;
}

static int SDKClueCount(const int *b) {
    int n = 0;
    for (int i = 0; i < 81; i++) if (b[i]) n++;
    return n;
}

static void SDKShuffleIndices(int *a, int n) {
    for (int i = n - 1; i > 0; i--) {
        int j = (int)arc4random_uniform((uint32_t)(i + 1));
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }
}

static SDKSudokuPuzzle *SDKBuildPuzzle(const int *puzzle, const int *solution, SDKDifficulty difficulty) {
    NSMutableArray *p = [NSMutableArray arrayWithCapacity:81];
    NSMutableArray *s = [NSMutableArray arrayWithCapacity:81];
    for (int i = 0; i < 81; i++) {
        [p addObject:@(puzzle[i])];
        [s addObject:@(solution[i])];
    }
    SDKSudokuPuzzle *pz = [SDKSudokuPuzzle new];
    pz.puzzle = p;
    pz.solution = s;
    pz.difficulty = difficulty;
    pz.clueCount = SDKClueCount(puzzle);
    return pz;
}

#pragma mark - Puzzle

@implementation SDKSudokuPuzzle

- (NSString *)description {
    NSMutableString *s = [NSMutableString string];
    for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
            [s appendFormat:@"%ld", (long)self.puzzle[r * 9 + c].integerValue];
        }
        [s appendString:@"\n"];
    }
    return s;
}

@end

#pragma mark - Engine

@implementation SDKSudokuEngine

+ (SDKSudokuPuzzle *)generatePuzzle:(SDKDifficulty)difficulty {
    int puzzle[81];
    int solution[81];
    int best[81];
    int bestSolution[81];
    int bestDelta = 1 << 30;
    BOOL haveBest = NO;
    int order[81];
    int attempts = (difficulty == SDKDifficultyHard) ? 10 : 14;
    int target = (difficulty == SDKDifficultyEasy) ? 44
               : (difficulty == SDKDifficultyMedium) ? 32 : 24;

    for (int attempt = 0; attempt < attempts; attempt++) {
        memset(puzzle, 0, sizeof(puzzle));
        SDKFillRandomSolution(puzzle);
        memcpy(solution, puzzle, sizeof(solution));

        for (int i = 0; i < 81; i++) order[i] = i;
        SDKShuffleIndices(order, 81);

        if (difficulty == SDKDifficultyHard) {
            // Aggressive minimisation: every remaining clue becomes required.
            int changed = 1, pass = 0;
            while (changed && pass < 8) {
                changed = 0; pass++;
                SDKShuffleIndices(order, 81);
                for (int k = 0; k < 81; k++) {
                    int a = order[k];
                    if (!puzzle[a]) continue;
                    int v = puzzle[a];
                    puzzle[a] = 0;
                    if (SDKHasUniqueSolution(puzzle)) changed = 1;
                    else puzzle[a] = v;
                }
            }
            int clues = SDKClueCount(puzzle);
            if (clues <= 26) return SDKBuildPuzzle(puzzle, solution, difficulty);
        } else {
            // 180° symmetric digging keeps the grid looking tidy.
            int lowBound = (difficulty == SDKDifficultyEasy) ? 38 : 28;
            int highBound = (difficulty == SDKDifficultyEasy) ? 81 : 36;
            for (int k = 0; k < 41; k++) {
                int a = order[k], b = 80 - order[k];
                if (!puzzle[a]) continue;
                int va = puzzle[a], vb = puzzle[b];
                puzzle[a] = 0; puzzle[b] = 0;
                if (!SDKHasUniqueSolution(puzzle)) { puzzle[a] = va; puzzle[b] = vb; }
                if (SDKClueCount(puzzle) <= target) break;
            }
            int clues = SDKClueCount(puzzle);
            if (clues >= lowBound && clues <= highBound) {
                return SDKBuildPuzzle(puzzle, solution, difficulty);
            }
        }

        // Remember the candidate closest to the requested difficulty, keeping
        // its own solution so puzzle and solution never drift apart.
        int delta = abs(SDKClueCount(puzzle) - target);
        if (!haveBest || delta < bestDelta) {
            bestDelta = delta;
            memcpy(best, puzzle, sizeof(best));
            memcpy(bestSolution, solution, sizeof(bestSolution));
            haveBest = YES;
        }
    }

    if (haveBest) return SDKBuildPuzzle(best, bestSolution, difficulty);

    // Extremely unlikely fallback: hand out a solved grid (always self consistent).
    memset(solution, 0, sizeof(solution));
    SDKFillRandomSolution(solution);
    return SDKBuildPuzzle(solution, solution, difficulty);
}

+ (NSInteger)countSolutions:(NSArray<NSNumber *> *)board limit:(NSInteger)limit {
    if (board.count < 81) return 0;
    int b[81];
    for (int i = 0; i < 81; i++) b[i] = (int)board[(NSUInteger)i].integerValue;
    unsigned rm[9], cm[9], bm[9];
    SDKComputeMasks(b, rm, cm, bm);
    sSDKSolutionFound = 0;
    return SDKCountSols(b, rm, cm, bm, (int)MAX(limit, 1), 0);
}

+ (BOOL)isPlacementValid:(NSArray<NSNumber *> *)board index:(NSInteger)index value:(NSInteger)value {
    if (index < 0 || index > 80 || value < 1 || value > 9) return NO;
    return ([self candidateMask:board index:index] & (1u << (unsigned)(value - 1))) != 0;
}

+ (NSUInteger)candidateMask:(NSArray<NSNumber *> *)board index:(NSInteger)index {
    if (index < 0 || index > 80 || board.count < 81) return 0;
    NSInteger row = index / 9, col = index % 9;
    NSInteger boxRow = (row / 3) * 3, boxCol = (col / 3) * 3;
    unsigned used = 0;
    for (NSInteger i = 0; i < 9; i++) {
        NSInteger idxRow = row * 9 + i;
        NSInteger idxCol = i * 9 + col;
        NSInteger idxBox = (boxRow + i / 3) * 9 + (boxCol + i % 3);
        NSInteger d = 0;
        if (idxRow != index) { d = board[(NSUInteger)idxRow].integerValue; if (d) used |= 1u << (unsigned)(d - 1); }
        if (idxCol != index) { d = board[(NSUInteger)idxCol].integerValue; if (d) used |= 1u << (unsigned)(d - 1); }
        if (idxBox != index) { d = board[(NSUInteger)idxBox].integerValue; if (d) used |= 1u << (unsigned)(d - 1); }
    }
    return (~used) & 0x1FFu;
}

+ (NSArray<NSNumber *> *)solveBoard:(NSArray<NSNumber *> *)board {
    if (board.count < 81) return nil;
    int b[81];
    for (int i = 0; i < 81; i++) b[i] = (int)board[(NSUInteger)i].integerValue;
    unsigned rm[9], cm[9], bm[9];
    SDKComputeMasks(b, rm, cm, bm);
    sSDKSolutionFound = 0;
    if (SDKCountSols(b, rm, cm, bm, 1, 0) != 1) return nil;
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:81];
    for (int i = 0; i < 81; i++) [out addObject:@(sSDKSolutionBuffer[i])];
    return out;
}

@end
