//
//  BFStoryboardTool.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFStoryboardTool.h"

@implementation BFStoryboardTool

+ (UIViewController *)viewControllerForStoryboardName:(NSString *)storyboard andIdentifier:(NSString *)ID {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:storyboard bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:ID];
    
    return vc;
}

@end
