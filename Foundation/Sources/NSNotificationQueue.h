/* 
   NSNotificationQueue.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSNotificationQueue
#define _mySTEP_H_NSNotificationQueue

#import <Foundation/NSNotification.h>

@class NSMutableArray;

typedef enum {
    NSPostWhenIdle,	
    NSPostASAP,		
    NSPostNow		
} NSPostingStyle;

typedef enum {
    NSNotificationNoCoalescing		 = 0,
    NSNotificationCoalescingOnName	 = 1,
    NSNotificationCoalescingOnSender = 2,
} NSNotificationCoalescing;


@interface NSNotificationQueue : NSObject
{
    NSNotificationCenter *_center;
    struct _NSNotificationQueueList *_asapQueue;
    struct _NSNotificationQueueList *_idleQueue;
}

+ (NSNotificationQueue *) defaultQueue;

- (void) dequeueNotificationsMatching:(NSNotification *) notification
						 coalesceMask:(UInteger) coalesceMask;
- (void) enqueueNotification:(NSNotification *) notification
				postingStyle:(NSPostingStyle) postingStyle;
- (void) enqueueNotification:(NSNotification *) notification
				postingStyle:(NSPostingStyle) postingStyle
				coalesceMask:(UInteger) coalesceMask
					forModes:(NSArray *) modes;
- (id) initWithNotificationCenter:(NSNotificationCenter *) notificationCenter;

@end

#endif /* _mySTEP_H_NSNotificationQueue */
