//
//  SDKMaterial.m
//  Sudoku
//

#import "SDKMaterial.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

// 用 iOS 26 SDK 编译时，UIButtonConfiguration 的玻璃工厂方法才存在；
// 旧 SDK 编译则整段被裁掉，app 依旧可构建，只是退回语义色卡片。
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 260000
#define SDK_HAS_GLASS_API 1
#else
#define SDK_HAS_GLASS_API 0
#endif

// UIGlassEffectStyleRegular == 0（iOS 26 枚举第一个值）
static const NSInteger kSDKGlassStyleRegular = 0;

@implementation SDKMaterial

+ (BOOL)glassAvailable {
#if SDK_HAS_GLASS_API
    static BOOL available;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // 有 UIGlassEffect 这一类 = 系统是 iOS 26 起；再用旧 SDK 编译的包不算，
        // 因为系统不会给旧 SDK 包套用新设计。
        available = (NSClassFromString(@"UIGlassEffect") != nil);
    });
    return available;
#else
    return NO;
#endif
}

/// 直接走 runtime 取 UIGlassEffect，不用 @available：
/// @available 会引入 ___isPlatformVersionAtLeast 这个 compiler-rt 内置函数，
/// 而本工具链没有 iOS 版 compiler-rt。
+ (nullable id)newGlassEffectInteractive:(BOOL)interactive {
    Class cls = NSClassFromString(@"UIGlassEffect");
    if (!cls) return nil;
    SEL sel = NSSelectorFromString(@"effectWithStyle:");
    if (![cls respondsToSelector:sel]) return nil;

    id (*send)(id, SEL, NSInteger) = (id (*)(id, SEL, NSInteger))(void *)objc_msgSend;
    id effect = send(cls, sel, kSDKGlassStyleRegular);
    if (!effect) return nil;
    if ([effect respondsToSelector:NSSelectorFromString(@"setInteractive:")]) {
        BOOL flag = interactive;
        void (*setBool)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))(void *)objc_msgSend;
        setBool(effect, NSSelectorFromString(@"setInteractive:"), flag);
    }
    return effect;
}

#pragma mark - Panels

+ (UIView *)panelWithCornerRadius:(CGFloat)radius {
    id effect = [self newGlassEffectInteractive:NO];
    if (effect) {
        UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:(UIVisualEffect *)effect];
        glass.clipsToBounds = YES;
        glass.layer.cornerRadius = radius;
        glass.layer.cornerCurve = kCACornerCurveContinuous;
        return glass;
    }
    // 回退：系统语义色卡片，跟着浅色 / 深色走。
    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    card.layer.cornerRadius = radius;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    return card;
}

#pragma mark - Buttons

+ (nullable UIButtonConfiguration *)glassButtonConfigurationProminent:(BOOL)prominent {
#if SDK_HAS_GLASS_API
    if ([self glassAvailable]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
        return prominent ? [UIButtonConfiguration prominentGlassButtonConfiguration]
                         : [UIButtonConfiguration glassButtonConfiguration];
#pragma clang diagnostic pop
    }
#endif
    return nil;
}

#pragma mark - Circle

+ (nullable UIView *)glassCircleWithDiameter:(CGFloat)diameter {
    id effect = [self newGlassEffectInteractive:YES];   // 跟手时有反光
    if (!effect) return nil;
    UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:(UIVisualEffect *)effect];
    glass.frame = CGRectMake(0, 0, diameter, diameter);
    glass.clipsToBounds = YES;
    glass.layer.cornerRadius = diameter / 2.0;
    glass.layer.cornerCurve = kCACornerCurveContinuous;
    glass.userInteractionEnabled = NO;
    return glass;
}

@end
