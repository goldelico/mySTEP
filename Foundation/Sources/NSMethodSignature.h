/* 
   NSMethodSignature.h

   Interface for NSMethodSignature

   Copyright (C) 1995, 1998 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	1998
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
 
   Refer to http://gcc.gnu.org/onlinedocs/gcc-4.0.2/gcc/Type-encoding.html#Type-encoding how gcc encodes types

*/ 

#ifndef _mySTEP_H_NSMethodSignature
#define _mySTEP_H_NSMethodSignature

#import <Foundation/NSObject.h>

@interface NSMethodSignature : NSObject
{
    const char *methodTypes;
    unsigned argFrameLength;
    unsigned numArgs;
    struct NSArgumentInfo *info;
}

+ (NSMethodSignature*) signatureWithObjCTypes:(const char*)types;	// create from @encode()

- (unsigned) frameLength;
- (const char *) getArgumentTypeAtIndex:(unsigned) index;
- (BOOL) isOneway;
- (unsigned) methodReturnLength;
- (const char *) methodReturnType;
- (unsigned) numberOfArguments;

@end

#endif /* _mySTEP_H_NSMethodSignature */
