//
//  SDKHistoryViewController.h
//  Sudoku — Liquid Glass Edition
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDKHistorySection) {
    SDKHistorySectionRecords = 0,
    SDKHistorySectionStats = 1
};

@interface SDKHistoryViewController : UIViewController

- (instancetype)initWithSection:(SDKHistorySection)section;

@end

NS_ASSUME_NONNULL_END
