//
//  UIView+BFCustom.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "UIView+BFCustom.h"

@implementation UIView (BFCustom)

- (void)cornerView {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.bounds.size.height/2;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [[UIColor blackColor] CGColor];
}

- (void)cornerViewWithBorderColor:(UIColor *)borderColor {
    [self cornerView];
    self.layer.borderColor = [borderColor CGColor];
}

@end
