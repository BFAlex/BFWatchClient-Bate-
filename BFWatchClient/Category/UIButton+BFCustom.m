//
//  UIButton+BFCustom.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "UIButton+BFCustom.h"

@implementation UIButton (BFCustom)

- (void)enableBtn {
    [self setBackgroundColor:mainColorDef];
}

- (void)disableBtn {
    [self setBackgroundColor:[UIColor lightGrayColor]];
}

@end
