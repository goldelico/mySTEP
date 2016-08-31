/*
 NSMethodSignature.m

 Implementation of NSMethodSignature for mySTEP
 This class encapsulates all CPU specific specialities

 Note that the stack frame storage is not part of the NSMethodSignature because several NSInvocations may share the same NSMethodSignature:

 Copyright (C) 1994, 1995, 1996, 1998 Free Software Foundation, Inc.

 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	August 1994
 Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	August 1998
 Rewrite: Nikolaus Schaller <hns@computer.org> - remove as much of mframe as possible and only rely on gcc/libobjc/libffi
 Date:    November 2003, Jan 2006-2007,2011-2016

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.

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
	NSInteger offset;				// can potentially be negative (!)
	NSUInteger size;				// size (not reliable!)
	/* extensions */
	NSUInteger align;				// alignment
	ffi_type *ffitype;				// pointer to some ffi type
	unsigned short qual;			// qualifier bits (oneway, byref, bycopy, in, inout, out)
	BOOL isReg;						// signature says it is passed in a register (+) and not on stack
#if 1 || OLD
	// FIXME: do we always have byref?
	BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
									// CHECKME: is this an architecture constant or for each individual parameter???
#endif
};

#define cif ((ffi_cif *)internal1)
#define cif_types ((ffi_type **)internal2)

/* forwarding */

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

// note: if this returns NULL, the objc runtime will try old style builtin_apply based forwarding!

static IMP gs_objc_msg_forward2(id receiver, SEL sel)
{
	NSMethodSignature *sig = nil;
	const char *types;
#if 1
	fprintf(stderr, "gs_objc_msg_forward2 called\n");
	fprintf(stderr, "receiver = %s\n", [[receiver description] UTF8String]);
	fprintf(stderr, "selector = %s\n", [NSStringFromSelector(sel) UTF8String]);
#endif
	*((long *)1) = 1;	// segfault into debugger
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
#endif
	/* debug */ if(!sig) sig = [NSMethodSignature signatureWithObjCTypes: "v@::"];
	return [sig _forwardingImplementation];
}

/* ffi_types */

static ffi_type *parse_ffi_type(const char **typePtr)
{ // returns NULL on error
	const char *t=strchr(*typePtr, '=');
	if(t)
		*typePtr=t+1;	// skip optional variable name
	switch(*(*typePtr)++) {
		default:		return NULL;	// unknown
		case _C_VOID:	return &ffi_type_void;
		case _C_ID:
		case _C_CLASS:
		case _C_SEL:	return &ffi_type_pointer;
		case _C_CHR:	return &ffi_type_sint8;
		case _C_UCHR:	return &ffi_type_uint8;
		case _C_SHT:	return &ffi_type_sint16;
		case _C_USHT:	return &ffi_type_uint16;
		case _C_INT:	return sizeof(int) == 4 ? &ffi_type_sint32 : &ffi_type_sint64;
		case _C_UINT:	return sizeof(unsigned int) == 4 ? &ffi_type_uint32 : &ffi_type_uint64;
		case _C_LNG:	return sizeof(long) == 4 ? &ffi_type_sint32 : &ffi_type_sint64;
		case _C_ULNG:	return sizeof(unsigned long) == 4 ? &ffi_type_sint32 : &ffi_type_sint64;
		case _C_LNG_LNG:	return &ffi_type_sint64;
		case _C_ULNG_LNG:	return &ffi_type_uint64;
		case _C_FLT:		return &ffi_type_float;
		case _C_DBL:		return &ffi_type_double;
#if 0
		case _C_LDBL:		return &ffi_type_longdouble:
#endif
		case _C_ATOM:
		case _C_CHARPTR:	return &ffi_type_pointer;
		case _C_PTR:
			if(**typePtr == _C_UNDEF)
				(*typePtr)++;	// ^?
			else
				parse_ffi_type(typePtr); // type follows, e.g. ^{_NSPoint=ff}
			return &ffi_type_pointer;

			// FIXME: handle structs and arrays!

		case _C_ARY_B: {
			NSUInteger size=0;
			// allocate struct ffitype
			// set number of elements and sizes
			// for that, recursively process starting at info->type+1
			while (isdigit(**typePtr))
				size=10*size+*(*typePtr)++-'0';	// collect array dimensions
			// type follows
			if(*(*typePtr)++ == _C_ARY_E)
				(*typePtr)++;
			return &ffi_type_pointer;
		}
		case _C_STRUCT_B: {
			// FIXME: recursively allocate ffi_type for struct
			// how do we do memory management?
#if 0
			NSLog(@"  struct 1: %s", *typePtr);
#endif
			while((**typePtr && **typePtr != _C_STRUCT_E))
				{ // process elements
#if 0
					NSLog(@"  struct 2: %s", *typePtr);
#endif
					parse_ffi_type(typePtr);
				}
#if 0
			NSLog(@"  struct 3: %s", *typePtr);
#endif
			if (**typePtr == _C_STRUCT_E)
				(*typePtr)++;
#if 0
			NSLog(@"  struct 4: %s", *typePtr);
#endif
			return &ffi_type_pointer;
		}
		case _C_UNION_B: {
			// FIXME: allocate ffitype with subtypes
#if 0
			NSLog(@"  union 1: %s", *typePtr);
#endif
			while((**typePtr && **typePtr != _C_UNION_E))
				{ // process elements
#if 0
					NSLog(@"  union 2: %s", *typePtr);
#endif
					parse_ffi_type(typePtr);
				}
			if (**typePtr == _C_UNION_E)
				(*typePtr)++;
			return &ffi_type_pointer;
		}
	}
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
	OBJC_FREE((void*) methodTypes);
	OBJC_FREE((void*) info);
	OBJC_FREE((void*) internal1);
	OBJC_FREE((void*) internal2);
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
{ // collect all information from methodTypes in a platform independent way
	if(info == NULL)
		{ // calculate method info
			const char *types = methodTypes;
			int i=0;
			int allocArgs=6;	// this is usually enough, i.e. retval+self+_cmd+3 args
			int needs;
			argFrameLength=0;	// offset on stack
#if 0
			NSLog(@"methodInfo create for types %s", methodTypes);
#endif
			OBJC_MALLOC(info, struct NSArgumentInfo, allocArgs);
			while(*types)
				{ // process all types
					const char *t;
#if 0
					NSLog(@"%d: %s", i, types);
#endif
					if(i >= allocArgs)	// we need more memory
						OBJC_REALLOC(info, struct NSArgumentInfo, allocArgs+=5);
					info[i].qual = 0;	// start with no qualifier
					info[i].isReg = NO;
					// FIXME: we always use byRef!
					// because we have pointers into the data area of a frame
					info[i].byRef = YES;
					for(; YES; types++)
						{ // Skip past any type qualifiers
						switch (*types) {
							case _C_CONST:  info[i].qual |= _F_CONST; continue;
							case _C_IN:     info[i].qual |= _F_IN; continue;
							case _C_INOUT:  info[i].qual |= _F_INOUT; continue;
							case _C_OUT:    info[i].qual |= _F_OUT; continue;
							case _C_BYCOPY: info[i].qual |= _F_BYCOPY; info[i].qual &= ~_F_BYREF; continue;
#ifdef _C_BYREF
							case _C_BYREF:  info[i].qual |= _F_BYREF; info[i].qual &= ~_F_BYCOPY; continue;
#endif
							case _C_ONEWAY: info[i].qual |= _F_ONEWAY; continue;
							default: break;
						}
						break;	// break loop if there was no continue
						}
					t=info[i].type=types;
					types=NSGetSizeAndAlignment(types, &info[i].size, &info[i].align);
					if(!types)
						break;	// some error
					if((info[i].qual & _F_INOUT) == 0)
						{ // set default qualifiers
							if(i == 0)
								info[i].qual |= _F_OUT;		// default to "bycopy out" for the return value
							else if(*t == _C_PTR || *t == _C_ATOM || *t == _C_CHARPTR)
								info[i].qual |= _F_INOUT;	// pointers default to "bycopy in/out"
							else
								info[i].qual |= _F_IN;		// others default to "bycopy in"
						}
					info[i].ffitype=parse_ffi_type(&t);
#if 1	// a comment in encoding.c source says a '+' was stopped to be generated at gcc 3.4
					info[i].isReg = NO;
					if(*types == '+')
						{ // register
							types++;
							info[i].isReg = YES;
						}
#endif
					info[i].offset = 0;
					while(isdigit(*types))
						info[i].offset = 10 * info[i].offset + (*types++ - '0');
					if(info[i].align < sizeof(void *))
						info[i].align=sizeof(void *);	// minimum alignment
					needs=((info[i].size+info[i].align-1)/info[i].align)*info[i].align;	// how much this needs incl. padding
					info[i].offset=ROUND(argFrameLength, info[i].align);	// offset relative to frame pointer
					argFrameLength=info[i].offset+needs;
					i++;
				}
			numArgs = i-1;	// return type does not count
#if 0
			NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
		}
#if 0
	[self _logMethodTypes];
#endif
	if(index > numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %u too high (%d).", index, numArgs];
	return &info[index];
}

- (void *) _frameDescriptor;
{
	if(!cif)
		{
		int i;
		int r;
		int space;
		NEED_INFO();
#if 0
		NSLog(@"_frameDescriptor");
#endif
		OBJC_CALLOC(internal1, ffi_cif, 1);	// allocates cif
		OBJC_CALLOC(internal2, ffi_type, space=1+numArgs);	// allocates cif_types
		for(i=0; i<=numArgs; i++)
			cif_types[i]=info[i].ffitype;
		if((r=ffi_prep_cif(cif, FFI_DEFAULT_ABI, numArgs, cif_types[0], &cif_types[1])) != FFI_OK)
			[NSException raise: NSInvalidArgumentException format: @"Invalid types"];
		}
	return (void *) cif;
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
		OBJC_MALLOC(methodTypes, char, strlen(t)+1);
		// strip off embedded offsets, i.e. convert from gcc to OpenSTEP format?
		strcpy(methodTypes, t);	// save unchanged
#if 0
		NSLog(@"NSMethodSignature -> %s", methodTypes);
#endif
		}
	return self;
}

- (const char *) _methodTypes	{ return methodTypes; }


- (void) _logFrame:(void *) _argframe target:(id) target selector:(SEL) selector;
{
	int i;
	void **af=(void **) _argframe;
	NEED_INFO();	// get valid argFrameLength and methodReturnLength
	for(i=0; i <= numArgs; i++)
		{
		NSString *note=@"";
		// FIXME: af[i] is just a pointer to the data!
		if(target && af[i] == target) note=[note stringByAppendingString:@" self"];
		if(selector && af[i] == selector) note=[note stringByAppendingString:@" _cmd"];
		NSLog(@"arg[%2d]:%p %p %12ld %12g %12lg%@", i,
			  &af[i],
			  af[i],
			  (long) af[i],
			  *(float *) &af[i],
			  *(double *) &af[i],
			  note);
		}
}

- (void) _logMethodTypes;
{
	int i;
	NSLog(@"method Types %s:", methodTypes);
	for(i=0; i<=numArgs; i++)
		NSLog(@"   %3d: size=%02lu align=%01lu isreg=%d offset=%02ld qual=%x byRef=%d type=%s",
			  i-1, (unsigned long)info[i].size, (unsigned long)info[i].align,
			  info[i].isReg, (long)info[i].offset, info[i].qual,
			  info[i].byRef,
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
#if 0
	NSLog(@"_getArgument[%ld]:%p offset=%lu addr=%p[%lu] isReg=%d byref=%d type=%s", (long)index, buffer, (unsigned long)info[index+1].offset, addr, (unsigned long)info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].type);
#endif
	if(info[index+1].byRef)
		memcpy(buffer, *(void**)addr, info[index+1].size);
	else
		{
#if 0
		NSLog(@"_getArgument memcpy(%p, %p, %lu);", buffer, addr, (unsigned long)info[index+1].size),
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
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", (long)index, numArgs];
	addr=_getArgumentAddress(_argframe, index+1);
#if 0
	NSLog(@"_setArgument[%ld]:%p offset=%lu addr=%p[%lu] isReg=%d byref=%d type=%s mode=%d", (long)index, buffer, (unsigned long)info[index+1].offset, addr, (unsigned long)info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].type, 1);
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
				OBJC_FREE(*(char **)addr);
				}
			if(buffer && (*(char **)buffer) && mode == _INVOCATION_ARGUMENT_SET_RETAINED)
				{
				char *tmp;
#if 1
				NSLog(@"_setArgument copy new %s", *(char **)buffer);
#endif
				OBJC_MALLOC(tmp, char, strlen(*(char **)buffer)+1);
				strcpy(tmp, *(char **)buffer);
				*(char **)buffer=tmp;
				}
			else if(mode == _INVOCATION_ARGUMENT_RETAIN)
				{
				char *tmp;
#if 1
				NSLog(@"_setArgument copy current %s", *(char **)addr);
#endif
				OBJC_MALLOC(tmp, char, strlen(*(char **)buffer)+1);
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
		else
			{
#if 0
			NSLog(@"_setArgument memcpy(%p, %p, %lu);", addr, buffer, (unsigned long)info[index+1].size),
#endif
			memcpy(addr, buffer, info[index+1].size);
			}
		}
	else if(mode != _INVOCATION_ARGUMENT_RELEASE)
		{ // wipe out (used for handling the return value of -invoke with nil target)
			if(info[index+1].byRef)	// struct by reference
				memset(*(void**)addr, 0, info[index+1].size);
			else
				{
#if 1
				NSLog(@"_setArgument memset(%p, %ul, %lu);", addr, 0, (unsigned long)info[index+1].size),
#endif
				memset(addr, 0, info[index+1].size);
				}
		}
}

/*
 * we allocate a buffer that starts with a pointer array to speed up the _call:
 * and then data areas for all arguments
 * the first pointer is for the return value
 */

- (void *) _allocArgFrame:(void *) frame
{ // (re)allocate stack frame
	if(!frame)
		{ // allocate a new buffer that is large enough to hold the space for frameLength arguments and methodReturnLength
			unsigned int len;
			int i;
			char *argp;
			NEED_INFO();	// get valid argFrameLength and methodReturnLength
			len=sizeof(void *) * (numArgs+1) + info[0].size + argFrameLength;
			OBJC_CALLOC(frame, char, len);
			argp=((char *) frame) + sizeof(void *) * (numArgs+1);	// start behind argument pointers
#if 0
			NSLog(@"allocated frame=%p..%p framelength=%d len=%d", frame, len + (char*) frame, argFrameLength, len);
#endif
			for(i=0; i <= numArgs; i++)
				{ // set up retval and argument pointers into data area
				((void **) frame)[i]=argp+info[i].offset;
				}
		}
	else
		{ // clear return value (if there is no setReturnValue for a forwardInvocation:)
			memset(_getArgumentAddress(frame, 0), 0, info[0].size);
		}
#if 0
	[self _logFrame:frame target:nil selector:NULL];
#endif
	return frame;
}

- (BOOL) _call:(void *) imp frame:(void *) _argframe;
{ // call implementation and pass values from argframe buffer
	void **af=(void **) _argframe;
	if(!cif)
		[self _frameDescriptor];
#if 0
	NSLog(@"cif=%p imp=%p return=%p args=%p", cif, imp, *(void **) _argframe, ((void **) _argframe)+1);
#endif
	ffi_call(cif, imp, af[0], &af[1]);
	return YES;
}

- (IMP) _forwardingImplementation;
{
	// memory = cifframe_closure(sig, GSFFIInvocationCallback);

	IMP imp=[NSObject instanceMethodForSelector:@selector(nimp:)];
	NSLog(@"_forwardingImplementation imp = %p", imp);
	return imp;
}

@end  /* NSMethodSignature (NSPrivate) */

