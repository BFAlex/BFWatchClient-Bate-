//
//  BFWPSingleManager.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/26.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>

// ***************************************************

// 测试服务器地址
#define HostName @"120.25.120.222" // 测试
#define HostPort 8866

// ***************************************************

@interface BFWPSingleManager : NSObject

+ (instancetype)shareManager;

#pragma mark - Login (登录)
- (BOOL)Login;

#pragma mark - Add/Remove Stream Delegate
- (void)addWPStreamDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeWPStreamDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeWPStreamDelegate:(id)delegate;

@end
