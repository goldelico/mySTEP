/* 
   NSObjCRuntime.h

   Interface to ObjC runtime

   Copyright (C) 1995, 1997 Free Software Foundation, Inc.

   Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSObjCRuntime
#define _mySTEP_H_NSObjCRuntime

// include all important standard C libraries

#include <stddef.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <stdint.h>
#include <fcntl.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <assert.h>

#ifndef mySTEP_MAJOR_VERSION
#define mySTEP_MAJOR_VERSION	2
#define mySTEP_MINOR_VERSION	0
#endif

#define main objc_main						// redefine main() to objc_main()

// libobjc interface

// common

#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Protocol.h>

// new types that might appear in the AppKit API of 10.5

#if 0	// 64 bit processor
typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef double CGFloat;
typedef signed long CFIndex; 
#else	// 32 bit processor
typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;
typedef signed long CFIndex; 
#endif

typedef struct __CGEvent *CGEventRef;

#define NSIntegerMax   LONG_MAX
#define NSIntegerMin   LONG_MIN
#define NSUIntegerMax  ULONG_MAX

#ifdef __linux__			
// those from gcc but not available on MacOS X

#include <objc/encoding.h>
#include <objc/sarray.h>
#include <objc/thr.h>
#include <objc/objc-api.h>
#include <objc/objc-list.h>

// we don't have Obj-C 2.0 GC yet

#define __strong
#define __weak

#endif

#ifdef __APPLE__			
// MacOS X - translate libobjc to MacOS X calling conventions (if possible?)

#include <objc/objc-class.h>
#include <objc/objc-load.h>
#include <objc/objc-runtime.h>

#define arglist_t marg_list
#define retval_t void *

#define objc_malloc(A) malloc(A)
#define objc_free(A) free(A)
#define objc_calloc(A, B) calloc((A), (B))
#define objc_realloc(A, B) realloc((A), (B))

#define objc_get_class(NAME) ((Class)objc_lookUpClass((const char *) NAME))
#define objc_msg_lookup(OBJECT, SELECTOR) (class_getInstanceMethod(objc_get_class(OBJECT), SELECTOR)->method_imp)
#define objc_lookup_class(CLASS) ((Class)objc_lookUpClass((const char *) CLASS))

#define objc_sizeof_type(A) 1
#define objc_alignof_type(A) 1
#define objc_skip_typespec(A) (A)

#define objc_verror(OBJECT, CODE, FORMAT, ...)

#define objc_check_undefineds(FILE)
#define objc_invalidate_dtable(CLASS)
#define objc_initialize_loading(FILE) (0)

#define objc_load_callback(CLASS, CATEGORY)
#define objc_load_module(NAME, FILE, CALLBACK, HEADER, DEBUG) (0)
#define objc_dynamic_find_file(ADDRESS) (0)

#define objc_thread_set_data(THREAD)
#define objc_thread_get_data() (0)
#define objc_thread_detach(SELECTOR, THREAD, ARG) NULL
#define objc_thread_exit()

#define class_get_class_name(CLASS) "class name"
#define class_get_class_method(CLASS, SELECTOR) (void *)(class_getClassMethod(CLASS, SELECTOR)->method_imp)
#define class_get_instance_method(CLASS, SELECTOR) (void *)(class_getInstanceMethod(CLASS, SELECTOR)->method_imp)
#define class_get_meta_class(CLASS) Nil
#define class_get_super_class(CLASS) Nil
#define class_get_instance_size(CLASS) 10
#define class_get_version(CLASS) 1
#define class_is_class(CLASS) YES
#define class_pose_as(CLASS1, CLASS2)
#define class_set_version(CLASS, VERSION)

#define CLS_ISCLASS(PTR) NO
#define CLS_ISMETA(PTR) NO

#define object_get_class(OBJECT) Nil
#define object_is_instance(OBJECT) YES
#define object_is_class(OBJECT) NO
#define object_get_class_name(OBJECT) "class name"
#define object_get_super_class(OBJECT) (Class) Nil

#define method_get_imp(METHOD) METHOD
#define METHOD_NULL ((IMP) NULL)

#define sel_get_typed_uid(name, types) ((SEL)name)
#define sel_get_any_uid(name) ((SEL)name)
#define sel_get_any_typed_uid(X) ((SEL)name)
#define sel_get_name(X) (char *) (X)
#define sel_get_type(X) "x"
#define sel_types_match(A, B) NO
#define sel_register_typed_name(NAME, TYPE) ((SEL)name)

typedef void *objc_mutex_t;
typedef void *objc_condition_t;

// differs from GNU definition!
#define _C_CONST	'c'
#define _C_IN		'i'
#define _C_INOUT	'j'
#define _C_OUT		'o'
#define _C_BYCOPY	'b'
#define _C_ONEWAY	'-'
#define _C_BYREF	'r'

#define _C_LNG_LNG	'1'
#define _C_ULNG_LNG	'2'
#define _C_ATOM		'%'

#define _F_CONST	0x01
#define _F_IN		0x02
#define _F_INOUT	0x04
#define _F_OUT		0x08
#define _F_BYCOPY	0x10
#define _F_ONEWAY	0x20
#define _F_BYREF	0x40

#else

int objc_check_undefineds(FILE *errorStream);
void objc_invalidate_dtable(Class class);
int objc_initialize_loading(FILE *errorStream);
void objc_load_callback(Class class, Category *category);
long objc_load_module(const char *filename,
					  FILE *errorStream,
					  void (*loadCallback)(Class, Category*),
					  void **header,
					  char *debugFilename);
char *objc_dynamic_find_file(const void *address);

#endif

#define ROUND(V, A)  ({ typeof(V) __v=(V); typeof(A) __a=(A); \
	__a*((__v+__a-1)/__a); })

#define OBJC_MALLOC(VAR, TYPE, NUM) \
((VAR) = (TYPE *) objc_malloc ((unsigned)(NUM)*sizeof(TYPE))) 
#define OBJC_REALLOC(VAR, TYPE, NUM) \
((VAR) = (TYPE *) objc_realloc ((VAR), (unsigned)(NUM)*sizeof(TYPE)))
#define OBJC_FREE(PTR) objc_free (PTR)


#ifndef	YES
#define YES	1
#endif

#ifndef	NO
#define NO	0
#endif

#ifndef nil
#define nil (void *) 0
#endif

#ifndef Nil
#define Nil (Class) 0
#endif

#ifndef	INLINE
#define	INLINE inline
#endif

#ifndef ABS
#define ABS(a) ({typeof(a) _a = (a); _a < 0 ? -_a : _a; })
#endif

#ifndef SIGN
#define SIGN(x)  ({typeof(x) _x = (x); _x > 0 ? 1 : (_x == 0 ? 0 : -1); })
#endif

#ifndef SEL_EQ
#ifdef __linux__
#define SEL_EQ(sel1, sel2)	sel_eq(sel1, sel2)
#else
#define SEL_EQ(sel1, sel2)	(sel1 == sel2)
#endif
#endif

#ifndef MAX
#define MAX(a,b) ({typeof(a) _a = (a); typeof(b) _b = (b); _a > _b ? _a : _b;})
#endif

#ifndef MIN
#define MIN(a,b) ({typeof(a) _a = (a); typeof(b) _b = (b); _a < _b ? _a : _b;})
#endif

#define Strlen strlen
#define Strcmp strcmp

#ifndef PTR2LONG
#define PTR2LONG(P) (((char*)(P))-(char*)0)
#endif

#ifndef LONG2PTR
#define LONG2PTR(L) (((char*)0)+(L))
#endif

//// NOTE: these macros are only defined on GNUstep!

//
//	RETAIN(), RELEASE(), and AUTORELEASE() are placeholders for the
//	(possible)  future day when we have garbage collecting.
//

#ifndef RETAIN
#define	RETAIN(object)		[object retain]
#endif
#ifndef RELEASE
#define	RELEASE(object)		[object release]
#endif
#ifndef AUTORELEASE
#define	AUTORELEASE(object)	[object autorelease]
#endif
#ifndef DESTROY
#define	DESTROY(object)		{ id o=(object); object=nil; [o release]; }	// recursion safe destroy
#endif

//
//	ASSIGN(object,value) assignes the value to the object
//	with appropriate retain and release operations.
//  note: value may be an expression that allocates/copies etc. new objects - must be called only once!
//  note: retain first if we assign the same value as we have already assigned!
//
#ifndef ASSIGN
#define	ASSIGN(object,value) ({ id temp=(value); \
if (temp) \
	[(temp) retain]; \
								if (object) \
									[(object) release]; \
										object = (temp);	})
#endif
//
// Method that must be implemented by a subclass
//
#define SUBCLASS  [self _subclass:_cmd];

//
// Method that is not implemented and should not be called
//
#define NIMP  [self _nimp:_cmd];
#define SHOULDNIMP NIMP

//*****************************************************************************
//
// 		Define a wrapper structure around each NSObject to store the
//		reference count locally. 
//
//*****************************************************************************

typedef struct obj_layout_unpadded			// Define a structure to hold data locally before the start of each object
{
    unsigned retained;
} unp;

#define	UNP sizeof(unp)
#ifdef ALIGN
#undef ALIGN
#endif
#define	ALIGN __alignof__(double)	

// Now do the REAL version - using the other version to determine what padding if any is required to get the alignment of the structure correct.

typedef struct _object_layout 
{
	unsigned retained;
	char padding[ALIGN - ((UNP % ALIGN) ? (UNP % ALIGN) : ALIGN)];
	// the bytes defined by NSObject follow here
} *_object_layout;

@class NSArchiver;
@class NSCoder;
@class NSPortCoder;
@class NSMethodSignature;
@class NSRecursiveLock;
@class NSString;
@class NSInvocation;

extern SEL NSSelectorFromString(NSString *aSelectorName);
extern Class NSClassFromString(NSString *aClassName);
extern Protocol *NSProtocolFromString(NSString *aProtocolName);
extern NSString *NSStringFromSelector(SEL aSelector);
extern NSString *NSStringFromClass(Class aClass);
extern NSString *NSStringFromProtocol(Protocol *protocol);
extern const char *NSGetSizeAndAlignment(const char *typePtr,
										 unsigned int *sizep,
										 unsigned int *alignp);

extern void NSLog (NSString *format, ...);
extern void NSLogv(NSString *format, va_list args);

unsigned NSPageSize(void);
unsigned NSLogPageSize(void);
unsigned NSRoundDownToMultipleOfPageSize(unsigned bytes);
unsigned NSRoundUpToMultipleOfPageSize(unsigned bytes);
unsigned NSRealMemoryAvailable();
void *NSAllocateMemoryPages(unsigned bytes);
void NSDeallocateMemoryPages(void *ptr, unsigned bytes);
void NSCopyMemoryPages(const void *source, void *dest, unsigned bytes);

#ifdef DEBUG
#define NSDebugLog(format, args...)	NSLog(format, args...)
#else
#define NSDebugLog(format, args...)
#endif

// Global lock to be used by classes when operating on any 
// global data that invoke other methods which also access 
// global; thus, creating the potential for deadlock.

extern NSRecursiveLock *__NSGlobalLock;

static INLINE BOOL
_classIsKindOfClass(Class c, Class aClass)
{
	for (;c != Nil; c = class_get_super_class(c))
		if (c == aClass)
			return YES;

    return NO;
}

#endif /* _mySTEP_H_NSObjCRuntime */
