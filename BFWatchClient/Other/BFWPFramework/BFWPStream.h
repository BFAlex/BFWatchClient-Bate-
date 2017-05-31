//
//  BFWPStream.h
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/25.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GCDAsyncSocket.h>

@interface BFWPStream : NSObject<GCDAsyncSocketDelegate>
NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, assign) UInt16 hostPort;
@property (nonatomic, copy) NSString *hostName;


/**
 连接 Server
 */
- (BOOL)connectToServerForType:(int)type withTimeout:(NSTimeInterval)timeout error:(NSError * _Nullable __autoreleasing * _Nullable)connectErr;

#pragma mark About Status

- (BOOL)isConnected;

#pragma mark About Login
/**
 密码登录
 */
- (BOOL)loginAccount:(NSString *)account password:(NSString *)pwd error:(NSError * _Nullable __autoreleasing *)error;
/**
 授权码登录
 */
- (BOOL)loginAccount:(NSString *)account auth:(NSString *)auth error:(NSError * _Nullable __autoreleasing *)error;

#pragma mark status

- (BOOL)isLoginConnecting;

#pragma mark - GCDMulticastDelegate
/**
 * RBWPStream uses a multicast delegate.
 * This allows one to add multiple delegates to a single RBWPStream instance,
 * which makes it easier to separate various components and extensions.
 *
 * For example, if you were implementing two different custom extensions on top of RBWP,
 * you could put them in separate classes, and simply add each as a delegate.
 **/
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;

@end


@protocol BFWPStreamDelegate

@optional
/**
 连接中
 * This method is called after the tcp socket has connected to the remote host.
 * It may be used as a hook for various things, such as updating the UI or extracting the server's IP address.
 */
- (void)bfWPStreamWillConnect:(BFWPStream *)sender;
/**
 * This method is called after the XML stream has been fully opened.
 * More precisely, this method is called after an opening <xml/> and <stream:stream/> tag have been sent and received,
 * and after the stream features have been received, and any required features have been fullfilled.
 * At this point it's safe to begin communication with the server.
 **/
- (void)bfWPStream:(BFWPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket;
/**
 *  登录中
 */
- (void)bfWPStreamWillAuthenticate:(BFWPStream *)sender;
/**
 * This method is called after the stream is closed.
 *
 * The given error parameter will be non-nil if the error was due to something outside the general rbwp realm.
 * Some examples:
 * - The TCP socket was unexpectedly disconnected.
 * - The SRV resolution of the domain failed.
 * - Error parsing json sent from server.
 **/
- (void)bfWPStreamDidDisconnect:(BFWPStream *)sender withError:(NSError *)error;

NS_ASSUME_NONNULL_END
@end
