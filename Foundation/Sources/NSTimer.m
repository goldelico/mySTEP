/* 
   NSTimer.m

   Implementation of NSTimer

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.
   
   Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	March 1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSTimer.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSInvocation.h>


@implementation NSTimer

+ (NSTimer*) timerWithTimeInterval:(NSTimeInterval)seconds
						invocation:(NSInvocation *)invocation
						repeats:(BOOL)f
{
	NSTimer *t = [self alloc];
	if(t)
		{
		t->_interval = (seconds <= 0.0) ? 0.01 : seconds;
		t->_fireDate = [[NSDate alloc] initWithTimeIntervalSinceNow: seconds];
		t->_is_valid = YES;
		t->_target = [invocation retain];
		t->_repeats = f;
		}
	return [t autorelease];
}

+ (NSTimer*) timerWithTimeInterval:(NSTimeInterval)seconds
							target:(id)object
						  selector:(SEL)selector
						  userInfo:(id)info
						   repeats:(BOOL)f
{
	return [[[self alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:seconds]
								  interval:seconds
									target:object
								  selector:selector
								  userInfo:info
								   repeats:f] autorelease];
}

+ (NSTimer*) scheduledTimerWithTimeInterval:(NSTimeInterval)ti
								 invocation:(NSInvocation *)invocation
									repeats:(BOOL)f
{
	NSTimer *t = [self timerWithTimeInterval:ti invocation:invocation repeats:f];
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
	return t;
}

+ (NSTimer*) scheduledTimerWithTimeInterval:(NSTimeInterval)ti
									 target:(id)object
									 selector:(SEL)selector
									 userInfo:(id)info
									 repeats:(BOOL)f
{
	NSTimer *t = [self timerWithTimeInterval: ti
									  target: object
									selector: selector
									userInfo: info
									 repeats: f];
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
	return t;
}

- (id) initWithFireDate:(NSDate *) date
			   interval:(NSTimeInterval)seconds
				 target:(id)object
			   selector:(SEL)selector
			   userInfo:(id)info
				repeats:(BOOL)f
{
#if 0
	if(f)
		NSLog(@"NSTimer initWithFireDate:%@ interval:%.0lf selector:%@", date, seconds, NSStringFromSelector(selector));
	else
		NSLog(@"NSTimer initWithFireDate:%@ selector:%@", date, NSStringFromSelector(selector));
#endif
	if((self=[super init]))
		{		
		_interval = (seconds <= 0.0) ? 0.01 : seconds;
		_fireDate = [date retain];
		_is_valid = YES;
		_selector = selector;
		_target = [object retain];	// retaining is correct according to description of -invalidate
		_info = [info retain];
		_repeats = f;
		}
	return self;
}

- (void) dealloc
{
#if 0
	NSLog(@"%p dealloc %@", self, self);
#endif
	[_target release];
	[_fireDate release];
	[_info release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ fireDate:%@ interval:%.0lf%@%@",
				NSStringFromClass([self class]),
				_fireDate,
				_interval,
				_repeats?@" repeats":@"",
				_is_valid?@"":@" invalid"];
}

- (void) fire
{
#if 0
	NSLog(@"fire %@", self);
#endif
	if(!_repeats)
		_is_valid = NO;	// has fired once
	else if(_is_valid)
		{ // is repeating
		NSTimeInterval ti = [_fireDate timeIntervalSinceReferenceDate];
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		while(ti < now)		// we have lost one or more intervals
			ti += _interval;	// forward until next multiple of timeslot
#if 0
		NSLog(@"fire 1 [%d] %@", [_fireDate retainCount], _fireDate);
#endif
		[_fireDate release];
#if 0
		NSLog(@"fire 2");
#endif
		_fireDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate: ti];
#if 0
		NSLog(@"fire 3 [%d] %@", [_fireDate retainCount], _fireDate);
#endif
		}
	if(_selector)
		[_target performSelector:_selector withObject:self];
	else
		[_target invoke];	
#if 0
	NSLog(@"fired");
#endif
}

- (void) invalidate
{
#if 0
	NSLog(@"invalidate %@", self);
#endif
	_is_valid = NO;
}

- (BOOL) isValid						{ return _is_valid; }
- (NSDate *) fireDate					{ return _fireDate; }
- (NSTimeInterval) timeInterval			{ return _interval; }
- (id) userInfo							{ return _info; }

- (void) setFireDate:(NSDate *)date;
{
	ASSIGN(_fireDate, date);
}

- (int) compare:(NSTimer*)anotherTimer
{
    return [_fireDate compare: anotherTimer->_fireDate];
}

@end
