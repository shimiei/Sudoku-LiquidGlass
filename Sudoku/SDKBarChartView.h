//
//  SDKBarChartView.h
//  Sudoku — Apple HIG rebuild
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A small, quiet 7-day bar chart. System tint, no gradients, no glow.
@interface SDKBarChartView : UIView

@property (nonatomic, copy) NSArray<NSNumber *> *values;   // 7 counts, oldest first
@property (nonatomic, copy) NSArray<NSString *> *labels;   // 7 short labels
@property (nonatomic, strong) UIColor *barColor;

@end

NS_ASSUME_NONNULL_END
