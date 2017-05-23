//
//  BFSocketStream.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GCDAsyncSocket.h>

@interface BFSocketStream : NSObject <GCDAsyncSocketDelegate>

+ (instancetype)shareStream;

- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port withTimeout:(NSTimeInterval)timeout error:(NSError * _Nullable __autoreleasing * _Nullable)errPtr;

- (BOOL)connectToReadboyHost;

#pragma mark - Stream Status

- (BOOL)isConnected;

@end
