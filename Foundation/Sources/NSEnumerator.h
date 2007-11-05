/* 
   NSEnumerator.h

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:	Felipe A. Rodriguez <far@pcmagic.net>
   Date: 	Jan 2000

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSEnumerator
#define _mySTEP_H_NSEnumerator

#import <Foundation/NSObject.h>

@interface NSEnumerator : NSObject

- (NSArray *) allObjects;
- (id) nextObject;

@end

@protocol NSFastEnumeration

typedef struct
{
    unsigned long state;
    id *itemsPtr;
    unsigned long *mutationsPtr;
    unsigned long extra[5];
} NSFastEnumerationState;

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *) state
								   objects:(id *) stackbuf
									 count:(NSUInteger) len;

@end

#endif /* _mySTEP_H_NSEnumerator */
