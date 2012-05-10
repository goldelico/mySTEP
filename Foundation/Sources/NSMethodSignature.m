/* 
   NSMethodSignature.m

   Implementation of NSMethodSignature for mySTEP
   This file encapsulates all CPU specific specialities (e.g. how the __builtin_apply() frame is organized, how registers are handled etc.)

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
 * we should use more support functions from libobjc...
 
 ARM-Stackframe conventions are described in section 5.3-5.5, 7.2 of http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042b/IHI0042B_aapcs.pdf
 Unfortunately, this does not cover Objective-C conventions (which appear to be different from C/C++!)

 * libffi documentation: https://github.com/atgreen/libffi/blob/master/doc/libffi.info
 
*/ 

#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "NSPrivate.h"
#ifndef __APPLE__
#include <ffi.h>
#endif

struct NSArgumentInfo
	{ // internal Info about layout of arguments. Extended from the original OpenStep version - no longer available in OSX
		const char *type;				// type (pointer to first type character)
		int offset;						// can be negative (!)
		unsigned size;					// size 
		unsigned align;					// alignment
		unsigned qual;					// qualifier (oneway, byref, bycopy, in, inout, out)
		unsigned index;					// argument index (to decode return=0, self=1, and _cmd=2)
		BOOL isReg;						// is passed in a register (+)
		BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
		BOOL floatAsDouble;				// its a float value that is passed as double
		// ffi type
	};

/*
 * define architecture specific values and fixes
 */

#if defined(__APPLE__)	// compile on MacOS X (no need to run)

#define REGISTERSAVEAREASIZE		4*sizeof(long)
#define STRUCTRETURNPOINTERLENGTH	sizeof(void *)
#define FLOATASDOUBLE				YES
#define POINTERADJUST				12
#define MINALIGN					sizeof(long)
#define STRUCTBYREF					YES

#elif defined(__arm__)	// for ARM
#if defined(__ARM_EABI__)

#define REGISTERSAVEAREASIZE		4*sizeof(long)
#define STRUCTRETURNPOINTERLENGTH	sizeof(void *)
#define FLOATASDOUBLE				YES
#define POINTERADJUST				12
#define MINALIGN					sizeof(long)
#define STRUCTBYREF					YES

#else // not EABI

#define REGISTERSAVEAREASIZE		4*sizeof(long)
#define STRUCTRETURNPOINTERLENGTH	sizeof(void *)
#define FLOATASDOUBLE				YES
#define POINTERADJUST				12
#define MINALIGN					sizeof(long)
#define STRUCTBYREF					YES

#endif	// ARM_EABI
#elif defined(__mips__)	// for MIPS

#define REGISTERSAVEAREASIZE		4*sizeof(long)
#define STRUCTRETURNPOINTERLENGTH	sizeof(void *)
#define FLOATASDOUBLE				YES
#define POINTERADJUST				0
#define MINALIGN					sizeof(long)
#define STRUCTBYREF					YES

#elif defined(i386)	// for Intel

#define REGISTERSAVEAREASIZE		4*sizeof(long)
#define STRUCTRETURNPOINTERLENGTH	sizeof(void *)
#define FLOATASDOUBLE				YES
#define POINTERADJUST				0
#define MINALIGN					sizeof(long)
#define STRUCTBYREF					YES

#elif defined(__x86_64__)
#elif defined(__ppc__)
#elif defined(__ppc64__)
#elif defined(__m68k__)

#else

#error "unknown architecture"

#endif

#define ISBIGENDIAN					(NSHostByteOrder()==NS_BigEndian)

// merge this into NSMethodSignature

static const char *mframe_next_arg(const char *typePtr, struct NSArgumentInfo *info)
{ // returns NULL on error
	NSCAssert(info, @"missing NSArgumentInfo");
	// FIXME: NO, we should keep the flags+type but remove the offset
	info->qual = 0;	// start with no qualifier
	info->isReg = NO;
	info->floatAsDouble = NO;
	// Skip past any type qualifiers,
	for(; YES; typePtr++)
		{
		switch (*typePtr)
			{
			case _C_CONST:  info->qual |= _F_CONST; continue;
			case _C_IN:     info->qual |= _F_IN; continue;
			case _C_INOUT:  info->qual |= _F_INOUT; continue;
			case _C_OUT:    info->qual |= _F_OUT; continue;
			case _C_BYCOPY: info->qual |= _F_BYCOPY; info->qual &= ~_F_BYREF; continue;
#ifdef _C_BYREF
			case _C_BYREF:  info->qual |= _F_BYREF; info->qual &= ~_F_BYCOPY; continue;
#endif
			case _C_ONEWAY: info->qual |= _F_ONEWAY; continue;
			default: break;
			}
		break;	// break loop
		}
	info->type = typePtr;
	
	if(STRUCTBYREF)
		info->byRef = (*typePtr == _C_STRUCT_B || *typePtr == _C_UNION_B || *typePtr == _C_ARY_B);
	else
		info->byRef = NO;
	
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
			if(FLOATASDOUBLE)
				{
				// I guess we should set align/size differently...
				info->floatAsDouble = YES;
				info->size = sizeof(double);
				info->align = __alignof__(double);
				}
			else
				{
				info->size = sizeof(float);
				info->align = __alignof__(float);
				}
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
				struct NSArgumentInfo local;
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
				struct NSArgumentInfo local;
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
				struct NSArgumentInfo local;
				//	struct { int x; double y; } fooalign;
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
					if (!typePtr)
						return typePtr;						// error
					
					acc_size = ROUND(acc_size, local.align);
					acc_size += local.size;
					acc_align = MAX(local.align, __alignof__(fooalign));
					}
				// Continue accumulating 
				while (*typePtr != _C_STRUCT_E)			// structure size.
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (!typePtr)
						return typePtr;						// error
					
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
				struct NSArgumentInfo local;
				int	max_size = 0;
				int	max_align = 0;
				
				while (*typePtr != _C_UNION_E)			// Skip "<name>=" stuff.
					if (*typePtr++ == '=')
						break;
				
				while (*typePtr != _C_UNION_E)
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (!typePtr)
						return typePtr;						// error
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
			return NULL;	// unknown
		}
	
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
		}
	
	// FIXME: to be more compatible, we should return a string incl. qualifier but without offset part!
	// i.e. Vv, R@, O@ etc.

	return typePtr;
}

@implementation NSMethodSignature

#define NEED_INFO() if(info == NULL) [self _methodInfo]

- (void) _methodInfo
{ // collect all information from methodTypes in a platform independent way
	if(info == NULL) 
		{ // calculate method info
			const char *types = methodTypes;
			int i=0;
			int allocArgs=5;
			argFrameLength=STRUCTRETURNPOINTERLENGTH;
#if 1
			NSLog(@"methodInfo create for types %s", methodTypes);
#endif
			info = objc_malloc(sizeof(struct NSArgumentInfo) * allocArgs);
			while(*types)
				{ // process all types
#if 1
					NSLog(@"%d: %s", i, types);
#endif
					if(i >= allocArgs)
						allocArgs+=5, info = objc_realloc(info, sizeof(struct NSArgumentInfo) * allocArgs);	// we need more space
					types = mframe_next_arg(types, &info[i]);
					if(!types)
						break;	// some error
					info[i].index=i-1;
					if((info[i].qual & _F_INOUT) == 0)
						{ // add default qualifiers
							if(i == 0)
								info[i].qual |= _F_OUT;		// default to "bycopy out" for the return value
							else if(*info[i].type == _C_PTR || *info[i].type == _C_ATOM || *info[i].type == _C_CHARPTR)
								info[i].qual |= _F_INOUT;	// pointers default to "bycopy in/out"
							else
								info[i].qual |= _F_IN;		// others default to "bycopy in"
						}
					if(info[i].align < MINALIGN)
						info[i].align=MINALIGN;
					info[i].offset = argFrameLength;
					if(!info[i].isReg)	// value is on stack - counts for frameLength
						argFrameLength += ((info[i].size+info[i].align-1)/info[i].align)*info[i].align;
					i++;
				}
			numArgs = i-1;	// return type does not count
#if 1
			NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
    	}
	// FIXME: is this a general problem and not only ARM? Fixed in gcc 3.x and later? How to handle e.g. (double) as arguments in a protocol?
	if(!info[numArgs].isReg && info[numArgs].offset == 0)
		{ // fix bug in gcc 2.95.3 signature for @protocol (last argument is described as @0 instead of e.g. @+16)
#if 1
			NSLog(@"fix ARM @protocol()");
#endif
			info[numArgs].offset=info[numArgs-1].offset-20;
		}
#if 1
	{
	int i;
	for(i=0; i<=numArgs; i++)
		NSLog(@"%d: type=%s size=%d align=%d isreg=%d offset=%d qual=%x byRef=%d fltDbl=%d",
			  info[i].index, info[i].type, info[i].size, info[i].align,
			  info[i].isReg, info[i].offset, info[i].qual,
			  info[i].byRef, info[i].floatAsDouble);
	}
#endif
}

// standard methods

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

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't replace by another proxy, i.e. encode bycopy

// NOTE: this encoding is not platform independent! And not compatible to OSX!

- (void) encodeWithCoder:(NSCoder*)aCoder
{ // encode type string - NOTE: it can't encode _makeOneWay
	[aCoder encodeValueOfObjCType:@encode(char *) at:&methodTypes];
}

- (id) initWithCoder:(NSCoder*)aCoder
{ // initialize from received type string
	char *type;
	[aCoder decodeValueOfObjCType:@encode(char *) at:&type];
	return [self _initWithObjCTypes:type];
}

+ (NSMethodSignature *) signatureWithObjCTypes:(const char*) t;
{ // now officially made public (10.5) - but not documented
	return [[[NSMethodSignature alloc] _initWithObjCTypes:t] autorelease];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ %s", [super description], methodTypes];
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

- (const char *) _methodType	{ return methodTypes; }
- (NSString *) _type	{ return [NSString stringWithUTF8String:methodTypes]; }

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
	char *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	if(index == -1)
			{ // copy return value to buffer
				if(info[0].size > 0)
					memcpy(buffer, _argframe, info[0].size);
				return info[0].type;
			}
	addr=(char *)_argframe;
	if(!info[index+1].isReg)
		addr=*(char **)addr;	// indirect through pointer
	addr+=info[index+1].offset;
#if 1
	NSLog(@"_getArgument[%d] offset=%d addr=%p isReg=%d byref=%d double=%d", index, info[index+1].offset, addr, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble);
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
	char *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	if(index == -1)
			{ // copy buffer to return value
				if(info[0].size > 0)
					memcpy(_argframe, buffer, info[0].size);
				return;
			}
	addr=(char *)_argframe;
	if(!info[index+1].isReg)
		addr=*(char **)addr;	// indirect through pointer
	addr+=info[index+1].offset;
#if 1
	NSLog(@"_setArgument[%d] offset=%d addr=%p isReg=%d byref=%d double=%d", index, info[index+1].offset, addr, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble);
#endif
	if(info[index+1].byRef)
		memcpy(*(void**)addr, buffer, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(double*)addr = *(float*)buffer;
	else
		memcpy(addr, buffer, info[index+1].size);
}

- (arglist_t) _allocArgFrame:(arglist_t) frame
{ // (re)allocate stack frame for ARM CPU
	if(!frame)
		{ // make a single buffer that is large enough to hold the _builtin_apply() block + space for frameLength arguments
		int part1 = sizeof(void *) + STRUCTRETURNPOINTERLENGTH + REGISTERSAVEAREASIZE;	// first part
		void *args;
		NEED_INFO();	// get valid argFrameLength
		frame=(arglist_t) objc_calloc(part1 + argFrameLength, sizeof(char));
		args=(char *) frame + part1;
#if 1
		NSLog(@"allocated frame=%p args=%p framelength=%d", frame, args, argFrameLength);
#endif
		((void **)frame)[0]=args;		// insert argument pointer (points to part 2 of the buffer)
		}
	else if(POINTERADJUST > 0)
		((char **)frame)[0]+=POINTERADJUST;
	return frame;
}

#define RETURN(CODE, TYPE) CODE: { \
		inline TYPE retframe##CODE(void *imp, arglist_t frame, int stack) \
			{ \
			NSLog(@"retframe##CODE called (imp=%p frame=%p stack=%d)", imp, frame, stack); \
			retval_t retval=__builtin_apply(imp, frame, stack); \
			NSLog(@"__builtin_apply called"); \
			__builtin_return(retval); \
			}; \
		NSLog(@"call retframe##CODE"); \
		*(TYPE *) retbuf = retframe##CODE(imp, frame, stack); \
		NSLog(@"call retframe##CODE"); \
		break; \
		}

#if 0
- (void) test
{
	NSLog(@"test");
}
#endif

static BOOL wrapped_builtin_apply(void *imp, arglist_t frame, int stack, void *retbuf, struct NSArgumentInfo *info)
{ // wrap call because it fails if __builtin_apply is called directly from within a Objective-C method
//	imp=[NSMethodSignature instanceMethodForSelector:@selector(test)];
#ifndef __APPLE__
	typedef struct {
		char val[1 /*info[0].size */];
	} block;
#if 1
	NSLog(@"type %s imp=%p frame=%p stack=%d retbuf=%p", info[0].type, imp, frame, stack, retbuf);
#endif
	switch(*info[0].type) {
		case RETURN(_C_ID, id);
		case RETURN(_C_CLASS, Class);
		case RETURN(_C_SEL, SEL);
		case RETURN(_C_CHR, char);
		case RETURN(_C_UCHR, unsigned short);
		case RETURN(_C_SHT, char);
		case RETURN(_C_USHT, unsigned short);
		case RETURN(_C_INT, int);
		case RETURN(_C_UINT, unsigned int);
		case RETURN(_C_LNG, long);
		case RETURN(_C_ULNG, unsigned long);
		case RETURN(_C_LNG_LNG, long long);
		case RETURN(_C_ULNG_LNG, unsigned long long);
		case RETURN(_C_FLT, float);
		case RETURN(_C_DBL, double);
		case RETURN(_C_PTR, char *);
		case RETURN(_C_ATOM, char *);
		case RETURN(_C_CHARPTR, char *);
			// FIXME: needs special handling for variable size
		case RETURN(_C_ARY_B, block);
		case RETURN(_C_STRUCT_B, block);
		case RETURN(_C_UNION_B, block);
		case _C_VOID:
			break;
		default:
			NSLog(@"unprocessed type %s for _call", info[0].type);
			return NO;	// unknown type
	}
#endif
	return YES;	// ok
}

- (BOOL) _call:(void *) imp frame:(arglist_t) _argframe retbuf:(void *) retbuf;
{ // preload registers from ARM stack frame and call implementation
	NEED_INFO();	// make sure that argFrameLength is defined
#if 1
	NSLog(@"doing __builtin_apply(%08x, %08x, %d)", imp, _argframe, (argFrameLength+3)&~3);
#endif
	if(POINTERADJUST)
		((void **)_argframe)[1] = ((void **)_argframe)[2];		// copy target/self value to the register frame
	return wrapped_builtin_apply(imp, _argframe, (argFrameLength+3)&~3, retbuf, &info[0]);	// here, we really invoke the implementation	
}

@end  /* NSMethodSignature (mySTEP) */
