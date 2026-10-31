//
//  SDKDiagnostics.h
//  Sudoku
//
//  一步一条面包屑：崩了之后回到 app，能看到最后走到哪一行代码。
//  未签名自签安装拿不到符号化的 crash log，这是最省事的替身。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 记录「现在走到哪一步」，立刻落盘（崩溃也不会丢）。
FOUNDATION_EXPORT void SDKStep(NSString *step);

/// 上次异常退出前的最后一步；没有异常退出则为 nil。
FOUNDATION_EXPORT NSString *_Nullable SDKLastCrashStep(void);
FOUNDATION_EXPORT void SDKClearCrashStep(void);

/// 启动 / 进后台、退出时调用，用来判断上次是不是正常离开。
FOUNDATION_EXPORT void SDKSessionBegin(void);
FOUNDATION_EXPORT void SDKSessionEnd(void);

NS_ASSUME_NONNULL_END
