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
 Date:    November 2003, Jan 2006-2007,2011-2012
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 
 Some notes&observations by H. N. Schaller:
 * the argframe passed when forward:: is the one created by the libobjc functions __objc_x_forward(id, SEL, ...)
 * x can be word, double, block
 * that argframe structure can/will be different on ARM from the argframe within a called method with known number of arguments!
 * therefore, the method signature might be different for implemented and non-implemented methods - the latter being based on (id, SEL, ...)
 * so we need to create a different structure to call any existing/nonexisting method by __builtin_apply()
 * libobjc seems to use #define OBJC_MAX_STRUCT_BY_VALUE 1 (runtime-info.h) meaning that a char[1] only struct is returned in a register
 * we should use more support functions from libobjc...
 * libffi documentation: https://github.com/atgreen/libffi/blob/master/doc/libffi.info
 
 */ 

#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "NSPrivate.h"
#ifndef __APPLE__
#include <ffi.h>	// not really used yet (maybe never...)
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

#define ADJUST_STACK					0
#define REGISTER_SAVEAREA_SIZE			4*sizeof(long)
#define STRUCT_RETURN_POINTER_LENGTH	sizeof(void *)
#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define STRUCT_BYREF					YES

#elif defined(__arm__)	// for ARM
#if defined(__ARM_EABI__)

#define ADJUST_STACK					1
#define REGISTER_SAVEAREA_SIZE			4*sizeof(long)
#define STRUCT_RETURN_POINTER_LENGTH	sizeof(void *)
#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define STRUCT_BYREF					YES

#else // not EABI

#define ADJUST_STACK					1
#define REGISTER_SAVEAREA_SIZE			4*sizeof(long)
#define STRUCT_RETURN_POINTER_LENGTH	sizeof(void *)
#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define STRUCT_BYREF					YES

#endif	// ARM_EABI
#elif defined(__mips__)	// for MIPS

#define ADJUST_STACK					0
#define REGISTER_SAVEAREA_SIZE			4*sizeof(long)
#define STRUCT_RETURN_POINTER_LENGTH	sizeof(void *)
#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define STRUCT_BYREF					YES

#elif defined(i386)	// for Intel

#define ADJUST_STACK					0
#define REGISTER_SAVEAREA_SIZE			7*sizeof(long)
#define STRUCT_RETURN_POINTER_LENGTH	0
#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define STRUCT_BYREF					YES

#elif defined(__x86_64__)
#elif defined(__ppc__)
#elif defined(__ppc64__)
#elif defined(__m68k__)

#else

#error "unknown architecture"

#endif

#define ISBIGENDIAN					(NSHostByteOrder()==NS_BigEndian)

// this may be called recursively (structs)

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
		switch (*typePtr) {
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
		break;	// break loop if there was no continue
		}
	info->type = typePtr;
	
	if(STRUCT_BYREF)
		info->byRef = (*typePtr == _C_STRUCT_B || *typePtr == _C_UNION_B || *typePtr == _C_ARY_B);
	else
		info->byRef = NO;
	
	switch (*typePtr++) { // Scan for size and alignment information.
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
			if(FLOAT_AS_DOUBLE)
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
			
		case _C_ARY_B: {
			struct NSArgumentInfo local;
			int	length = atoi(typePtr);
			
			while (isdigit(*typePtr))
				typePtr++;
			
			typePtr = mframe_next_arg(typePtr, &local);
			info->size = length * ROUND(local.size, local.align);
			info->align = local.align;
			typePtr++;								// Skip end-of-array
			break; 
		}
			
		case _C_STRUCT_B: {
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
			break;
		}
			
		case _C_UNION_B: {
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
			break;
		}
			
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

- (unsigned) frameLength
{
	NEED_INFO();
	return argFrameLength;
}

- (const char *) getArgumentTypeAtIndex:(unsigned)index
{
	NEED_INFO();	// make sure numArgs and type is defined
	if(index >= numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index too high."];
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

- (BOOL) isEqual:(id)other
{
	if(other == self)
		return YES;
	if(![super isEqual:other])
		return NO;
	// fixme: strip off offsets if included
	return strcmp([self _methodType], [other _methodType]) == 0;
}

- (NSUInteger) hash;
{
	// checkme
	return [super hash];
}

+ (NSMethodSignature *) signatureWithObjCTypes:(const char*) t;
{ // now officially made public (10.5) - but not documented
	return [[[NSMethodSignature alloc] _initWithObjCTypes:t] autorelease];
}

@end

@implementation NSMethodSignature (NSUndocumented)

- (NSString *) _typeString	{ return [NSString stringWithUTF8String:methodTypes]; }

- (struct NSArgumentInfo *) _argInfo:(unsigned) index
{
	NEED_INFO();	// make sure numArgs and type is defined
	if(index >= numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index too high."];
	return &info[index+1];	
}

- (void *) _frameDescriptor;
{
	NIMP;
	return NULL;
}

@end

@implementation NSMethodSignature (NSPrivate)

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ %s", [super description], methodTypes];
}

- (void) _methodInfo
{ // collect all information from methodTypes in a platform independent way
	if(info == NULL) 
		{ // calculate method info
			const char *types = methodTypes;
			int i=0;
			int allocArgs=5;	// this is usually enough, i.e. self+_cmd+3 args
			argFrameLength=STRUCT_RETURN_POINTER_LENGTH;
#if 0
			NSLog(@"methodInfo create for types %s", methodTypes);
#endif
			info = objc_malloc(sizeof(struct NSArgumentInfo) * allocArgs);
			while(*types)
				{ // process all types
#if 0
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
					if(i == 0)
						info[i].isReg=YES;	// !structReturn
					if(info[i].align < MIN_ALIGN)
						info[i].align=MIN_ALIGN;
					if(!info[i].isReg)
						{ // value is on stack - counts for frameLength
							info[i].offset = argFrameLength;
							argFrameLength += ((info[i].size+info[i].align-1)/info[i].align)*info[i].align;						
						}
					i++;
				}
			numArgs = i-1;	// return type does not count
#if 0
			NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
    	}
#if 0
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

- (id) _initWithObjCTypes:(const char*) t;
{
#if 0
	NSLog(@"_initWithObjCTypes: %s", t);
#endif
	if((self=[super init]))
		{
		methodTypes=objc_malloc(strlen(t)+1);
		// strip off embedded offsets, i.e. convert from gcc to OpenSTEP format?
		strcpy(((char *) methodTypes), t);	// save unchanged
#if 0
		NSLog(@"NSMethodSignature -> %s", methodTypes);
#endif
		}
	return self;
}

- (const char *) _methodType	{ return methodTypes; }

- (unsigned) _getArgumentLengthAtIndex:(int) index;
{
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	return info[index+1].size;
}

- (unsigned) _getArgumentQualifierAtIndex:(int)index;
{
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	return info[index+1].qual;
}

- (const char *) _getArgument:(void *) buffer fromFrame:(arglist_t) _argframe atIndex:(int) index;
{ // extract argument from frame
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
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
#if 0
	NSLog(@"_getArgument[%d] offset=%d size=%d addr=%p isReg=%d byref=%d double=%d", index, info[index+1].offset, info[index+1].size, addr, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble);
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
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
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
#if 0
	NSLog(@"_setArgument[%d] offset=%d size=%d addr=%p isReg=%d byref=%d double=%d", index, info[index+1].offset, info[index+1].size, addr, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble);
#endif
	if(info[index+1].byRef)
		memcpy(*(void**)addr, buffer, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(double*)addr = (double)*(float*)buffer;
	else
		memcpy(addr, buffer, info[index+1].size);
}

/*
 * if frame == NULL
 *    allocate a fresh arg frame for outgoing invokes
 *    i.e. it must be compatible to __builtin_apply() to construct a function call
 *
 * layout (at least for ARM EABI):
 *  frame[0]	pointer to frame[n] - will be used for memcpy to stack
 *  frame[1]	self - copied to r0	
 *  frame[2]	_cmd - copied to r1
 *  frame[3]	arg1 - copied to r2
 *  frame[4]	arg2 - copied to r3
 *  ...         fill info
 *  frame[n]    first word copied to stack (unused/unclear)
 *  frame[n+1]  self
 *  frame[n+2]  _cmd
 *  frame[n+3]  arg1
 *  ...
 *
 * if frame != NULL
 *    this is a frame received from the objc-runtime through -forward::
 *    in this case we have to modify it since it has a different layout and can't be
 *    passed directly to __builtin_apply()
 *
 *    we need this since a -forwardInvocation: may call -invokeWithTarget:
 *
 *    the reason why the layout is different appears to be that the objc runtime
 *    installs __objc_word_forward (sendmsg.c) as the IMP which is a varargs
 *    C function.
 *
 *    static id __objc_word_forward (id rcv, SEL op, ...)
 *
 *    In that case __builtin_apply_args() returns this different
 *    stack layout (depends if it is called within a varargs function or not).
 *
 * layout:
 *  frame[0]	pointer to frame[10] - first non-register argument
 *  frame[1]	r0	self (rcv)
 *  frame[2]    r1	_cmd (op)
 *  frame[3]    r2	arg1
 *  frame[4]    r3	arg2
 *  frame[5]	temp
 * here could be more temporary variables defined in __objc_word_forward but they have been optimized away
 *  frame[6]    lr			return address of __objc_word_forward
 *  frame[7]	r1	_cmd	registers pushed by __objc_word_forward
 *  frame[8]	r2	arg1
 *  frame[9]	r3	arg2
 *  frame[10]	arg3
 *
 *  the main difference is that the self parameter is not accessible through frame[0]
 *  i.e. we must adjust frame[0] by REGISTER_SAVEAREA_SIZE
 *  and save the lr value (!)
 *
 */

/* here is the definition of the retval_t and arglist_t */

#if 0	// already defined in objc.h on Linux */

typedef void* retval_t;		/* return value */
typedef void(*apply_t)(void);	/* function pointer */
typedef union arglist {
	char *arg_ptr;
	char arg_regs[sizeof (char*)];
} *arglist_t;			/* argument frame */

#endif

- (arglist_t) _allocArgFrame:(arglist_t) frame
{ // (re)allocate stack frame
	if(!frame)
		{ // allocate a new buffer that is large enough to hold the _builtin_apply() block + space for frameLength arguments
			int part1 = sizeof(void *) + STRUCT_RETURN_POINTER_LENGTH + REGISTER_SAVEAREA_SIZE;	// first part
			unsigned long *args;
			NEED_INFO();	// get valid argFrameLength
			frame=(arglist_t) objc_calloc(part1 + argFrameLength, sizeof(char));
			args=(unsigned long *) ((char *) frame + part1);
#if 1
			NSLog(@"allocated frame=%p args=%p framelength=%d part1=%d", frame, args, argFrameLength, part1);
#endif
			((void **)frame)[0]=args;		// insert argument pointer (points to part 2 of the buffer)
		}
#if ADJUST_STACK
	else
		{ // adjust the frame received from -forward:: so that argument offsets are correct and we can call __builtin_apply()
			unsigned long *f=(unsigned long *) frame;
			unsigned long _self=f[1];	// original r0 value
			unsigned long *args;
			f[0] -= STRUCT_RETURN_POINTER_LENGTH + REGISTER_SAVEAREA_SIZE;	// adjust
#if 1
			NSLog(@"frame=%p", f);
#endif
			args=(unsigned long *) f[0];	// new arguments pointer - this will be copied to the stack by __builtin_apply()
#if 1
			NSLog(@"adjusted args=%p", args);
#endif
			args[0]=args[1];	// save link register in tmp
			args[1]=_self;		// insert self value to be copied to r0
		}
#endif
	return frame;
}

// NOTE: this approach is not sane since the retval_t from __builtin_apply_args() may be a pointer into a stack frame that becomes invalid if we return apply()
// therefore, this mechanism is not signal()-safe (i.e. don't use NSTask)
// well, this is already broken in the libobjc - there, __objc_forward() is called which calls forward:: and the latter must return a safe retval_t

#ifndef __APPLE__

// the following functions convert their argument into a proper retval_t that can be passed back
// they do it by using __builtin_apply() on well known functions which transparently pass back their argument

typedef struct { id many[8]; } __big;		// For returning structures ...etc

static __big return_block (void *data)		{ return *(__big*)data; }

static retval_t apply_block(void *data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_block, args, sizeof(data));
}

#endif

#if 0	// with logging

#define APPLY(NAME, TYPE)  NAME: { \
/*static*/ TYPE return##NAME(TYPE data) { fprintf(stderr, "return"#NAME" %x\n", (unsigned)data); return data; } \
inline retval_t apply##NAME(TYPE data) { void *args = __builtin_apply_args(); fprintf(stderr, "apply"#NAME" args=%p %x\n", args, (unsigned)data); return __builtin_apply((apply_t)return##NAME, args, sizeof(data)); } \
fprintf(stderr, "case "#NAME":\n"); \
memcpy(_r, apply##NAME(*(TYPE *) retval), 16); \
break; \
} 

#define APPLY_VOID(NAME)  NAME: { \
/*static*/ void return##NAME(void) { return; } \
inline retval_t apply##NAME(void) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, 0); } \
memcpy(_r, apply##NAME(), 16); \
break; \
}

#else

#define APPLY(NAME, TYPE)  NAME: { \
/*static*/ TYPE return##NAME(TYPE data) { return data; } \
inline retval_t apply##NAME(TYPE data) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, sizeof(data)); } \
memcpy(_r, apply##NAME(*(TYPE *) retval), 16); \
break; \
} 

#define APPLY_VOID(NAME)  NAME: { \
/*static*/ void return##NAME(void) { return; } \
inline retval_t apply##NAME(void) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, 0); } \
memcpy(_r, apply##NAME(), 16); \
break; \
}

#endif

- (retval_t) _returnValue:(void *) retval frame:(arglist_t) frame;
{ // get the return value as a retval_t so that we can return from forward::
	//	retval_t r;
#ifndef __APPLE__
	unsigned long *f=(unsigned long *) frame;
	unsigned long *args;
#if 1
	NSLog(@"_returnValue:%p frame:%p (%p)", retval, frame, f);
#endif
	args=(unsigned long *) f[0];	// current arguments pointer
#if 1
	NSLog(@"adjusted args=%p", args);
#endif
#if ADJUST_STACK
	args[1]=args[0];	// restore link register
	f[0] += STRUCT_RETURN_POINTER_LENGTH + REGISTER_SAVEAREA_SIZE;	// adjust back
#endif
#if 0
	args=(unsigned long *) f[0];	// current arguments pointer
	NSLog(@"restored args=%p", args);
	NSLog(@"frame=%p", f);
	NSLog(@"apply %s", info[0].type);
#endif
	switch(*info[0].type) {
		case APPLY_VOID(_C_VOID);
		case APPLY(_C_ID, id);
		case APPLY(_C_CLASS, Class);
		case APPLY(_C_SEL, SEL);
		case APPLY(_C_CHR, char);
		case APPLY(_C_UCHR, unsigned char);
		case APPLY(_C_SHT, short);
		case APPLY(_C_USHT, unsigned short);
		case APPLY(_C_INT, int);
		case APPLY(_C_UINT, unsigned int);
		case APPLY(_C_LNG, long);
		case APPLY(_C_ULNG, unsigned long);
		case APPLY(_C_LNG_LNG, long long);
		case APPLY(_C_ULNG_LNG, unsigned long long);
		case APPLY(_C_FLT, float);
		case APPLY(_C_DBL, double);
		case APPLY(_C_PTR, char *);
		case APPLY(_C_ATOM, char *);
		case APPLY(_C_CHARPTR, char *);
			
#if FIXME
		case APPLY(_C_ARY_B, char *);
		case _C_UNION_B:
		case _C_STRUCT_B:
			// FIXME
			//				memcpy(((void **)_argframe)[2], retval, _info[0].size);
			if(_info[0].byRef)
				return (retval_t) retval;	// ???
			// #else
			if (_info[0].size > 8)
				// should be dependent on maximum size returned in a register (typically 8 but sometimes 4)
				// can we use sizeof(retval_t) for that purpose???
				return apply_block(*(void**)retval);
			
			// #endif
			return apply_block(*(void**)retval);
#endif
			
		default: { // all others
			//			long dummy[4] = { 0, 0, 0, 0 };	// will be copied to registers r0 .. r3
			NSLog(@"unprocessed type %s for _returnValue", info[0].type);
			//			r=(void *) &dummy;
		}
	}
#endif
	//	r=(void *) _r;
#if 0
	fprintf(stderr, "_returnValue:frame: %p %p %p %p %p %p\n", _r, *(void **) _r, ((void **) _r)[0], ((void **) _r)[1], ((void **) _r)[2], ((void **) _r)[3]);
#endif
	return _r;
}

#if 0	// with logging

#define RETURN(CODE, TYPE) CODE: { \
inline TYPE retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
NSLog(@"retframe%s called (imp=%p frame=%p stack=%d)", #CODE, imp, frame, stack); \
retval_t retval=__builtin_apply(imp, frame, stack); \
NSLog(@"__builtin_apply called"); \
__builtin_return(retval); \
}; \
NSLog(@"call retframe%s", #CODE); \
*(TYPE *) retbuf = retframe##CODE(imp, frame, stack); \
NSLog(@"called retframe%s", #CODE); \
break; \
}

#define RETURN_VOID(CODE, TYPE) CODE: { \
inline TYPE retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
NSLog(@"retframe%s called (imp=%p frame=%p stack=%d)", #CODE, imp, frame, stack); \
retval_t retval=__builtin_apply(imp, frame, stack); \
NSLog(@"__builtin_apply called"); \
__builtin_return(retval); \
}; \
NSLog(@"call retframe%s", #CODE); \
retframe##CODE(imp, frame, stack); \
NSLog(@"called retframe%s", #CODE); \
break; \
}

#else

#define RETURN(CODE, TYPE) CODE: { \
inline TYPE retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
retval_t retval=__builtin_apply(imp, frame, stack); \
__builtin_return(retval); \
}; \
*(TYPE *) retbuf = retframe##CODE(imp, frame, stack); \
break; \
}

#define RETURN_VOID(CODE, TYPE) CODE: { \
inline TYPE retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
retval_t retval=__builtin_apply(imp, frame, stack); \
__builtin_return(retval); \
}; \
retframe##CODE(imp, frame, stack); \
break; \
}

#endif

#if 0
- (void) test
{
	NSLog(@"test");
}
#endif

/*
 * formally, a __builtin_apply(imp, frame, size)
 * does (at least on ARM-EABI)
 *
 *  sp -= round(size, 8);		// create space on stack (rounded up)
 * 	memcpy(sp, frame[0], size);	// copy stack frame
 *  r0=frame[1]
 *  r1=frame[2]
 *  r2=frame[3]
 *  r3=frame[4]
 *  (*imp)()
 */

static BOOL wrapped_builtin_apply(void *imp, arglist_t frame, int stack, void *retbuf, struct NSArgumentInfo *info)
{ // wrap call because it fails if __builtin_apply is called directly from within a Objective-C method
	//	imp=[NSMethodSignature instanceMethodForSelector:@selector(test)];
#ifndef __APPLE__
	typedef struct {
		char val[1 /*info[0].size */];
	} block;
#if 0
	NSLog(@"type %s imp=%p frame=%p stack=%d retbuf=%p", info[0].type, imp, frame, stack, retbuf);
#endif
	switch(*info[0].type) {
		case RETURN_VOID(_C_VOID, void);
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
		default:
			NSLog(@"unprocessed type %s for _call", info[0].type);
			return NO;	// unknown type
	}
#endif
	return YES;	// ok
}

- (BOOL) _call:(void *) imp frame:(arglist_t) _argframe retbuf:(void *) retbuf;
{ // preload registers from stack frame and call implementation
	NEED_INFO();	// make sure that argFrameLength is defined
#if 0
	// FIXME: it is not necessary to round that up - __builtin_apply does it for us
	NSLog(@"doing __builtin_apply(%08x, %08x, %d)", imp, _argframe, argFrameLength);
#endif
	if(REGISTER_SAVEAREA_SIZE > 0)
		{ // copy values from stack frame into locations where registers are loaded from
			void *stackframe=((void **)_argframe)[0];
			int i;
			for(i=1; i<REGISTER_SAVEAREA_SIZE/sizeof(void *); i++)	// a good compiler should be able to unroll this loop
				((void **)_argframe)[i] = ((void **)stackframe)[i];	// copy from stack frame to register filling locations
		}
	return wrapped_builtin_apply(imp, _argframe, argFrameLength, retbuf, &info[0]);	// here, we really invoke the implementation and store the result in retbuf
}

@end  /* NSMethodSignature (mySTEP) */
