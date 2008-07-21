/* 
   NSThread.h

   Object representing a context of execution within a shared memory space

   Copyright (C) 1996 Free Software Foundation, Inc.

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSThread
#define _mySTEP_H_NSThread

#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDate.h>

@class NSMutableDictionary;
@class NSDate;


@interface NSThread : NSObject
{
	NSMutableDictionary *_dictionary;
	id _target;
	SEL _selector;

@public
	NSHandler2 *_exception_handler;
	struct autorelease_thread_vars
		// Each thread has its own copy of these variables.
		// A ptr to this structure is an ivar of NSThread.
		{					// The current, default NSAutoreleasePool for the calling 
							// thread; the one that will hold objects that are 
							// arguments to [NSAutoreleasePool +addObject:].
			NSAutoreleasePool *current_pool;
			
			// Total number of objects autoreleased since the
			// thread was started, or since 
			// -resetTotalAutoreleasedObjects was called in this thread
			unsigned total_objects_count;
			
			id *pool_cache;			// A cache of NSAutoreleasePool's already alloc'ed
			int pool_cache_size;	// Caching old pools instead of dealloc / realloc
			int pool_cache_count;	// saves time
			
			BOOL thread_in_dealloc;
		} _autorelease_vars;
}

+ (NSThread *) currentThread;
+ (void) detachNewThreadSelector:(SEL) aSelector
						toTarget:(id) aTarget
						withObject:(id) anArgument;
+ (void) exit;
+ (BOOL) isMainThread;
+ (BOOL) isMultiThreaded;
+ (NSThread *) mainThread;
+ (BOOL) setThreadPriority:(double) priority;
+ (void) sleepForTimeInterval:(NSTimeInterval) interval;
+ (void) sleepUntilDate:(NSDate *) date;
+ (double) threadPriority;

- (void) cancel;
- (id) init;
- (id) initWithTarget:(id) target selector:(SEL) sel object:(id) arg;
- (BOOL) isCancelled;
- (BOOL) isExecuting;
- (BOOL) isFinished;
- (BOOL) isMainThread;
- (void) main;    // thread body method
- (NSString *) name;
- (void) setName:(NSString *) name;
- (void) setStackSize:(NSUInteger) size;
- (NSUInteger) stackSize;
- (void) start;
- (NSMutableDictionary *) threadDictionary;

@end

@interface NSObject (NSThread)

- (void) performSelectorOnMainThread:(SEL) sel
						  withObject:(id) arg
					   waitUntilDone:(BOOL) wait;
- (void) performSelectorOnMainThread:(SEL) sel
						  withObject:(id) arg
					   waitUntilDone:(BOOL) wait
							   modes:(NSArray *) array;
- (void) performSelector:(SEL) sel
				onThread:(NSThread *) thread
			  withObject:(id) arg
		   waitUntilDone:(BOOL) wait;
- (void) performSelector:(SEL) sel
				onThread:(NSThread *) thread
			  withObject:(id) arg
		   waitUntilDone:(BOOL) wait
				   modes:(NSArray *) array;
- (void) performSelectorInBackground:(SEL) sel withObject:(id) arg;

@end

extern NSString *NSDidBecomeSingleThreadedNotification;		// not implemented
extern NSString *NSThreadWillExitNotification;
extern NSString *NSWillBecomeMultiThreadedNotification;					// Notifications

#endif /* _mySTEP_H_NSThread */
