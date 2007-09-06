/* 
   NSInvocation.h

   Object rendering of an Obj-C message (action).

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSInvocation
#define _mySTEP_H_NSInvocation

#import <Foundation/NSMethodSignature.h>

enum _NSObjCValueType
{
    NSObjCNoType		= 0,
    NSObjCVoidType		= 'v',
    NSObjCCharType		= 'c',
    NSObjCShortType		= 's',
    NSObjCLongType		= 'l',
    NSObjCLonglongType	= 'q',
    NSObjCFloatType		= 'f',
    NSObjCDoubleType	= 'd',
    NSObjCBoolType		= 'B',
    NSObjCSelectorType	= ':',
    NSObjCObjectType	= '@',
    NSObjCStructType	= '{',
    NSObjCPointerType	= '^',
    NSObjCStringType	= '*',
    NSObjCArrayType		= '[',
    NSObjCUnionType		= '(',
    NSObjCBitfield		= 'b'
};

typedef struct
{
    enum _NSObjCValueType type;
    union {
    	char charValue;
		short shortValue;
		long longValue;
		long long longlongValue;
		float floatValue;
		double doubleValue;
		BOOL boolValue;
		SEL selectorValue;
		id objectValue;
		void *pointerValue;
		void *structLocation;
		char *cStringLocation;
    } value;
} NSObjCValue;

@interface NSInvocation : NSObject
{
	NSMethodSignature *_sig;
	arglist_t _argframe;
	void *_retval;
	struct NSArgumentInfo *_info;	// FIXME: should be moved to NSMethodSignature!
	int _numArgs;
	// FIXME: use bitfields
	BOOL _argframeismalloc;		// _argframe has been malloc'ed locally
	BOOL _retvalismalloc;		// _retval has been malloc'ed locally
	BOOL _argsRetained;			// (id) arguments have been retained
	BOOL _validReturn;			// setReturn or invoke has been called
}

+ (NSInvocation*) invocationWithMethodSignature:(NSMethodSignature*)signature;

- (BOOL) argumentsRetained;									// Manage arguments
- (void) getArgument:(void *)buffer atIndex:(int)index;		// Access message
- (void) getReturnValue:(void *)buffer;						// elements
- (void) invoke;											// Dispatch
- (void) invokeWithTarget:(id)target;
- (NSMethodSignature *) methodSignature;					// Signature
- (void) retainArguments;
- (SEL) selector;
- (void) setArgument:(void *)buffer atIndex:(int)index;
- (void) setReturnValue:(void *)buffer;
- (void) setSelector:(SEL)selector;
- (void) setTarget:(id)target;
- (id) target;

@end

#endif /* _mySTEP_H_NSInvocation */
