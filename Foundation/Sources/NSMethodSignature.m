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
#include <objc/message.h>
#include <ffi.h>

struct NSArgumentInfo
{ // internal Info about layout of arguments. Extended from the original OpenStep version - no longer available in OSX
	const char *type;				// type (pointer to first type character)
	int offset;						// can potentially be negative (!)
	unsigned int size;				// size (not reliable!)
	/* extensions */
	ffi_type ffitype;				// pointer to some ffi type
	unsigned short qual;			// qualifier bits (oneway, byref, bycopy, in, inout, out)
#if 1 || OLD
	unsigned int align;				// alignment
	BOOL isReg;						// is passed in a register (+) and not on stack
	BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
									// CHECKME: is this an architecture constant or for each individual parameter???
	BOOL floatAsDouble;				// its a float value that is passed as double
									// ffi type
#endif
};

#define cif ((ffi_cif *)internal1)

static void GSFFIInvocationCallback(ffi_cif *cifp, void *retp, void **args, void *user)
{
	id	obj;
	SEL	selector;
	NSInvocation *inv;
	NSMethodSignature *sig;
#if 1
	fprintf(stderr, "GSFFIInvocationCallback called\n");
#endif
	obj = *(id *)args[0];
	selector = *(SEL *)args[1];

	if (!class_respondsToSelector(object_getClass(obj),
								  @selector(forwardInvocation:)))
		{
		[NSException raise: NSInvalidArgumentException
					format: @"GSFFIInvocation: Class '%s' does not respond to forwardInvocation: for '%c%s'",
							class_getName(object_getClass(obj)),
							(class_isMetaClass(object_getClass(obj)) ? '+' : '-'),
							selector ? sel_getName(selector) : "(null)"];
		}

	sig = nil;
	if (gs_protocol_selector(GSTypesFromSelector(selector)) == YES)
		{
		sig = [NSMethodSignature signatureWithObjCTypes:
			   GSTypesFromSelector(selector)];
		}
	if (sig == nil)
		{
		sig = [obj methodSignatureForSelector: selector];
		}

#if FIXME
	/*
	 * If we got a method signature from the receiving object,
	 * ensure that the selector we are using matches the types.
	 */
	if (sig != nil)
		{
		const char	*receiverTypes = [sig methodType];
		const char	*runtimeTypes = GSTypesFromSelector(selector);

		if (NO == GSSelectorTypesMatch(receiverTypes, runtimeTypes))
			{
	  const char	*runtimeName = sel_getName(selector);

	  selector = GSSelectorFromNameAndTypes(runtimeName, receiverTypes);
	  if (runtimeTypes != 0)
		  {
		  /*
		   * FIXME ... if we have a typed selector, it probably came
		   * from the compiler, and the types of the proxied method
		   * MUST match those that the compiler supplied on the stack
		   * and the type it expects to retrieve from the stack.
		   * We should therefore discriminate between signatures where
		   * type qalifiers and sizes differ, and those where the
		   * actual types differ.
		   */
		  NSDebugFLog(@"Changed type signature '%s' to '%s' for '%s'",
					  runtimeTypes, receiverTypes, runtimeName);
		  }
			}
		}

	if (sig == nil)
		{
		/* NB Don't overwrite selector prematurely, so we can show the untyped
		 * selector in the error message below if there is no best selector. */
		SEL typed_sel = gs_find_best_typed_sel (selector);

		if (typed_sel != 0)
			{
			selector = typed_sel;
			if (GSTypesFromSelector(selector) != 0)
				{
				sig = [NSMethodSignature signatureWithObjCTypes:
						GSTypesFromSelector(selector)];
				}
			}
		}

	if (sig == nil)
		{
		[NSException raise: NSInvalidArgumentException
					format: @"Can not determine type information for %s[%s %s]",
					GSObjCIsInstance(obj) ? "-" : "+",
					GSClassNameFromObject(obj),
					selector ? sel_getName(selector) : "(null)"];
		}
#endif

	inv = [[[NSInvocation alloc] _initWithMethodSignature:(NSMethodSignature *) sig andArgFrame:NULL] autorelease];

	// FIXME: setup cifp args user sig;
	// ...
	// No. If *user is the NSMethodSignature we already have a cifp
	// we only need a frame buffer inside the NSInvocation
	// which is allocated by invocationWithMethodSignature

	[inv setTarget:obj];
	[inv setSelector:selector];

	[obj forwardInvocation:inv];

	/* If we are returning a value, we must copy it from the invocation
	 * to the memory indicated by 'retp'.
	 */
	if (retp)
		{
		[inv getReturnValue:retp];
		/* We need to (re)encode the return type for it's trip back. */
		cifframe_encode_arg([sig methodReturnType], retp);
		}
}

static IMP gs_objc_msg_forward2(id receiver, SEL sel)
{
	NSMethodSignature *sig = nil;
	const char *types;
#if FIXME
	GSCodeBuffer *memory;

	/*
	 * If we're called with a typed selector, then use this when deconstructing
	 * the stack frame.  This deviates from OS X behaviour (where there are no
	 * typed selectors), but it always more reliable because the compiler will
	 * set the selector types to represent the layout of the call frame.  This
	 * means that the invocation will always deconstruct the call frame
	 * correctly.
	 */

	if (NULL != (types = GSTypesFromSelector(sel)))
		{
		sig = [NSMethodSignature signatureWithObjCTypes: types];
		}

	/* Take care here ... the receiver may be nil (old runtimes) or may be
	 * a proxy which implements a method by forwarding it (so calling the
	 * method might cause recursion).  However, any sane proxy ought to at
	 * least implement -methodSignatureForSelector: in such a way that it
	 * won't cause infinite recursion, so we check for that method being
	 * implemented and call it.
	 * NB. object_getClass() and class_respondsToSelector() should both
	 * return NULL when given NULL arguments, so they are safe to use.
	 */
	if (nil == sig)
		{
		Class c = object_getClass(receiver);

		if (class_respondsToSelector(c, @selector(methodSignatureForSelector:)))
			{
			sig = [receiver methodSignatureForSelector: sel];
			}
		if (nil == sig
			&& (NULL != (types = GSTypesFromSelector(gs_find_best_typed_sel(sel)))))
			{
			sig = [NSMethodSignature signatureWithObjCTypes: types];
			}
		if (nil == sig)
			{
			if (nil == receiver)
				{
				/* If we have a nil receiver, so the runtime is probably trying
				 * to check for forwarding ... return NULL to let it fall back
				 * on the standard forwarding mechanism.
				 */
				return NULL;
				}
			[NSException raise: NSInvalidArgumentException
				format: @"%c[%s %s]: unrecognized selector sent to instance %p",
				(class_isMetaClass(c) ? '+' : '-'),
				class_getName(c), sel_getName(sel), receiver];
			}
		}

	// here we should make the sig allocate a new closure function
	// i.e. rather than calling cifframe_closure here we move it into _forwardingImplementation

	// memory = cifframe_closure(sig, GSFFIInvocationCallback);

	// initialize and allocate a new forwarding function
	return [sig _forwardingImplementation];
#else
	return NULL;
#endif
}

#define ISBIGENDIAN					(NSHostByteOrder()==NS_BigEndian)

// this may be called recursively (structs)

// FIXME: move some of this to NSGetSizeAndAlignment()

static const char *next_arg(const char *typePtr, struct NSArgumentInfo *info)
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
#if defined(i386)	// for Intel 32 bit
			info->align = __alignof__(long);
#else
			info->align = __alignof__(long long);
#endif
			break;

		case _C_ULNG_LNG:
			info->size = sizeof(unsigned long long);
#if defined(i386)	// for Intel 32 bit
			info->align = __alignof__(unsigned long);
#else
			info->align = __alignof__(unsigned long long);
#endif
			break;

#define FLOAT_AS_DOUBLE 0

		case _C_FLT:
			if(FLOAT_AS_DOUBLE)
				{
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
					typePtr = next_arg(typePtr, &local);
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

			typePtr = next_arg(typePtr, &local);
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
			while (*typePtr && *typePtr != _C_STRUCT_E && *typePtr != '=')			// Skip "<strut-name>="
				typePtr++;
			if (*typePtr == '=')	// did end at '='
				typePtr++;
			// Base structure alignment
			if (*typePtr != _C_STRUCT_E)			// on first element.
				{
				typePtr = next_arg(typePtr, &local);
				if (!typePtr)
					return typePtr;						// error

				acc_size = ROUND(acc_size, local.align);
				acc_size += local.size;
				acc_align = MAX(local.align, __alignof__(fooalign));
				}
			// Continue accumulating
			while (*typePtr && *typePtr != _C_STRUCT_E)			// structure size.
				{
				typePtr = next_arg(typePtr, &local);
				if (!typePtr)
					return typePtr;						// error

				acc_size = ROUND(acc_size, local.align);
				acc_size += local.size;
				}
			info->size = acc_size;
			info->align = acc_align;
			//printf("_C_STRUCT_B  size %d align %d\n",info->size,info->align);
			if(*typePtr)
				typePtr++;		// Skip end-of-struct
			break;
		}

		case _C_UNION_B: {
			struct NSArgumentInfo local;
			int	max_size = 0;
			int	max_align = 0;

			while (*typePtr && *typePtr != _C_UNION_E && *typePtr != '=')			// Skip "<strut-name>="
				typePtr++;
			if (*typePtr == '=')	// did end at '='
				typePtr++;

			while (*typePtr && *typePtr != _C_UNION_E)
				{
				typePtr = next_arg(typePtr, &local);
				if (!typePtr)
					return typePtr;						// error
				max_size = MAX(max_size, local.size);
				max_align = MAX(max_align, local.align);
				}
			info->size = max_size;
			info->align = max_align;
			if(*typePtr)
				typePtr++;		// Skip end-of-struct
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

#define NEED_INFO() if(info == NULL) [self _argInfo:0]

- (NSUInteger) frameLength
{
	NEED_INFO();
	// FIXME: this should probably be the stackframe length + what additional arguments and return value need
	// or it is the real argument length (but not return value and additional register area)? So that we have to add sizeof(fp->copied)
	return argFrameLength;
}

- (const char *) getArgumentTypeAtIndex:(NSUInteger) index
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

- (NSUInteger) methodReturnLength
{
	NEED_INFO();
	return info[0].size;
}

- (const char*) methodReturnType
{
	NEED_INFO();
	return info[0].type;
}

- (NSUInteger) numberOfArguments
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

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ %s", [super description], methodTypes];
}

@end

@implementation NSMethodSignature (NSUndocumented)

#ifndef __APPLE__
+ (void) load
{ // install handler for forwarding
	__objc_msg_forward2 = gs_objc_msg_forward2;
}
#endif

- (NSString *) _typeString	{ return [NSString stringWithUTF8String:methodTypes]; }

- (struct NSArgumentInfo *) _argInfo:(unsigned) index
{ // collect all information from methodTypes in a platform independent way and allocate integer, floating point registers and stack values
	if(info == NULL)
		{ // calculate method info
#ifndef __APPLE__
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
					types = next_arg(types, &info[i]);
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
					info[i].isReg=NO;	// default is to pass-on-stack
					if(info[i].align < MIN_ALIGN)
						info[i].align=MIN_ALIGN;
#if defined(i386)
					// i386 has different alignment rules for structs and stack
					// next_arg returns alignment for structs so we have to fix for stack
					// http://www.wambold.com/Martin/writings/alignof.html
					if(*t == _C_DBL)
						info[i].align = __alignof__(float);
#endif
#if defined(__ARM_PCS_VFP)	// armhf - don't know/care about armel yet
					if(*t == _C_LNG_LNG || *t == _C_ULNG_LNG)
						info[i].align = __alignof__(long);
#endif
					if(i == 0)
						{ // return value
							if(!INDIRECT_RETURN(info[0]))
								{ // keep as !byRef
									i++;
									continue;
								}
							info[0].byRef=YES;	// use register/stack to indirectly reference
							needs=sizeof(void *);	// we need a struct pointer...
						}
					else
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
					else if(nextireg < offsetof(struct stackframe, fpuregs))
						{ // yes, fits into the integer register area
						  // make this all dependend on sizeof(copied)-sizeof(iregs)
						  // so that we theoretically can specify more than one "real" register
							if(nextireg == offsetof(struct stackframe, iregs))
								{ // first register that is allocated is "real"
									info[i].isReg=YES;
									info[i].offset = nextireg;
								}
							else
								info[i].offset = ROUND(nextireg - offsetof(struct stackframe, iregs[1]) - sizeof(((struct stackframe *) NULL)->copied), info[i].align);	// use negative offset relative to link register
							nextireg+=needs;
							if(nextireg > offsetof(struct stackframe, fpuregs))
								argFrameLength+=nextireg-offsetof(struct stackframe, fpuregs); // handle overflow into real stack
							i++;
							continue;
						}
					info[i].offset=ROUND(argFrameLength, info[i].align);	// offset relative to frame pointer
					argFrameLength=info[i].offset+needs;
					i++;
				}
			numArgs = i-1;	// return type does not count
#if 0
			NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
#endif
		}
#if 0	// still needed?
	if(!info[0].byRef)
		info[0].offset=argFrameLength;	// unless returned indirectly through r0, place return value behind all arguments
										// FIXME: how to return float values?
#endif
#if 1
	[self _logMethodTypes];
#endif
	if(index > numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %u too high (%d).", index, numArgs];
	return &info[index];
}

- (void *) _frameDescriptor;
{
#ifndef __APPLE__
	return (void *) cif;
#else
	NIMP;
	return NULL;
#endif
}

@end

@implementation NSMethodSignature (NSPrivate)

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

- (const char *) _methodTypes	{ return methodTypes; }

#if FIXMEFIXME

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
		NSLog(@"arg[%2d]:%p %+4ld %+4ld %p %12ld %12g %12lg%@", i,
			  &af[i],
			  (char *) &af[i] - (char *) &af[0],
			  (char *) &af[i] - (char *) f->fp,
			  af[i],
			  (long) af[i],
			  *(float *) &af[i],
			  *(double *) &af[i],
			  note);
		}
}
#endif

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

- (NSUInteger) _getArgumentLengthAtIndex:(NSInteger) index;
{
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	return info[index+1].size;
}

- (NSUInteger) _getArgumentQualifierAtIndex:(NSInteger) index;
{
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	return info[index+1].qual;
}

static inline void *_getArgumentAddress(void *frame, int i)
{
	if(!frame)
		[NSException raise:NSInternalInconsistencyException format:@"missing stack frame"];
	// requires that argument pointers are initialized!
	return &((void **) frame)[i];
}

- (const char *) _getArgument:(void *) buffer fromFrame:(void *) _argframe atIndex:(NSInteger) index;
{ // extract argument from frame
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	addr=_getArgumentAddress(_argframe, index+1);
#if 1
	NSLog(@"_getArgument[%ld]:%p offset=%d addr=%p[%d] isReg=%d byref=%d double=%d type=%s", (long)index, buffer, info[index+1].offset, addr, info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble, info[index+1].type);
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

- (void) _setArgument:(void *) buffer forFrame:(void *) _argframe atIndex:(NSInteger) index retainMode:(enum _INVOCATION_MODE) mode;
{
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	addr=_getArgumentAddress(_argframe, index+1);
#if 1
	NSLog(@"_setArgument[%ld]:%p offset=%d addr=%p[%d] isReg=%d byref=%d double=%d type=%s mode=%d", (long)index, buffer, info[index+1].offset, addr, info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].floatAsDouble, info[index+1].type, 1);
#endif
	if(mode != _INVOCATION_ARGUMENT_SET_NOT_RETAINED && info[index+1].type[0] == _C_CHARPTR)
		{ // retain/copy C-strings if needed
			if(buffer && *(char **)buffer == *(char **)addr)
				return;	// no need to change
			if(((*(char **)addr) && mode == _INVOCATION_ARGUMENT_SET_RETAINED) || mode == _INVOCATION_ARGUMENT_RELEASE)
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
				{ // release current value
#if 1
					NSLog(@"_setArgument release old %@", *(id*)addr);
#endif
					[*(id*)addr autorelease];	// this makes retainCount compatible with OS X
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
 * we allocate a buffer that starts with a pointer array to speed up the call:
 * and then data areas for all arguments
 * the first pointer is for the return value
 */

- (void *) _allocArgFrame:(void *) frame
{ // (re)allocate stack frame
	if(!frame)
		{ // allocate a new buffer that is large enough to hold the space for frameLength arguments and methodReturnLength
			unsigned int len;
			int i;
			NEED_INFO();	// get valid argFrameLength and methodReturnLength
			len=sizeof(void *) * numArgs + info[0].size; + argFrameLength;
			frame=(void *) objc_calloc(len, sizeof(char));
#if 0
			NSLog(@"allocated frame=%p..%p framelength=%d len=%d", frame, len + (char*) frame, argFrameLength, len);
#endif
			for(i=0; i<numArgs; i++)
				((void **) frame)[i]=&((void **) frame)[i];	// set up retval and argument pointers
		}
	else
		{ // clear return value (if there is no setReturnValue for a forwardInvocation:
			memset(_getArgumentAddress(frame, 0), 0, info[0].size);
		}
	return frame;
}

- (BOOL) _call:(void *) imp frame:(void *) _argframe;
{ // call implementation and pass values from argframe buffer
  // use ffi_arg type?
	ffi_call(cif, imp, *(void **) _argframe, ((void **) _argframe)+1);
	return YES;
}

@end  /* NSMethodSignature (NSPrivate) */

