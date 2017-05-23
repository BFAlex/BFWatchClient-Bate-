//
//  BFRegisterPhoneVC.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFRegisterPhoneVC.h"
#import "UIView+BFCustom.h"
#import "UIButton+BFCustom.h"
#import "BFStoryboardTool.h"

@interface BFRegisterPhoneVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *phoneContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UIView *navigationBar;

@end

@implementation BFRegisterPhoneVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.hidden = false;
}

#pragma mark - private

- (void)setupViews {
    
    [self.phoneContainer cornerView];
    [self setupNextBtn];
    [self setupPhoneTextField];
    
    [self.navigationBar setBackgroundColor:mainColorDef];

}

- (void)setupNextBtn {
    [self.nextBtn cornerViewWithBorderColor:[UIColor clearColor]];
    [self.nextBtn setBackgroundColor:mainColorDef];
    [self enableNextBtn:false];
}

- (void)setupPhoneTextField {
    self.phoneField.delegate = self;
}

- (void)enableNextBtn:(BOOL)enable {
    self.nextBtn.enabled = enable;
    if (self.nextBtn.enabled) {
        [self.nextBtn enableBtn];
    } else {
        [self.nextBtn disableBtn];
    }
}

- (BOOL)checkPhoneValid {
#warning 电话号码是否有效
    return false;
}

#pragma mark - TextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    BFLog(@"");
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BFLog([NSString stringWithFormat:@"range.location:%d, range.length:%d", range.location, range.length]);
    
    [self enableNextBtn:range.length == 0
                    && (range.location == 10 || self.phoneField.text.length == 11)];
    
    
    return range.location <= 10;
}

//- (void)textFieldDidEndEditing:(UITextField *)textField {
//    BFLog(@"");
//    [self enableNextBtn:self.phoneField.text.length == 11];
//}

#pragma mark - action

- (IBAction)pressBackBtn:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (IBAction)pressNextBtn:(UIButton *)sender {
    BFLog(@"clicking...");
    
    // 判断号码是否满足注册条件
//    if (![self checkPhoneValid]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"该账号已被注册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//        [alert show];
//        
//        return;
//    }
    
    UIViewController *vc = [BFStoryboardTool viewControllerForStoryboardName:@"BFLoginSB" andIdentifier:@"BFRegisterVerificationVCID"];
    [self.navigationController pushViewController:vc animated:true];
}
@end
