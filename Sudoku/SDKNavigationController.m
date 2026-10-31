//
//  SDKNavigationController.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKNavigationController.h"
#import "SDKTheme.h"

@interface SDKNavigationController () <UINavigationControllerDelegate>
@end

@implementation SDKNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.delegate = self;
    self.view.backgroundColor = [SDKTheme bgBottom];
    self.interactivePopGestureRecognizer.enabled = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (UIViewController *)childViewControllerForStatusBarStyle { return self.topViewController; }

@end
