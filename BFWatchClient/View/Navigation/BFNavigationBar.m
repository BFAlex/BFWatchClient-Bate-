//
//  BFNavigationBar.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFNavigationBar.h"

@interface BFNavigationBar ()
@property (weak, nonatomic) IBOutlet UIView *leftContainer;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIView *rightContainer;
@end

@implementation BFNavigationBar

- (void)setBarTitle:(NSString *)title {
    if (title) {
        self.title.text = title;
    } else {
        self.title.text = @"";
    }
}

- (void)setBarBackButtonWithImage:(UIImage *)img andText:(NSString *)text {
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (img) {
        [backBtn setBackgroundImage:img forState:UIControlStateNormal];
    }
    if (text.length > 0) {
        [backBtn setTitle:text forState:UIControlStateNormal];
    }
    [backBtn addTarget:self action:@selector(pressBackBtn) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - private

- (void)pressBackBtn {
    
}

@end
