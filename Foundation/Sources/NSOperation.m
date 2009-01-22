//
//  NSOperation.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 05.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSOperation.h"
#import "NSArray.h"
#import "NSException.h"
#import "NSInvocation.h"
#import "NSMethodSignature.h"

@implementation NSOperation

- (void) addDependency:(NSOperation *) op;
{
	[_dependencies addObject:op];
}

- (void) cancel;
{
	_isCancelled=YES;
}

- (NSArray *) dependencies; { return [[_dependencies copy] autorelease]; }

- (id) init;
{
	if((self=[super init]))
			{
				_dependencies=[[NSMutableArray alloc] initWithCapacity:5];
			}
	return self;
}

- (void) dealloc;
{
	[_dependencies release];
	[super dealloc];
}

- (BOOL) isCancelled; { return _isCancelled; }
- (BOOL) isConcurrent; { return NO; }	// subclass should override
- (BOOL) isExecuting; { return _isExecuting; }
- (BOOL) isFinished; { return _isFinished; }
- (BOOL) isReady; { return NO; /* fixme - check dependencies */ }
- (void) main; { return; }	// implement in subclass
- (NSOperationQueuePriority) queuePriority; { return _queuePriority; }
- (void) removeDependency:(NSOperation *) op; { [_dependencies removeObject:op]; }

- (void) setQueuePriority:(NSOperationQueuePriority) prio;
{
	// round to next available level
	_queuePriority=prio;
}

- (void) start;
{
	_isExecuting=YES;
}

- (void) _setQueue:(NSOperationQueue *) q
{
	if(_queue)
		[NSException raise:NSInvalidArgumentException format:@"Operation is already queued"];
	_queue=q;
}

@end

@implementation NSOperationQueue

- (id) init;
{
	if((self=[super init]))
			{
				_operations=[[NSMutableArray alloc] initWithCapacity:5];
			}
	return self;
}

- (void) dealloc;
{
	[_operations release];
	[super dealloc];
}


- (void) addOperation:(NSOperation *) op;
{
	[_operations addObject:op];
	// check if we can run one
}

- (void) cancelAllOperations;
{
	[_operations makeObjectsPerformSelector:@selector(cancel:)];
}

- (BOOL) isSuspended; { return _isSuspended; }

- (NSInteger) maxConcurrentOperationCount; { return _maxConcurrentOperationCount; }
- (NSArray *) operations; { return [[_operations copy] autorelease]; }
- (void) setMaxConcurrentOperationCount:(NSInteger) c; { _maxConcurrentOperationCount=c; }

- (void) setSuspended:(BOOL) flag;
{
	if(_isSuspended && !flag)
		; // resume
	_isSuspended=flag;
}

- (void) waitUntilAllOperationsAreFinished;
{
	while(YES /* not all operations done */)
		[self setSuspended:NO];
}

@end

@implementation NSInvocationOperation

- (id) initWithInvocation:(NSInvocation *) invocation;
{
	if((self=[super init]))
			{
				_invocation=[invocation retain];
			}
	return self;
}

- (id) initWithTarget:(id) target selector:(SEL) sel object:(id) obj;
{
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	int numberOfArguments=[ms numberOfArguments];
	if(numberOfArguments == 2 || numberOfArguments == 3)
			{
				NSInvocation *inv=[NSInvocation invocationWithMethodSignature:ms];
				[inv setTarget:target];
				[inv setSelector:sel];
				if(numberOfArguments == 3)
					[inv setArgument:&obj atIndex:2];
				return [self initWithInvocation:inv];
			}
	else
			{
				[self release];
				return nil;
			}
}

- (void) dealloc
{
	[_invocation release];
	[super dealloc];
}

- (NSInvocation *) invocation; { return _invocation; }

- (id) result;
{
	id r;
	if(![self isFinished])
		return nil;	// still running
	// re-raise exceptions
	/* check return type */
	[_invocation getReturnValue:&r];
	return r;
}

- (void) main
{
	[_invocation invoke];
}

@end
