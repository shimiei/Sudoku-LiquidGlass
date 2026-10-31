//
//  SDKLoupeView.h
//  Sudoku — Liquid Glass Edition
//
//  A real magnifier: it re-renders the neighbourhood of the touched cell at
//  `magnification` scale, clipped to a glass circle, so you can read the cell
//  under your finger without lifting it.
//

#import <UIKit/UIKit.h>
#import "SDKGameState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDKLoupeView : UIView

@property (nonatomic, weak, nullable) SDKGameState *game;
@property (nonatomic, assign) CGFloat magnification;   // default 2.15
@property (nonatomic, assign) NSInteger focusIndex;    // cell being magnified
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

- (void)presentInHost:(UIView *)host
                center:(CGPoint)center
            boardPoint:(CGPoint)boardPoint
              cellSize:(CGFloat)cellSize
                  game:(SDKGameState *)game
            focusIndex:(NSInteger)focusIndex;

- (void)updateCenter:(CGPoint)center
          boardPoint:(CGPoint)boardPoint
            cellSize:(CGFloat)cellSize
          focusIndex:(NSInteger)focusIndex;

- (void)hideAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
