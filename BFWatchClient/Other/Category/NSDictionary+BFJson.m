//
//  NSDictionary+BFJson.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/27.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "NSDictionary+BFJson.h"

@implementation NSDictionary (BFJson)

#pragma mark - Custom

/**
 判断是否属于JSON协议类型信息数据
 (协议请求 / 协议响应)
 */
- (BOOL)checkBFWPJson:(NSString *)protocol {
    // 请求
    NSString *q = [self objectForKey:@"q"];
    if ([q isEqualToString:protocol]) {
        return true;
    }
    
    // 服务器响应
    NSString *r = [self objectForKey:@"r"];
    if ([r isEqualToString:protocol]) {
        return true;
    }
    
    return false;
}

#pragma mark - public

- (BOOL)isBFWPLogin {
    return [self checkBFWPJson:@"login"];
}

- (BOOL)isBFWPLogout {
    return [self checkBFWPJson:@"logout"];
}

/**
 在线推送信息
 */
- (BOOL)isNotify {
    return [self checkBFWPJson:@"notify"];
}

/**
 消息ID
 */
-(NSString*)messageID
{
    return [self objectForKey:@"o"];
}

/**
 *  消息类型
 */
- (NSString *)messageType {
    return nil;
}
- (NSString *)key {
    return [self objectForKey:@"k"];
}
- (NSString *)data {
    return [self objectForKey:@"data"];
}
- (id)jsonData {
    return nil;
}
- (NSString *)msgSyncTag {
    return nil;
}

@end
