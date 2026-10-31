//
//  SDKBoardView.h
//  Sudoku — Liquid Glass Edition
//
//  The 9x9 grid: everything is drawn with Core Graphics so it stays crisp
//  and cheap, with a few CALayers on top for the animated selection ring.
//

#import <UIKit/UIKit.h>
#import "SDKGameState.h"

NS_ASSUME_NONNULL_BEGIN

@class SDKBoardView;

@protocol SDKBoardViewDelegate <NSObject>
- (void)boardView:(SDKBoardView *)board didSelectIndex:(NSInteger)index;
@optional
- (void)boardView:(SDKBoardView *)board didMoveFingerTo:(CGPoint)point insideBoard:(BOOL)inside;
- (void)boardViewDidEndTracking:(SDKBoardView *)board;
@end

@interface SDKBoardView : UIView

@property (nonatomic, strong, nullable) SDKGameState *game;
@property (nonatomic, assign) NSInteger selectedIndex;   // -1 = none
@property (nonatomic, weak, nullable) id<SDKBoardViewDelegate> delegate;

@property (nonatomic, assign) BOOL highlightSameNumbers;
@property (nonatomic, assign) BOOL highlightPeers;
@property (nonatomic, assign) BOOL showConflicts;
@property (nonatomic, assign) BOOL autoCheck;
@property (nonatomic, assign) CGFloat contentInset;

- (CGRect)rectForCellAtIndex:(NSInteger)index;
- (nullable NSValue *)cellCenterValueAtIndex:(NSInteger)index;
- (NSInteger)indexForPoint:(CGPoint)point;
- (CGFloat)cellSize;

- (void)reloadData;
- (void)flashIndex:(NSInteger)index color:(nullable UIColor *)color;
- (void)celebrateCompletion;
- (void)cancelTracking;

@end

NS_ASSUME_NONNULL_END
