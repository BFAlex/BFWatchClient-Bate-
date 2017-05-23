//
//  UIViewController+BFCustom.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "UIViewController+BFCustom.h"

@implementation UIViewController (BFCustom)

- (void)resignViewsFirstResponder {
    UITapGestureRecognizer *simpleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFR)];
    [self.view addGestureRecognizer:simpleTap];
}

#pragma mark - private

- (void)resignFR {
     [self.view endEditing:YES];
}

@end
