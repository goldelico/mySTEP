/*
    NSOperation.h
    Foundation

    Created by H. Nikolaus Schaller on 05.11.07.
    Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
	Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSObject.h>

@class NSArray;

typedef NSInteger NSOperationQueuePriority;

enum 
{
	NSOperationQueuePriorityVeryLow = -8,
	NSOperationQueuePriorityLow = -4,
	NSOperationQueuePriorityNormal = 0,
	NSOperationQueuePriorityHigh = 4,
	NSOperationQueuePriorityVeryHigh = 8
};

@interface NSOperation : NSObject
{
	
}

- (void) addDependency:(NSOperation *) op;
- (void) cancel;
- (NSArray *) dependencies;
- (id) init;
- (BOOL) isCancelled;
- (BOOL) isConcurrent;
- (BOOL) isExecuting;
- (BOOL) isFinished;
- (BOOL) isReady;
- (void) main;
- (NSOperationQueuePriority) queuePriority;
- (void) removeDependency:(NSOperation *) op;
- (void) setQueuePriority:(NSOperationQueuePriority) prio;
- (void) start;

@end

enum 
{
	NSOperationQueueDefaultMaxConcurrentOperationCount = -1
};

@interface NSOperationQueue : NSObject
{
	
}

- (void) addOperation:(NSOperation *) op;
- (void) cancelAllOperations;
- (BOOL) isSuspended;
- (NSInteger) maxConcurrentOperationCount;
- (NSArray *) operations;
- (void) setMaxConcurrentOperationCount:(NSInteger) c;
- (void) setSuspended:(BOOL) flag;
- (void) waitUntilAllOperationsAreFinished;

@end

extern NSString * const NSInvocationOperationVoidResultException;
extern NSString * const NSInvocationOperationCancelledException;

@interface NSInvocationOperation : NSObject
{
	
}

- (id) initWithInvocation:(NSInvocation *) invocation;
- (id) initWithTarget:(id) target selector:(SEL) sel object:(id) obj;
- (NSInvocation *) invocation;
- (id) result;

@end
