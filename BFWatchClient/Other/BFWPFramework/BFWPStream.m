//
//  BFWPStream.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/25.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFWPStream.h"
#import "GCDMulticastDelegate.h"
#import "BFEncrypt.h"


//===================================================

//不超时参数， -1
const NSTimeInterval BFASSTimeoutNone = -1;
NSString *const BFASSErrorDomain   = @"BFWPStreamErrorDomain";
NSString *const BFASSLoginTimeOut  = @"登录超时，请稍后再试。";
NSString *const BFASSTimeOut  =      @"操作超时，请稍后再试。";
NSString *const BFASSDisconnect  =   @"无法连接服务器，请检查网络。";
NSString *const BFASSOften    =      @"请不要频繁操作，稍后再试。";

//登录协议 默认序号
NSString * BFWPStreamLoginOrder      = @"Login";//@"100";
NSString * BFWPStreamReconnectOrder  = @"Reconect";//@"101";

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


@interface BFWPStream () {
    // Socket
    GCDAsyncSocket *_asyncSocket;
    dispatch_queue_t _socketQueue;
    void *_socketQueueTag;
    // 多播代理
    GCDMulticastDelegate<BFWPStreamDelegate> *_multicastDelegate;
}
@property (nonatomic, assign) int status;

@end

@implementation BFWPStream

#pragma mark - Property

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        [self setupData];
        [self initSocket];
    }
    
    return self;
}

- (void)dealloc {
    BFLogTrace();
    // 取消Socket代理，断开连接
    [_asyncSocket setDelegate:nil delegateQueue:nil];
    [_asyncSocket disconnect];
}

#pragma mark - Custom

- (void)setupData {
    BFLogTrace();
    
    // 初始化多播代理
    _multicastDelegate = (GCDMulticastDelegate<BFWPStreamDelegate> *)[[GCDMulticastDelegate alloc] init];
    
    // 初始化Stream状态
    self.status = STATUS_AAS_DISCONNECT;
    
    // 默认端口
    self.hostPort = 5222;
    // 默认服务器(本地)
    self.hostName = @"127.0.0.1";
}

- (NSString *)getAppVersion {
    NSDictionary *bundle = [[NSBundle mainBundle] infoDictionary];
    return [bundle objectForKey:@"CFBundleShortVersionString"];
}

- (NSData *)jsonToData:(id)json {
    BFLogTrace();
    
    NSString *dataString;
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    if (!data) {
        BFLog([NSString stringWithFormat:@"dataTojsonString Got an error: %@", error]);
    } else {
        dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    //一行之内 每一条消息不能有\n或\r
    //MESSAGE := JSONObject
    //消息内容使用 JSON 对象封装,JSONObject 中不能含有换行字符,即 CR、LF 字符。
    dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    dataString = [dataString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    BFLog([NSString stringWithFormat:@"send data: %@", dataString]);
    
    NSString *entrypt = [BFEncrypt bfWPEncrypt:dataString];
    //每条消息(MESSAGE)以换行符 \r\n 隔开
    //要先加密再加 换行符
    entrypt = [entrypt stringByAppendingString:@"\r\n"];
    
    return [entrypt dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark Socket ~
- (void)initSocket {
    BFLogTrace();
    
    // Socket队列
    _socketQueueTag = &_socketQueueTag;
    _socketQueue = dispatch_queue_create(_socketQueueTag, NULL);
    dispatch_queue_set_specific(_socketQueue, _socketQueueTag, _socketQueueTag, NULL);
    
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    // 设置socket的网络协议，支持IPv6
    _asyncSocket.IPv4PreferredOverIPv6 = NO;
}

- (BOOL)connectToServerForType:(int)type withTimeout:(NSTimeInterval)timeout error:(NSError *__autoreleasing  _Nullable *)connectErr {
    BFLogTrace();
    
    return [self connectToHost:self.hostName onPort:self.hostPort type:type withTimeout:timeout error:connectErr];
}

- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port type:(int)type withTimeout:(NSTimeInterval)timeout error:(NSError *__autoreleasing  _Nullable *)connectErr {
    BFLogTrace();
    
    __block NSError *err = nil;
    __block BOOL result = false;
    
    dispatch_block_t connectBlock = ^{@autoreleasepool{
        // Socket当前是否已经连接状态
        if ([_asyncSocket isConnected]) {
            NSString *errMsg = @"Attempting to connect while already connected or connecting";
            NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            err = [NSError errorWithDomain:errMsg code:BFWPStreamInvalidState userInfo:info];
            
            result = false;
            
            return_from_block;
        }
        
        // 标记连接类型
        if (0 == type) {
            // 登录连接
            self.status = STATUS_AAS_CONNECTING;
        } else {
            // 断开重连
            self.status = STATUS_AAS_RECONNECTING;
        }
        
        // Socket开始连接服务器
        result = [_asyncSocket connectToHost:host onPort:port withTimeout:timeout error:&err];
        if (result) {
            // 开始连接
            // 反馈连接信息（这里使用多播方式反馈）
            [_multicastDelegate bfWPStreamWillConnect:self];
        } else {
            // 连接失败
            self.status = STATUS_AAS_DISCONNECT;
        }
    }};
    
    if (dispatch_get_specific(_socketQueueTag)) {
        connectBlock();
    } else {
        dispatch_sync(_socketQueue, connectBlock);
    }
    
    if (connectErr) { *connectErr = err; }
    
    return result;
}

#pragma mark socket status

- (BOOL)isConnected {
    return [_asyncSocket isConnected];
}

#pragma mark About Login

- (NSString *)createMessageID:(NSString *)preStr {
    BFLogTrace();
    
    NSString *msgID; // preStr + 时间戳 + 随机数
    
    // preStr
    if (preStr && ![preStr isEqualToString:@""]) {
        msgID = preStr;
    } else {
        msgID = @"";
    }
    
    // 时间戳
    NSString *timeStamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    if (timeStamp.length > 6) {
        msgID = [msgID stringByAppendingString:[timeStamp substringFromIndex:5]];
    } else {
        msgID = [msgID stringByAppendingString:timeStamp];
    }
    
    // 随机数
    int random = arc4random() % 10;
    NSString *randomStr = [NSString stringWithFormat:@"%ld", (long)random];
    msgID = [msgID stringByAppendingString:randomStr];
    
    BFLog([NSString stringWithFormat:@"msgID: %@", msgID]);
    return msgID;
}

- (BOOL)loginAccount:(NSString *)account password:(NSString *)pwd error:(NSError *__autoreleasing  _Nullable *)error {
    BFLogTrace();
    
    NSDate *curDate = [NSDate date];
    NSString *tsp = [NSString stringWithFormat:@"%ld", (long)[curDate timeIntervalSince1970]];
    
    NSString *order = [self createMessageID:BFWPStreamLoginOrder];
    
    // 时间戳 + md5(密码) + 账号 + 登录序号
    NSMutableString *authStr = [[NSMutableString alloc] init];
    [authStr appendString:tsp];
    [authStr appendString:[BFEncrypt md5_16:pwd]];
    [authStr appendString:account];
    [authStr appendString:order];
    
    NSString *authMD5 = [BFEncrypt md5_16:authStr];
    
    BOOL result = [self wpStreamLoginAccount:account auth:authMD5 timeStamp:tsp order:order uuid:nil error:error];
    
    return result;
}

- (BOOL)loginAccount:(NSString *)account auth:(NSString *)auth error:(NSError *__autoreleasing  _Nullable *)error {
    BFLogTrace();
    
    NSDate *curDate = [NSDate date];
    NSString *tsp = [NSString stringWithFormat:@"%ld", (long)[curDate timeIntervalSince1970]]; // UNIX格式时间戳
    
    NSString *order = [self createMessageID:BFWPStreamLoginOrder];
    
    NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"BFWP_USERID"];
    
    BOOL result = [self wpStreamLoginAccount:account auth:auth timeStamp:tsp order:order uuid:uuid error:error];
    
    return result;
}

- (BOOL)wpStreamLoginAccount:(NSString *)account auth:(NSString *)auth timeStamp:(NSString *)tsp order:(NSString *)order uuid:(NSString *)uuid error:(NSError **)error {
    BFLog([NSString stringWithFormat:@"account: %@, auth: %@, timeStamp: %@, order: %@, uuid: %@",
           account, auth, tsp, order, uuid]);
    
    __block BOOL result = true;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{
        /* Socket是否已经连接*/
        if (![_asyncSocket isConnected]) {
            NSString *errMsg = @"Please wait until the stream is connected";
#warning 能解释清楚这两个命令行意思吗
            NSDictionary *errInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            err = [NSError errorWithDomain:BFASSErrorDomain code:BFWPStreamInvalidState userInfo:errInfo];
            
            result = false;
            
            BFLog(errMsg);
            return_from_block;
        }
        
        /* 是否正在登录 */
        if (self.status == STATUS_AAS_AUTHING) {
            NSString *errMsg = @"Please wait until the  authenticate is finish";
            NSDictionary *errInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            err = [NSError errorWithDomain:BFASSErrorDomain code:BFWPStreamInvalidState userInfo:errInfo];
            
            result = false;
            
            BFLog(errMsg);
            return_from_block;
        }
        
        // 参数是否为nil
        if (!account || !auth || !tsp || !order) {
            NSString *errMsg = @"Login Param is nil";
            NSDictionary *errInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            err = [NSError errorWithDomain:BFASSErrorDomain code:BFWPStreamInvalidState userInfo:errInfo];
            
            result = false;
            
            BFLog(errMsg);
            return_from_block;
        }
        
        // 设备名
        NSString *deviceName = [[UIDevice currentDevice] name];
        if (!deviceName) { deviceName = @"iphone"; }
        // 设备ID
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        // APP版本号
        NSString *appVersion = [self getAppVersion];
        BFLog([NSString stringWithFormat:@"deviceName: %@, deviceID: %@, appVersion: %@",
               deviceName, deviceID, appVersion]);
        
        // 登录协议
        NSMutableDictionary *loginJson = [[NSMutableDictionary alloc] init];
        [loginJson setObject:@"login" forKey:@"q"];             //协议请求
        [loginJson setObject:order forKey:@"o"];                //序号
        [loginJson setObject:account forKey:@"username"];       //账号
        [loginJson setObject:auth forKey:@"auth"];              //授权码
        [loginJson setObject:tsp forKey:@"t"];                  //时间戳
        [loginJson setObject:appVersion forKey:@"v"];           //版本号
        [loginJson setObject:deviceID forKey:@"device_id"];     //设备UUID,被挤下线用
        [loginJson setObject:deviceName forKey:@"device_name"]; //设备名,被挤下线用
        if (uuid) {
            [loginJson setObject:uuid forKey:@"id"];            //家长用户ID
        }
        
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"BFWP_DEVICE_TOKEN"];
        if (deviceToken) {
            [loginJson setObject:deviceToken forKey:@"device_token"];   //推送作用
        } else {
            BFLog([NSString stringWithFormat:@"device_token null!"]);
        }
        
#warning 消息池设置
#warning 超时处理设置
        
        
        // Data格式化数据
        NSData *data = [self jsonToData:loginJson];
        // 标记登录中状态
        self.status = STATUS_AAS_AUTHING;
        // 向服务器发(写)数据
        [_asyncSocket writeData:data withTimeout:TIMEOUT_JSON_READ_STREAM tag:TAG_JSON_WRITE_STREAM];
        // 反馈登录中的状态
        [_multicastDelegate bfWPStreamWillAuthenticate:self];
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
    
    if (error) {
        *error = err;
    }
    
    return result;
}

#pragma mark status

- (BOOL)isLoginConnecting {
    
    __block BOOL result;
    dispatch_block_t block = ^{
        result = self.status == STATUS_AAS_CONNECTING;
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
    
    return result;
}

#pragma mark GCDMulticastDelegate ~

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
    BFLogTrace();
    
    dispatch_block_t block = ^{
        [_multicastDelegate removeDelegate:delegate];
    };
    
    if (dispatch_get_specific(_socketQueueTag)) {
        block();
    } else {
        dispatch_sync(_socketQueue, block);
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    BFLogTrace();
    
    // 反馈连接成功信息
    [_multicastDelegate bfWPStream:self socketDidConnect:sock];
    
    // 开启读数据
    [_asyncSocket readDataWithTimeout:TIMEOUT_JSON_READ_STREAM tag:TAG_JSON_READ_STREAM];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    BFLogTrace();
    BFLog([NSString stringWithFormat:@"did read data: %@", data]);
    // 解析数据
#warning 解析数据
    
    // 继续读数据
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    BFLogTrace();
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    BFLogTrace();
    
    // 改变状态标记
    self.status = STATUS_AAS_DISCONNECT;
    
    // 反馈断开信息
    [_multicastDelegate bfWPStreamDidDisconnect:self withError:err];
}

@end
