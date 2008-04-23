/* 
   NSLock.h

   Definitions for locking protocol and classes

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   NSConditionLock: aligned with 10.5 by Fabian Spillner 22.04.2008
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSLock
#define _mySTEP_H_NSLock

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

@class NSThread;

@protocol NSLocking										// NSLocking protocol

- (void) lock;
- (void) unlock;

@end


@interface NSLock : NSObject  <NSLocking>				// simple lock class
{
	NSString *_name;
	objc_mutex_t _mutex;
}

- (BOOL) lockBeforeDate:(NSDate *)limit;
- (NSString *) name;
- (void) setName:(NSString *) name;
- (BOOL) tryLock;

@end


@interface NSConditionLock : NSObject  <NSLocking>
{
	NSString *_name;
	objc_mutex_t _mutex;								// Allows locking and 
	objc_condition_t _condition;						// unlocking to be based 
	NSInteger _conditionValue;								// upon a condition
}

- (NSInteger) condition;									// condition of the lock
- (id) initWithCondition:(NSInteger) value;
- (BOOL) lockBeforeDate:(NSDate *) limit;			// Acquiring the lock with 
- (void) lockWhenCondition:(NSInteger) value;				// Acquire / release lock
- (BOOL) lockWhenCondition:(NSInteger) condition			// a date condition
				beforeDate:(NSDate *) limit;
- (NSString *) name;
- (void) setName:(NSString *) name;
- (BOOL) tryLock;
- (BOOL) tryLockWhenCondition:(NSInteger) value;
- (void) unlockWithCondition:(NSInteger) value;

@end


@interface NSRecursiveLock : NSObject  <NSLocking>
{								// Allows the lock to be recursively acquired
	NSString *_name;
	objc_mutex_t _mutex;		// by the same thread.  If the same thread
}								// locks the mutex (n) times then that same
								// thread must also unlock it (n) times before
								// another thread can acquire the lock.
- (BOOL) lockBeforeDate:(NSDate *)limit;
- (NSString *) name;
- (void) setName:(NSString *) name;
- (BOOL) tryLock;	

@end

#endif /* _mySTEP_H_NSLock */
