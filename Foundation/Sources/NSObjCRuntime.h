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
#define __EXPORTED_HEADERS__	// disable some warnings in gcc/Linux

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
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>

#ifndef mySTEP_MAJOR_VERSION
#define mySTEP_MAJOR_VERSION	3
#define mySTEP_MINOR_VERSION	0
#endif

// libobjc interface

#include <objc/objc.h>

// new objc API available since gcc 4.6
#if __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 6)
#include <objc/runtime.h>
#define OBJC_ROOT_CLASS
#define __NEW_OBJC_API
// check with #ifdef __GNU_LIBOBJC__
#else
#include <objc/objc-api.h>
#endif

#ifdef __APPLE__
#undef __OBJC2__	/* avoid problems with objc/Protocol.h on Xcode SDK */
#endif

// new types that might appear in the AppKit API of 10.5

#if __LP64__	// 64 bit processor
typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef double CGFloat;
enum CGRectEdge
{
	CGRectMinXEdge,
	CGRectMinYEdge,
	CGRectMaxXEdge,
	CGRectMaxYEdge
};
typedef enum CGRectEdge CGRectEdge;
typedef signed long CFIndex; 
#else	// 32 bit processor
typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;
enum CGRectEdge
{
	CGRectMinXEdge,
	CGRectMinYEdge,
	CGRectMaxXEdge,
	CGRectMaxYEdge
};
typedef enum CGRectEdge CGRectEdge;
typedef signed long CFIndex; 
#endif

typedef struct __CGEvent *CGEventRef;

#define NSIntegerMax	LONG_MAX
#define NSIntegerMin	LONG_MIN
#define NSUIntegerMax	ULONG_MAX
#ifndef LONG_LONG_MAX
#define LONG_LONG_MAX	LLONG_MAX
#define LONG_LONG_MIN	LLONG_MIN
#define ULONG_LONG_MAX	ULLONG_MAX
#endif

#ifdef __linux__			
// those from gcc but not available on MacOS X

#include <objc/thr.h>

#ifndef __NEW_OBJC_API
#include <objc/encoding.h>
#include <objc/sarray.h>
#include <objc/objc-list.h>
#endif

// we don't have Obj-C 2.0 GC yet

#define __strong
#define __weak

#endif

#ifdef __APPLE__			
// MacOS X - translate libobjc to MacOS X calling conventions (if possible?)
// this makes it compile but not run on MacOS X

#include <objc/objc-class.h>
#include <objc/objc-load.h>
#include <objc/objc-load.h>
#include <objc/objc-runtime.h>
#include <sys/malloc.h>

//#define arglist_t marg_list
//#define retval_t void *

#define objc_malloc(A) malloc(A)
#define objc_free(A) { if(A) free(A); }
#define objc_calloc(A, B) calloc((A), (B))
#define objc_realloc(A, B) realloc((A), (B))

int objc_alignof_type(const char *type);
int objc_sizeof_type(const char *type);
int objc_aligned_size(const char *type);
const char *objc_skip_typespec (const char *type);

#define objc_verror(OBJECT, CODE, FORMAT, ...)

#define objc_check_undefineds(FILE)
#define objc_invalidate_dtable(CLASS)
#define objc_initialize_loading(FILE) (0)

//#define objc_load_callback(CLASS, CATEGORY)
// #define objc_load_module(NAME, FILE, CALLBACK, HEADER, DEBUG) (0)
//#define objc_dynamic_find_file(ADDRESS) (0)

#define objc_thread_set_data(THREAD) fprintf(stderr, "can't objc_thread_set_data for %p\n", THREAD)
#define objc_thread_get_data() (fprintf(stderr, "can't objc_thread_get_data\n"), NULL)
#define objc_thread_detach(SELECTOR, THREAD, ARG) NULL
#define objc_thread_exit()

#if OLD_GNU_COMPATIBILITY

//#define objc_msg_lookup(OBJECT, SELECTOR) (class_getInstanceMethod(objc_get_class(OBJECT), SELECTOR)->method_imp)
//#define objc_lookup_class(CLASS) ((Class)objc_lookUpClass((const char *) CLASS))
#define objc_get_class(NAME) ((Class)objc_lookUpClass((const char *) NAME))
#define class_get_class_name(CLASS) class_getImageName(CLASS)
#define class_get_class_method(CLASS, SELECTOR) (void *)(class_getClassMethod(CLASS, SELECTOR)->method_imp)
#define class_get_instance_method(CLASS, SELECTOR) (void *)(class_getInstanceMethod(CLASS, SELECTOR)->method_imp)
#define class_get_meta_class(CLASS) Nil
//#define class_getSuperclass(CLASS) Nil
#define class_get_instance_size(CLASS) 10
#define class_get_version(CLASS) 1
#define class_is_class(CLASS) YES
#define class_pose_as(CLASS1, CLASS2)
#define class_set_version(CLASS, VERSION)

#define CLS_ISCLASS(PTR) NO
#define CLS_ISMETA(PTR) NO

//#define object_get_class(OBJECT) Nil
#define object_is_instance(OBJECT) YES
#define object_is_class(OBJECT) NO
#define object_get_class_name(OBJECT) "class name"
#define object_get_super_class(OBJECT) (Class) Nil

#define method_get_imp(METHOD) METHOD

#define sel_get_typed_uid(name, types) ((SEL)name)
#define sel_get_any_uid(name) ((SEL)name)
#define sel_register_name(name) ((SEL)name)
#define sel_get_any_typed_uid(X) ((SEL)name)
#define sel_get_name(X) (char *) (X)
#define sel_get_type(X) "x"
#define sel_types_match(A, B) NO
#define sel_register_typed_name(NAME, TYPE) ((SEL)name)

#endif

typedef void *objc_mutex_t;
typedef void *objc_condition_t;

// this differs from GNU definition!

#define _C_CONST	'r'
#define _C_IN		'n'
#define _C_INOUT	'N'
#define _C_OUT		'o'
#define _C_BYCOPY	'O'
#define _C_BYREF	'R'
#define _C_ONEWAY	'V'

#ifndef _C_LNG_LNG
#define _C_LNG_LNG	'q'
#define _C_ULNG_LNG	'Q'
#endif
#define _C_ATOM		'%'

#define _F_CONST	0x01
#define _F_IN		0x02
#define _F_INOUT	0x04
#define _F_OUT		0x08
#define _F_BYCOPY	0x10
#define _F_ONEWAY	0x20
#define _F_BYREF	0x40

#else	/* __Apple__ */

#include <malloc.h>
#include <objc/Protocol.h>

int objc_check_undefineds(FILE *errorStream);
void objc_invalidate_dtable(Class class);
int objc_initialize_loading(FILE *errorStream);

int objc_loadModule(char *filename,
					void (*loadCB)(Class, Category),
					int *error);

long objc_loadModules(char *list[],
					  void *errStream,
					  void (*loadCB) (Class, Category),
					  void **header,
					  char *debugfile);

long objc_unloadModules(void *errStream,
						void (*unloadCB)(Class, Category));


#endif

char *objc_moduleForAddress(const void *address);

#define ROUND(V, A)  ({ typeof(V) __v=(V); typeof(A) __a=(A); \
	__a*((__v+__a-1)/__a); })

#define OBJC_MALLOC(VAR, TYPE, NUM) \
((VAR) = (TYPE *) objc_malloc ((unsigned)(NUM)*sizeof(TYPE)))
#define OBJC_CALLOC(VAR, TYPE, NUM) \
((VAR) = (TYPE *) objc_calloc ((unsigned)(NUM), sizeof(TYPE)))
#define OBJC_REALLOC(VAR, TYPE, NUM) \
((VAR) = (TYPE *) objc_realloc ((VAR), (unsigned)(NUM)*sizeof(TYPE)))
#define OBJC_FREE(PTR) { if(PTR) objc_free (PTR); }


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

#ifdef __APPLE__	// & SDK before 10.5
#define sel_isEqual(A, B) ((A) == (B))
#else
extern BOOL sel_isEqual(SEL a, SEL b);	// we must declare the function for Debian-i386
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
//	note: value may be an expression that allocates/copies etc. new objects - must be called only once!
//	note: retain first if we assign the same value as we have already assigned!
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

// #define NIMP [NSException raise:NSGenericException format:@"%@ method %@ not implemented", NSStringFromClass([self class]), NSStringFromSelector(_cmd)], (id)nil]

#define SHOULDNIMP NIMP

//*****************************************************************************
//
//		Define a wrapper structure around each NSObject to store the
//		reference count locally.
//
//*****************************************************************************

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
										 NSUInteger *sizep,
										 NSUInteger *alignp);

extern void NSLog (NSString *format, ...);
extern void NSLogv(NSString *format, va_list args);

// extern unsigned NSPageSize(void);
// extern unsigned NSLogPageSize(void);
extern NSUInteger NSRoundDownToMultipleOfPageSize(NSUInteger bytes);
extern NSUInteger NSRoundUpToMultipleOfPageSize(NSUInteger bytes);
extern NSUInteger NSRealMemoryAvailable();
extern void *NSAllocateMemoryPages(NSUInteger bytes);
extern void NSDeallocateMemoryPages(void *ptr, NSUInteger bytes);
extern void NSCopyMemoryPages(const void *source, void *dest, NSUInteger bytes);
extern void __NSCountAllocate(Class aClass);
extern void __NSCountDeallocate(Class aClass);

extern int32_t NSVersionOfRunTimeLibrary(const char *libraryName);
extern int32_t NSVersionOfLinkTimeLibrary(const char *libraryName);
extern int _NSGetExecutablePath(char *buf, uint32_t *bufsize);

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
	for (;c != Nil; c = class_getSuperclass(c))
		if (c == aClass)
			return YES;

	return NO;
}

// helper for doing timing measurements

#define NS_TIME_START(VAR) { \
	struct timeval VAR, _ns_time_end; \
	fprintf(stderr, ">>> "); \
	gettimeofday(&VAR, NULL);

#define NS_TIME_END(VAR, MESSAGE...) \
	gettimeofday(&_ns_time_end, NULL); \
	_ns_time_end.tv_sec-=VAR.tv_sec; \
	_ns_time_end.tv_usec-=VAR.tv_usec; \
	if(_ns_time_end.tv_usec < 0) _ns_time_end.tv_sec-=1, _ns_time_end.tv_usec+=1000000; \
	if(_ns_time_end.tv_sec > 0 || _ns_time_end.tv_usec > 0) \
		fprintf(stderr, "<<< %u.%06ds: ", (unsigned int) _ns_time_end.tv_sec, _ns_time_end.tv_usec), \
		fprintf(stderr, MESSAGE), \
		fprintf(stderr, "\n"); \
	}

#if 1

#define LEAK(CALL) \
	{ \
	NSInteger p=__NSAllocatedObjects, p2; \
	NSAutoreleasePool *arp=[NSAutoreleasePool new]; \
	CALL; \
	[arp release]; \
	p2=__NSAllocatedObjects; \
	if(p2 != p) \
		NSLog(@"[%@ %@] allocation change %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), p2 - p); \
	}

#define LEAK_OBJ(CALL) \
	({ \
	id r; \
	NSInteger p=__NSAllocatedObjects, p2; \
	NSAutoreleasePool *arp=[NSAutoreleasePool new]; \
	r=CALL; \
	[r retain]; \
	[arp release]; \
	p2=__NSAllocatedObjects; \
	if(p2 != p) \
	NSLog(@"[%@ %@] allocation change %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), p2 - p); \
	[r autorelease]; \
	})

#else

#define LEAK(CALL) CALL
#define LEAK_OBJ(CALL) CALL

#endif

#endif /* _mySTEP_H_NSObjCRuntime */
