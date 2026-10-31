//
//  SDKBoardView.h
//  Sudoku — Apple HIG rebuild
//

#import <UIKit/UIKit.h>
#import "SDKGameState.h"

NS_ASSUME_NONNULL_BEGIN

@class SDKBoardView;

@protocol SDKBoardViewDelegate <NSObject>
- (void)boardView:(SDKBoardView *)boardView didSelectIndex:(NSInteger)index;
@optional
- (void)boardView:(SDKBoardView *)boardView
   didMoveFingerTo:(CGPoint)point
        cellIndex:(NSInteger)index
      insideBoard:(BOOL)inside;
- (void)boardViewDidEndTracking:(SDKBoardView *)boardView;
@end

/// A plain 9×9 card: system colours, hairline separators, rounded corners.
/// The same drawing routine also feeds the magnifier, so both stay identical.
@interface SDKBoardView : UIView

@property (nonatomic, weak, nullable) id<SDKBoardViewDelegate> delegate;
@property (nonatomic, strong, nullable) SDKGameState *game;

@property (nonatomic) NSInteger selectedIndex;   // -1 when nothing is selected
@property (nonatomic) BOOL highlightSameNumbers;
@property (nonatomic) BOOL highlightPeers;
@property (nonatomic) BOOL showConflicts;
@property (nonatomic) BOOL autoCheck;
@property (nonatomic) CGFloat contentInset;      // default 6

- (CGFloat)cellSize;
- (CGRect)gridRect;                              // the 9×9 square inside the card
- (CGRect)rectForIndex:(NSInteger)index;
- (CGPoint)centerForIndex:(NSInteger)index;
- (NSInteger)indexAtPoint:(CGPoint)point;

- (void)reloadData;
- (void)flashIndex:(NSInteger)index color:(UIColor *)color;
- (void)celebrateCompletion;

/// Draws the whole grid (highlights, rules, digits) into `gridRect` in the given
/// context's coordinate space. Used by the view itself and by the magnifier.
- (void)drawGridInRect:(CGRect)gridRect context:(CGContextRef)ctx;

@end

NS_ASSUME_NONNULL_END
