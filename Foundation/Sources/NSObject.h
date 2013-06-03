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

#ifdef __mySTEP__
struct __NSAllocationCount
{
	unsigned long alloc;				// number of +alloc
	unsigned long instances;		// number of instances (balance of +alloc and -dealloc)
	unsigned long linstances;		// last number of instances (when we did print the last time)
	unsigned long peak;					// maximum instances
	// could also count/balance retains&releases ??
};
extern unsigned long __NSAllocatedObjects;
@class NSMapTable;
extern NSMapTable *__NSAllocationCountTable;
#endif

static inline NSObject *NSAllocateObject(Class aClass, NSUInteger extra, NSZone *zone)							// object allocation
{
	id newobject=nil;
#ifdef __linux__
	if (CLS_ISCLASS (aClass))
		{
		unsigned size = aClass->instance_size + sizeof(struct _object_layout);
		if ((newobject = NSZoneMalloc(zone, size)) != nil)
			{
#if 1	// if we trace object allocation
				extern void __NSCountAllocate(Class aClass);
//				fprintf(stderr, "NSAllocateObject -> %p [%s alloc]\n", &((_object_layout)newobject)[1], aClass->name);
				__NSCountAllocate(aClass);
#endif
				memset (newobject, 0, size);
			newobject = (id)&((_object_layout)newobject)[1];
#ifdef __mySTEP__
			newobject->class_pointer = aClass;
#endif
			}
//				fprintf(stderr, "%08x [%s alloc:%d]\n", newobject, aClass->name, size);
			__NSAllocatedObjects++;	// one more
	}
#endif
	return newobject;
}

static inline void NSDeallocateObject(NSObject *anObject)					// object deallocation
{
#ifdef __linux__
	extern Class __zombieClass;
	if (anObject != nil)
		{
		_object_layout o = &((_object_layout)anObject)[-1];
#if 0
		fprintf(stderr, "NSDeallocateObject: %p [%s dealloc]\n", anObject, anObject->isa->name);
#endif
#if 1	// if we trace object allocation
			{
			extern void __NSCountDeallocate(Class aClass);
			__NSCountDeallocate([anObject class]);
			}
#endif
#ifdef __linux__
		((id)anObject)->class_pointer = (void *)__zombieClass;	// destroy class pointer
#endif
		objc_free(o);
		__NSAllocatedObjects--;	// one less
		}
#endif
}

static inline NSObject *NSCopyObject(NSObject *obj, unsigned int extraBytes, NSZone *zone)
{
	id newobject=nil;
#ifdef __linux__
	int size = ((id)obj)->class_pointer->instance_size + sizeof(struct _object_layout) + extraBytes;
	if ((newobject = NSZoneMalloc(zone, size)) != nil)
		{
		newobject = (id)&((_object_layout)newobject)[1];
		newobject->class_pointer = ((id)obj)->class_pointer;	// same as original
		}
	// fprintf(stderr, "%08x [%s copyObject:%d]\n", new, aClass->name, size);
	memcpy(newobject, obj, ((id)obj)->class_pointer->instance_size);
#endif
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
