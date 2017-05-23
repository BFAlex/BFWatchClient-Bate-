//
//  BFNavigationBar.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFNavigationBar : UIView


- (void)setBarTitle:(NSString *)title;
- (void)setBarBackButtonWithImage:(UIImage *)img andText:(NSString *)text;
- (void)setBarRightButtonWithImage:(UIImage *)img target:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end
