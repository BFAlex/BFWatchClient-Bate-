//
//  BFStoryboardTool.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/15.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFStoryboardTool : NSObject

+ (UIViewController *)viewControllerForStoryboardName:(NSString *)storyboard andIdentifier:(NSString *)ID;

@end
