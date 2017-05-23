//
//  BFWPManager.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFWPManager.h"

@interface BFWPManager ()

@end

@implementation BFWPManager

+ (instancetype)shareWPManager {
    static BFWPManager *shareWPManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareWPManager = [[BFWPManager alloc] init];
    });
    
    return shareWPManager;
}

/**
 1、Socket处于连接状态: 直接登录
 2、Socket处于断开状态: 线连接Scoket，成功后再登录

 @return 成功/失败
 */
- (BOOL)Login {
    BFLog(@"");
    NSError *error;
    
    BOOL isSuccess = [[BFWPManager shareWPManager] Login];
    if (!isSuccess) {
        // 登录失败，稍后再试
        [BFAlertView showAlertViewExample];
    }
    
    return false;
}

@end
