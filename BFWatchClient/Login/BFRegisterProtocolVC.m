//
//  BFRegisterProtocolVC.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFRegisterProtocolVC.h"

@interface BFRegisterProtocolVC ()
@property (weak, nonatomic) IBOutlet UIWebView *protocolContent;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;

@end

@implementation BFRegisterProtocolVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
}

#pragma mark - private

- (void)setupViews {
    [self.navigationBar setBackgroundColor:mainColorDef];
}

#pragma mark - action

- (IBAction)pressBackBtn:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}

@end
