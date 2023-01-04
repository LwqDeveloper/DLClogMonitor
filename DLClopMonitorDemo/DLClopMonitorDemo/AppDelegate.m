//
//  AppDelegate.m
//  DLClopMonitorDemo
//
//  Created by weiqiong.li on 2023/1/4.
//

#import "AppDelegate.h"
#import "DLClogMonitor.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[DLClogMonitor shared] setClogHandler:^(NSString * _Nonnull className, float interval) {
        
    }];
    [[DLClogMonitor shared] setDeadHandler:^(NSString * _Nonnull className) {
        
    }];
    
    return YES;
}

@end
