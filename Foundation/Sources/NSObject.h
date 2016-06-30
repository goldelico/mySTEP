/* 
   NSObject.h

   Interface to NSObject

   Copyright (C) 1994, 1995, 1996 Free Software Foundation, Inc.
   
   Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	August 1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSObject
#define _mySTEP_H_NSObject

#define TRACE_OBJECT_ALLOCATION	1

// import everything we need from the basic runtime system (incl. POSIX headers)

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSZone.h>


@protocol NSObject

- (id) autorelease;
- (Class) class;
- (BOOL) conformsToProtocol:(Protocol *) aProtocol;
- (NSString *) description;
- (NSUInteger) hash;
- (BOOL) isEqual:(id) anObject;
- (BOOL) isKindOfClass:(Class) aClass;
- (BOOL) isMemberOfClass:(Class) aClass;
- (BOOL) isProxy;
- (id) performSelector:(SEL) aSelector;
- (id) performSelector:(SEL) aSelector withObject:(id) anObject;
- (id) performSelector:(SEL) aSelector withObject:(id) object1 withObject:(id) object2;
- (oneway void) release;
- (BOOL) respondsToSelector:(SEL) aSelector;
- (id) retain;
- (NSUInteger) retainCount;
- (id) self;
- (Class) superclass;
- (NSZone *) zone;

- (id) _nimp:(SEL) cmd;

@end

@protocol NSCopying
- (id) copyWithZone:(NSZone *) zone;
@end


@protocol NSMutableCopying
- (id) mutableCopyWithZone:(NSZone *) zone;
@end


@protocol NSCoding
- (void) encodeWithCoder:(NSCoder *) aCoder;
- (id) initWithCoder:(NSCoder *) aDecoder;
@end

@interface NSObject <NSObject, NSCoding>
{												
	Class isa;	// pointer to instance's class structure
}

+ (id) alloc;
+ (id) allocWithZone:(NSZone *) z;
+ (Class) class;
+ (BOOL) conformsToProtocol:(Protocol *) aProtocol;
+ (id) copyWithZone:(NSZone *) zone;
+ (NSString *) description;
+ (void) initialize;
+ (IMP) instanceMethodForSelector:(SEL) aSelector;
+ (NSMethodSignature *) instanceMethodSignatureForSelector:(SEL) aSelector;	// define in NSMethodSignature.h or NSClassDescription.h?
+ (BOOL) instancesRespondToSelector:(SEL) aSelector;
+ (BOOL) isSubclassOfClass:(Class) aClass;
+ (void) load;
+ (id) mutableCopyWithZone:(NSZone *) zone;
+ (id) new;
+ (void) poseAsClass:(Class) aClass; // deprecated
+ (void) setVersion:(NSInteger) aVersion;
+ (Class) superclass;
+ (NSInteger) version;

//- (unsigned long) classCode;	// -> NSScriptClassDescription
- (NSString *) className;
- (id) copy;
- (void) dealloc;
- (void) doesNotRecognizeSelector:(SEL) aSelector;
- (void) finalize;
- (id) forwardingTargetForSelector:(SEL) sel;
- (void) forwardInvocation:(NSInvocation *) anInvocation;
- (id) init;
- (IMP) methodForSelector:(SEL) aSelector;
- (NSMethodSignature *) methodSignatureForSelector:(SEL) aSelector;	// -> NSMethodSignature.h?
- (id) mutableCopy;
//- (NSDictionary *) scriptingProperties;	// -> NSScriptClassDescription
//- (void) setScriptingProperties:(NSDictionary *) properties;	// -> NSScriptClassDescription

@end

extern unsigned long __NSAllocatedObjects;
#ifdef TRACE_OBJECT_ALLOCATION
struct __NSAllocationCount
{
	NSUInteger alloc;				// number of +alloc
	NSUInteger instances;		// number of instances (balance of +alloc and -dealloc)
	NSUInteger linstances;		// last number of instances (when we did print the last time)
	NSUInteger peak;					// maximum instances
	// could also count/balance retains&releases ??
};
@class NSMapTable;
extern NSMapTable *__NSAllocationCountTable;
#endif

static inline NSObject *NSAllocateObject(Class aClass, NSUInteger extra, NSZone *zone)							// object allocation
{
	id newobject=nil;
#if 1
	fprintf(stderr, "NSAllocateObject: aClass = %p %s\n", aClass, class_getName(aClass));
#endif
#if 1
	fprintf(stderr, "  class_isMetaClass = %d\n", class_isMetaClass(aClass));
	fprintf(stderr, "  object_getClass = %p\n", object_getClass(aClass));
	fprintf(stderr, "  class_isMetaClass(object_getClass) = %d\n", class_isMetaClass(object_getClass(aClass)));
#endif
	if (class_isMetaClass(object_getClass(aClass)))
		{
		NSUInteger size = sizeof(_object_layout) + class_getInstanceSize(aClass) + extra;
		if ((newobject = NSZoneMalloc(zone, size)) != nil)
			{
#if TRACE_OBJECT_ALLOCATION	// if we trace object allocation
			extern void __NSCountAllocate(Class aClass);
			__NSCountAllocate(aClass);
#endif
			memset (newobject, 0, size);
			newobject = (id)&((_object_layout)newobject)[1];
			object_setClass(newobject, aClass);	// install class pointer
#if 0
			fprintf(stderr, "NSAllocateObject(%lu) -> %p [%s alloc]\n", size, &((_object_layout)newobject)[1], class_getName(aClass));
#endif
			}
#if 1
		fprintf(stderr, "%p [%s alloc:%lu]\n", newobject, class_getName(aClass), size);
#endif
		__NSAllocatedObjects++;	// one more
		}
	return newobject;
}

static inline void NSDeallocateObject(NSObject *anObject)					// object deallocation
{
	extern Class __zombieClass;
	if (anObject != nil)
		{
		_object_layout o = &((_object_layout)anObject)[-1];
#if 1
		fprintf(stderr, "NSDeallocateObject: %p [%s dealloc]\n", anObject, class_getName(object_getClass(anObject)));
#endif
#if TRACE_OBJECT_ALLOCATION	// if we trace object allocation
			{
			extern void __NSCountDeallocate(Class aClass);
			__NSCountDeallocate([anObject class]);
			}
#endif
		object_setClass((id)anObject, __zombieClass);	// install zombie class pointer
		objc_free(o);
		__NSAllocatedObjects--;	// one less
		}
}

static inline NSObject *NSCopyObject(NSObject *obj, NSUInteger extraBytes, NSZone *zone)
{
	id newobject=nil;
	NSUInteger size = sizeof(_object_layout) + class_getInstanceSize(object_getClass((id)obj)) /* + extra */;
	if ((newobject = NSZoneMalloc(zone, size)) != nil)
		{
		newobject = (id)&((_object_layout)newobject)[1];
#if 1
		fprintf(stderr, "%p [%s copyObject:%ul]\n", newobject, class_getName(object_getClass((id)obj)), size);
#endif
		object_setClass(newobject, object_getClass((id)obj));	// same as original
		memcpy(newobject, obj, size);
		}
	return newobject;
}

void NSIncrementExtraRefCount(id anObject);
BOOL NSDecrementExtraRefCountWasZero(id anObject);

typedef enum _NSComparisonResult 
{
	NSOrderedAscending = -1,
	NSOrderedSame, 
	NSOrderedDescending

} NSComparisonResult;

enum { NSNotFound = NSIntegerMax };

@interface NSObject (Miscellaneous)
- (id) _subclass:(SEL) cmd;
- (id) _error:(const char *)aString, ...;
@end

#if 0
@interface NSObject (Old)
- (BOOL) resolveClassMethod:(SEL) sel;
- (BOOL) resolveInstanceMethod:(SEL) sel;
@end
#endif

#endif /* _mySTEP_H_NSObject */
