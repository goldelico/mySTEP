/* 
 NSRunLoop.m
 
 Implementation of object for waiting on several input sources.
 
 Copyright (C) 1996, 1997 Free Software Foundation, Inc.
 
 Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	March 1996
 GNUstep: Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	August 1997
 mySTEP:	Felipe A. Rodriguez <farz@mindspring.com>
 Date:	April 1999
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSThread.h>
#import "NSPrivate.h"

#include <time.h>
#include <sys/time.h>
#include <sys/types.h>

//*****************************************************************************
//
// 		_NSRunLoopPerformer 
//
//*****************************************************************************

@interface _NSRunLoopPerformer: NSObject
{										// The RunLoopPerformer class is used
	SEL selector;						// to hold information about messages
	id target;							// which are due to be sent to objects
	id argument;						// once a particular runloop iteration 
	unsigned order;						// has passed.
@public
	NSArray	*modes;
	NSTimer	*timer;		// nonretained pointer!
}

- (id) initWithSelector:(SEL)aSelector
				 target:(id)target
			   argument:(id)argument
				  order:(unsigned int)order
				  modes:(NSArray*)modes;
- (void) invalidate;
- (BOOL) matchesTarget:(id)aTarget;
- (BOOL) matchesSelector:(SEL)aSelector
				  target:(id)aTarget
				argument:(id)anArgument;
- (unsigned int) order;
- (void) setTimer:(NSTimer*)timer;
- (NSArray*) modes;
- (NSTimer*) timer;
- (void) fire;

@end

@interface NSRunLoop (Private)

- (NSMutableArray*) _timedPerformers;

@end

#if WORK_IN_PROGRESS

// FIXME: there is a problem with this approach: a timer/performer is invalidated/removed as soon as it triggers in *any* mode! So it must be removed from all _NSRunLoopMode objects!

@interface _NSRunLoopMode : NSObject
{
	NSMutableArray *performers;
	NSMutableArray *timers;
	NSMutableArray *inputWatchers, *outputWatchers;
}

- (void) addInputWatcher:(id) watcher;
- (void) removeInputWatcher:(id) watcher;
- (void) addOutputWatcher:(id) watcher;
- (void) removeOutputWatcher:(id) watcher;
- (void) addPerformer:(_NSRunLoopPerformer *) performer;
- (void) addTimer:(NSTimer *) timer;

- (BOOL) runOnceUntilDate:(NSDate *) date;	// run loop for watchers once but timeout at given date
- (NSDate *) fireTimers;	// fire all overdue timers and return date of next pending timer (or distantFuture)

@end

@implementation _NSRunLoopMode

- (id) init
{
	if((self=[super init]))
		{
		
		}
	return self;
}

- (void) dealloc;
{
	[performers release];
	[timers release];
	[inputWatchers release];
	[outputWatchers release];
	[super dealloc];
}

- (void) addInputWatcher:(id) watcher;
{
	if([inputWatchers containsObject:watcher])
		NSLog(@"trying to add input watcher twice: %@", watcher);
	if(!inputWatchers) inputWatchers=[[NSMutableArray alloc] initWithCapacity:5];
	[inputWatchers addObject:watcher];
}

- (void) removeInputWatcher:(id) watcher;
{
	[inputWatchers removeObject:watcher];
}

- (void) addOutputWatcher:(id) watcher;
{
	if([outputWatchers containsObject:watcher])
		NSLog(@"trying to add output watcher twice: %@", watcher);
	if(!outputWatchers) outputWatchers=[[NSMutableArray alloc] initWithCapacity:5];
	[outputWatchers addObject:watcher];
}

- (void) removeOutputWatcher:(id) watcher;
{
	[outputWatchers removeObject:watcher];
}

- (void) addPerformer:(_NSRunLoopPerformer *) performer;
{
	if(!performers) performers=[[NSMutableArray alloc] initWithCapacity:5];
	[performers addObject:performer];
}

- (void) addTimer:(NSTimer *) timer;
{
	if([timers containsObject:timer])
		NSLog(@"trying to add timer twice: %@", timer);
	if(!timers) timers=[[NSMutableArray alloc] initWithCapacity:5];
	// we may insert-sort?
	[timers addObject:timer];
}

- (BOOL) runPerformers;
{
	
}

- (BOOL) runOnceUntilDate:(NSDate *) date;
{ // run loop for watchers once but timeout at given date (but don't handle performers and timers)
	
}

- (NSDate *) fireTimers;
{ // fire all overdue timers and return date of next pending timer (or distantFuture)
	
}

@end

#endif

@implementation _NSRunLoopPerformer

- (void) dealloc
{
#if 0
	NSLog(@"%@ dealloc", self);
	NSLog(@"timer: %@", timer);
#endif
	[timer invalidate];	// if any
	[target release];
	[argument release];
	[modes release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ timer:(%p) target:%@ selector:%@",
			NSStringFromClass([self class]),
			timer,
			target,
			NSStringFromSelector(selector)];
}

- (void) invalidate
{
#if 0
	NSLog(@"invalidate %@", self);
#endif
	[timer invalidate];	// invalidate our timer (if any)
	timer=nil;
}

- (void) fire
{ // untimed performers are being processed or timer has fired
#if 0
	NSLog(@"fire %@ retainCount=%d", self, [self retainCount]);
#endif
	if(timer != nil)
		{
#if 0
		NSLog(@"remove self from list of timed performers: %@", [[NSRunLoop currentRunLoop] _timedPerformers]);
#endif
		[[[NSRunLoop currentRunLoop] _timedPerformers] removeObjectIdenticalTo:self];	// remove us from performers list
		}
	[target performSelector:selector withObject:argument];
}

- (id) initWithSelector:(SEL)aSelector
				 target:(id)aTarget
			   argument:(id)anArgument
				  order:(unsigned int)theOrder
				  modes:(NSArray*)theModes
{
	if((self = [super init]))
		{
		selector = aSelector;
		target = [aTarget retain];
		argument = [anArgument retain];
		order = theOrder;
		modes = [theModes copy];
		}
	return self;
}

- (BOOL) matchesTarget:(id)aTarget
{
	return (target == aTarget);
}

- (BOOL) matchesSelector:(SEL)aSelector
				  target:(id)aTarget
				argument:(id)anArgument
{ 
#if 0
	NSLog(@"%s == %s?", sel_get_name(aSelector), sel_get_name(selector));
	NSLog(@"%@ == %@?", target, aTarget);
	NSLog(@"%@ == %@?", argument, anArgument);
#endif
	return (target == aTarget) && sel_isEqual(aSelector, selector) && (argument == anArgument || [argument isEqual:anArgument]);
}

- (NSArray*) modes						{ return modes; }
- (NSTimer*) timer						{ return timer; }
- (unsigned int) order					{ return order; }
- (void) setTimer:(NSTimer*)t
{
#if 0
	NSLog(@"timer %p := %p", timer, t);
#endif
	timer=t;	// we are retained by the timer - and not vice versa
}

@end /* _NSRunLoopPerformer */

@implementation NSRunLoop

// Class variables
static NSThread *__currentThread = nil;
static NSRunLoop *__currentRunLoop = nil;
static NSRunLoop *__mainRunLoop = nil;
NSString *NSDefaultRunLoopMode = @"NSDefaultRunLoopMode";

+ (NSRunLoop *) currentRunLoop
{
	NSString *key = @"NSRunLoopThreadKey";
	NSThread *t = [NSThread currentThread];
	if(__currentThread != t)
		{
		__currentThread = t;
		
		if((__currentRunLoop = [[t threadDictionary] objectForKey:key]) == nil)					
			{										// if current thread has no
				__currentRunLoop = [NSRunLoop new];		// run loop create one
				if(!__mainRunLoop)
					__mainRunLoop=__currentRunLoop;		// the first runloop is the main runloop
				[[t threadDictionary] setObject:__currentRunLoop forKey:key];
				[__currentRunLoop release];
			}
		}
	return __currentRunLoop;
}

+ (NSRunLoop *) mainRunLoop
{
	return __mainRunLoop;
}

- (id) init											// designated initializer
{
	if((self=[super init]))
		{
		_mode_2_timers = NSCreateMapTable (NSNonRetainedObjectMapKeyCallBacks,
										   NSObjectMapValueCallBacks, 0);
		_mode_2_inputwatchers = NSCreateMapTable (NSObjectMapKeyCallBacks,
												  NSObjectMapValueCallBacks, 0);
		_mode_2_outputwatchers = NSCreateMapTable (NSObjectMapKeyCallBacks,
												   NSObjectMapValueCallBacks, 0);
		rfd_2_object = NSCreateMapTable (NSIntMapKeyCallBacks,
										 NSObjectMapValueCallBacks, 0);
		wfd_2_object = NSCreateMapTable (NSIntMapKeyCallBacks,
										 NSObjectMapValueCallBacks, 0);
		_performers = [[NSMutableArray alloc] initWithCapacity:8];
		_timedPerformers = [[NSMutableArray alloc] initWithCapacity:8];
		// we should have a list of ALL runloops so that we can remove watchers for any of them
		}
	return self;
}

- (void) dealloc
{
	NSFreeMapTable(_mode_2_timers);
	NSFreeMapTable(_mode_2_inputwatchers);
	NSFreeMapTable(_mode_2_outputwatchers);
	NSFreeMapTable (rfd_2_object);
	NSFreeMapTable (wfd_2_object);
	[_performers release];
	[_timedPerformers release];
	[super dealloc];
}

- (void) addTimer:(NSTimer *)timer forMode:(NSString*)mode		// Add timer. It is removed when it becomes invalid
{
	NSMutableArray *timers = NSMapGet(_mode_2_timers, mode);
#if 0
	NSLog(@"addTimer %@ forMode:%@", timer, mode);
#endif
	if(!timers)
		{
		timers = [NSMutableArray new];
		NSMapInsert(_mode_2_timers, mode, timers);
		[timers release];
		}
	if([timers containsObject:timer])
		NSLog(@"trying to add timer twice: %@", timer);
	[timers addObject:timer];	// append timer
#if 0
	NSLog(@"timers: %@", timers);
#endif
}

/* idea for different architecture
 *
 * have a private _NSRunLoopMode class
 * that collects all watchers for a single mode
 * and have NSRunLoop manage the mode -> _NSRunLoopMode mapping
 * _NSRunLoopMode could have methods to manage the timers in a sorted queue
 * - limitDate
 * - fireTimers
 * - selectForInputs
 */

// FIXME: rebuild according to the pseudo-code at http://www.mikeash.com/pyblog/friday-qa-2010-01-01-nsrunloop-internals.html

- (BOOL) _runLoopForMode:(NSString *) mode beforeDate:(NSDate *) before limitDate:(NSDate **) limit;
{ // this is the core runloop that runs the loop exactly once - blocking until before or the limit date (whichever comes first)
	NSTimeInterval ti;					// Listen to input sources.
	struct timeval timeout;
	void *select_timeout;
	NSMutableArray *watchers;
	// fd_set fds;						// file descriptors we will listen to. 
	fd_set read_fds;					// Copy for listening to read-ready fds.
	fd_set exception_fds;				// Copy for listening to exception fds.
	fd_set write_fds;					// Copy for listening for write-ready fds.
	int select_return;
	int fd_index;
	int num_inputs = 0;
	int count = [_performers count];
	id saved_mode=_current_mode;	// an input handler might run the same loop recursively!
	int i, loop;
	NSMutableArray *timers;
	NSAutoreleasePool *arp;
	BOOL anyInput;
	NSDate *limitDate=[NSDate distantFuture];	// default

	NSAssert(mode, NSInvalidArgumentException);
#if 0
	NSLog(@"_runLoopForMode:%@ beforeDate:%@ limitDate:%p", mode, before, limit);
#endif
	arp=[NSAutoreleasePool new];
#if 0
	NSLog(@"_checkPerformersAndTimersForMode:%@ count=%d", mode, count);
#endif
	_current_mode = mode;
	for(loop = 0, i=0; loop < count; loop++)
		{ // check for performers to fire
			_NSRunLoopPerformer *item;
			if(i >= [_performers count])
				break;	// firing some performer may re-enter this runloop and/or cancel some others
			item = [_performers objectAtIndex: i];
			if([item->modes containsObject:mode])
				{ // here we have untimed performers only - timed performers will be triggered by timer
					[item retain];
					[_performers removeObjectAtIndex:i];	// remove before firing - it may add a new one to the end of the array
					[item fire];
					[item release];
				}
			else									// inc cntr only if obj is not
				i++;								// removed else we will run off
		}										// the end of the array
	
	// FIXME: timers must be able to fire multiple times until beforeDate!
	
	if((timers = NSMapGet(_mode_2_timers, mode)))									
		{ // process all timers for this mode - we must be careful, since firing timers may add/remove timers and recursively enter the same runloop
			i = [timers count];
#if 0
			NSLog(@"timers=%@", timers);
#endif
			while(i-- > 0)
				{ // process backwards because we might remove the timer (or add new ones at the end)
					NSTimer *timer;
					if(i >= [timers count])
						continue;	// someone has modified our timers array... This can happen if a fire method re-enters this runloop and itself processes invalidated timers
					timer = [timers objectAtIndex:i];
#if 0
					NSLog(@"%d: check timer to fire %p: %@ forMode:%@", i, timer, timer, mode);
#endif
#if 0
					NSLog(@"retainCount=%d", [timer retainCount]);
#endif
					[timer retain];	// note: we may reenter this run-loop through -fire - where the timer may already be invalid; the inner run-loop will remove the timer from the array
					if(timer->_is_valid)
						{ // valid timer (may be left over with negative interval from firing while we did run in a different mode or did have too much to do)
#if 0
							NSLog(@"timeFromNow = %lf", [[timer fireDate] timeIntervalSinceNow]); 
#endif
							if([[timer fireDate] timeIntervalSinceNow] <= 0.0)
								{ // fire!
#if 0
									NSLog(@"fire %p!", timer);
#endif
									/* NOTEs:
									 * this might also fire an attached timed performer object
									 * append new timers etc.
									 * and even re-enter this run-loop!
									 * will update the fireDate for repeating timers
									 */
									
									// FIXME: if the fire method re-enters this runloop, it may invalidate
									// and remove timers we have not yet processed here!
									// So we better should start over with our index i and check it against [timers count]
									
									[timer fire];
#if 0
									NSLog(@"fire %p done.", timer);
									NSLog(@"retainCount=%d", [timer retainCount]);
#endif
									[NSNotificationQueue _runLoopASAP];
								}
						}
					if(!timer->_is_valid)
						{ // now invalid after firing (i.e. this is not a repeating timer or was invalidated)
#if 0
							NSLog(@"%d[%d] remove %@", i, [timers count], timer);
#endif
							[timers removeObjectIdenticalTo:timer];
						}
					[timer release];	// this should finally dealloc an invalid timer (and a timed performer) if it is the last mode we have checked
				}
			// second loop to determine the limit date of the first non-fired timer
			i = [timers count];
#if 0
			NSLog(@"timers=%@", timers);
#endif
			while(i-- > 0)
				{
				NSTimer *min_timer = [timers objectAtIndex:i];
#if 0
				NSLog(@"%d: check timer for limit %p: %@ forMode:%@", i, min_timer, min_timer, mode);
#endif
				if(min_timer->_is_valid)
					{
#if 0
					NSLog(@"timeFromNow = %lf", [[min_timer fireDate] timeIntervalSinceNow]); 
#endif
					NSDate *fire=[min_timer fireDate];	// get (new) fire date
#if 0
					NSLog(@"new fire date %@", fire);
#endif
					if([fire compare:limitDate] == NSOrderedAscending)
						limitDate=fire;	// timer with earlier trigger date has been found
					}
				}
		}
	
	if(before && [limitDate compare:before] == NSOrderedAscending)
		{
#if 0
		NSLog(@"reduce before %@ to limit date %@", before, limitDate);
#endif
		before = limitDate;	// don't wait longer than until the limit date
		}

#if FIXME
	// we also should timeout immediately (i.e. poll only once) if we have any pending idle notifications
	if([NSNotificationQueue _runLoopMore])			// Detect if the NSRunLoop has idle notifications
		{
		timeout.tv_sec = 0;
		timeout.tv_usec = 0;
		select_timeout = &timeout;
		}
#endif
	
	if(!before || (ti = [before timeIntervalSinceNow]) <= 0.0)		// Determine time to wait and
		{															// set SELECT_TIMEOUT.	Don't
			timeout.tv_sec = 0;											// wait if no limit date or it lies in the past. i.e.		
			timeout.tv_usec = 0;										// call select() once with 0 timeout effectively polling inputs
			select_timeout = &timeout;
#if 0
			NSLog(@"_runLoopForMode:%@ beforeDate:%@ - don't wait", mode, before);
#endif
    	}
	else if (ti < LONG_MAX)
		{ // Wait until the LIMIT_DATE.
#if 0
			NSLog(@"NSRunLoop accept input %g seconds from now %f", [before timeIntervalSinceReferenceDate], ti);
#endif
			timeout.tv_sec = ti;
			timeout.tv_usec = (ti - timeout.tv_sec) * 1000000.0;
			select_timeout = &timeout;
		}
	else
		{ // Wait very long (beyond precision), i.e. forever
#if 0
			NSLog(@"NSRunLoop accept input waiting forever");
#endif
			select_timeout = NULL;
		}
	
	FD_ZERO (&read_fds);						// Initialize the set of FDS
	FD_ZERO (&write_fds);						// we'll pass to select()
	
	if((watchers = NSMapGet(_mode_2_inputwatchers, mode)))
		{										// Do the pre-listening set-up
			int	i=[watchers count];					// for the file descriptors of
			// this mode.
			while(i-- > 0)
				{
				NSObject *watcher = [watchers objectAtIndex:i];
				int fd=[watcher _readFileDescriptor];
#if 0
				NSLog(@"watch fd=%d for input", fd);
#endif
				if(fd >= 0 && fd < FD_SETSIZE)
					{
					FD_SET(fd, &read_fds);
					NSMapInsert(rfd_2_object, (void*)fd, watcher);
					num_inputs++;
					}
				}
		}
	if((watchers = NSMapGet(_mode_2_outputwatchers, mode)))
		{										// Do the pre-listening set-up
			int	i=[watchers count];					// for the file descriptors of
			// this mode.
			while(i-- > 0)
				{
				NSObject *watcher = [watchers objectAtIndex:i];
				int fd=[watcher _writeFileDescriptor];
#if 0
				NSLog(@"watch fd=%d for output", fd);
#endif
				if(fd >= 0 && fd < FD_SETSIZE)
					{
					FD_SET(fd, &write_fds);
					NSMapInsert(wfd_2_object, (void*)fd, watcher);
					num_inputs++;
					}
				}
		}
	
	if(num_inputs == 0)
		{
		_current_mode = saved_mode;
		[arp release];
		return NO;	// don't wait - we have no watchers
		}
	
	// CHECKME: should we introduce separate watchers for exceptions?
	
	exception_fds = read_fds;			// the file descriptors in _FDS.
	
	// FIXME: we must only select until the next timer fires and loop until we have reached the before-date - or any input watcher has data to process
	
	select_return = select(FD_SETSIZE, &read_fds, &write_fds, &exception_fds, select_timeout);
#if 0
	NSLog(@"NSRunLoop select returned %d", select_return);
#endif
	anyInput=NO;
	if(select_return < 0)
		{
		if(errno == EINTR)	// a signal was caught - handle like Idle Mode
			select_return = 0;
		else	// Some kind of exceptional condition has occurred
			{
			perror("NSRunLoop acceptInputForMode:beforeDate: during select()");
			abort();
			}
		}

	if(select_return == 0)
		{
		[NSNotificationQueue _runLoopIdle];			// dispatch pending notifications if we timeout (incl. task terminated)
#if 0
			{
			extern void __NSPrintAllocationCount(void);
			__NSPrintAllocationCount();
			}
#endif
		}
	else 
		{ // inspect all file descriptors where select() says they are ready, notify the respective object for each fd that is ready.
			for (fd_index = 0; fd_index < FD_SETSIZE; fd_index++)
				{
				if (FD_ISSET (fd_index, &write_fds))
					{
					NSObject *w = NSMapGet(wfd_2_object, (void*)fd_index);
					NSAssert(w, NSInternalInconsistencyException);
#if 0
					NSLog(@"_writeFileDescriptorReady: %@", w);
#endif
					[w _writeFileDescriptorReady];	// notify
					anyInput=YES;
					}
				
				if (FD_ISSET (fd_index, &read_fds))
					{
					NSObject *w = NSMapGet(rfd_2_object, (void*)fd_index);
					// FIXME: is it possible that some other handler or _runLoopASAP has removed this watcher while we did wait/select?
					NSAssert(w, NSInternalInconsistencyException);
#if 0
					NSLog(@"_readFileDescriptorReady: %@", w);
#endif
					[w _readFileDescriptorReady];	// notify
					anyInput=YES;
					}
				}
		}
	
	NSResetMapTable (rfd_2_object);					// Clean up before return.
	NSResetMapTable (wfd_2_object);
	[NSNotificationQueue _runLoopASAP];	// run any pending notifications (similar to 'performSelector:withObject:afterDelay:0.0')
#if 0
	NSLog(@"acceptInput done");
#endif
	_current_mode = saved_mode;	// restore
	if(limit)
		{
		[limitDate retain];	// move to outer arp
		[arp release];		
		*limit=limitDate;
		[limitDate autorelease];
		}
	else
		[arp release];
	return anyInput;
}

- (NSDate *) limitDateForMode:(NSString *)mode
{  // determine the earliest timeout of all timers in this mode to end a following accept loop
	NSDate *limit=nil;
	[self _runLoopForMode:mode beforeDate:nil limitDate:&limit];	// run once, non-blocking, return limit date
	return limit;
}

- (void) acceptInputForMode:(NSString *) mode beforeDate:(NSDate *) limit_date
{
	[self runMode:mode beforeDate:limit_date];	// same except ignoring the result
}

- (BOOL) runMode:(NSString *) mode beforeDate:(NSDate *) limit_date
{ // block until limit_date or input becomes available - triggers timers (repeatedly)
#if 0
	NSLog(@"runMode:%@ beforeDate:%@", mode, limit_date);
#endif
	// should run once if we have any timers (?)
	if([((NSArray *)NSMapGet(_mode_2_inputwatchers, mode)) count]+[((NSArray *)NSMapGet(_mode_2_outputwatchers, mode)) count] == 0)
		{
#if 0
		NSLog(@"runMode:%@ beforeDate:%@ - no watchers for this mode!", mode, limit_date);
#endif
		return NO;	// we have no watchers for this mode
		}
	do
		{
		if([self _runLoopForMode:mode beforeDate:limit_date limitDate:NULL])
			break;	// any input was processed -> exit early
		}
	while([limit_date timeIntervalSinceNow] > 0.0);	// run and fire timers multiple times if needed until limit date
	return YES;	// any input was processed or timeout reached
}

- (void) runUntilDate:(NSDate *) limit_date
{ // run default run loop mode until date (and return earlier only in case of errors)
	do
		{
		if(![self runMode:NSDefaultRunLoopMode beforeDate:limit_date])
			return;	// failed to run at all
		}
	while([limit_date timeIntervalSinceNow] > 0.0);	// run until limit date
}

- (void) run				{ [self runUntilDate:[NSDate distantFuture]]; }
- (NSString*) currentMode	{ return _current_mode; }	// nil when !running
- (void) configureAsServer	{ return; }
- (NSMutableArray*) _timedPerformers			{ return _timedPerformers; }

- (void) cancelPerformSelectorsWithTarget:(id)target;
{
	int i = [_performers count];
	[target retain];
	while(i-- > 0)
		{
		_NSRunLoopPerformer *item = [_performers objectAtIndex:i];		
		if ([item matchesTarget:target])
			{
			[item invalidate];
			[_performers removeObjectAtIndex:i];
			}
		}
	[target release];
}

- (void) cancelPerformSelector:(SEL)aSelector
						target:target
					  argument:argument
{
	int i = [_performers count];
	[target retain];
	[argument retain];
	while(i-- > 0)
		{
		_NSRunLoopPerformer *item = [_performers objectAtIndex:i];
		if ([item matchesSelector:aSelector target:target argument:argument])
			{
			[item invalidate];
			[_performers removeObjectAtIndex:i];
			}
		}
	[argument release];
	[target release];
}

- (void) performSelector:(SEL)aSelector
				  target:target
				argument:argument
				   order:(unsigned int)order
				   modes:(NSArray*)modes
{
	_NSRunLoopPerformer *item;
	int i, count = [_performers count];
	item = [[_NSRunLoopPerformer alloc] initWithSelector: aSelector
												  target: target
												argument: argument
												   order: order
												   modes: modes];
	
	if (count == 0)									// Add new item to list - 
		[_performers addObject:item];				// reverse ordering
	else
		{
		for (i = 0; i < count; i++)
			{
			if ([[_performers objectAtIndex:i] order] <= order)
				{
				[_performers insertObject:item atIndex:i];
				break;
				}
			}
		if (i == count)
			[_performers addObject:item];
		}
	[item release];	// should have been added or inserted
}

- (void) _addInputWatcher:(id) watcher forMode:(NSString *) mode;
{ // each observer should be added only once for each fd/mode - but this implementation takes care that it still works
	NSMutableArray *watchers = NSMapGet(_mode_2_inputwatchers, mode);
	NSAssert(mode != nil, @"trying to add input watcher for nil mode");
#if 0
	NSLog(@"_addInputWatcher:%@ forMode:%@", watcher, mode);
#endif
	if(!watchers)
		{ // first for this mode
			watchers = [NSMutableArray new];
			NSMapInsert(_mode_2_inputwatchers, mode, watchers);
			[watchers release];
		}
	[watchers addObject:watcher];
#if 0
	NSLog(@"watchers=%@", watchers);
#endif
}

- (void) _removeInputWatcher:(id) watcher forMode:(NSString *) mode;
{
	NSMutableArray *watchers = NSMapGet(_mode_2_inputwatchers, mode);
	NSAssert(mode != nil, @"trying to remove input watcher for nil mode");
#if 0
	NSLog(@"_removeInputWatcher:%@ forMode:%@", watcher, mode);
#endif
	if(watchers)
		{ // remove first one only!
			unsigned int idx=[watchers indexOfObjectIdenticalTo:watcher];
			if(idx != NSNotFound)
				[watchers removeObjectAtIndex:idx];	// remove only one instance!
		}
#if 0
	NSLog(@"watchers=%@", watchers);
#endif
}

- (void) _addOutputWatcher:(id) watcher forMode:(NSString *) mode;
{ // each observer should be added only once for each fd/mode
	NSMutableArray *watchers = NSMapGet(_mode_2_outputwatchers, mode);
	if(!watchers)
		{ // first for this mode
			watchers = [NSMutableArray new];
			NSMapInsert (_mode_2_outputwatchers, mode, watchers);
			[watchers release];
		}
	[watchers addObject:watcher];
}

- (void) _removeOutputWatcher:(id) watcher forMode:(NSString *) mode;
{
	NSMutableArray *watchers = NSMapGet(_mode_2_outputwatchers, mode);
#if 0
	NSLog(@"_removeOutputWatcher:%@ forMode:%@", watcher, mode);
#endif
	if(watchers)
		{ // remove first one only!
			unsigned int idx=[watchers indexOfObjectIdenticalTo:watcher];
			if(idx != NSNotFound)
				[watchers removeObjectAtIndex:idx];	// remove only one instance!
		}
}

- (void) _removeWatcher:(id) watcher;
{ // remove from all modes as input and as output watchers
	NSEnumerator *e;
	NSString *mode;
	e=[NSAllMapTableKeys(_mode_2_inputwatchers) objectEnumerator];
	while((mode=[e nextObject]))
		[(NSMutableArray *) NSMapGet(_mode_2_inputwatchers, mode) removeObjectIdenticalTo:watcher];		// removes all occurrences
	e=[NSAllMapTableKeys(_mode_2_outputwatchers) objectEnumerator];
	while((mode=[e nextObject]))
		[(NSMutableArray *) NSMapGet(_mode_2_outputwatchers, mode) removeObjectIdenticalTo:watcher];	// removes all occurrences
}

+ (void) _removeWatcher:(id) watcher
{
	// FIXME: remove from all runloops
	[__mainRunLoop _removeWatcher:watcher];
}

- (void) removePort:(NSPort *)aPort forMode:(NSString *)mode;
{ // we do this indirectly
	[aPort removeFromRunLoop:self forMode:mode];
}

- (void) addPort:(NSPort *)aPort forMode:(NSString *)mode;
{ // add default callbacks (if present)
	[aPort scheduleInRunLoop:self forMode:mode];
}

@end  /* NSRunLoop */


//*****************************************************************************
//
// 		NSObject (TimedPerformers) 
//
//*****************************************************************************

@implementation NSObject (TimedPerformers)

+ (void) cancelPreviousPerformRequestsWithTarget:(id) target;
{
	NSMutableArray *array = [[NSRunLoop currentRunLoop] _timedPerformers];
	int i=[array count];
#if 0
	NSLog(@"cancel target %@ for timed performers %@", target, array);
#endif
	//	[target retain];
	while(i-- > 0)
		{
		_NSRunLoopPerformer *o = [array objectAtIndex:i];
		if([o matchesTarget:target])
			{
#if 0
			NSLog(@"cancelled all for %@", target);
#endif
			[o invalidate];
			[array removeObjectAtIndex:i];	// this will not yet release the performer since we are the retained target of the timer
			}
		}
	//	[target release];
}

+ (void) cancelPreviousPerformRequestsWithTarget:(id)target
										selector:(SEL)aSelector
										  object:(id)arg
{
	NSMutableArray *array = [[NSRunLoop currentRunLoop] _timedPerformers];
	int i=[array count];
	
	//	[target retain];
	//	[arg retain];
	while(i-- > 0)
		{
		_NSRunLoopPerformer *o = [array objectAtIndex:i];
		if([o matchesSelector:aSelector target:target argument:arg])
			{
#if 0
			NSLog(@"cancelled %@", NSStringFromSelector(aSelector));
#endif
			[o invalidate];
			[array removeObjectAtIndex:i];
			}
		}
	//	[arg release];
	//	[target release];
}

- (void) performSelector:(SEL)aSelector
	      	  withObject:(id)argument
	      	  afterDelay:(NSTimeInterval)seconds
{
	NSMutableArray *array = [[NSRunLoop currentRunLoop] _timedPerformers];
	_NSRunLoopPerformer *item;
#if 0
	NSLog(@"%@: %lf", NSStringFromSelector(_cmd), seconds);
#endif
	item = [[_NSRunLoopPerformer alloc] initWithSelector: aSelector
												  target: self
												argument: argument
												   order: 0
												   modes: nil];
	[array addObject: item];	// 1st retain
	[item setTimer: [NSTimer scheduledTimerWithTimeInterval: seconds
													 target: item	// we will be a 2nd time retained by the timer - and not vice versa
												   selector: @selector(fire)
												   userInfo: nil
													repeats: NO]];
	[item release];
#if 0
	NSLog(@"%@ retainCount=%d", item, [item retainCount]);
#endif
}

- (void) performSelector:(SEL)aSelector
			  withObject:(id)argument
			  afterDelay:(NSTimeInterval)seconds
				 inModes:(NSArray*)modes
{
	int i, count;
	if ((modes != nil) && ((count = [modes count]) > 0))	// HNS
		{
		NSRunLoop *loop = [NSRunLoop currentRunLoop];
		NSMutableArray *array = [loop _timedPerformers];
		_NSRunLoopPerformer *item;
		NSTimer *timer;
		
		item = [[_NSRunLoopPerformer alloc] initWithSelector: aSelector
													  target: self
													argument: argument
													   order: 0
													   modes: nil];
		[array addObject: item];	// first retain
		timer = [NSTimer timerWithTimeInterval: seconds
										target: item	// second retain
									  selector: @selector(fire)
									  userInfo: nil
									   repeats: NO];
		[item setTimer: timer];
		[item release];
		// schedule timer in specified modes
		for (i = 0; i < count; i++)
			[loop addTimer: timer forMode: [modes objectAtIndex: i]];
		}
}

@end /* NSObject (TimedPerformers) */
