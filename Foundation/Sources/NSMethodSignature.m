/* 
 NSMethodSignature.m
 
 Implementation of NSMethodSignature for mySTEP
 This class encapsulates all CPU specific specialities (e.g. how the __builtin_apply() frame is organized, how registers are handled etc.)
 
 Note that the stack frame storage is not part of the NSMethodSignature because several NSInvocations may share the same NSMethodSignature:
 
 Copyright (C) 1994, 1995, 1996, 1998 Free Software Foundation, Inc.
 
 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	August 1994
 Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	August 1998
 Rewrite: Nikolaus Schaller <hns@computer.org> - remove as much of mframe as possible and only rely on gcc/libobjc to run on ARM processor
 Date:    November 2003, Jan 2006-2007,2011-2014
 
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
 
 * libffi (not used!) documentation: https://github.com/atgreen/libffi/blob/master/doc/libffi.info
 
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
	int offset;						// can potentially be negative (!)
	unsigned int size;				// size
	/* extensions */
	unsigned int align;				// alignment
	unsigned short qual;			// qualifier bits (oneway, byref, bycopy, in, inout, out)
	BOOL isReg;						// is passed in a register (+) and not on stack
	BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
	// CHECKME: is this an architecture constant or for each individual parameter???
	BOOL floatAsDouble;				// its a float value that is passed as double
	// ffi type
};

/*
 * define architecture specific values and fixes
 *
 * Frame Layout assumed by __builtin_apply, __builtin_return:
 *
 * frame:       link pointer -->
 *              r0			(copy of self)
 *              r1			(copy of _cmd)
 *              r2			(copy of arg1)
 *              r3			(copy of args)	- REGISTER_SAVEAREA_SIZE bytes
 *              ...			(optionally more space - FPU_REGISTER_SAVEAREA_SIZE)
 *              return value
 *              self
 *              _cmd
 *              arg1
 *              arg2
 * link --->    arg3
 *              arg4
 *              ...
 *
 * note: if the function returns a struct, r0 is used to reference the storage area and r1 is _self, r2 is _cmd
 *
 * i.e. [obj struct_returning_method:arg]
 * should have IMP like struct_returning_method(struct *ret, id self, SEL _cmd, arg);
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

#if defined(__APPLE__)	// compile on MacOS X (don't expect it to run)

#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define INDIRECT_RETURN(info)			NO	// assume never

struct stackframe /* Apple */
{
	void *fp;			// points to the 'more' field
	long iregs[0];		// r0..r3
	float fpuregs[0];	// s0..s15
	void *unused[0];
	void *lr;			// link register
	long copied[0];		// copied between iregs[1..n]
	char more[0];		// dynamically extended to what we need
};

#elif defined(__arm__)	// for ARM
#if defined(__ARM_EABI__)

#if defined(__ARM_PCS_VFP)	// armhf: hard float uses VFP

#define FLOAT_AS_DOUBLE					NO
#define MIN_ALIGN						sizeof(long)
#define INDIRECT_RETURN(info)			(info.size > sizeof(void *) && (info.type[0] == _C_STRUCT_B || info.type[0] == _C_UNION_B || info.type[0] == _C_ARY_B))

struct stackframe /* armhf eabi */
{
	void *fp;			// points to the 'more' field
	long iregs[4];		// r0..r3
	float fpuregs[16];	// s0..s15 / d0..d7
	void *unused[3];
	void *lr;			// link register
	long copied[3];		// copied between iregs[1..n] - most likely that we can ask for the address of a parameter passed in a register
	char more[0];		// dynamically extended to what we need
};

#else	// armel: soft float

#warning "not tested"

#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define INDIRECT_RETURN(info)			(info.size > sizeof(void *) && (info.type[0] == _C_STRUCT_B || info.type[0] == _C_UNION_B || info.type[0] == _C_ARY_B))

struct stackframe /* armel eabi */
{
	void *fp;			// points to the 'more' field
	long iregs[4];		// r0..r3
	float fpuregs[0];	// s0..s15
	void *unused[3];
	void *lr;			// link register
	long copied[3];		// copied between iregs[1..n]
	char more[0];		// dynamically extended to what we need
};

#endif // __ARM_PCS_VFP
#else // not EABI - must be OABI

#error "not tested"

#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define INDIRECT_RETURN(info)			(info.size > sizeof(void *) && (info.type[0] == _C_STRUCT_B || info.type[0] == _C_UNION_B || info.type[0] == _C_ARY_B))

struct stackframe /* armel oabi */
{
	void *fp;			// points to the 'more' field
	long iregs[4];		// r0..r3
	float fpuregs[0];	// s0..s15
	void *unused[3];
	void *lr;			// link register
	long copied[3];		// copied between iregs[1..n]
	char more[0];		// dynamically extended to what we need
};

#endif	// ARM_EABI
#elif defined(__mips__)	// for MIPS

#warning "not tested"

#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define INDIRECT_RETURN(info)			(info.size > sizeof(void *) && (info.type[0] == _C_STRUCT_B || info.type[0] == _C_UNION_B || info.type[0] == _C_ARY_B))

struct stackframe /* mipsel */
{
	void *fp;			// points to the 'more' field
	long iregs[4];		// r0..r3
	float fpuregs[0];	// s0..s15
	void *unused[3];
	void *lr;			// link register
	long copied[3];		// copied between iregs[1..n]
	char more[0];		// dynamically extended to what we need
};

#elif defined(i386)	// for Intel 32 bit

#warning "not tested"

#define FLOAT_AS_DOUBLE					YES
#define MIN_ALIGN						sizeof(long)
#define INDIRECT_RETURN(info)			(info.size > sizeof(void *) && (info.type[0] == _C_STRUCT_B || info.type[0] == _C_UNION_B || info.type[0] == _C_ARY_B))

struct stackframe /* i386 */
{
	void *fp;			// points to the 'more' field
	long iregs[7];		// r0..r3
	float fpuregs[0];	// s0..s15
	void *unused[3];
	void *lr;			// link register
	long copied[3];		// copied between iregs[1..n]
	char more[0];		// dynamically extended to what we need
};

#elif defined(__x86_64__)
#error "not tested"
#elif defined(__ppc__)
#error "not tested"
#elif defined(__ppc64__)
#error "not tested"
#elif defined(__m68k__)
#error "not tested"

#else

#error "unknown architecture"

#endif

#define ISBIGENDIAN					(NSHostByteOrder()==NS_BigEndian)

// this may be called recursively (structs)

// FIXME: move some of this to NSGetSizeAndAlignment()

static const char *mframe_next_arg(const char *typePtr, struct NSArgumentInfo *info)
{ // returns NULL on error
	NSCAssert(info, @"missing NSArgumentInfo");
	// FIXME: NO, we should keep the flags+type but remove the offset
	info->qual = 0;	// start with no qualifier
	info->isReg = NO;
	info->byRef = NO;
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
	// FIXME: this should probably be the stackframe length + what additional arguments and return value need
	// or it is the real argument length (but not return value and additional register area) so that we have to add sizeof(fp->copied)
	return argFrameLength;
}

- (const char *) getArgumentTypeAtIndex:(unsigned) index
{
	NEED_INFO();	// make sure numArgs and type is defined
	if(index >= numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %u too high (%d).", index, numArgs];
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
	return numArgs /* -1 if we change the index to count from 0 */;
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

- (void) encodeWithCoder:(NSCoder*) aCoder
{ // encode type string - NOTE: it can't encode _makeOneWay
	[aCoder encodeValueOfObjCType:@encode(char *) at:&methodTypes];
}

- (id) initWithCoder:(NSCoder*) aCoder
{ // initialize from received type string
	char *type;
	[aCoder decodeValueOfObjCType:@encode(char *) at:&type];
	return [self _initWithObjCTypes:type];
}

- (BOOL) isEqual:(id) other
{
	if(other == self)
		return YES;
	// fixme: strip off offsets if included
	// i.e. we should better compare numArgs and individual _argInfo:
	if(strcmp([self _methodTypes], [other _methodTypes]) != 0)
		return NO;
	return [super isEqual:other];
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
	if(index > numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %u too high (%d).", index, numArgs];
	return &info[index];
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

- (void) _logFrame:(arglist_t) _argframe target:(id) target selector:(SEL) selector;
{
	int i;
	struct stackframe *f=(struct stackframe *) _argframe;
	void **af=(void **) _argframe;
	int len;
	NEED_INFO();	// get valid argFrameLength and methodReturnLength
	len=offsetof(struct stackframe, more) + argFrameLength + info[0].size;	// as calculated by _allocArgFrame
	for(i=0; i<10+(len/sizeof(void *)); i++)
		{
		NSString *note=@"";
		if(&af[i] == &af[0]) note=[note stringByAppendingFormat:@" link %+d ->>", (char *) f->fp- (char *) &af[0]];
		if(&af[i] == f->fp) note=[note stringByAppendingString:@" <<- link"];
		if(target && af[i] == target) note=[note stringByAppendingString:@" self"];
		if(selector && af[i] == selector) note=[note stringByAppendingString:@" _cmd"];
//		if(&((void **)_argframe)[i] == (_argframe+0x28)) note=[note stringByAppendingString:@" argp"];
		if((char *) &af[i] == ((char *) _argframe)+len) note=[note stringByAppendingString:@" <<- END"];
		NSLog(@"arg[%2d]:%08x %+4d %+4d %08x %12ld %12g%@", i, 
			  &af[i],
			  (char *) &af[i] - (char *) &af[0],
			  (char *) &af[i] - (char *) f->fp,
			  af[i],
			  (long) af[i],
			  *(float *) &af[i],
			  note);
		}
}

- (const char *) _methodTypes	{ return methodTypes; }

- (void) _logMethodTypes;
{
	int i;
	NSLog(@"method Types %s:", methodTypes); 
	for(i=0; i<=numArgs; i++)
		NSLog(@"   %3d: size=%02d align=%01d isreg=%d offset=%02d qual=%x byRef=%d fltDbl=%d type=%s",
			  i-1, info[i].size, info[i].align,
			  info[i].isReg, info[i].offset, info[i].qual,
			  info[i].byRef, info[i].floatAsDouble,
			  info[i].type);
}

- (struct NSArgumentInfo *) _methodInfo
{ // collect all information from methodTypes in a platform independent way and allocate integer, floating point registers and stack values
	if(info == NULL) 
		{ // calculate method info
			const char *types = methodTypes;
			int i=0;
			int nextireg=offsetof(struct stackframe, iregs);	// first integer register offset
			int nextfpreg=offsetof(struct stackframe, fpuregs);	// first fp register offset
			int nextdpreg=nextfpreg;	// double precision offset
			int allocArgs=6;	// this is usually enough, i.e. retval+self+_cmd+3 args
			int needs;
			argFrameLength=0;	// offset on stack
#if 0
			NSLog(@"methodInfo create for types %s", methodTypes);
#endif
			info = objc_malloc(sizeof(struct NSArgumentInfo) * allocArgs);
			while(*types)
				{ // process all types
					const char *t;
#if 0
					NSLog(@"%d: %s", i, types);
#endif
					if(i >= allocArgs)
						allocArgs+=5, info = objc_realloc(info, sizeof(struct NSArgumentInfo) * allocArgs);	// we need more space
					types = mframe_next_arg(types, &info[i]);
					if(!types)
						break;	// some error
					t=info[i].type;
					if((info[i].qual & _F_INOUT) == 0)
						{ // add default qualifiers
							if(i == 0)
								info[i].qual |= _F_OUT;		// default to "bycopy out" for the return value
							else if(*t == _C_PTR || *t == _C_ATOM || *t == _C_CHARPTR)
								info[i].qual |= _F_INOUT;	// pointers default to "bycopy in/out"
							else
								info[i].qual |= _F_IN;		// others default to "bycopy in"
						}
					if(info[i].align < MIN_ALIGN)
						info[i].align=MIN_ALIGN;
					info[i].isReg=NO;	// default to pass-on-stack
					if(i == 0)
						{ // return value
							if(INDIRECT_RETURN(info[0]))
								{ // the first ireg is reserved for the struct return pointer to a memory area allocated by the caller
									info[0].byRef=YES;
									info[0].isReg=YES;
									info[0].offset=nextireg;
									nextireg+=sizeof(void *);
								}
							i++;
							continue;
						}
					needs=((info[i].size+info[i].align-1)/info[i].align)*info[i].align;	// how much this needs incl. padding
					if(*t == _C_FLT)
						{ // try to put into FPU_REGISTER
							if(nextfpreg + needs <= offsetof(struct stackframe, unused))
								{ // yes, fits into the FPU register area
									info[i].isReg=YES;
									info[i].offset = nextfpreg;
									if(nextfpreg == nextdpreg)
										{
										nextdpreg+=sizeof(double);
										nextfpreg+=needs;
										}
									else
										nextfpreg=nextdpreg;	// we did fill a gap before the next double register
									i++;
									continue;
								}
							nextfpreg=offsetof(struct stackframe, unused);	// don't put more values into registers if any was on stack
						}
					else if(*t == _C_DBL)
						{ // try to put into double precision FPU_REGISTER
							if(nextdpreg + needs <= offsetof(struct stackframe, unused))
								{ // yes, fits into the double precision FPU register area
									info[i].isReg=YES;
									info[i].offset = nextdpreg;
									if(nextfpreg == nextdpreg)
										nextfpreg+=needs;	// don't assign as fp registers
									nextdpreg+=needs;
									i++;
									continue;
								}
							nextfpreg=offsetof(struct stackframe, unused);	// don't put more values into registers if any was on stack
						}
					else
						// FIXME what about small structs passed as arguments?
						{ // if integer or other type
							if(nextireg + needs <= offsetof(struct stackframe, fpuregs))
								{ // yes, fits into the integer register area
									info[i].isReg=YES;
									info[i].offset = nextireg;
									nextireg+=needs;
					//				argFrameLength+=needs;	// and reserve space on stack
									i++;
									continue;
								}
							nextireg=offsetof(struct stackframe, fpuregs);	// don't put more values into registers if any was on stack
						}
					// this is still inconsistent - is [self frameLength] the total length? Or just the stack?
					// does lr+copied count or not?
					// currently we have a framelength > what we really need - but it does not include the fp+registers
					info[i].offset=argFrameLength;	// offset relative to frame pointer
					argFrameLength+=needs;
					i++;
				}
			numArgs = i-1;	// return type does not count
#if 0
			NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
    	}
	if(!info[0].isReg)
		info[0].offset=argFrameLength;	// unless returned indirectly through r0, place return value behind all arguments
	// FIXME: how to return float values?
	// FIXME: does return value count to the argFrameLength?
#if 1
	[self _logMethodTypes];
#endif
	return info;
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
		strcpy(methodTypes, t);	// save unchanged
#if 0
		NSLog(@"NSMethodSignature -> %s", methodTypes);
#endif
		}
	return self;
}

- (unsigned) _getArgumentLengthAtIndex:(int) index;
{
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	return info[index+1].size;
}

- (unsigned) _getArgumentQualifierAtIndex:(int) index;
{
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	return info[index+1].qual;
}

static inline void *_getArgumentAddress(arglist_t frame, struct NSArgumentInfo info)
{
	char *addr;
	if(!frame)
		[NSException raise:NSInternalInconsistencyException format:@"missing stack frame"];
	addr=info.isReg?(char *) frame:((char *) ((struct stackframe *) frame)->fp);
#if 0
	NSLog(@"_getArgumentAddress %p %p %d %d", frame, addr, info.offset, info.isReg);
#endif
	return addr + info.offset;
	if(!info.isReg)
		return ((char *) ((struct stackframe *)frame)->fp) + info.offset;	// indirectly through frame pointer
	return ((char *) &((struct stackframe *)frame)->fp) + info.offset;	// registers start behind frame pointer
}

- (const char *) _getArgument:(void *) buffer fromFrame:(arglist_t) _argframe atIndex:(int) index;
{ // extract argument from frame
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	addr=_getArgumentAddress(_argframe, info[index+1]);
#if 1
	NSLog(@"_getArgument[%d]:%p offset=%d addr=%p[%d] isReg=%d byref=%d double=%d type=%s", index, buffer, info[index+1].offset, addr, info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble, info[index+1].type);
#endif
	if(info[index+1].byRef)
		memcpy(buffer, *(void**)addr, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(float*)buffer = (float)*(double*)addr;
	else
		{
#if 1
		NSLog(@"_getArgument memcpy(%p, %p, %u);", buffer, addr, info[index+1].size),
#endif
		memcpy(buffer, addr, info[index+1].size);
		}
	return info[index+1].type;
}

- (void) _setArgument:(void *) buffer forFrame:(arglist_t) _argframe atIndex:(int) index retainMode:(enum _INVOCATION_MODE) mode;
{
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	addr=_getArgumentAddress(_argframe, info[index+1]);
#if 1
	NSLog(@"_setArgument[%d]:%p offset=%d addr=%p[%d] isReg=%d byref=%d double=%d type=%s mode=%d", index, buffer, info[index+1].offset, addr, info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble, info[index+1].type, 1);
#endif
	if(mode != _INVOCATION_ARGUMENT_SET_NOT_RETAINED && info[index+1].type[0] == _C_CHARPTR)
		{ // retain/copy C-strings if needed
			if(buffer && *(char **)buffer == *(char **)addr)
				return;	// no need to change
			if((*(char **)addr) && mode == _INVOCATION_ARGUMENT_SET_RETAINED || mode == _INVOCATION_ARGUMENT_RELEASE)
				{
#if 1
				NSLog(@"_setArgument free old %s", *(char **)addr);
#endif
				objc_free(*(char **)addr);
				}
			if(buffer && (*(char **)buffer) && mode == _INVOCATION_ARGUMENT_SET_RETAINED)
				{
				char *tmp;
#if 1
				NSLog(@"_setArgument copy new %s", *(char **)buffer);
#endif
				tmp = objc_malloc(strlen(*(char **)buffer)+1);
				strcpy(tmp, *(char **)buffer);
				*(char **)buffer=tmp;
				}
			else if(mode == _INVOCATION_ARGUMENT_RETAIN)
			   {
			   char *tmp;
#if 1
			   NSLog(@"_setArgument copy current %@", *(id*)addr);
#endif
			   tmp = objc_malloc(strlen(*(char **)addr)+1);
			   strcpy(tmp, *(char **)addr);
			   *(char **)addr=tmp;
			   return;	// copy but ignore buffer
			   }
		}
	else if(mode != _INVOCATION_ARGUMENT_SET_NOT_RETAINED && info[index+1].type[0] == _C_ID)
		{ // retain objects if needed
			if(buffer && *(id*)buffer == *(id*)addr)
				return;	// no need to change
			if(mode == _INVOCATION_ARGUMENT_SET_RETAINED || mode == _INVOCATION_ARGUMENT_RELEASE)
				{
#if 1
				NSLog(@"_setArgument release old %@", *(id*)addr);
#endif
				[*(id*)addr release];
				}
			if(buffer && mode == _INVOCATION_ARGUMENT_SET_RETAINED)
				{
#if 1
				NSLog(@"_setArgument retain new %@", *(id*)buffer);
#endif
				[*(id*)buffer retain];
				}
			else if(mode == _INVOCATION_ARGUMENT_RETAIN)
				{
#if 1
				NSLog(@"_setArgument retain current %@", *(id*)addr);
#endif
				[*(id*)addr retain];
				return;	// retain but ignore buffer
				}
		}
	if(buffer)
		{
		if(info[index+1].byRef)	// struct by reference
			memcpy(*(void**)addr, buffer, info[index+1].size);
		else if(info[index+1].floatAsDouble)
			*(double*)addr = (double)*(float*)buffer;
		else
			{
#if 1
			NSLog(@"_setArgument memcpy(%p, %p, %u);", addr, buffer, info[index+1].size),
#endif
			memcpy(addr, buffer, info[index+1].size);
			}
		}
	else if(mode != _INVOCATION_ARGUMENT_RELEASE)
		{ // wipe out (used for handling the return value of -invoke with nil target)
			if(info[index+1].byRef)	// struct by reference
				memset(*(void**)addr, 0, info[index+1].size);
			else if(info[index+1].floatAsDouble)
				*(double*)addr = 0.0;
			else
				{
#if 1
				NSLog(@"_setArgument memset(%p, %ul, %u);", addr, 0, info[index+1].size),
#endif
				memset(addr, 0, info[index+1].size);
				}
		}	
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
 *  ...         FPU registers (if available)
 *  frame[n]    first word copied to stack (unused/unclear - link register?)
 *  frame[n+1]  self - to r0
 *  frame[n+2]  _cmd - to r1
 *  frame[n+3]  arg1 - to r2
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
 *  frame[0]	pointer to frame[n] - first non-register argument
 *  frame[1]	r0	self (rcv)
 *  frame[2]    r1	_cmd (op)
 *  frame[3]    r2	arg1
 *  frame[4]    r3	arg2
 *  frame[5]	temp
 * here could be more temporary variables defined in __objc_word_forward but they have been optimized away
 *  frame[n-4]  lr			return address into __objc_word_forward
 *  frame[n-3]	r1	_cmd	registers pushed by __objc_word_forward
 *  frame[n-2]	r2	arg1
 *  frame[n-1]	r3	arg2
 *  frame[n]	arg3
 *
 *  the main difference is that the self parameter is not accessible through frame[0]
 *  i.e. we must adjust frame[0] by REGISTER_SAVEAREA_SIZE
 *  and save the lr value (!)
 *
 *  NOTE: all this might depend on the compiler/libobjc that is used...
 *
 */

- (arglist_t) _allocArgFrame:(arglist_t) frame
{ // (re)allocate stack frame
	if(!frame)
		{ // allocate a new buffer that is large enough to hold the _builtin_apply() block + space for frameLength arguments and methodReturnLength
			struct stackframe *f;
			unsigned int len;
			NEED_INFO();	// get valid argFrameLength and methodReturnLength
			len=offsetof(struct stackframe, more) + argFrameLength + info[0].size;
			f=(struct stackframe *) objc_calloc(len, sizeof(char));
			frame=(arglist_t) f;
#if 0
			NSLog(@"allocated frame=%p..%p framelength=%d len=%d", frame, len + (char*) frame, argFrameLength, len);
#endif
			// how can/should we set the link register?
			f->fp=(void *) f->more;	// set frame link pointer
			if(INDIRECT_RETURN(info[0]))
				f->iregs[0]=(long) _getArgumentAddress(frame, info[0]);	// initialize r0 with address of return value buffer
		}
	return frame;
}

#ifndef __APPLE__

// the following functions convert their argument into a proper retval_t that can be passed back
// they do it by using __builtin_apply() on well known functions which transparently pass back their argument

typedef struct { id many[8]; } big_block;		// For returning big structures ...etc. real size does not matter

static big_block return_block (void *data)		{ return *(big_block*)data; }

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
memcpy(_r, apply##NAME(*(TYPE *) retval), sizeof(_r)); \
break; \
} 

#define APPLY_VOID(NAME)  NAME: { \
/*static*/ void return##NAME(void) { return; } \
inline retval_t apply##NAME(void) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, 0); } \
memcpy(_r, apply##NAME(), sizeof(_r)); \
break; \
}

#else

#define APPLY(NAME, TYPE)  NAME: { \
/*static*/ TYPE return##NAME(TYPE data) { return data; } \
inline retval_t apply##NAME(TYPE data) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, sizeof(data)); } \
memcpy(_r, apply##NAME(*(TYPE *) retval), sizeof(_r)); \
break; \
} 

#define APPLY_VOID(NAME)  NAME: { \
/*static*/ void return##NAME(void) { return; } \
inline retval_t apply##NAME(void) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, 0); } \
memcpy(_r, apply##NAME(), sizeof(_r)); \
break; \
}

#endif

- (retval_t) _returnValue:(arglist_t) frame retbuf:(char [32]) _r;
{ // get the return value as a retval_t so that we can return from forward::
#ifndef __APPLE__
	void *retval=_getArgumentAddress(frame, info[0]);	// return buffer
#if 0	// critital - calling functions will overwrite the stack!
//	NSLog(@"_returnValue:%p frame:%p (%p)", retval, frame, f);
	fprintf(stderr, "_returnValue:%p frame:%p (%p)\n", retval, frame, f);
#endif
#if 0
	NSLog(@"  args=%p", frame.arg_ptr[0]);
	NSLog(@"  frame=%p", frame);
	NSLog(@"  apply %s", info[0].type);
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
#if 0	// this may overwrite the registers we just have modified
	fprintf(stderr, "_returnValue:frame: %p %p %p %p %p %p\n", _r, *(void **) _r, ((void **) _r)[0], ((void **) _r)[1], ((void **) _r)[2], ((void **) _r)[3]);
#endif
	return _r;
}

/*
 * the following macros define the case selectors
 * for handling different return data types of wrapped_builtin_apply
 * so that the return value is stored in the retbuf
 * for that we define an (inlined) helper function that handles
 * the call to __builtin_return() for conversion into the type we need
 *
 * FIXME: handle struct return of variable size!
 * FIXME: handle float/double return correctly (unclear if the bug is here)
 */

#if 1	// with logging

#define RETURN(CODE, TYPE) CODE: { \
inline TYPE retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
NSLog(@"retframe%s called (imp=%p frame=%p stack=%d)", #CODE, imp, frame, stack); \
retval_t retval=__builtin_apply(imp, frame, stack); \
NSLog(@"retframe%s: returned from __builtin_apply", #CODE); \
__builtin_return(retval); \
}; \
NSLog(@"call retframe%s", #CODE); \
*(TYPE *) retbuf = retframe##CODE(imp, frame, stack); \
NSLog(@"called retframe%s", #CODE); \
break; \
}

#define RETURN_VOID(CODE) CODE: { \
inline void retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
NSLog(@"retframe%s called (imp=%p frame=%p stack=%d)", #CODE, imp, frame, stack); \
retval_t retval=__builtin_apply(imp, frame, stack); \
NSLog(@"retframe%s: returned from __builtin_apply", #CODE); \
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

#define RETURN_VOID(CODE) CODE: { \
inline void retframe##CODE(void *imp, arglist_t frame, int stack) \
{ \
retval_t retval=__builtin_apply(imp, frame, stack); \
__builtin_return(retval); \
}; \
retframe##CODE(imp, frame, stack); \
break; \
}

#endif

/*
 * formally, a __builtin_apply(imp, frame, size)
 * does (at least on ARMHF)
 *
 *  sp -= round(size, 8);		// create space on stack (rounded up)
 * 	memcpy(sp, frame[0], size);	// copy stack frame
 *  r0=frame[1]
 *  r1=frame[2]
 *  r2=frame[3]
 *  r3=frame[4]
 *  s0=frame[5]
 * ...
 * s15=frame[...]
 *  (*imp)() -- calls implementation
 *  frame[1]=r0
 *  frame[2]=r1
 *  frame[3]=r2
 *  frame[4]=r3
 *  frame[5]=s0
 *
 * a __builtin_return(retval)
 * does
 *  r0=retval[0]
 *  r1=retval[1]
 *  r2=retval[2]
 *  r3=retval[3]
 *  s0=retval[4]
 *  sp += 52;
 *  pop {r4, r5, r6, r7, pc} (this ends the current function)
 *  
 */

static BOOL wrapped_builtin_apply(void *imp, arglist_t frame, int stack, struct NSArgumentInfo *info)
{ // wrap call because it fails if __builtin_apply is called directly from within a Objective-C method
	//	imp=[NSMethodSignature instanceMethodForSelector:@selector(test)];
#ifndef __APPLE__
	void *retbuf;
	unsigned structlen=info[0].size;
	retbuf=_getArgumentAddress(frame, info[0]);
#if 0
	NSLog(@"wrapped_builtin_apply: type %s imp=%p frame=%p stack=%d retbuf=%p", info[0].type, imp, frame, stack, retbuf);
#endif
	switch(*info[0].type) {
		case RETURN_VOID(_C_VOID);
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
		case RETURN(_C_ARY_B, big_block);	// does this really exist? How can a method return an array and not a pointer?
		case RETURN(_C_STRUCT_B, big_block);
		case RETURN(_C_UNION_B, big_block);
		default:
			NSLog(@"unprocessed type %s for _call", info[0].type);
			return NO;	// unknown type
	}
#endif
	return YES;	// successful
}

#define EXTRA	0	// it does not appear as if we need extra stack space

- (BOOL) _call:(void *) imp frame:(arglist_t) _argframe;
{ // preload registers from stack frame and call implementation
	struct stackframe *f=(struct stackframe *) _argframe;
	NEED_INFO();	// make sure that argFrameLength is defined correctly
#if 1
	NSLog(@"doing __builtin_apply(%08x, %08x, %d)", imp, _argframe, argFrameLength+EXTRA);
#endif
	if(sizeof(f->copied) > 0)
		memcpy(f->copied, &f->iregs[1], sizeof(f->copied));	// copy from registers to stack
#if 1
	[self _logFrame:_argframe target:nil selector:NULL];
#endif
	return wrapped_builtin_apply(imp, _argframe, argFrameLength+EXTRA, &info[0]);	// here, we really invoke the implementation and store the result in retbuf
}

@end  /* NSMethodSignature (mySTEP) */
