//
//  BFWPParser.m
//  BFWatchClient
//
//  Created by Readboy_BFAlex on 2017/5/24.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFWPParser.h"

@interface BFWPParser () {
    __weak id parserDelegate;
    
    dispatch_queue_t delegateQueue;
    dispatch_queue_t parserQueue;
    NSMutableData * receviceData;
    
    void *bfwpParserQueueTag;
}

@end

@implementation BFWPParser

#pragma mark - init

- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)dq
{
    return [self initWithDelegate:delegate delegateQueue:dq parserQueue:NULL];
}
- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)dq parserQueue:(dispatch_queue_t)pq
{
    if (self = [super init]) {
        
        parserDelegate = delegate;
        delegateQueue = dq;
        
        if (pq) {
            parserQueue = pq;
        }else{
            parserQueue = dispatch_queue_create("bfwp.parser", NULL);
        }
        
        bfwpParserQueueTag = &bfwpParserQueueTag;
        dispatch_queue_set_specific(parserQueue, bfwpParserQueueTag, bfwpParserQueueTag, NULL);
        
        receviceData = [[NSMutableData alloc]initWithCapacity:5];
    }
    
    return self;
}

#pragma mark - method


@end
