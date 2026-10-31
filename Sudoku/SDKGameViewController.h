//
//  SDKGameViewController.h
//  Sudoku — Liquid Glass Edition
//

#import <UIKit/UIKit.h>
#import "SDKGameState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDKGameViewController : UIViewController

/// Starts a brand new puzzle of the given difficulty.
- (instancetype)initWithDifficulty:(SDKDifficulty)difficulty;

/// Resumes a game (used by "继续游戏" on the home screen).
- (instancetype)initWithSavedGame:(SDKGameState *)game;

@end

NS_ASSUME_NONNULL_END
