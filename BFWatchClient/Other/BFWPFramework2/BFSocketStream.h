//
//  BFSocketStream.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/22.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GCDAsyncSocket.h>
#import "GCDMulticastDelegate.h"

@interface BFSocketStream : NSObject <GCDAsyncSocketDelegate>

#pragma mark - Property
// 状态
@property (nonatomic, assign) int status;
// 主机端口
@property (nonatomic, assign) UInt16 hostPort;
// 主机名
@property (nonatomic, copy, nullable) NSString *hostName;
// 用户名
@property (nonatomic, copy, nullable) NSString *userName;
// 登录令牌
@property (nonatomic, copy, nullable) NSString *authToken;



#pragma mark - Method
NS_ASSUME_NONNULL_BEGIN
+ (nonnull instancetype)shareStream;

- (BOOL)connectWithTimeout:(NSTimeInterval)timeout type:(int)type error:(NSError **)err;

- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port withTimeout:(NSTimeInterval)timeout error:(NSError * _Nullable __autoreleasing * _Nullable)errPtr;

- (BOOL)connectToReadboyHost;

#pragma mark - Stream Status

- (BOOL)isConnected;

#pragma mark - add/remove delegate
/**
 * BFSocketStream uses a multicast delegate.
 * This allows one to add multiple delegates to a single BFSocketStream instance,
 * which makes it easier to separate various components and extensions.
 *
 * For example, if you were implementing two different custom extensions on top of BFSocketStream,
 * you could put them in separate classes, and simply add each as a delegate.
 **/
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;

@end


/*
 BFScoketStream 代理协议
 */
@protocol BFSocketStreamDelegate

@optional
/**
 连接中
 * This method is called after the tcp socket has connected to the remote host.
 * It may be used as a hook for various things, such as updating the UI or extracting the server's IP address.
 */
- (void)bfsocketStreamWillConnect:(BFSocketStream *)sender;
/**
 * This method is called after the XML stream has been fully opened.
 * More precisely, this method is called after an opening <xml/> and <stream:stream/> tag have been sent and received,
 * and after the stream features have been received, and any required features have been fullfilled.
 * At this point it's safe to begin communication with the server.
 **/
-(void)bfwpStream:(BFSocketStream *)sender socketDidConnect:(GCDAsyncSocket *)socket;
NS_ASSUME_NONNULL_END
@end
