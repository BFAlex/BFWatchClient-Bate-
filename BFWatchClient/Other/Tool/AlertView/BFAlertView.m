//
//  BFAlertView.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFAlertView.h"

@implementation BFAlertView

+ (void)showAlertViewExample {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sample" message:@"Show Sample" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

@end
