//
//  BFSocketStream.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFSocketStream.h"

//===================================================
//不超时参数， -1
const NSTimeInterval BFASSTimeoutNone = -1;
NSString *const BFASSErrorDomain   = @"RBWPStreamErrorDomain";
NSString *const BFASSLoginTimeOut  = @"登录超时，请稍后再试。";
NSString *const BFASSTimeOut  =      @"操作超时，请稍后再试。";
NSString *const BFASSDisconnect  =   @"无法连接服务器，请检查网络。";
NSString *const BFASSOften    =      @"请不要频繁操作，稍后再试。";

//===================================================
//测试服务器地址
#define HostName @"120.25.120.222" // 测试
#define SmartWatchHostName @"wear.readboy.com"

#define HostPort 8866

//===================================================
enum BFAsyncSocketServerStatus {
    STATUS_AAS_DISCONNECT,      // 未连接
    STATUS_AAS_CONNECTING,      //登录连接中
    STATUS_AAS_RECONNECTING,    //断线连接中
    STATUS_AAS_CONNECTED,       //已连接
    STATUS_AAS_AUTHING,         //授权验证中
    STATUS_AAS_AUTH,            //验证成功
    STATUS_AAS_AUTH_FAIL,       //验证失败
    STATUS_AAS_REAUTH_FAIL,     //验证失败
};
typedef enum BFAsyncSocketServerStatus BFAsyncSocketServerStatus;

// Define the timeouts (in seconds) for retreiving various parts of the Json stream
#define TIMEOUT_JSON_WRITE_STREAM   -1
#define TIMEOUT_JSON_READ_START     10
#define TIMEOUT_JSON_READ_STREAM    -1

// Define the tags we'll use to differentiate what it is we're currently reading or writing
#define TAG_JSON_READ_START         100
#define TAG_JSON_READ_STREAM        101
#define TAG_JSON_WRITE_START        200
#define TAG_JSON_WRITE_STREAM       201
#define TAG_JSON_WRITE_RECEIPT      202

//===================================================

@interface BFSocketStream () {
    GCDAsyncSocket *_socket;
    dispatch_queue_t _socketQueue;
    void *_socketQueueTag;
}

// 状态
@property (nonatomic, assign) int status;
// 主机名
@property (nonatomic, copy) NSString *hostName;
// 主机端口
@property (nonatomic, assign) UInt16 hostPort;
// 用户名
@property (nonatomic, copy) NSString *userName;
// 登录令牌
@property (nonatomic, copy) NSString *authToken;

@end

@implementation BFSocketStream

#pragma mark - recall

- (void)dealloc {
    // 关闭socket
    [_socket setDelegate:nil delegateQueue:NULL];
    [_socket disconnect];
}


#pragma mark - custom

+ (instancetype)shareStream {
    static BFSocketStream *shareStream = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        shareStream = [[BFSocketStream alloc] init];
        [shareStream initSocket];
    });
    
    return shareStream;
}

- (void)initSocket {
    [self initData];
    
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    // 设置socket的网络协议，支持IPv6
    _socket.IPv4PreferredOverIPv6 = NO;
}

- (void)initData {
    // 初始化Socket服务线程
    _socketQueueTag = &_socketQueueTag;
    _socketQueue = dispatch_queue_create(_socketQueueTag, NULL);
    dispatch_queue_set_specific(_socketQueue, _socketQueueTag, _socketQueueTag, NULL);
    
    // 初始化服务状态
    self.status = STATUS_AAS_DISCONNECT;
    // 服务器 (端口+IP)
    self.hostPort = HostPort;
    self.hostName = HostName;
}

#pragma mark - socket -> 连接socket

/**
 client 连接 server
 
 @param host 主机
 @param port 端口
 @param timeout 超时时间(-1: 不超时)
 @param errPtr <#errPtr description#>
 @return <#return value description#>
 */
- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port withTimeout:(NSTimeInterval)timeout error:(NSError * _Nullable __autoreleasing * _Nullable)errPtr {
    
    BOOL result = [_socket connectToHost:host onPort:port withTimeout:timeout error:errPtr];
    
    return result;
}

#pragma mark - GCDAsyncSocketDelegate
#pragma mark - socket -> socket连接结果

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"socket连接成功 -> [host: %@\tport: %d]", host, port);
    
    [_socket readDataWithTimeout:TIMEOUT_JSON_READ_STREAM tag:TAG_JSON_READ_STREAM];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"socket读取数据成功 -> [data: %@\tag: %ld]", data, tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socket连接失败 -> err: %@", err);
}

#pragma mark - Stream Status

- (BOOL)isConnected {
    
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        result = [_socket isConnected];
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
    
    return result;
}

#pragma mark - example

- (BOOL)connectToReadboyHost {
    BFLog(@"");
    NSError *connectErr = nil;
    BOOL result = [self connectToHost:self.hostName onPort:self.hostPort withTimeout:BFASSTimeoutNone error:&connectErr];
    
    return result;
}

@end
