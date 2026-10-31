//
//  SDKGameViewController.h
//  Sudoku — Apple HIG rebuild
//

#import <UIKit/UIKit.h>
#import "SDKSudokuEngine.h"
#import "SDKGameState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDKGameViewController : UIViewController

- (instancetype)initWithDifficulty:(SDKDifficulty)difficulty;
- (instancetype)initWithSavedGame:(SDKGameState *)game;

@end

NS_ASSUME_NONNULL_END
