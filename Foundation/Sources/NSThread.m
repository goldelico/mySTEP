/* 
   NSThread.m

   Objects representing a unit of execution within a shared memory space

   Copyright (C) 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>

#include <unistd.h>

// Class variables
static BOOL __hasEverBeenMultiThreaded = NO;

typedef enum _NSThreadPriority
{
	NSInteractiveThreadPriority,
	NSBackgroundThreadPriority,
	NSLowThreadPriority
} NSThreadPriority;


@implementation NSThread

+ (NSThread *) currentThread		{ return (id) objc_thread_get_data(); }
+ (BOOL) isMultiThreaded			{ return __hasEverBeenMultiThreaded; }

- (void) _gsThreadDetach:(id)anArgument
{
	id (*imp)(id,SEL,id);

	objc_thread_set_data(self);
	_autorelease_vars.current_pool = [NSAutoreleasePool new];
#ifndef __APPLE__
	if ((imp = (id(*)(id, SEL, id))objc_msg_lookup(_target, _selector)))
		(*imp)(_target, _selector, anArgument);
	else
#endif
		NSLog(@"Unable to call thread detach method");	// FIX ME exception
}

+ (void) detachNewThreadSelector:(SEL)aSelector
						toTarget:(id)aTarget
						withObject:(id)anArgument		// Have the runtime
{										 				// detach the thread
	NSThread *t = [NSThread new];

	t->_target = aTarget;
	t->_selector = aSelector;
										// Post note if this is first thread
	if (!__hasEverBeenMultiThreaded)	// Won't work properly if threads are
		{								// not all created by the objc runtime.
		__hasEverBeenMultiThreaded = YES;

		[[NSNotificationCenter defaultCenter] postNotificationName:NSWillBecomeMultiThreadedNotification object:nil];
		}

	if (objc_thread_detach(@selector(_gsThreadDetach:), t, anArgument) == NULL)
		NSLog(@"Unable to detach thread (unknown error)");	// FIX ME exception
}

+ (void) sleepUntilDate:(NSDate*)date
{
	NSTimeInterval delay = [date timeIntervalSinceNow];		// delay is the number
														// of seconds remaining 
	while (delay > (30.0 * 60.0))						// in our sleep period
		{
		sleep(30 * 60);									// sleep 30 minutes
		delay = [date timeIntervalSinceNow];
		}

	while (delay > 0)									// sleep may return 
    	{												// early because of
      	sleep(delay);									// signals
      	delay = [date timeIntervalSinceNow];
    	}
	// FIXME: use usleep() for sub-seconds precision
}

+ (void) exit											// Terminate thread
{
	NSThread *t = [NSThread currentThread];
#if 0
	NSLog(@"NSThread: __NSGlobalLock lock");
#endif
	[__NSGlobalLock lock];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSThreadWillExitNotification object:t];
	[t release];										// Release thread obj
	[__NSGlobalLock unlock];

	objc_thread_exit();									// Ask the runtime to
}														// exit the thread

- (void) dealloc
{
	_autorelease_vars.thread_in_dealloc = YES;
	while((_autorelease_vars.current_pool))
		[_autorelease_vars.current_pool release];
	[_dictionary release];
	[super dealloc];
}

#undef main	// may be defined as objc_main

- (void) main
{
	NIMP;
}

- (NSMutableDictionary*) threadDictionary
{
	return (_dictionary) ? _dictionary 
						 : (_dictionary = [NSMutableDictionary new]);
}

+ (double) threadPriority { return 0.5; }

+ (BOOL) setThreadPriority:(double) priority;
{
	if(priority < 0.0)
		priority=0.0;
	else if(priority > 1.0)
		priority=1.0;	// limit
	NIMP;
	return NO;
}

@end
