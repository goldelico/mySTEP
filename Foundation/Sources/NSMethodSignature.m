/* 
   NSMethodSignature.m

   Implementation of NSMethodSignature for mySTEP

   Copyright (C) 1994, 1995, 1996, 1998 Free Software Foundation, Inc.
   
   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	August 1994
   Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1998
   Rewrite: Nikolaus Schaller <hns@computer.org> - remove as much of mframe as possible and only rely on gcc/libobjc to run on ARM processor
   Date:    November 2003, Jan 2006-2007

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.

 Some notes&observations by H. N. Schaller:
 * the argframe passed when forward:: is the one created by the libobjc functions __objc_x_forward(id, SEL, ...)
 * x can be word, double, block
 * that argframe structure can/will be different on ARM from the argframe within a called method with known number of arguments!
 * therefore, the method signature might be different for implemented and non-implemented methods - the latter being
   based on (id, SEL, ...)
 * so we need to create a different structure to call any existing/nonexisting method by __builtin_apply()
 * libobjc seems to use #define OBJC_MAX_STRUCT_BY_VALUE 1 (runtime-info.h) meaning that a char[1] only struct is returned in a register
 * should finally merge mframe.m into this source
 * use more support functions from libobjc

*/ 

#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "NSPrivate.h"

#include "mframe.h"	// this should be the only location to use outside mframe.m and NSInvocation.h

#define AUTO_DETECT 0

#if AUTO_DETECT	// to identify calling conventions automatically - EXPERIMENTAL
@interface NSMethodSignature (Autodetect)
+ (id) __call_me:(id) s :(SEL) cmd : (id) arg;
@end

static SEL sel=@selector(__call_me::);

static BOOL passStructByPointer;			// passes structs by pointer
static BOOL returnStructByVirtualArgument;	// returns structs by virtual argument pointer

#endif

static int registerSaveAreaSize;			// how much room do we need for that (may be 0)
static int structReturnPointerLength;		// how much room do we need for that (may be 0)

@implementation NSMethodSignature

+ (void) initialize
{
//	NSLog(@"This is [NSMethodSignature initialize]\n");
#if AUTO_DETECT
	[NSMethodSignature __call_me:self :sel :self];
	passStructByPointer=NO;
	returnStructByVirtualArgument=YES;
#else
#if defined(Linux_ARM)
// for ARM_Linux
	registerSaveAreaSize=10*sizeof(long);		// just to be safe
	structReturnPointerLength=sizeof(void *);
#endif
#endif
}

// standard methods

#define NEED_INFO() if(info == NULL) [self _methodInfo]

- (unsigned) frameLength
{
	NEED_INFO();
	return argFrameLength;
}

- (const char *) getArgumentTypeAtIndex:(unsigned)index
{
    if(index >= numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index too high."];
	NEED_INFO();
    return info[index+1].type;
}

- (BOOL) isOneway
{
	NEED_INFO();
	return (info[0].qual & _F_ONEWAY) ? YES : NO;
}

- (unsigned) methodReturnLength
{
	NEED_INFO();
	return info[0].size;
}

- (const char*) methodReturnType
{
	NEED_INFO();
    return info[0].type;
}

- (unsigned) numberOfArguments
{
	NEED_INFO();
	return numArgs;
}

- (void) dealloc
{
    if(methodTypes)
		objc_free((void*) methodTypes);
    if(info)
		objc_free((void*) info);
    [super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)aCoder	{ NIMP; }
- (id) initWithCoder:(NSCoder*)aCoder		{ NIMP; return nil; }

// private methods

+ (NSMethodSignature *) signatureWithObjCTypes:(const char*) t;
{ // although private, we know that this method exists in Cocoa
	return [[[NSMethodSignature alloc] _initWithObjCTypes:t] autorelease];
}

- (id) _initWithObjCTypes:(const char*) t;
{
	if((self=[super init]))
		{
		methodTypes=objc_malloc(strlen(t)+1);
		strcpy(((char *) methodTypes), t);	// save unchanged
#if 0
		NSLog(@"NSMethodSignature -> %s", t);
#endif
		}
	return self;
}

#if 1	// still needed to be public because it is heavily used in NSInvocation

//
// FIXME: this is not yet platform independent
// and contains a lot of hacks for the ARM architecture
//

- (NSArgumentInfo *) _methodInfo
{ // collect all information from methodTypes in a platform independent way
    if(info == NULL) 
		{ // calculate method info
		const char *types = methodTypes;
		int i;
		int allocArgs=5;
#if 0
		NSLog(@"methodInfo create");
#endif
		argFrameLength = sizeof(void *)		// pointer to original stack arguments
			+ registerSaveAreaSize;			// saved registers
//		if(*types == _C_STRUCT_B || *types == _C_UNION_B || *types == _C_ARY_B)
//			argFrameLength+=structReturnPointerLength;
		info = objc_malloc(sizeof(NSArgumentInfo) * allocArgs);
		for(i = 0; *types != 0; i++)
			{ // process all types
#if 0
			NSLog(@"%d: %s", i, types);
#endif
			if(i >= allocArgs)
				allocArgs+=5, info = objc_realloc(info, sizeof(NSArgumentInfo) * allocArgs);	// we need more space
			types = mframe_next_arg(types, &info[i]);
			info[i].index=i;
			if((info[i].qual & _F_INOUT) == 0)
				{ // default qualifiers
				if(i == 0)
					info[i].qual |= _F_OUT;		// default to "bycopy out" for the return value
				else if(*info[0].type == _C_PTR || *info[0].type == _C_ATOM || *info[0].type == _C_CHARPTR)
					info[i].qual |= _F_INOUT;	// default to "bycopy in/out"
				else
					info[i].qual |= _F_IN;		// default to "bycopy in"
				}
			// check for useless combinations
			// i.e. "in" for return value
			// and "byref char *"
#if defined(Linux_ARM)
			/// manipulate offsets - should be done by constants/rules identified in +initialize
			if(i == 0 && (*info[0].type == _C_STRUCT_B || *info[0].type == _C_UNION_B || *info[0].type == _C_ARY_B))
				{ // denote struct return by virtual first argument
				argFrameLength+=structReturnPointerLength;	// enlarge
				info[i].isReg=YES;	// formally handle as a register offset
				info[i].byRef=YES;	// and value is stored by reference
				info[i].offset=2*structReturnPointerLength;	// set offset so we can use argframe_get_arg() properly
				}
			else if(i == 2)
				{ // convert _cmd to stack access
				info[i].offset=0;		// default offset for _cmd is :+12 and real location is just at arg_ptr
				info[i].isReg=NO;		// no longer access as register
				}
			else if(i > 2)
				{ // increment offset
				if(info[i].align < 4)
					info[i].align=4;			// ARM seems to push all arguments as long
				info[i].offset=info[i-1].offset+info[i-1].size;	// behind previous
				info[i].offset=info[i].align*((info[i].align-1+info[i].offset)/info[i].align);
				info[i].isReg=NO;	// no (longer) access as register
				}
#endif
			if(i>0 && info[i].isReg && info[0].byRef)
				info[i].offset += structReturnPointerLength;	// adapt offset because we have a virtual first argument
#if 0
			NSLog(@"%d: type %s size %d align %d offset %d isreg %d qual %d byRef %d fltDbl %d",
		           info[i].index,  info[i].type,  info[i].size,  info[i].align,
		           info[i].offset, info[i].isReg, info[i].qual,
				   info[i].byRef,  info[i].floatAsDouble);
#endif
			if(info[i].byRef)
				argFrameLength += sizeof(void *);
			else
				{ // handle alignment here
				argFrameLength += info[i].align*((info[i].align-1+info[i].size)/info[i].align);
				}
			}
		numArgs = i-1;	// 0 i.e. return type does not count
//		NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
    	}
    return info;
}

#endif

- (const char*) _methodType	{ return methodTypes; }

- (unsigned) _getArgumentLengthAtIndex:(int) index;
{
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	return info[index+1].size;
}

- (unsigned) _getArgumentQualifierAtIndex:(int)index;
{
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	return info[index+1].qual;
}

- (const char *) _getArgument:(void *) buffer fromFrame:(arglist_t) _argframe atIndex:(int) index;
{ // extract argument from frame
 	int offset;
	void *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	offset = info[index+1].offset;
#if WORDS_BIGENDIAN
	if(info[index+1].size < sizeof(int))
		offset += sizeof(int) - info[index+1].size;
#endif
#ifndef __APPLE__
	if(info[index+1].isReg)
		addr = _argframe->arg_regs + offset;
	else
		addr = _argframe->arg_ptr + offset;
#else
	addr = ((char *) _argframe) + offset;
#endif
	if(info[index+1].byRef)
		memcpy(buffer, *(void**)addr, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(float*)buffer = (float)*(double*)addr;
	else
		memcpy(buffer, addr, info[index+1].size);
	return info[index+1].type;
}

- (void) _setArgument:(void *) buffer forFrame:(arglist_t) _argframe atIndex:(int) index;
{
 	int offset;
	void *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	offset = info[index+1].offset;
#if 0
	NSLog(@"_setArgument offset=%u", offset);
#endif
#if WORDS_BIGENDIAN
	if(info[index+1].size < sizeof(int))
		offset += sizeof(int) - info[index+1].size;
#endif
#ifndef __APPLE__
	if(info[index+1].isReg)
		addr = _argframe->arg_regs + offset;
	else
		addr = _argframe->arg_ptr + offset;
#else
	addr = ((char *) _argframe) + offset;
#endif
	if(info[index+1].byRef)
		memcpy(*(void**)addr, buffer, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(double*)addr = *(float*)buffer;
	else
		memcpy(addr, buffer, info[index+1].size);
}

- (void) _prepareFrameForCall:(arglist_t) _argframe;
{ // preload registers for ARM stack frame
#ifndef __APPLE__
	((void **)_argframe)[1] = ((void **)_argframe)[2];		// copy target/self value to the register frame
	((void **)_argframe)[3] = (*(void ***)_argframe)[0];	// copy first 3 stack args to the register frame
	((void **)_argframe)[4] = (*(void ***)_argframe)[1];
	((void **)_argframe)[5] = (*(void ***)_argframe)[2];
#endif
}

#if AUTO_DETECT

+ (id) __call_me:(id) s :(SEL) cmd : (id) arg;
{
	arglist_t argFrame=__builtin_apply_args();
	Method *m;
	const char *type;
//	NSLog(@"This is [NSMethodSignature __call_me::]");
//	NSLog(@"argFrame=%08x", (unsigned) argFrame);
	m=class_get_instance_method(((struct objc_class*) s)->class_pointer, cmd);
//	NSLog(@"m=%08x", (unsigned) m);
	if(m)
		{
		NSLog(@"firstarg=%08x", (unsigned) method_get_first_argument(m, argFrame, &type));
		NSLog(@"nextarg=%08x", (unsigned) method_get_next_argument(argFrame, &type));

// retval_t objc_msg_sendv(id object, SEL op, arglist_t arg_frame)
//{
// Method* m = class_get_instance_method(object->class_pointer, op);
// const char *type;
// *((id*)method_get_first_argument (m, arg_frame, &type)) = object;
// *((SEL*)method_get_next_argument (arg_frame, &type)) = op;
//  return __builtin_apply((apply_t)m->method_imp, arg_frame, method_get_sizeof_arguments (m));
//  }
		}
	return nil;
	}

#endif

@end  /* NSMethodSignature (mySTEP) */
