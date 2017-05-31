//
//  BFWPParser.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/27.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFWPParser.h"
#import "BFEncrypt.h"
#import "NSDictionary+BFJson.h"

@interface BFWPParser () {
    // 数据解析对象代理及代理队列
    __weak id _parserDelegate;
    dispatch_queue_t _parserDelegateQueue;
    // 数据解析对象队列及队列标签
    dispatch_queue_t _parserQueue;
    void *_parserQueueTag;
    // 要解析的数据
    NSMutableData *_parserData;
}

@end

@implementation BFWPParser

#pragma mark - Init

- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    return [self initWithDelegate:delegate delegateQueue:delegateQueue parserQueue:NULL];
}

- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue parserQueue:(dispatch_queue_t)parserQueue {
    if (self = [super init]) {
        _parserDelegate = delegate;
        _parserDelegateQueue = delegateQueue;
        
        if (parserQueue) {
            _parserQueue = parserQueue;
        } else {
            _parserQueue = dispatch_queue_create("BFParserQueue", NULL);
        }
        // 队列打标签
        _parserQueueTag = &_parserQueueTag;
        dispatch_queue_set_specific(_parserQueue, _parserQueueTag, _parserQueueTag, NULL);

        _parserData = [[NSMutableData alloc] initWithCapacity:5];
    }
    
    return self;
}

- (void)setDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    
    dispatch_block_t block = ^{
        _parserDelegate = delegate;
        _parserDelegateQueue = delegateQueue;
    };
    
    if (dispatch_get_specific(_parserQueueTag)) {
        block();
    } else {
        dispatch_sync(_parserQueue, block);
    }
}

#pragma mark - Parser Data
/**
 * 统一返回参数格式,{"r":xxx,"n": xxx,"o":xxx,"data"},其中 r 为必须字段,n, o, data 均为可选字段。
 * Asynchronously parses the given data.
 * The delegate methods will be dispatch_async'd as events occur.
 **/
- (void)parseData:(NSData *)data messagepool:(NSMutableArray *)pool {
    
    dispatch_block_t block = ^{@autoreleasepool{
        
        [_parserData appendData:data];
        
        BOOL isComplete = [self isCompleteData:data];
        if (!isComplete) { return; }
        
        // 拆分数据
        [self separateData:data messagePool:pool];
    }};
    
    
}

/**
 把数据集重新整理
 每条数据信息之间分割标识:"\r\n"
 */
- (void)separateData:(NSData *)data messagePool:(NSMutableArray *)pool {
    
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *results = [json componentsSeparatedByString:@"\r\n"];
    
    for (NSString *result in results) {
        // 逐条处理每一个单体数据
        NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
        if (data.length > 0) {
            [self parserEachData:data messagePool:pool];
        }
    }
}

/**
 * android 做法是 先处理 [self doConfilict:json];
 *  Recevice 到的不一定是自己发送后的返回。比如:
 1:在线消息推送(notify是服务器主动推的)
 2:
 自己解绑自己，收到两条消息
 RECEVIE:{"r":"unbind","o":"unbind191240"}
 RECEVIE:{"r":"unbind","o":"unbind191240","n":-8,"data":"您已解除与智能手表【宝贝】的绑定"}
 被管理员解绑
 {"r":"unbind","o":"1","n":-8,"data":"您已被管理员解除与智能手表【宝贝疙瘩】的绑定"}
 3:被挤下线
 {"r":"login","o":"1463025429","n":-8,"t":"1463025429","data":"您的帐号已在【Meizu-MX5】登录"}
 {"r":"login","o":"Login339876","t":"1463033987","n":-10,"data":"对不起，密码错误，请检查后重新登录（连续6次错误会被锁定哦）。"}
 */
- (void)parserEachData:(NSData *)data messagePool:(NSMutableArray *)pool {
    
    // 解密
    NSData *resultData = [BFEncrypt bfWPDecrypt:data];
    
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:resultData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&err];
    // 消息类型处理
    // 在线消息推送(notify是服务器主动推的)
    if ([json isNotify]) {
        // 以通知方式处理信息
        [self parserNotify:json];
    }
    
    // 异地登录冲突
    [self resolveConflict:json];
    
    // 处理消息池中的该信息
    dispatch_async(_parserDelegateQueue, ^{@autoreleasepool{
        
        if ([pool containsObject:[json messageID]]) {
            [pool removeObject:[json messageID]];
        } else {
            // 消息池中不存在该ID的消息了 或 消息已经超时
            return;
        }
        
        // 信息类型处理
        if (json) {
            // 登录
            if ([json isBFWPLogin]) {
                [self parserLogin:json];
            }
            // 退出登录
            else if ([json isBFWPLogout]) {
                [self parserLogout:json];
            }
            // ...
        }
    }});
}

#pragma mark - private

/**
 错误码 n
 0 或不存在则表示无错误
 -1 服务器内部异常
 -2 系统繁忙
 -3 禁止访问
 -4 版本过低
 -5 未找到(如账号不存在等)
 -6 目标离线
 -7 已被占用(如权限较低的用户无法操作正在使用的资源)
 -8 权限降级(如同一个账号在另外一处登陆、转让管理员等)
 -9 超出限额(如授权过期、超时等)
 -10 认证失败(错误的密码、验证码、签名)
 -11 错误参数(如数据格式错误、IMEI、手机号等参数格式不合法)
 -12 错误操作
 -101 数据未更改(如获取通讯录、消息时返回,可以不用返回未改变的数据)
 *
 *  n 错误码/结果码
 */
-(NSString*)errorMsgWithResultCode:(NSDictionary*)json{
    /**
     *  如果服务器有返回错误提示，则显示服务器的提示
     */
    NSString *errorData = [json objectForKey:@"data"];
    if (errorData && ![errorData isEqualToString:@""]) {
        return errorData;
    }
    
    NSInteger n = [self resultCode:json];
    NSString *msg = @"";
    switch (n) {
        case NO_ERROR: msg         = @"无错误";
            break;
        case SERVER_EXCEPTION: msg = @"服务器内部异常";
            break;
        case SYSTEM_BUSY: msg      = @"系统繁忙";
            break;
        case FORBID_ACCESS: msg    = @"禁止访问";
            break;
        case LOWER_VERSION: msg    = @"版本过低";
            break;
        case NOT_FOUND: msg        = @"未找到(如账号不存在等)";
            break;
        case OFF_LINE: msg         = @"目标离线";
            break;
        case ALREADY_TAKEN: msg    = @"已被占用(如权限较低的用户无法操作正在使用的资源)";
            break;
        case LIMITS_AUTHORITY: msg = @"权限降级(如同一个账号在另外一处登陆、转让管理员等)";
            break;
        case OVERFLOW_LIMITS: msg  = @"超出限额(如授权过期、超时等)";
            break;
        case AUTH_FAILURE:msg      = @"认证失败(错误的密码、验证码、签名)";
            break;
        case ERROR_PARAMS:msg      = @"错误参数(如数据格式错误、IMEI、手机号等参数格式不合法)";
            break;
        case ERROR_OPERATE:msg     = @"错误操作";
            break;
        case DATA_NO_CHANGED:msg   = @"数据未更改(如获取通讯录、消息时返回,可以不用返回未改变的数据)";
            break;
        default:
            break;
    }
    return msg;
}

/**
 通过结果码判断冲突类型，并做响应处理
 */
- (void)resolveConflict:(NSDictionary *)json {
    
    NSInteger resultCode = [self resultCode:json];
    if (LIMITS_AUTHORITY == resultCode
        || OVERFLOW_LIMITS == resultCode
        || AUTH_FAILURE == resultCode) {
        // 下线处理
        if (_parserDelegateQueue && [_parserDelegate respondsToSelector:@selector(bfWPLoginConflict:reason:)]) {
            __strong id curDelegate = _parserDelegate;
            dispatch_async(_parserDelegateQueue, ^{
                [curDelegate bfWPLoginConflict:json reason:[json data]];
            });
        }
    }
}

/**
 返回结果码/错误码
 n 不存在，则默认为 0
 */
- (NSInteger)resultCode:(NSDictionary *)json {
    
    if ([json objectForKey:@"n"] == nil) { return 0; }
    
    return [[json objectForKey:@"n"] integerValue];
}

#pragma mark parser watch protocl

/**
 登录
 */
- (void)parserLogin:(NSDictionary *)json {
    BFLogTrace();
    
    if ([self resultCode:json] == NO_ERROR) {
        // 登录成功
        if (_parserDelegateQueue && [_parserDelegate respondsToSelector:@selector(bfWPDidLogin:)]) {
            __strong id curDelegate = _parserDelegate;
            dispatch_async(_parserDelegateQueue, ^{@autoreleasepool{
                [curDelegate bfWPDidLogin:json];
            }});
        }
    } else {
        // 登录失败
        if (_parserDelegateQueue && [_parserDelegate respondsToSelector:@selector(bfWPDidLoginFail:reason:)]) {
            __strong id curDelegate = _parserDelegate;
            dispatch_async(_parserDelegateQueue, ^{@autoreleasepool{
                NSString *failReason = [self errorMsgWithResultCode:json];
                [curDelegate bfWPDidLoginFail:json reason:failReason];
            }});
        }
    }
}

/**
 退出登录
 */
- (void)parserLogout:(NSDictionary *)json {
    BFLogTrace();
    
    if ([self resultCode:json] == NO_ERROR) {
        // 响应成功
        if (_parserDelegateQueue && [_parserDelegate respondsToSelector:@selector(bfWPDidLogout:)]) {
            __strong id curDelegate = _parserDelegate;
            dispatch_async(curDelegate, ^{@autoreleasepool{
                [curDelegate bfWPDidLogout:json];
            }});
        }
    } else {
        // 响应失败
        if (_parserDelegate && [_parserDelegate respondsToSelector:@selector(bfWPDidLoginFail:reason:)]) {
            __strong id curDelegate = _parserDelegate;
            dispatch_async(_parserDelegateQueue, ^{@autoreleasepool{
                NSString *failReason = [self errorMsgWithResultCode:json];
                [curDelegate bfWPDidLogoutFail:json reason:failReason];
            }});
        }
    }
}

/**
 解析在线消息推送
 */
- (void)parserNotify:(NSDictionary *)json {
    BFLogTrace();
    
    if (_parserDelegateQueue && [_parserDelegate respondsToSelector:@selector(bfWPNotify:key:data:)]) {
        
        __strong id curDelegate = _parserDelegate;
        dispatch_async(_parserDelegateQueue, ^{@autoreleasepool{
            [curDelegate bfWPNotify:json key:[json key] data:[json data]];
        }});
    }
}

/**
 根据最后两个字符判断: \r\n
 */
- (BOOL)isCompleteData:(NSData *)data {
    
    NSData *lastTwoBuffer = [data subdataWithRange:NSMakeRange(data.length-2, 2)];
    NSString *bufferStr = [[NSString alloc] initWithData:lastTwoBuffer encoding:NSUTF8StringEncoding];
    
    if ([bufferStr isEqualToString:@"\r\n"]) { return false; }
    
    return true;
}

@end
