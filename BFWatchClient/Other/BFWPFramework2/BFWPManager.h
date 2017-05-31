//
//  BFWPManager.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>

//===================================================
//测试服务器地址
#define HostName @"120.25.120.222" // 测试
#define HostPort 8866


@class BFWPAutoPing;
@class BFWPReconnect;

@interface BFWPManager : NSObject

#pragma mark - Property

@property (nonatomic, strong, readonly) BFSocketStream *socketStream;
@property (nonatomic, strong, readonly) BFWPAutoPing *wpAutoPing;
@property (nonatomic, strong, readonly) BFWPReconnect *wpReconnect;

#pragma mark - Method

+ (instancetype)shareWPManager;

/**
 登录
 @return 成功/失败
 */
- (BOOL)Login;

@end
