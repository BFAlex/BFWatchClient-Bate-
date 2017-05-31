//
//  BFWPParser.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/24.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  返回结果码
 */
typedef enum{
    NO_ERROR = 0,//无错误
    SERVER_EXCEPTION = -1,//服务器内部异常
    SYSTEM_BUSY = -2,//系统繁忙
    FORBID_ACCESS = -3,//禁止访问
    LOWER_VERSION = -4,//版本过低
    NOT_FOUND = -5,//未找到(如账号不存在等)
    OFF_LINE = -6,//目标离线
    ALREADY_TAKEN = -7,//已被占用(如权限较低的用户无法操作正在使用的资源)
    LIMITS_AUTHORITY = -8,//权限降级(如同一个账号在另外一处登陆、转让管理员等)
    OVERFLOW_LIMITS = -9,//超出限额(如授权过期、超时等)
    AUTH_FAILURE = -10,//认证失败(错误的密码、验证码、签名)
    ERROR_PARAMS = -11,//错误参数(如数据格式错误、IMEI、手机号等参数格式不合法)
    ERROR_OPERATE = -12,//错误操作
    DATA_NO_CHANGED = -101,//数据未更改(如获取通讯录、消息时返回,可以不用返回未改变的数据)
    
    OP_TIMEOUT = -501//操作超时，本地添加的用于超时处理
    
}ResultCode;

@interface BFWPParser : NSObject

/**
 *  Init
 */
- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)dq;
- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)dq parserQueue:(dispatch_queue_t)pq;
- (void)setDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
/**
 * Asynchronously parses the given data.
 * The delegate methods will be dispatch_async'd as events occur.
 **/
- (void)parseData:(NSData *)data messagepool:(NSMutableArray*)pool;

@end

@protocol BFWPParserDelegate

@optional

#pragma mark - 登录

/**
 登录成功
 */
- (void)bfWPDidLogin:(NSDictionary *)json;

@end
