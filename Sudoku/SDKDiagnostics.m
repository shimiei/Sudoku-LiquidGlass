//
//  SDKDiagnostics.m
//  Sudoku
//

#import "SDKDiagnostics.h"

static NSString *const kSDKDiagStep = @"sdk.diag.step";
static NSString *const kSDKDiagCrash = @"sdk.diag.crash";
static NSString *const kSDKDiagClean = @"sdk.diag.clean";

void SDKStep(NSString *step) {
    if (step.length == 0) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 同一步反复写没有意义，跳过省 IO
    if ([defaults stringForKey:kSDKDiagStep] == step) return;
    if (step.length > 200) step = [step substringToIndex:200];
    [defaults setObject:step forKey:kSDKDiagStep];
    [defaults synchronize];
}

NSString *SDKLastCrashStep(void) {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kSDKDiagCrash];
}

void SDKClearCrashStep(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSDKDiagCrash];
    [defaults removeObjectForKey:kSDKDiagStep];
    [defaults synchronize];
}

void SDKSessionBegin(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastStep = [defaults stringForKey:kSDKDiagStep];
    BOOL lastExitWasClean = [defaults objectForKey:kSDKDiagClean] == nil ||
                            [defaults boolForKey:kSDKDiagClean];

    // 上次没正常收尾，而且留下了步骤 → 记成崩溃点
    if (!lastExitWasClean && lastStep.length > 0) {
        [defaults setObject:lastStep forKey:kSDKDiagCrash];
    }
    [defaults removeObjectForKey:kSDKDiagStep];
    [defaults setBool:NO forKey:kSDKDiagClean];
    [defaults synchronize];
}

void SDKSessionEnd(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kSDKDiagClean];
    [defaults synchronize];
}
