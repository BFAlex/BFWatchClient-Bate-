//
//  BFLoginVC.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/8.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFLoginVC.h"
#import "UIView+BFCustom.h"

@interface BFLoginVC () {
    // 授权失败
    BOOL _isAuthFail;
    // app启动流程标记
    BOOL _isLoginComeIn;    // 是否是登录成功后，进入的主界面
    BOOL _isAppFirstlaunch; // 应用首次启动
}

@property (weak, nonatomic) IBOutlet UIView *headImgContainer;
@property (weak, nonatomic) IBOutlet UIView *iphoneContainer;
@property (weak, nonatomic) IBOutlet UIView *pwdContainer;
@property (weak, nonatomic) IBOutlet UIImageView *headImg;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UITextField *pwdField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation BFLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupPropertiesDefaultValue];
    [self setupViews];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.hidden = true;
    NSLog(@"navigation bar height: %f", self.navigationController.navigationBar.bounds.size.height);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

#pragma mark - private

- (void)setupPropertiesDefaultValue {
    _isAuthFail = false;
    _isLoginComeIn = false;
    _isAppFirstlaunch = false;
}

- (void)setupViews {
    NSLog(@"app -> %@", appName);
    
    self.navigationController.navigationBar.barTintColor = mainColorDef;
    
    [self.headImgContainer setBackgroundColor:mainColorDef];
    [self.loginBtn setBackgroundColor:mainColorDef];
    [self.iphoneContainer cornerView];
    [self.pwdContainer cornerView];
    [self.loginBtn cornerViewWithBorderColor:[UIColor clearColor]];
}

- (BOOL)checkUsefulLogin {
    BFLog([NSString stringWithFormat:@"phone:%@", self.phoneField.text]);
    BFLog([NSString stringWithFormat:@"pwd:%@", self.pwdField.text]);
    if (!self.phoneField.text || self.phoneField.text.length != PHONE_LENGTH) {
        [BFHUD showWarnMessage:@"请输入有效手机号"];
        return false;
    }
    
    if (!self.pwdField.text || self.pwdField.text.length < ACCOUNT_PWD_LENGTH) {
        [BFHUD showWarnMessage:@"请输入有效密码"];
        return false;
    }
    
    return true;
}

#pragma mark - action

- (IBAction)clickLoginBtn:(UIButton *)sender {
    BFLog(@"");
    // 检查账号密码是否有效
    if (![self checkUsefulLogin]) { return; }
    
    _isAuthFail = false;
    _isLoginComeIn = false;
    
    [[BFSocketStream shareStream] connectToReadboyHost];
}
- (IBAction)clickRegisterBtn:(UIButton *)sender {
}
- (IBAction)clickForgetPwdBtn:(UIButton *)sender {
}

@end
