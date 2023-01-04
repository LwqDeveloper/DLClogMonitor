//
//  DLClogMonitor.m
//  DLClogMonitor
//
//  Created by weiqiong.li on 2023/1/3.
//

#import "DLClogMonitor.h"
#import "AppDelegate.h"

@interface DLClogMonitor ()

@property (nonatomic, assign) CFRunLoopObserverRef runloopObserver;
@property (nonatomic, assign) CFRunLoopActivity runloopActivity;
@property (nonatomic, assign) dispatch_semaphore_t semaphore;

@property (nonatomic, assign) NSUInteger clogCount;

@end

@implementation DLClogMonitor

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static DLClogMonitor *monitor;
    dispatch_once(&onceToken, ^{
        monitor = [[DLClogMonitor alloc] init];
        
    });
    return monitor;
}

- (instancetype)init {
    if (self = [super init]) {
        self.clogTime = 80;
        self.deadTime = 5000;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)startMonitor {
    if (_runloopObserver == NULL) return;
    
    dispatch_queue_t queue = dispatch_queue_create("DLClogMonitor", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        while (YES) {
            /// 信号量-1
            long tmp = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, self.clogTime *NSEC_PER_MSEC));
            if (tmp < 0) {
                /// 小于0，则是在等待
                if (self.runloopActivity == kCFRunLoopBeforeSources ||
                    self.runloopActivity == kCFRunLoopAfterWaiting) {
                    self.clogCount ++;
                    if (++ self.clogCount < 3) continue;
                    /// 卡顿3次，寻找位置
                    [self findClogLocation];
                }
            } else {
                /// 大于等于0，正常运行
                self.clogCount = 0;
            }
        }
    });
}

- (void)stopMonitor {
    if (_runloopObserver == NULL) return;
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _runloopObserver, kCFRunLoopCommonModes);
    CFRelease(_runloopObserver);
    _runloopObserver = NULL;
}

- (void)findClogLocation {
    static BOOL mainThreadPing = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        mainThreadPing = NO;
        /// 3次runloop丢失时间
        __block CFTimeInterval blockTime = self.clogTime *3 /1000.f;
        CFTimeInterval startTime = CACurrentMediaTime();
        dispatch_async(dispatch_get_main_queue(), ^{
            mainThreadPing = YES;
            CFTimeInterval endTime = CACurrentMediaTime();
            /// ping主线程时间
            blockTime += (endTime -startTime);
            if (blockTime < self.deadTime && self.clogHandler) {
                /// 卡顿
                self.clogHandler([self currentVCName], blockTime);
            }
        });
        /// 检测主线程未响应
        [NSThread sleepForTimeInterval:self.deadTime /1000.f];
        if (mainThreadPing == NO && self.deadHandler) {
            self.deadHandler([self currentVCName]);
        }
    });
}

- (NSString *)currentVCName {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIViewController *mainVC = delegate.window.rootViewController;
    if ([mainVC isKindOfClass:UITabBarController.class]) {
        UITabBarController *tabVC = (UITabBarController *)mainVC;
        return [self currentVCFromController:tabVC.selectedViewController];
    }
    return [self currentVCFromController:mainVC];
}

- (NSString *)currentVCFromController:(UIViewController *)controller {
    if ([controller isKindOfClass:UIViewController.class]) {
        return NSStringFromClass(controller.class);
    } else if ([controller isKindOfClass:UINavigationController.class]) {
        UINavigationController *mainNav = (UINavigationController *)controller;
        return NSStringFromClass(mainNav.topViewController.class);
    }
    return @"";
}

#pragma mark - notification
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self startMonitor];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self stopMonitor];
}

#pragma mark - block
static void mainRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    DLClogMonitor *monitor = (__bridge DLClogMonitor *)info;
    monitor.runloopActivity = activity;
    /// 信号量 +1
    dispatch_semaphore_signal(monitor.semaphore);
}

#pragma mark - getter
- (CFRunLoopObserverRef)runloopObserver {
    if (_runloopObserver == NULL) {
        CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
        _runloopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &mainRunLoopObserverCallBack, &context);
        CFRunLoopAddObserver(CFRunLoopGetMain(), _runloopObserver, kCFRunLoopCommonModes);
    }
    return _runloopObserver;
}

@end
