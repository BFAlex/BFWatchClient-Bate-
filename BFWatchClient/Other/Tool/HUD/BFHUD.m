//
//  BFHUD.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//


#import "BFHUD.h"
#import <SVProgressHUD.h>

@implementation BFHUD

+ (void)showTipMessage:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

+ (void)showMessage:(NSString *)message {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:message];
}

+ (void)hide {
    [SVProgressHUD dismiss];
}

@end
