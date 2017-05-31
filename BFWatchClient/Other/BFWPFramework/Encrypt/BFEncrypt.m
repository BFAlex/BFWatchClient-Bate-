//
//  BFEncrypt.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/26.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFEncrypt.h"

@implementation BFEncrypt

#pragma mark - 获得输入密码的MD5码

+ (NSString *)md5_16:(NSString *)str {
    const char *cStr =[str UTF8String];
    unsigned char resulut[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), resulut);
    
    return[NSString stringWithFormat:
           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
           resulut[0],resulut[1],resulut[2],resulut[3],
           resulut[4],resulut[5],resulut[6],resulut[7],
           resulut[8], resulut[9],resulut[10],resulut[11],
           resulut[12], resulut[13],resulut[14],resulut[15]];
}

+ (NSString *)md5_32:(NSString *)str {
    const char *cStr =[str UTF8String];
    unsigned char resulut[32];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), resulut);
    
    return[NSString stringWithFormat:
           @"%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x",
           resulut[0],resulut[1],resulut[2],resulut[3],
           resulut[4],resulut[5],resulut[6],resulut[7],
           resulut[8], resulut[9],resulut[10],resulut[11],
           resulut[12], resulut[13],resulut[14],resulut[15],
           resulut[16], resulut[17],resulut[18],resulut[19],
           resulut[20], resulut[21],resulut[22],resulut[23],
           resulut[24], resulut[25],resulut[26],resulut[27],
           resulut[28], resulut[29],resulut[30],resulut[31]];
}


#pragma mark - BFWP 协议解密/解密

+ (NSData *)bfWPDecrypt:(NSData *)aInput {
    NSString *  encryptStr = [[NSString alloc] initWithData:aInput encoding:NSUTF8StringEncoding];
    NSString *  decryStr = [BFEncrypt bfWPDecrypt:encryptStr Key:@"22690dfba7ab83b4"];
    
    NSData *  resultData = [decryStr dataUsingEncoding:NSUTF8StringEncoding];
    
    return resultData;
}

+ (NSString *)bfWPEncrypt:(NSString *)aInput {
    return [BFEncrypt bfWPEncrypt:aInput Key:@"22690dfba7ab83b4"];
}

/**
 *  协议加密 流程 ：原文 -> RC4解密 －> base64加密 －>密文
 */
+(NSString*)bfWPEncrypt:(NSString*)aInput Key:(NSString*)aKey
{
    NSData* initData = [aInput dataUsingEncoding:NSUTF8StringEncoding];
    NSData * rc4 = [BFEncrypt RC4Encrypt:initData withKey:aKey];
    NSString *base64 = [rc4 base64EncodedStringWithOptions:0];
    
    return base64;
}
/**
 *  协议解密 流程 ：密文 -> base64解密 －> RC4解密 －> 原文
 */
+(NSString*)bfWPDecrypt:(NSString*)aInput Key:(NSString*)aKey
{
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:aInput options:0];
    NSData * rc4Data = [BFEncrypt RC4Decrypt:decodedData withKey:aKey];
    
    return [[NSString alloc] initWithData:rc4Data encoding:NSUTF8StringEncoding];
}
#pragma RC4 加密/解密
+ (NSData *)RC4Encrypt:(NSData*)srcData withKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeMaxRC4+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [srcData length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + [key length];
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmRC4,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          [key length],// kCCKeySizeMaxRC4,
                                          NULL /* initialization vector (optional) */,
                                          [srcData bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

+ (NSData *)RC4Decrypt:(NSData*)srcData withKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeMaxRC4+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [srcData length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + [key length];
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmRC4,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          [key length],//kCCKeySizeMaxRC4,
                                          NULL /* initialization vector (optional) */,
                                          [srcData bytes],
                                          dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

@end
