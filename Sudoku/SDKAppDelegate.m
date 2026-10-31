//
//  SDKAppDelegate.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKAppDelegate.h"
#import "SDKStore.h"
#import "SDKTheme.h"
#import "SDKHomeViewController.h"
#import "SDKDiagnostics.h"

@implementation SDKAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SDKSessionBegin();   // 上次要是崩了，这里会把最后一步记下来
    SDKStore *store = [SDKStore shared];
    [SDKTheme setHapticsEnabled:store.hapticsEnabled];
    [store applyGlobalSideEffects];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    SDKHomeViewController *home = [SDKHomeViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:home];
    nav.navigationBar.prefersLargeTitles = YES;
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    SDKSessionEnd();
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    SDKSessionEnd();
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
