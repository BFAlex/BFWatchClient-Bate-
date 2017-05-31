//
//  BFWPManager.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFWPManager.h"

@interface BFWPManager () {
    // Manager 实现队列
    dispatch_queue_t _managerQueue;
    void *_managerQueueTag;
    NSMutableArray *_oftenPool; // 频繁操作
}

@end

@implementation BFWPManager

+ (instancetype)shareWPManager {
    static BFWPManager *shareWPManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareWPManager = [[BFWPManager alloc] init];
        [shareWPManager configureManager];
    });
    
    return shareWPManager;
}

- (void)configureManager {
    BFLogTrace();
    
    // Stream
    [self configureStream];
    
}

- (void)configureStream {
    BFLogTrace();
    _socketStream = [BFSocketStream shareStream];
    
    // 设置服务器
    _socketStream.hostName = HostName;
    // 设置端口
    _socketStream.hostPort = HostPort;
    // 添加WPManager作为Stream的代理
    [_socketStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    /* 初始化模块 */
    // 心跳
    // 自动重连
    // ...
    
    
}

/**
 1、Socket处于连接状态: 直接登录
 2、Socket处于断开状态: 线连接Scoket，成功后再登录

 @return 成功/失败
 */
- (BOOL)Login {
    BFLog(@"");
    NSError *error;
    BOOL result;
    
    // 判断是否连接服务器
    if (![_socketStream isConnected]) {
        // 连接 server
        BFLog([NSString stringWithFormat:@"连接服务器"]);
        result = [self connectToServer:&error];
    } else {
        // 登录操作
        BFLog([NSString stringWithFormat:@"执行登录操作"]);
    }
    
    return result;
}

/**
 连接 server
 */
- (BOOL)connectToServer:(NSError **)err {
    BFLogTrace();
    
    BOOL result = [self.socketStream connectWithTimeout:-1 type:0 error:err];
    
    return result;
}

#pragma mark - stream delegate

//-(void)bfwpStream:(BFSocketStream *)sender socketDidConnect:(GCDAsyncSocket *)socket;

@end
