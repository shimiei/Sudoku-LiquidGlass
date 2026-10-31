//
//  SDKBackdropView.h
//  Sudoku
//
//  玻璃需要背景才有折射感。这里只放两团极淡的系统色光晕（透明度 ≤ 0.13），
//  浅色 / 深色都成立，也不抢棋盘的注意力。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKBackdropView : UIView
@end

NS_ASSUME_NONNULL_END
