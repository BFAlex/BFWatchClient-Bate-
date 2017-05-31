//
//  BFEncrypt.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/26.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>
// IOS自带密码库
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>

@interface BFEncrypt : NSObject

#pragma mark - 获得输入密码的MD5码
+ (NSString*)md5_32:(NSString*)str;
+ (NSString*)md5_16:(NSString*)str;


#pragma mark - BFWP 协议解密/解密
+ (NSString*)bfWPEncrypt:(NSString*)aInput;
+ (NSData*)bfWPDecrypt:(NSData*)aInput;

@end
