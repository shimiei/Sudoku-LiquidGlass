//
//  SDKMaterial.h
//  Sudoku
//
//  iOS 26 Liquid Glass 的唯一入口。
//
//  规则：液态玻璃是系统渲染的材质，只有「用 iOS 26 SDK 编译」的 app 才拿得到它。
//  所以这里有两条路径——
//    1) 用 iOS 26 SDK 编译 + 运行在 iOS 26 上  →  真正的 UIGlassEffect / 玻璃按钮
//    2) 其他情况（旧 SDK 编译、旧系统）        →  语义色卡片，占位但不丑
//  其余代码一律只跟本类打交道，不直接碰 UIGlassEffect。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDKMaterial : NSObject

/// 系统当前是否真的会渲染液态玻璃。
+ (BOOL)glassAvailable;

/// 一块圆角玻璃面板（不可交互）。玻璃不可用时返回语义色卡片。
+ (UIView *)panelWithCornerRadius:(CGFloat)radius;

/// 玻璃按钮配置；玻璃不可用时返回 nil，调用方自行回退。
+ (nullable UIButtonConfiguration *)glassButtonConfigurationProminent:(BOOL)prominent;

/// 圆形玻璃（放大镜用）；不可用时返回 nil。
+ (nullable UIView *)glassCircleWithDiameter:(CGFloat)diameter;

@end

NS_ASSUME_NONNULL_END
