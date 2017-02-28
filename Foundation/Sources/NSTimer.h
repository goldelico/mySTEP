/* 
   NSTimer.h

   Interface to NSTimer

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSTimer
#define _mySTEP_H_NSTimer

#import <Foundation/NSDate.h>

@class NSInvocation;

@interface NSTimer : NSObject
{
	NSTimeInterval _interval;
	NSTimeInterval _tolerance;
	id _info;
	id _target;
	SEL _selector;
	unsigned _repeats:2;
	unsigned _timer_filler:6;
@public
	NSDate *_fireDate;
	BOOL _is_valid;
}

+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval) ti
								  invocation:(NSInvocation *) invocation
									 repeats:(BOOL) f;
+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval) ti
									  target:(id) object
									selector:(SEL) selector
									userInfo:(id) info
									 repeats:(BOOL) f;
+ (NSTimer *) timerWithTimeInterval:(NSTimeInterval) ti
						 invocation:(NSInvocation *) invocation
							repeats:(BOOL) f;
+ (NSTimer *) timerWithTimeInterval:(NSTimeInterval) ti
							 target:(id) object
						   selector:(SEL) selector
						   userInfo:(id) info
							repeats:(BOOL) f;

- (void) fire;
- (NSDate *) fireDate;
- (id) initWithFireDate:(NSDate *) date
			   interval:(NSTimeInterval) seconds
				 target:(id) target
			   selector:(SEL) aSelector
			   userInfo:(id) userInfo
				repeats:(BOOL) repeats;
- (void) invalidate;
- (BOOL) isValid;
- (void) setFireDate:(NSDate *) date;
- (void) setTolerance:(NSTimeInterval) tolerance;
- (NSTimeInterval) timeInterval;
- (NSTimeInterval) tolerance;
- (id) userInfo;

@end

#endif /* _mySTEP_H_NSTimer */
