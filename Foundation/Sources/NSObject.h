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

OBJC_ROOT_CLASS
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

extern NSUInteger __NSAllocatedObjects;

NSObject *NSAllocateObject(Class aClass, NSUInteger extra, NSZone *zone);	// object allocation
void NSDeallocateObject(NSObject *anObject);	// object deallocation
NSObject *NSCopyObject(NSObject *obj, NSUInteger extraBytes, NSZone *zone);
NSUInteger NSGetExtraRefCount(id anObject);
void NSIncrementExtraRefCount(id anObject);
BOOL NSDecrementExtraRefCountWasZero(id anObject);

typedef enum _NSComparisonResult 
{
	NSOrderedAscending = -1,
	NSOrderedSame, 
	NSOrderedDescending

} NSComparisonResult;

enum { NSNotFound = NSIntegerMax };

#if 0
@interface NSObject (Miscellaneous)
- (id) _subclass:(SEL) cmd;
- (id) _nimp:(SEL) cmd;
@end
#endif

#if 0
@interface NSObject (Old)
- (BOOL) resolveClassMethod:(SEL) sel;
- (BOOL) resolveInstanceMethod:(SEL) sel;
@end
#endif

#endif /* _mySTEP_H_NSObject */
