//
//  TestClass.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/24.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "TestClass.h"

@interface TestClass () {
    NSString *_str;
}
@end



@implementation TestClass

- (void)setStr:(NSString *)str {
    _str = str;
}

- (NSString *)str {
    return _str;
}

@end
