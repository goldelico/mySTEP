/* 
   NSMethodSignature.h

   Interface for NSMethodSignature

   Copyright (C) 1995, 1998 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	1998
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, May 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
 
   Refer to http://gcc.gnu.org/onlinedocs/gcc-4.0.2/gcc/Type-encoding.html#Type-encoding how gcc encodes types

   on Cocoa this appears to reside in CoreFoundation.framework
*/ 

#ifndef _mySTEP_H_NSMethodSignature
#define _mySTEP_H_NSMethodSignature

#import <Foundation/NSObject.h>

@interface NSMethodSignature : NSObject
{
    const char *methodTypes;		// ObjCTypes
    unsigned argFrameLength;
    unsigned numArgs;
    struct NSArgumentInfo *info;	// forward reference
	void *internal1;	// used to reference ffi_cif
	void *internal2;	// used to reference ffi_type
	char _r[16];
}

+ (NSMethodSignature *) signatureWithObjCTypes:(const char *) types;

- (NSUInteger) frameLength;
- (const char *) getArgumentTypeAtIndex:(NSUInteger) index;
- (BOOL) isOneway;
- (NSUInteger) methodReturnLength;
- (const char *) methodReturnType;
- (NSUInteger) numberOfArguments;

@end

#endif /* _mySTEP_H_NSMethodSignature */
