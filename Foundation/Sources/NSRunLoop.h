/* 
   NSRunLoop.h

   Interface of object for waiting on several input sources.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	March 1996

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSRunLoop
#define _mySTEP_H_NSRunLoop

#import <Foundation/NSMapTable.h>
#import <Foundation/NSDate.h>

@class NSTimer;
@class NSDate;
@class NSPort;
@class NSMutableArray;

extern NSString *NSDefaultRunLoopMode;							// Mode strings
extern NSString *NSRunLoopCommonModes;
// NSConnectionReplyMode defined in Foundation/NSConnection.h
// NSModalPanelRunLoopMode defined in AppKit/NSApplication.h
// NSEventTrackingRunLoopMode defined in AppKit/NSApplication.h

@interface NSRunLoop : NSObject
{
@private 
	id _current_mode;
	NSMapTable *_mode_2_timers;
	NSMapTable *_mode_2_inputwatchers;
	NSMapTable *_mode_2_outputwatchers;
	NSMutableArray *_performers;
	NSMutableArray *_timedPerformers;
	NSMapTable *rfd_2_object;
	NSMapTable *wfd_2_object;
}

+ (NSRunLoop *) currentRunLoop;
+ (NSRunLoop *) mainRunLoop;

- (void) acceptInputForMode:(NSString *) mode beforeDate:(NSDate *) date;
- (void) addPort:(NSPort *) port forMode:(NSString *) mode;
- (void) addTimer:(NSTimer *) timer forMode:(NSString *) mode;
- (void) cancelPerformSelectorsWithTarget:(id) target;
- (void) cancelPerformSelector:(SEL) aSelector
						target:(id) target
					  argument:(id) argument;
- (void) configureAsServer; // deprecated
- (NSString *) currentMode;
// - (CFRunLoopRef) getCFRunLoop;	// we don't have CF
- (NSDate *) limitDateForMode:(NSString *) mode;
- (void) performSelector:(SEL) aSelector
				  target:(id) target
				argument:(id) argument
				   order:(NSUInteger) order
				   modes:(NSArray *) modes;
- (void) removePort:(NSPort *) port forMode:(NSString *) mode;
- (void) run;
- (BOOL) runMode:(NSString *) mode beforeDate:(NSDate *) date;
- (void) runUntilDate:(NSDate *) limit_date;

@end


@interface NSObject (TimedPerformers)

+ (void) cancelPreviousPerformRequestsWithTarget:(id) aTarget;
+ (void) cancelPreviousPerformRequestsWithTarget:(id) obj
										selector:(SEL) s
										object:(id) arg;

- (void) performSelector:(SEL) s
			  withObject:(id) arg
			  afterDelay:(NSTimeInterval) seconds;
- (void) performSelector:(SEL) aSelector
			  withObject:(id) argument
			  afterDelay:(NSTimeInterval) seconds
			  inModes:(NSArray *) modes;
@end

#endif /*_mySTEP_H_NSRunLoop */
