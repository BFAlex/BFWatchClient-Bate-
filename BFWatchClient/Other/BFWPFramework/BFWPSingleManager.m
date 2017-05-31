//
//  BFWPSingleManager.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/26.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFWPSingleManager.h"
#import "BFWPStream.h"

//#define BFWP_ACCOUNT    @"BFWP_ACCOUNT"
//#define BFWP_PASSWORD    @"BFWP_PASSWORD"
//#define BFWP_AUTH_TOKEN  @"BFWP_AUTH_TOKEN"

NSString *const BFWPManagerErrorDomain = @"BFWPManagerErrorDomain";

@interface BFWPSingleManager () <BFWPStreamDelegate> {
    // Manager 实现队列
    dispatch_queue_t _managerQueue;
    void *_managerQueueTag;
}
@property (nonatomic, strong) BFWPStream *wpStream;

@end

@implementation BFWPSingleManager

+ (instancetype)shareManager {
    static BFWPSingleManager *shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[BFWPSingleManager alloc] init];
        [shareManager configureManager];
    });
    
    return shareManager;
}

#pragma mark - Custom

- (void)configureManager {
    BFLogTrace();
    
    // 设置Stream
    [self configureStream];
}

- (void)configureStream {
    BFLogTrace();
    
    self.wpStream = [[BFWPStream alloc] init];
    
#warning 搭建完成基本App架构以后在这里增加一个正式和测试服务器的切换条件
    
    // 设置服务器
    self.wpStream.hostName = HostName;
    // 设置服务器端口
    self.wpStream.hostPort = HostPort;
    
    // 注册成为Stream的代理（为什么这个在主队列）
    [self.wpStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark Login

/**
 账号登录
 1、判断是否已经连接服务器
 2、是：直接登录
 3、否：先连接，后登录
 */
- (BOOL)Login {
    BFLogTrace();
    
    NSError *error;
    
    if ([self isConnected]) {
        // 登录
        return [self loginServer:&error];
    } else {
        // 连接
        return [self connectToServer:&error];
    }
}

#pragma mark - About Socket


/**
 连接server
 */
- (BOOL)connectToServer:(NSError **)error {
    BFLogTrace();
    
    return [self.wpStream connectToServerForType:0 withTimeout:-1 error:error];
}

/**
 账号登录
 
 两种登陆方式:
 1、使用密码登陆
 2、密码登陆后返回的auth字段登录
 */
- (BOOL)loginServer:(NSError **)error {
    BFLogTrace();
    
    // 获取登录账号、密码、授权码(auth)
    NSString *account = [[NSUserDefaults standardUserDefaults] objectForKey:BFWP_ACCOUNT];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:BFWP_PASSWORD];
    NSString *auth = [[NSUserDefaults standardUserDefaults] objectForKey:BFWP_AUTH_TOKEN];
    BFLog([NSString stringWithFormat:@"account: %@, account: %@, account: %@", account, password, auth]);
    
    // 检查账号和密码是否为空
    if (!account || !password) {
        
        NSString *errMsg = @"登录账号和密码都不能为空...";
        BFLog(errMsg);
        
        NSDictionary *errInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:BFWPManagerErrorDomain code:-1 userInfo:errInfo];
        
        if (error) {
            *error = err;
        }
        
        return false;
    }
    
    if (auth && ![auth isEqualToString:@""]) {
        // 授权码登录
        [self.wpStream loginAccount:account auth:auth error:error];
    } else {
        // 密码登录
        [self.wpStream loginAccount:account password:password error:error];
    }
    
    
    return false;
}

#pragma mark add/remove stream delegate
- (void)addWPStreamDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    [self.wpStream addDelegate:delegate delegateQueue:delegateQueue];
}

- (void)removeWPStreamDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    [self.wpStream removeDelegate:delegate delegateQueue:delegateQueue];
}

- (void)removeWPStreamDelegate:(id)delegate {
    [self.wpStream removeDelegate:delegate];
}

#pragma mark stream delegate

/**
 正在连接服务器...
 */
//- (void)bfWPStreamWillConnect:(BFWPStream *)sender {
//    BFLogTrace();
//}
/**
 成功连接服务器
 */
- (void)bfWPStream:(BFWPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
    BFLogTrace();
    NSError *error;
    // 登陆操作 (确认流程是 连接中 -> 登陆)
    if ([sender isLoginConnecting]) {
        [self loginServer:&error];
    }
}
/**
 正在登陆...
 */
- (void)bfWPStreamWillAuthenticate:(BFWPStream *)sender {
    BFLogTrace();
}
/**
 与服务器断开连接
 */
- (void)bfWPStreamDidDisconnect:(BFWPStream *)sender withError:(NSError *)error {
    
}


#pragma mark sock status

- (BOOL)isConnected {
    return [self.wpStream isConnected];
}

@end
