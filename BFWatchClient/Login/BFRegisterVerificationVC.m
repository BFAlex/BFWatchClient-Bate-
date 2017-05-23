//
//  BFRegisterVerificationVC.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFRegisterVerificationVC.h"
#import "UIView+BFCustom.h"

@interface BFRegisterVerificationVC ()
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *verificationContainer;
@property (weak, nonatomic) IBOutlet UIView *pwdContainer;
@property (weak, nonatomic) IBOutlet UIButton *getCodeBtn;
@property (weak, nonatomic) IBOutlet UIButton *agreeBtn;

@end

@implementation BFRegisterVerificationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
}

#pragma mark - private

- (void)setupViews {
    
    [self.navigationBar setBackgroundColor:mainColorDef];
    [self.getCodeBtn setBackgroundColor:mainColorDef];
    [self.agreeBtn setBackgroundColor:mainColorDef];
    
    [self.verificationContainer cornerView];
    [self.pwdContainer cornerView];
    [self.getCodeBtn cornerViewWithBorderColor:mainColorDef];
    [self.agreeBtn cornerViewWithBorderColor:mainColorDef];
}


#pragma mark - action

- (IBAction)getVerificationCode:(UIButton *)sender {
}
- (IBAction)createNewAccount:(UIButton *)sender {
}
- (IBAction)pressBackBtn:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}

@end
