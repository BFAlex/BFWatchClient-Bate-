//
//  NSDictionary+BFJson.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/27.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (BFJson)

/**
 *  是否是 登录
 */
-(BOOL)isBFWPLogin;
-(BOOL)isBFWPLogout;
/**
 *  在线消息推送
 */
-(BOOL)isNotify;

/**
 消息ID
 */
-(NSString*)messageID;

/**
 *  消息类型
 */
-(NSString*)messageType;
-(NSString*)key;
-(NSString*)data;
-(id)jsonData;
-(NSString*)msgSyncTag;

@end
