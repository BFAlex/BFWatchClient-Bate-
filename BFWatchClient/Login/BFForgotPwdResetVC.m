//
//  BFForgotPwdResetVC.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFForgotPwdResetVC.h"
#import "UIView+BFCustom.h"

@interface BFForgotPwdResetVC ()
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *verifyContainer;
@property (weak, nonatomic) IBOutlet UIView *pwdContainer;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UIButton *getVerifyBtn;

@end

@implementation BFForgotPwdResetVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
}

#pragma mark - action

- (void)setupViews {
    [self.navigationBar setBackgroundColor:mainColorDef];
    [self.getVerifyBtn setBackgroundColor:mainColorDef];
    [self.resetBtn setBackgroundColor:mainColorDef];
    
    [self.verifyContainer cornerView];
    [self.pwdContainer cornerView];
    [self.getVerifyBtn cornerViewWithBorderColor:mainColorDef];
    [self.resetBtn cornerViewWithBorderColor:mainColorDef];
}

#pragma mark - action

- (IBAction)pressBackBtn:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}
- (IBAction)pressVerifyBtn:(UIButton *)sender {
}
- (IBAction)pressResetBtn:(id)sender {
}

@end
