//
//  SDKHistoryViewController.h
//  Sudoku — Apple HIG rebuild
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKHistoryViewController : UIViewController

/// 0 = 对局记录, 1 = 数据统计.
- (instancetype)initWithSection:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END
