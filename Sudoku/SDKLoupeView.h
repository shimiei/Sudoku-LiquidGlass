//
//  SDKLoupeView.h
//  Sudoku — Apple HIG rebuild
//
//  A real magnifier: it re-draws the grid through the board's own drawing
//  routine, so the cells under the finger stay vector-crisp at any zoom.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SDKBoardView;

@interface SDKLoupeView : UIView

@property (nonatomic) CGFloat diameter;      // default 132
@property (nonatomic) CGFloat magnification; // default 2.1
/// YES while the magnifier is on screen and not fading out.
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

- (void)showInHost:(UIView *)host
          atCenter:(CGPoint)center
             board:(SDKBoardView *)board
        focusIndex:(NSInteger)index;

- (void)moveToCenter:(CGPoint)center
               board:(SDKBoardView *)board
          focusIndex:(NSInteger)index;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
