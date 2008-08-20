/* 
   NSLock.m

   Mutual exclusion locking classes 

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:	1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSLock.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSException.h>

#import "NSPrivate.h"

#define BAD_RECURSIVE_LOCK @"Thread attempted to recursively lock"

// Exceptions
NSString *NSLockException = @"NSLockException";
NSString *NSConditionLockException = @"NSConditionLockException";
NSString *NSRecursiveLockException = @"NSRecursiveLockException";


//*****************************************************************************
//
// 		NSLock		simple lock for protecting critical sections of code 
//
//*****************************************************************************

@implementation NSLock


- (id) init											// Designated initializer
{
	self=[super init];
#ifndef __APPLE__

	if (!self || !(_mutex = objc_mutex_allocate()))			// Alloc mutex from runtime
		return GSError (self, @"NSLock failed to allocate a mutex");
#endif
	return self;
}
											// Ask the runtime to dealloc the
- (void) dealloc							// mutex.  If there are outstanding
{											// locks then it will block.
#ifndef __APPLE__
	if (objc_mutex_deallocate (_mutex) == -1)	
		[NSException raise:NSLockException format:@"NSLock invalid mutex"];
#endif
	[_name release];
	[super dealloc];
}

- (BOOL) tryLock										// Try to acquire the
{														// lock. Does not block
#ifndef __APPLE__
	if ((_mutex)->owner == objc_thread_id())
		[NSException raise:NSLockException format:BAD_RECURSIVE_LOCK];

	if (objc_mutex_trylock (_mutex) == -1)				// Ask the runtime to  	
		return NO;										// acquire a lock on
														// the mutex
#endif
	return YES;
}

- (BOOL) lockBeforeDate:(NSDate *)limit			{ NIMP return NO; }

- (void) lock											// NSLocking protocol
{
#ifndef __APPLE__
	if ((_mutex)->owner == objc_thread_id())
		[NSException raise:NSLockException format:BAD_RECURSIVE_LOCK];
	if (objc_mutex_lock (_mutex) == -1)					// Locking may block
		[NSException raise:NSLockException format:@"NSLock failed to lock mutex"];
#endif
}

- (void) unlock
{
#ifndef __APPLE__
#if 0
	NSLog(@"%@ unlock", self);
#endif
	if (objc_mutex_unlock (_mutex) == -1)
		[NSException raise:NSLockException 
					 format:@"NSLock unlock: failed to unlock mutex"];
#endif
}

- (NSString *) name; { return _name; }
- (void) setName:(NSString *) name; { ASSIGN(_name, name); }

@end /* NSLock */

//*****************************************************************************
//
// 		NSConditionLock 
//
//		Allows locking and unlocking to be based upon an integer condition
//
//*****************************************************************************

@implementation NSConditionLock

- (id) init							{ return [self initWithCondition: 0]; }

- (id) initWithCondition:(int)value					// Designated initializer 
{
	self=[super init];	
	
	_conditionValue = value;
#ifndef __APPLE__

	if (!self || !(_condition = objc_condition_allocate ()))
		return GSError (self, @"NSConditionLock failed to allocate a condition");

	if (!(_mutex = objc_mutex_allocate ()))
		return GSError (self, @"NSConditionLock failed to allocate a mutex");
#endif
	return self;
}

- (void) dealloc
{
#ifndef __APPLE__

	if (objc_condition_deallocate (_condition) == -1)
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock dealloc: invalid condition"];
	if (objc_mutex_deallocate (_mutex) == -1)		// Blocks if mutex locked
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock dealloc: invalid mutex"];
#endif
	[_name release];
	[super dealloc];
}
									// Return the current condition of the lock
- (int) condition				{ return _conditionValue; }

- (void) lockWhenCondition:(int)value
{
#ifndef __APPLE__
	if ((_mutex)->owner == objc_thread_id())
		[NSException raise:NSConditionLockException format:BAD_RECURSIVE_LOCK];

	if (objc_mutex_lock(_mutex) == -1)
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock lockWhenCondition: failed to lock mutex"];
													// Unlocks mutex while we
	while (_conditionValue != value)				// wait on the condition
		if (objc_condition_wait(_condition, _mutex) == -1)
			[NSException raise:NSConditionLockException
						 format:@"NSConditionLock objc_condition_wait failed"];
#endif
}

- (void) unlockWithCondition:(int)value
{
#ifndef __APPLE__
	int depth = objc_mutex_trylock (_mutex);

	if (depth == -1)								// Another thread has lock
		[NSException raise:NSConditionLockException
          format:@"NSConditionLock unlockWithCondition: Tried to unlock someone else's lock"];

	if (depth == 1)									// The lock was not locked
		[NSException raise:NSConditionLockException
				format:@"NSConditionLock unlockWithCondition: Unlock attempted without lock"];

	_conditionValue = value;						// This is a valid unlock 
													// so set the condition and
	if (objc_condition_broadcast(_condition) == -1)	// wake up blocked threads
		[NSException raise:NSConditionLockException
        	format:@"NSConditionLock unlockWithCondition: objc_condition_broadcast failed"];

	if ((objc_mutex_unlock (_mutex) == -1)			// and unlock twice
			|| (objc_mutex_unlock (_mutex) == -1))
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock unlockWithCondition: failed to unlock mutex"];
#endif
}

- (BOOL) tryLock
{
#ifndef __APPLE__
	if ((_mutex)->owner == objc_thread_id())
		[NSException raise:NSConditionLockException format:BAD_RECURSIVE_LOCK];

	return (objc_mutex_trylock(_mutex) == -1) ? NO : YES;
#else
	return NO;
#endif
}

- (BOOL) tryLockWhenCondition:(int)value	// tryLock message will check for 
{											// recursive locks
	if ([self tryLock])						// Can we even get the lock?
		{
		if (_conditionValue == value)		// If we got the lock is it the
			return YES;						// right condition?

		[self unlock];						// Wrong condition so release the
		}									// lock

	return NO;
}
									// Acquiring the lock with a date condition
- (BOOL) lockBeforeDate:(NSDate *)limit			{ NIMP return NO; }
- (BOOL) lockWhenCondition:(int)condition
                beforeDate:(NSDate *)limit		{ NIMP return NO; }

													// NSLocking protocol
- (void) lock
{													// These methods ignore the
#ifndef __APPLE__
	if ((_mutex)->owner == objc_thread_id())		// condition
		[NSException raise:NSConditionLockException format:BAD_RECURSIVE_LOCK];
													// Acquire a lock on mutex
	if (objc_mutex_lock (_mutex) == -1)				// This will block
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock lock: failed to lock mutex"];
#endif
}

- (void) unlock
{													// wake up blocked threads
#ifndef __APPLE__
#if 0
	NSLog(@"%@ unlock", self);
#endif
	if (objc_condition_broadcast(_condition) == -1)
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock unlock: objc_condition_broadcast failed"];

	if (objc_mutex_unlock (_mutex) == -1)			// Release lock on mutex
		[NSException raise:NSConditionLockException
					 format:@"NSConditionLock unlock: failed to unlock mutex"];
#endif
}

- (NSString *) name; { return _name; }
- (void) setName:(NSString *) name; { ASSIGN(_name, name); }

@end /* NSConditionLock */

//*****************************************************************************
//
// 		NSRecursiveLock 
//
//	Allows the lock to be recursively acquired by the same thread.  If the
//	same thread locks the mutex (n) times then that same thread must also
//	unlock it (n) times before another thread acquire the lock.
//
//*****************************************************************************

@implementation NSRecursiveLock

- (id) init											// Designated initializer
{
	self=[super init];
#ifndef __APPLE__
  													// Allocate the mutex
	if (!self || !(_mutex = objc_mutex_allocate()))
		return GSError (self, @"NSRecursiveLock failed to allocate a mutex");
#endif
	return self;
}

- (void) dealloc									// Deallocate the mutex If  
{													// there are outstanding 
#ifndef __APPLE__
	if (objc_mutex_deallocate (_mutex) == -1)		// locks then it will block
		[NSException raise:NSRecursiveLockException
					 format:@"NSRecursiveLock dealloc: invalid mutex"];
#endif
	[_name release];
	[super dealloc];
}

- (BOOL) tryLock									// Try to acquire lock.
{										  			// Does not block
#ifndef __APPLE__
	return (objc_mutex_trylock (_mutex) == -1) ? NO : YES;
#else
	return NO;
#endif
}
													// NSLocking protocol
- (void) lock							
{													// Acquire a lock on mutex
#ifndef __APPLE__
	if (objc_mutex_lock (_mutex) == -1)				// This will block
		[NSException raise:NSRecursiveLockException
					 format:@"NSRecursiveLock lock: failed to lock mutex"];
#endif
}

- (BOOL) lockBeforeDate:(NSDate *)limit		{ NIMP return NO; }

- (void) unlock
{
#ifndef __APPLE__
#if 0
	NSLog(@"%@ unlock", self);
#endif
	if (objc_mutex_unlock (_mutex) == -1)			// Release lock on mutex
		[NSException raise:NSRecursiveLockException
					 format:@"NSRecursiveLock unlock: failed to unlock mutex"];
#endif
}

- (NSString *) name; { return _name; }
- (void) setName:(NSString *) name; { ASSIGN(_name, name); }

@end /* NSRecursiveLock */
