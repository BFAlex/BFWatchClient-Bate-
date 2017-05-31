//
//  BFSocketStream.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFSocketStream.h"
#import "BFWPParser.h"

//===================================================
//不超时参数， -1
const NSTimeInterval BFASSTimeoutNone = -1;
NSString *const BFASSErrorDomain   = @"RBWPStreamErrorDomain";
NSString *const BFASSLoginTimeOut  = @"登录超时，请稍后再试。";
NSString *const BFASSTimeOut  =      @"操作超时，请稍后再试。";
NSString *const BFASSDisconnect  =   @"无法连接服务器，请检查网络。";
NSString *const BFASSOften    =      @"请不要频繁操作，稍后再试。";

//===================================================

enum BFWPStreamErrorCode
{
    BFWPStreamInvalidState,      // Invalid state for requested action, such as connect when already connected
    BFWPStreamInvalidProperty,   // Missing a required property
    BFWPStreamInvalidParameter,  // Invalid parameter, such as a nil JID
    BFWPStreamUnsupportedAction, // The server doesn't support the requested action
};
typedef enum RBWPStreamErrorCode XRBWPStreamErrorCode;

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

/**
 * Seeing a return statements within an inner block
 * can sometimes be mistaken for a return point of the enclosing method.
 * This makes inline blocks a bit easier to read.
 **/
#define return_from_block  return

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
    
    // 添加属性对象变量
    NSString *_hostName;
    UInt16 _hostPort;
    
    // 多播代理
    GCDMulticastDelegate<BFSocketStreamDelegate> *_multicastDelegate;
    
    //解析协议
    BFWPParser *_bfwpParser;
    NSError *_parserError;
}


@end

@implementation BFSocketStream

#pragma mark - property

- (NSString *)hostName {
    BFLogTrace();
    
    if (dispatch_get_specific(_socketQueueTag)) {
        return _hostName;
    } else {
        __block NSString *result;
        dispatch_sync(_socketQueue, ^{
            result = _hostName;
        });
        
        return result;
    }
}

- (void)setHostName:(NSString *)hostName {
    BFLog([NSString stringWithFormat:@"hostName: %@", hostName]);
    
    if (dispatch_get_specific(_socketQueueTag)) {
        if (_hostName != hostName) {
            _hostName = [hostName copy];
        }
    } else {
        __block NSString *newHostName = [hostName copy];
        dispatch_async(_socketQueue, ^{
            _hostName = newHostName;
        });
    }
}

- (UInt16)hostPort {
    BFLogTrace();
    
    if (dispatch_get_specific(_socketQueueTag)) {
        return _hostPort;
    } else {
        __block UInt16 result;
        dispatch_sync(_socketQueue, ^{
            result = _hostPort;
        });
        
        return result;
    }
}

- (void)setHostPort:(UInt16)hostPort {
    BFLog([NSString stringWithFormat:@"hostPort: %hu", hostPort]);
    
    if (dispatch_get_specific(_socketQueueTag)) {
        if (_hostPort != hostPort) {
            _hostPort = hostPort;
        }
    } else {
        __block UInt16 newHostPort = hostPort;
        dispatch_async(_socketQueue, ^{
            _hostPort = newHostPort;
        });
    }
}


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
 连接scoket
 */
- (BOOL)connectWithTimeout:(NSTimeInterval)timeout type:(int)type error:(NSError *__autoreleasing *)err {
    BFLogTrace();
    __block BOOL result = false;
    __block NSError *error = nil;
    
    dispatch_block_t block = ^{@autoreleasepool{
        // 是否已经连接
        if ([_socket isConnected]) {
            NSString *errMsg = @"Attempting to connect while already connected or connecting";
            NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:errMsg code:BFWPStreamInvalidState userInfo:info];
            
            result = NO;
            
            return_from_block;
        }
        
        // Open TCP connection to the configured hostName.
        BFLog([NSString stringWithFormat:@"连接状态类型: %d", type]);
        if (type == 0) {
            self.status = STATUS_AAS_DISCONNECT; // 登录连接中
        } else {
            self.status = STATUS_AAS_RECONNECTING; // 断线连接中
        }
        
        // 连接Scoket
        NSError *connectErr = nil;
        result = [self connectToHost:self.hostName onPort:self.hostPort withTimeout:BFASSTimeoutNone error:&connectErr];
        if (!result) {
            error = connectErr;
            self.status = STATUS_AAS_DISCONNECT;
        } else {
            // 显示连接中...
            // 多播代理反馈该过程信息给有关代理
            [_multicastDelegate bfsocketStreamWillConnect:self];
        }
    }};
    
    
    // block操作
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
    
    if (err) {
        *err = error;
    }
    
    return result;
}

/**
 client 连接 server
 
 @param host 主机
 @param port 端口
 @param timeout 超时时间(-1: 不超时)
 */
- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port withTimeout:(NSTimeInterval)timeout error:(NSError * _Nullable __autoreleasing * _Nullable)errPtr {
    
    BOOL result = [_socket connectToHost:host onPort:port withTimeout:timeout error:errPtr];
    
    return result;
}

#pragma mark - GCDAsyncSocketDelegate
#pragma mark - socket -> socket连接结果

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    BFLog([NSString stringWithFormat:@"socket连接成功 -> [host: %@\tport: %d]", host, port]);
    
    // 通知代理连接成功信息
    [_multicastDelegate bfwpStream:self socketDidConnect:sock];
    
    // 初始化协议解析对象
//    _bfwpParser = [[BFWPParser alloc] initWithDelegate:self delegateQueue:_socketQueue];
//    
//    // 从服务器中读取数据
//    [_socket readDataWithTimeout:TIMEOUT_JSON_READ_STREAM tag:TAG_JSON_READ_STREAM];
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

#pragma mark - add/remove delegate
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    BFLogTrace();
    
    dispatch_block_t block = ^{
        [_multicastDelegate addDelegate:delegate delegateQueue:delegateQueue];
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    BFLogTrace();
    
    dispatch_block_t block = ^{
        [_multicastDelegate removeDelegate:delegate delegateQueue:delegateQueue];
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
}

- (void)removeDelegate:(id)delegate {
    dispatch_block_t block = ^{
        [_multicastDelegate removeDelegate:delegate];
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
}

#pragma mark - example

- (BOOL)connectToReadboyHost {
    BFLog(@"");
    NSError *connectErr = nil;
    BOOL result = [self connectToHost:self.hostName onPort:self.hostPort withTimeout:BFASSTimeoutNone error:&connectErr];
    
    return result;
}

@end
