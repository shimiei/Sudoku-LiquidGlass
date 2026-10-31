//
//  SDKAppDelegate.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKAppDelegate.h"
#import "SDKTheme.h"
#import "SDKStore.h"
#import "SDKHomeViewController.h"
#import "SDKNavigationController.h"

@implementation SDKAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    [SDKStore shared];   // touch the store early so defaults are registered

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [SDKTheme bgBottom];

    SDKHomeViewController *home = [[SDKHomeViewController alloc] initWithNibName:nil bundle:nil];
    SDKNavigationController *nav = [[SDKNavigationController alloc] initWithRootViewController:home];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    (void)application;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    (void)application;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
