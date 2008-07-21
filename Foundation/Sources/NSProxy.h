/* 
   NSProxy.h

   Abstract class of objects that act as stand-ins for other objects

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1997

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSProxy
#define _mySTEP_H_NSProxy

#import <Foundation/NSObject.h>

@class NSDictionary;

@interface NSProxy <NSObject>	// is a root class
{
@public
    Class isa;
@private
    unsigned int _retain_count;
}

+ (id) alloc;
+ (id) allocWithZone:(NSZone *) zone;
+ (Class) class;
+ (BOOL) respondsToSelector:(SEL) aSelector;

- (void) dealloc;
- (NSString *) description;
- (void) forwardInvocation:(NSInvocation *) anInvocation;
- (void) finalize;
- (NSMethodSignature *) methodSignatureForSelector:(SEL) aSelector;

@end

#endif /* _mySTEP_H_NSProxy */
