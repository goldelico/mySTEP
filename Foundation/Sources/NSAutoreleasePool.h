/* 
   NSAutoreleasePool.h

   Interface to NSAutoreleasePool

   Copyright (C) 1995, 1996, 1997 Free Software Foundation, Inc.

   Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	07. April 2008 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSAutoreleasePool
#define _mySTEP_H_NSAutoreleasePool

#import <Foundation/NSObject.h>


@interface NSAutoreleasePool : NSObject 
{ // For re-setting the current pool when we are dealloc'ed. 
	NSAutoreleasePool *_parent;
								// This pointer to our child pool is  necessary 
								// for co-existing with exceptions. 
	NSAutoreleasePool *_child;
								// A collection of the objects to be released
	struct autorelease_array_list *_released;
	struct autorelease_array_list *_released_head;

	unsigned _released_count;	// number of objects autoreleased in this pool
}

+ (void) addObject:(id) anObject;
+ (void) showPools;	/* not implemented */
- (void) addObject:(id) anObject;
- (void) drain;

@end

#endif /* _mySTEP_H_NSAutoreleasePool */
