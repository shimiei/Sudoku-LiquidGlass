//
//  SDKCompletionOverlay.h
//  Sudoku
//
//  通关庆祝：玻璃卡 + 难度角色 + 星级 + 数据 + 彩纸。
//  Reduce Motion 打开时自动退化成淡入淡出，不放彩纸、不做弹簧。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDKCompletionAction) {
    SDKCompletionActionReplay = 0,
    SDKCompletionActionHome
};

@interface SDKCompletionOverlay : UIView

- (instancetype)initWithDifficulty:(NSInteger)difficulty
                           seconds:(NSInteger)seconds
                          mistakes:(NSInteger)mistakes
                             hints:(NSInteger)hints
                            isBest:(BOOL)isBest;

/// 盖在 host 上并播放整套入场动画。
- (void)presentInView:(UIView *)host completion:(void (^)(SDKCompletionAction action))completion;

@end

NS_ASSUME_NONNULL_END
