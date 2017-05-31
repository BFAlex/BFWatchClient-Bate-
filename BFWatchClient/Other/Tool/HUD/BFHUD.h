//
//  BFHUD.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFHUD : NSObject

+ (void)showTipMessage:(NSString *)msg;
+ (void)showMessage:(NSString *)message;
+ (void)hide;


@end
