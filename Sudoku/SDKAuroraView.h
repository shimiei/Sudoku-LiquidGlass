//
//  SDKAuroraView.h
//  Sudoku — Liquid Glass Edition
//
//  Ambient background: deep gradient + slowly drifting light blobs.
//  This is what the glass panels refract, so it stays deliberately soft.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKAuroraView : UIView

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
