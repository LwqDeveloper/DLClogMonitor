//
//  DLClogMonitor.h
//  DLClogMonitor
//
//  Created by weiqiong.li on 2023/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLClogMonitor : NSObject

+ (instancetype)shared;

/// 单次卡顿时间
@property (nonatomic, assign) NSUInteger clogTime;
/// 单次卡死时间
@property (nonatomic, assign) NSUInteger deadTime;

/// 卡顿回调
@property (nonatomic, copy) void(^clogHandler)(NSString *className, float interval);
/// 卡死回调
@property (nonatomic, copy) void(^deadHandler)(NSString *className);

@end

NS_ASSUME_NONNULL_END
