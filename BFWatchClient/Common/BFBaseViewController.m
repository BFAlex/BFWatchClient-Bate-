//
//  BFBaseViewController.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/8.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFBaseViewController.h"

@interface BFBaseViewController ()

@end

@implementation BFBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 所有的Controller View都带有一个点击手势事件: 取消所有子view的编辑状态
    UITapGestureRecognizer *simpleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFR)];
    [self.view addGestureRecognizer:simpleTap];
}

#pragma mark - private

- (void)resignFR {
    [self.view endEditing:YES];
}

@end
