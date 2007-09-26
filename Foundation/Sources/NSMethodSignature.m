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

// processor specific constants
// defined in +initialize

static BOOL isBigEndian;
static int registerSaveAreaSize;			// how much room do we need for that (may be 0)
static int structReturnPointerLength;		// how much room do we need for that (may be 0)

// merge this into NSMethodSignature

const char *mframe_next_arg(const char *typePtr, NSArgumentInfo *info)
{
	BOOL flag;								// information extracting details.
	
	NSAssert(info, @"missing NSArgumentInfo");
	
	// Skip past any type qualifiers,
	flag = YES;								// return them if caller wants them
	info->qual = 0;	// start with no qualifier
	info->floatAsDouble = NO;
	while(flag)
		{
		switch (*typePtr)
			{
			case _C_CONST:  info->qual |= _F_CONST; break;
			case _C_IN:     info->qual |= _F_IN; break;
			case _C_INOUT:  info->qual |= _F_INOUT; break;
			case _C_OUT:    info->qual |= _F_OUT; break;
			case _C_BYCOPY: info->qual |= _F_BYCOPY; info->qual &= ~_F_BYREF; break;
#ifdef _C_BYREF
			case _C_BYREF:  info->qual |= _F_BYREF; info->qual &= ~_F_BYCOPY; break;
#endif
			case _C_ONEWAY: info->qual |= _F_ONEWAY; break;
			default: flag = NO; continue;
			}
		if(flag)
			typePtr++;
		}
	// NO, we should keep the flags+type but remove the offset
	info->type = typePtr;
	
#if MFRAME_STRUCT_BYREF
	info->byRef = (*typePtr == _C_STRUCT_B || *typePtr == _C_UNION_B || *typePtr == _C_ARY_B);
#else
	info->byRef = NO;
#endif
	
	switch (*typePtr++)				// Scan for size and alignment information.
		{
		case _C_ID:
			info->size = sizeof(id);
			info->align = __alignof__(id);
			break;
			
		case _C_CLASS:
			info->size = sizeof(Class);
			info->align = __alignof__(Class);
			break;
			
		case _C_SEL:
			info->size = sizeof(SEL);
			info->align = __alignof__(SEL);
			break;
			
		case _C_CHR:
			info->size = sizeof(char);
			info->align = __alignof__(char);
			break;
			
		case _C_UCHR:
			info->size = sizeof(unsigned char);
			info->align = __alignof__(unsigned char);
			break;
			
		case _C_SHT:
			info->size = sizeof(short);
			info->align = __alignof__(short);
			break;
			
		case _C_USHT:
			info->size = sizeof(unsigned short);
			info->align = __alignof__(unsigned short);
			break;
			
		case _C_INT:
			info->size = sizeof(int);
			info->align = __alignof__(int);
			break;
			
		case _C_UINT:
			info->size = sizeof(unsigned int);
			info->align = __alignof__(unsigned int);
			break;
			
		case _C_LNG:
			info->size = sizeof(long);
			info->align = __alignof__(long);
			break;
			
		case _C_ULNG:
			info->size = sizeof(unsigned long);
			info->align = __alignof__(unsigned long);
			break;
			
		case _C_LNG_LNG:
			info->size = sizeof(long long);
			info->align = __alignof__(long long);
			break;
			
		case _C_ULNG_LNG:
			info->size = sizeof(unsigned long long);
			info->align = __alignof__(unsigned long long);
			break;
			
		case _C_FLT:
#if MFRAME_FLT_IN_FRAME_AS_DBL
			// I guess we should set align/size differently...
			info->floatAsDouble = YES;
			info->size = sizeof(double);
			info->align = __alignof__(double);
#else
			info->size = sizeof(float);
			info->align = __alignof__(float);
#endif
			break;
			
		case _C_DBL:
			info->size = sizeof(double);
			info->align = __alignof__(double);
			break;
			
		case _C_PTR:
			info->size = sizeof(char*);
			info->align = __alignof__(char*);
			if (*typePtr == '?')
				typePtr++;
			else
				{ // recursively
				NSArgumentInfo local;
				typePtr = mframe_next_arg(typePtr, &local);
				info->isReg = local.isReg;
				info->offset = local.offset;
				}
			break;
			
		case _C_ATOM:
		case _C_CHARPTR:
			info->size = sizeof(char*);
			info->align = __alignof__(char*);
			break;
			
		case _C_ARY_B:
			{
				NSArgumentInfo local;
				int	length = atoi(typePtr);
				
				while (isdigit(*typePtr))
					typePtr++;
				
				typePtr = mframe_next_arg(typePtr, &local);
				info->size = length * ROUND(local.size, local.align);
				info->align = local.align;
				typePtr++;								// Skip end-of-array
			}
			break; 
			
		case _C_STRUCT_B:
			{
				//			struct { int x; double y; } fooalign;
				NSArgumentInfo local;
				struct { unsigned char x; } fooalign;
				int acc_size = 0;
				int acc_align = __alignof__(fooalign);
				
				while (*typePtr != _C_STRUCT_E)			// Skip "<name>=" stuff.
					if (*typePtr++ == '=')
						break;
				// Base structure alignment 
				if (*typePtr != _C_STRUCT_E)			// on first element.
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (typePtr == 0)
						return 0;						// error
					
					acc_size = ROUND(acc_size, local.align);
					acc_size += local.size;
					acc_align = MAX(local.align, __alignof__(fooalign));
					}
				// Continue accumulating 
				while (*typePtr != _C_STRUCT_E)			// structure size.
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (typePtr == 0)
						return 0;						// error
					
					acc_size = ROUND(acc_size, local.align);
					acc_size += local.size;
					}
				info->size = acc_size;
				info->align = acc_align;
				//printf("_C_STRUCT_B  size %d align %d\n",info->size,info->align);
				typePtr++;								// Skip end-of-struct
			}
			break;
			
		case _C_UNION_B:
			{
				NSArgumentInfo local;
				int	max_size = 0;
				int	max_align = 0;
				
				while (*typePtr != _C_UNION_E)			// Skip "<name>=" stuff.
					if (*typePtr++ == '=')
						break;
				
				while (*typePtr != _C_UNION_E)
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (typePtr == 0)
						return 0;						// error
					max_size = MAX(max_size, local.size);
					max_align = MAX(max_align, local.align);
					}
				info->size = max_size;
				info->align = max_align;
				typePtr++;								// Skip end-of-union
			}
			break;
			
		case _C_VOID:
			info->size = 0;
			info->align = __alignof__(char*);
			break;
			
		default:
			return 0;
		}
	
	if(*typePtr == 0)
		return NULL;								// error
													// If we had a pointer argument, we will already have 
													// gathered (and skipped past) the argframe offset 
													// info - so we don't need to (and can't) do it here.
	if(info->type[0] != _C_PTR || info->type[1] == '?')
		{
		if(*typePtr == '+')	 
			{ // register offset
			typePtr++;
			info->isReg = YES;
			}
		else
			{ // stack offset
			info->isReg = NO;
			}
		info->offset = 0;
		while(isdigit(*typePtr))
			info->offset = 10 * info->offset + (*typePtr++ - '0');
//		if(!info->isReg)
//			info->offset += 12;	// FIXME: is this needed for all CPUs or ARM only?
		// should also be based on last + offset (i.e. highest register offset - 8 ?)
		}
	
	// FIXME: to be more compatible, we should return a string incl. qualifier but without offset part!

	return typePtr;
}

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
	registerSaveAreaSize=4*sizeof(long);		// for ARM processor
	structReturnPointerLength=sizeof(void *);	// if we have one
	isBigEndian=NSHostByteOrder()==NS_BigEndian;
#if 1
	NSLog(@"NSMethodSignature: processor is %@", isBigEndian?@"Big Endian":@"Little Endian");
#endif
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

#if 1	// still needed to be public because it is used in NSInvocation

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
		argFrameLength=0;
#if 0
		NSLog(@"methodInfo create");
#endif
		// should we add a struct return pointer
		info = objc_malloc(sizeof(NSArgumentInfo) * allocArgs);
		for(i = 0; *types != 0; i++)
			{ // process all types
#if 1
			NSLog(@"%d: %s", i, types);
#endif
			if(i >= allocArgs)
				allocArgs+=5, info = objc_realloc(info, sizeof(NSArgumentInfo) * allocArgs);	// we need more space
			types = mframe_next_arg(types, &info[i]);
			info[i].index=i;
			if((info[i].qual & _F_INOUT) == 0)
				{ // add default qualifiers
				if(i == 0)
					info[i].qual |= _F_OUT;		// default to "bycopy out" for the return value
				else if(*info[0].type == _C_PTR || *info[0].type == _C_ATOM || *info[0].type == _C_CHARPTR)
					info[i].qual |= _F_INOUT;	// default to "bycopy in/out"
				else
					info[i].qual |= _F_IN;		// default to "bycopy in"
				}
#if OLD
			// check for useless combinations
			// i.e. "in" for return value
			// and "byref char *"
#if defined(Linux_ARM)
			/// manipulate offsets - should be done by constants/rules identified in +initialize
			if(i == 0 && (*info[0].type == _C_STRUCT_B || *info[0].type == _C_UNION_B || *info[0].type == _C_ARY_B))
				{ // denote struct return by virtual first argument
			//	argFrameLength+=structReturnPointerLength;	// enlarge
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
#endif // OLD
			if(isBigEndian && info[i].align < 4)
				{ // adjust offset
				info[i].offset+=4-info[i].align;	// point to the correct byte
				info[i].align=4;					// ARM pushes all arguments as long words
				}
			// CHECKME!
			if(i>0 && info[i].isReg && info[0].byRef)
				info[i].offset += structReturnPointerLength;	// adapt offset because we have a virtual first argument
#if 1
			NSLog(@"%d: type=%s size=%d align=%d isreg=%d offset=%d qual=%x byRef=%d fltDbl=%d",
		           info[i].index, info[i].type, info[i].size, info[i].align,
		           info[i].isReg, info[i].offset, info[i].qual,
				   info[i].byRef, info[i].floatAsDouble);
#endif
			if(!info[i].isReg)	// value is on stack - counts for frameLength
//			if(i > 2)	// value is on stack - counts in frameLength
				argFrameLength += ((info[i].size+info[i].align-1)/info[i].align)*info[i].align;
#if OLD
			if(i > 2)
				{ // don't include self and _cmd
				if(info[i].byRef)
					argFrameLength += sizeof(void *);
				else
					{ // handle alignment here
					argFrameLength += info[i].align*((info[i].align-1+info[i].size)/info[i].align);
					}
				}
#endif
			}
		numArgs = i-1;	// 0 i.e. return type does not count
#if 1
		NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
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
	void *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	addr = (info[index+1].isReg?((char *)_argframe):(*(char **)_argframe)) + info[index+1].offset;
#if 0
	NSLog(@"_getArgument[%d] offset=%u addr=%p", index, info[index+1].offset, addr);
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
	void *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	addr = (info[index+1].isReg?((char *)_argframe):(*(char **)_argframe)) + info[index+1].offset;
#if 1
	NSLog(@"_setArgument[%d] offset=%u addr=%p", index, info[index+1].offset, addr);
#endif
	if(info[index+1].byRef)
		memcpy(*(void**)addr, buffer, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(double*)addr = *(float*)buffer;
	else
		memcpy(addr, buffer, info[index+1].size);
}

- (arglist_t) _allocArgFrame:(arglist_t) frame
{ // (re)allocate stack frame
	if(!frame)
		{ // make a single buffer that is large enough to hold the _builtin_apply() block + space for frameLength arguments
		int part1 = sizeof(void *) + structReturnPointerLength + registerSaveAreaSize;	// first part
		void *args;
		frame=(arglist_t) objc_calloc(part1 + argFrameLength, sizeof(char));
		args=(char *) frame + part1;
#if 1
		NSLog(@"allocated frame=%p args=%p framelength=%d", frame, args, argFrameLength);
#endif
		((void **)frame)[0]=args;		// insert argument pointer (points to part 2 of the buffer)
		}
	else
		((char **)frame)[0]+=12;	// on ARM - forward:: returns the full stack while __builtin_apply needs only the extra arguments
	return frame;
}

- (void) _prepareFrameForCall:(arglist_t) _argframe;
{ // preload registers from ARM stack frame
#ifndef __APPLE__
	((void **)_argframe)[1] = ((void **)_argframe)[2];		// copy target/self value to the register frame
//	((void **)_argframe)[3] = (*(void ***)_argframe)[0];	// copy first 3 stack args to the register frame
//	((void **)_argframe)[4] = (*(void ***)_argframe)[1];
//	((void **)_argframe)[5] = (*(void ***)_argframe)[2];
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
