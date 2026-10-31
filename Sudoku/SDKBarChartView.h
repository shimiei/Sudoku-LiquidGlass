//
//  SDKBarChartView.h
//  Sudoku — Liquid Glass Edition
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKBarChartView : UIView

@property (nonatomic, copy, nullable) NSArray<NSNumber *> *values;
@property (nonatomic, copy, nullable) NSArray<NSString *> *labels;
@property (nonatomic, strong, nullable) UIColor *barColor;

@end

NS_ASSUME_NONNULL_END
