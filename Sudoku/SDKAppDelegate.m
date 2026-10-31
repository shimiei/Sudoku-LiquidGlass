//
//  SDKAppDelegate.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKAppDelegate.h"
#import "SDKStore.h"
#import "SDKTheme.h"
#import "SDKHomeViewController.h"

@implementation SDKAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
