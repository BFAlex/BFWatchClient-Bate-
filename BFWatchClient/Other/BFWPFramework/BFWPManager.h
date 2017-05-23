//
//  BFWPManager.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFWPManager : NSObject

#pragma mark - Property

@property (nonatomic, strong, readonly) BFSocketStream *socketStream;


#pragma mark - Method

+ (instancetype)shareWPManager;

/**
 登录
 @return 成功/失败
 */
- (BOOL)Login;

@end
