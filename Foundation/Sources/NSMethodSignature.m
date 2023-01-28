/*
 NSMethodSignature.m

 Implementation of NSMethodSignature for mySTEP
 This class encapsulates all CPU specific specialities

 Note that the stack frame storage (retval and args) is not part of the NSMethodSignature
 because multiple NSInvocations may share the same NSMethodSignature

 Copyright (C) 1994, 1995, 1996, 1998 Free Software Foundation, Inc.

 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	August 1994
 Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	August 1998
 Rewrite: Nikolaus Schaller <hns@computer.org> - remove as much of mframe as possible and only rely on gcc/libobjc
 Date:	November 2003, Jan 2006-2007,2011-2013
 Rewrite: Nikolaus Schaller <hns@computer.org> - remove as much of mframe as possible and only rely on libffi
 Date:	November 2016

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.

 */

#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "NSPrivate.h"
#include <objc/message.h>
#include <ffi.h>
#include <sys/mman.h>   // for mmap()

struct NSArgumentInfo
{ // internal Info about layout of arguments. Extended from the original OpenStep version - no longer available in OSX
	const char *type;				// type (pointer to first type character)
	NSInteger offset;				// can potentially be negative (!)
	NSUInteger size;				// size (not reliable!)
	/* extensions */
	NSUInteger align;				// alignment
	ffi_type *ffitype;				// pointer to some ffi type
	unsigned short qual;			// qualifier bits (oneway, byref, bycopy, in, inout, out)
#if 1
	BOOL isReg;						// signature says it is passed in a register (+) and not on stack
#endif
#if 1 || OLD
	// FIXME: if we always have byref we can remove this variable
	BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
									// always YES
#endif
};

#define cif ((ffi_cif *)internal1)
#define cif_types ((ffi_type **)internal2)

/* forwarding */

@interface _NSFFIClosure : NSObject
{
	ffi_closure *_closure;
}
- (id) initWithImp:(IMP *) imp;
- (void *) closure;
@end

@implementation _NSFFIClosure

- (id) initWithImp:(IMP *) imp;
{
	if(self=[super init])
		{
		_closure=ffi_closure_alloc(sizeof(ffi_closure), (void **) imp);	// allocate writable memory
		}
	return self;
}

- (void *) closure; { return _closure; }

- (void) dealloc
{
	if(_closure)
		ffi_closure_free(_closure);
	[super dealloc];
}

@end

static void mySTEP_closureCallback(ffi_cif *cifp, void *retp, void **args, void *user)
{ // wrap into NSInvocation and call -forwardInvocation (if possible)
	void *frame;
#if 0
	fprintf(stderr, "mySTEP_closureCallback called\n");
#endif
	NSMethodSignature *sig=(NSMethodSignature *) user;
	NSUInteger numArgs=[sig numberOfArguments];
	int len=sizeof(void *) * (numArgs+1);
	NSInvocation *inv;
	id target;
	OBJC_CALLOC(frame, char, len);
	((void **) frame)[0]=retp;
	memcpy(&((void **) frame)[1], args, numArgs*sizeof(*args));	// copy data area pointers
	inv=[[[NSInvocation alloc] _initWithMethodSignature:sig argFrame:frame] autorelease];	// wrap passed arguments into NSInvocation
	[sig _setArgument:NULL forFrame:frame atIndex:-1 retainMode:_INVOCATION_ARGUMENT_SET_NOT_RETAINED];	// nullify return value
	target=[inv target];
#if 0
	NSLog(@"signature=%@", sig);
	NSLog(@"self=%@", target);
	NSLog(@"_cmd=%@", NSStringFromSelector([inv selector]));
#endif
	if (!class_respondsToSelector(object_getClass(target),
								  @selector(forwardInvocation:)))
		{
		SEL selector=[inv selector];
		[NSException raise: NSInvalidArgumentException
					format: @"Class '%s' does not respond to forwardInvocation: for '%c%s'",
							class_getName(object_getClass(target)),
							(class_isMetaClass(object_getClass(target)) ? '+' : '-'),
							selector ? sel_getName(selector) : "(null)"];
		}
	[target forwardInvocation:inv];
}

// note: if this returns NULL, the objc runtime will try old style builtin_apply based forwarding!

static IMP mySTEP_objc_msg_forward2(id receiver, SEL sel)
{
	NSMethodSignature *sig=nil;
	const char *types=NULL;
	Method m;
	Class c;
	if(!receiver)
		{ /* waht does this mean? */
		fprintf(stderr, "mySTEP_objc_msg_forward2 called with nil receiver\n");
		abort();
		}
#if 1
	fprintf(stderr, "mySTEP_objc_msg_forward2 called\n");
	c=object_getClass(receiver);
	if(strcmp(class_getName(c), "Object") == 0)
		{
		fprintf(stderr, "mySTEP_objc_msg_forward2 called with Object receiver\n");
		abort();
		}
	fprintf(stderr, "selector = %s\n", [NSStringFromSelector(sel) UTF8String]);
	fprintf(stderr, "receiver = %s\n", [[receiver description] UTF8String]);
#endif
	c=object_getClass(receiver);
	/* may trigger a call to +resolveInstanceMethod: */
	m=class_getInstanceMethod(c, sel);
	if(m)
		types=method_getTypeEncoding(m);
#if 1
	fprintf(stderr, "types = %s\n", types);
#endif
	if(types)
		sig=[NSMethodSignature signatureWithObjCTypes:types];
	if(!sig)
		{ // proxy expects that we call methodSignatureForSelector: and forwardInvocation:
		if(class_respondsToSelector(c, @selector(methodSignatureForSelector:)))
			sig=[receiver methodSignatureForSelector:sel];
		}
	if(!sig)	// still unknown
			[NSException raise: NSInvalidArgumentException
						format: @"%c[%s %s]: unrecognized selector sent to instance %p",
								(class_isMetaClass(c) ? '+' : '-'),
								class_getName(c), sel_getName(sel), receiver];
#if 1
	NSLog(@"mySTEP_objc_msg_forward2: sig = %@", sig);
#endif
#if 0
	//	*((long *)1) = 1;	// segfault into debugger
	/* debug */ if(!sig) sig = [NSMethodSignature signatureWithObjCTypes:"v@::"];
#endif
	return [sig _forwardingImplementation:(void (*)(void)) mySTEP_closureCallback];
}

/* ffi_types */

static void free_ffi_type(ffi_type *type)
{
#ifdef __APPLE__
	if(type == NULL)
		mySTEP_objc_msg_forward2(nil, NULL);	// silence compiler warning about unused function
#endif
#if 0
	NSLog(@"free ffi_type %p %d", type, type->type);
#endif
	if(type->type == FFI_TYPE_STRUCT)
		{ // has been malloc'ed
			ffi_type **e=type->elements;
			while(*e)
				free_ffi_type(*e++);	// release all subelements
			objc_free(type->elements);
			objc_free(type);
		}
}

static ffi_type *parse_ffi_type(const char **typePtr)
{ // returns NULL on error
	const char *t=*typePtr;
#if 0
	NSLog(@"type 1: %s", t);
#endif
	while(*t)
		{
		switch(*t++) {
			default:
				continue;
			case '=':
				*typePtr=t;	// skip optional variable name
				break;
			case _C_ARY_B:
			case _C_ARY_E:
			case _C_STRUCT_B:
			case _C_STRUCT_E:
			case _C_UNION_B:
			case _C_UNION_E:
				break;
		}
		break;
		}
#if 0
	NSLog(@"type 2: %s", *typePtr);
#endif
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
		case _C_PTR: {
#if 0
			NSLog(@"type 3: %s", *typePtr);
#endif
			if(**typePtr == _C_UNDEF)
				(*typePtr)++;	// ^?
			else
				{ // type follows, e.g. ^{_NSPoint=ff}
				ffi_type *f=f=parse_ffi_type(typePtr);
				if(!f)
					return NULL;	// failed
				free_ffi_type(f);	// we don't store/need it
				}
#if 0
			NSLog(@"type 4: %s", *typePtr);
#endif
			return &ffi_type_pointer;
		}
		case _C_ARY_B: {
			NSUInteger size=0;
			ffi_type *f;
			while (isdigit(**typePtr))
				size=10*size+*(*typePtr)++-'0';	// collect array dimensions
			f=parse_ffi_type(typePtr); // type follows, e.g. [5L]
			if(!f)
				return NULL;	// failed
			free_ffi_type(f);	// we don't store/need it
			if(*(*typePtr)++ != _C_ARY_E)
				return NULL;	// missing ]
			return &ffi_type_pointer;
		}
		case _C_STRUCT_B: {
			NSUInteger nelem;
			NSUInteger i=0;
			ffi_type *composite=(ffi_type *) objc_malloc(sizeof(ffi_type));
			composite->size=0;
			composite->alignment=0;
			composite->type=FFI_TYPE_STRUCT;
			composite->elements=(ffi_type **) objc_calloc((nelem=4), sizeof(ffi_type *));
#if 0
			NSLog(@"  struct 1: %s", *typePtr);
#endif
			while((**typePtr && **typePtr != _C_STRUCT_E))
				{ // process elements
#if 0
					NSLog(@"  struct 2: %s", *typePtr);
#endif
					if(i+1 >= nelem)
						composite->elements=(ffi_type **) objc_realloc(composite->elements, (nelem=2*nelem+3)*sizeof(ffi_type *));
					composite->elements[i]=parse_ffi_type(typePtr);
					if(composite->elements[i] == NULL)
						{ // release any memory allocated for sub-structs
						free_ffi_type(composite);
						return NULL;
						}
#if 0
					NSLog(@"  -> %p", composite->elements[i]);
#endif
					composite->elements[++i]=NULL;	// always keep an end-of-list indicator
				}
#if 0
			NSLog(@"  struct 3: %s", *typePtr);
#endif
			if (**typePtr == _C_STRUCT_E)
				(*typePtr)++;
#if 0
			NSLog(@"  struct 4: %s", *typePtr);
#endif
			return composite;
		}
		case _C_UNION_B: {
			return NULL;	// can't handle

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
{ // NOTE: since NSMethodSignatures are cached this will never happen
	OBJC_FREE((void*) methodTypes);
	if(info)
		{ // release dynamically allocated struct elements
		unsigned int i;
		for(i=0; i<=numArgs; i++)
			free_ffi_type(info[i].ffitype);
		}
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
	// FIXME: strip off offsets if included
	// i.e. we should better compare numArgs and individual _argInfo[]
	if(strcmp([self _methodTypes], [other _methodTypes]) != 0)
		return NO;
	return [super isEqual:other];
}

- (NSUInteger) hash;
{
	// FIXME: if equal they could have the same hash
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
	__objc_msg_forward2 = mySTEP_objc_msg_forward2;
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
					// FIXME: we always use byRef because we have pointers into the data area of a frame
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
					// FIXME: we should truncate info[i].type at types...
					// or make a copy with strncpy
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
#if 0
					NSLog(@"t1: %s", t);
#endif
					info[i].ffitype=parse_ffi_type(&t);
#if 0
					NSLog(@"t2: %s", t);
#endif
					if(!info[i].ffitype)
						[NSException raise: NSInternalInconsistencyException format: @"can't parse encoding type %s.", types];
#if 1	// a comment in encoding.c source says a '+' was stopped to be generated at gcc 3.4
					info[i].isReg = NO;
					if(*types == '+' || *types == '-')
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
		OBJC_MALLOC(internal1, ffi_cif, 1);	// allocates cif
		OBJC_MALLOC(internal2, ffi_type, space=1+numArgs);	// allocates cif_types
		for(i=0; i<=numArgs; i++)
			cif_types[i]=info[i].ffitype;
		if((r=ffi_prep_cif(cif, FFI_DEFAULT_ABI, numArgs, cif_types[0], &cif_types[1])) != FFI_OK)
			[NSException raise: NSInvalidArgumentException format: @"Invalid types"];
#if 0
		[self _logMethodTypes];
#endif
		}
	return (void *) cif;
}

@end

@implementation NSMethodSignature (NSPrivate)

static NSMapTable *__methodSignatures;	// map C signature to NSMethodSignature

- (id) _initWithObjCTypes:(const char *) t;
{
	NSMethodSignature *sig;
	if(!__methodSignatures)
		__methodSignatures=NSCreateMapTable(NSNonOwnedCStringMapKeyCallBacks,
											NSObjectMapValueCallBacks, 0);
	if((sig=(NSMethodSignature *) NSMapGet(__methodSignatures, t)))
		{ // look up by type - if already known
#if 0
			NSLog(@"_initWithObjCTypes found in cache: %s -> %@", t, sig);
#endif
			[self release];
			return [sig retain];	// replace by cached NSMethodSignature
		}
#if 0
	NSLog(@"_initWithObjCTypes: %s", t);
#endif
	if((self=[super init]))
		{
		OBJC_MALLOC(methodTypes, char, strlen(t)+1);
		strcpy(methodTypes, t);	// save original C string - also used for indexing
#if 0
		NSLog(@"NSMethodSignature -> %s", methodTypes);
#endif
		NSMapInsert(__methodSignatures, methodTypes, self); // save in cache!
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

static inline void *_getArgumentAddress(void *frame, int i, BOOL byRef)
{
	if(!frame)
		[NSException raise:NSInternalInconsistencyException format:@"missing stack frame"];
	// requires that argument pointers are initialized!
	if(byRef)		// NOTE: with libffi we always have byRef=YES
		return ((void **) frame)[i];	// fetch i-th pointer into frame
	[NSException raise:NSInternalInconsistencyException format:@"can do byRef only"];
	return NULL;
}

/* NOTE: the following functions use index -1 for the return value and 0 for the first argument! */

- (const char *) _getArgument:(void *) buffer fromFrame:(void *) _argframe atIndex:(NSInteger) index;
{ // extract argument from frame
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", index, numArgs];
	addr=_getArgumentAddress(_argframe, index+1, info[index+1].byRef);
#if 0
	NSLog(@"_getArgument[%ld]:%p offset=%lu addr=%p[%lu] isReg=%d byref=%d type=%s", (long)index, buffer, (unsigned long)info[index+1].offset, addr, (unsigned long)info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].type);
#endif
#if 0
		NSLog(@"_getArgument memcpy(%p, %p, %lu);", buffer, addr, (unsigned long)info[index+1].size),
#endif
	memcpy(buffer, addr, info[index+1].size);
	return info[index+1].type;
}

- (void) _setArgument:(void *) buffer forFrame:(void *) _argframe atIndex:(NSInteger) index retainMode:(enum _INVOCATION_MODE) mode;
{
	char *addr;
	NEED_INFO();
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d out of range (-1 .. %d).", (long)index, numArgs];
	addr=_getArgumentAddress(_argframe, index+1, info[index+1].byRef);
#if 0
	NSLog(@"_setArgument[%ld]:%p offset=%lu addr=%p[%lu] isReg=%d byref=%d type=%s mode=%d", (long)index, buffer, (unsigned long)info[index+1].offset, addr, (unsigned long)info[index+1].size, info[index+1].isReg, info[index+1].byRef, info[index+1].type, mode);
#endif
	if(mode != _INVOCATION_ARGUMENT_SET_NOT_RETAINED && info[index+1].type[0] == _C_CHARPTR)
		{ // retain/copy C-strings if needed
			if(buffer && *(char **)buffer == *(char **)addr)
				return;	// no need to change
			if(((*(char **)addr) && mode == _INVOCATION_ARGUMENT_SET_RETAINED) || mode == _INVOCATION_ARGUMENT_RELEASE)
				{
#if 0
				NSLog(@"_setArgument free old %s", *(char **)addr);
#endif
				OBJC_FREE(*(char **)addr);
				}
			if(buffer && (*(char **)buffer) && mode == _INVOCATION_ARGUMENT_SET_RETAINED)
				{
				char *tmp;
#if 0
				NSLog(@"_setArgument copy new %s", *(char **)buffer);
#endif
				OBJC_MALLOC(tmp, char, strlen(*(char **)buffer)+1);
				strcpy(tmp, *(char **)buffer);
				*(char **)buffer=tmp;
				}
			else if(mode == _INVOCATION_ARGUMENT_RETAIN)
				{
				char *tmp;
#if 0
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
#if 0
					NSLog(@"_setArgument release old %@", *(id*)addr);
#endif
					[*(id*)addr autorelease];	// this makes retainCount compatible with OS X
				}
			if(buffer && mode == _INVOCATION_ARGUMENT_SET_RETAINED)
				{
#if 0
				NSLog(@"_setArgument retain new %@", *(id*)buffer);
#endif
				[*(id*)buffer retain];
				}
			else if(mode == _INVOCATION_ARGUMENT_RETAIN)
				{
#if 0
				NSLog(@"_setArgument retain current %p", addr);
				NSLog(@"_setArgument retain current %p", *(id*)addr);
				NSLog(@"_setArgument retain current %@", *(id*)addr);
#endif
				[*(id*)addr retain];
				return;	// retain but ignore buffer
				}
		}
	if(buffer)
		{
#if 0
		NSLog(@"_setArgument memcpy(%p, %p, %lu);", addr, buffer, (unsigned long)info[index+1].size),
#endif
		memcpy(addr, buffer, info[index+1].size);
		}
	else if(mode != _INVOCATION_ARGUMENT_RELEASE)
		{ // wipe out (used for handling the return value of -invoke with nil target)
#if 0
		NSLog(@"_setArgument memset(%p, %ul, %lu);", addr, 0, (unsigned long)info[index+1].size),
#endif
		memset(addr, 0, info[index+1].size);
		}
}

/*
 * we allocate a buffer that starts with a pointer array to speed up the _call:
 * and then data areas for all arguments (unless args are provided)
 * the first pointer is for the return value
 */

- (void *) _allocArgFrame;
{ // allocate a new buffer that is large enough to hold the space for frameLength arguments and methodReturnLength
	void *frame;
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
		{ // set up pointers into data area for returnValue and argument
		((void **) frame)[i]=argp+info[i].offset;
		}
	return frame;
}

- (BOOL) _call:(void *) imp frame:(void *) _argframe;
{ // call implementation and pass values from argframe buffer
	void **af=(void **) _argframe;
	if(!cif) [self _frameDescriptor];
#if 0
	NSLog(@"cif=%p imp=%p return=%p args=%p", cif, imp, *(void **) _argframe, ((void **) _argframe)+1);
#endif
	ffi_call(cif, imp, af[0], &af[1]);
	return YES;
}

- (IMP) _forwardingImplementation:(void (*)(void)) cb;
{ // define a fowarding IMP for the given signature and callback
	_NSFFIClosure *closure;
	IMP imp;	// the executable code (generated by ffi_prep_closure_loc)
	ffi_status status;
	if(!cif) [self _frameDescriptor];	// prepare cif
	// FIXME: why do we pass uninitialized imp here?
	closure=[[[_NSFFIClosure alloc] initWithImp:&imp] autorelease];
#if 0
	NSLog(@"_forwardingImplementation closure=%p imp=%p", closure, imp);
#endif
	if((status = ffi_prep_closure_loc([closure closure], cif, (void (*)(ffi_cif *, void *, void **, void *)) cb, self, imp)) != FFI_OK)
		return NULL;
	return imp;	// can be called until current ARP is drained
}

@end  /* NSMethodSignature (NSPrivate) */
