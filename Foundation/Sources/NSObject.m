/*
 NSObject.m

 Implementation of NSObject

 Copyright (C) 1994, 1995, 1996 Free Software Foundation, Inc.

 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	August 1994

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#define REPORT_OBJECT_INITIALIZE 1

#include <limits.h>
#include <time.h>
#include <sys/time.h>

#ifdef __APPLE__
#include <objc/objc-api.h>
#endif

#import "NSPrivate.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSData.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDebug.h>

BOOL NSZombieEnabled=NO;
BOOL NSDeallocateZombies=NO;	// FIXME - not used
BOOL NSDebugEnabled=NO;
BOOL NSHangOnUncaughtException=NO;
BOOL NSEnableAutoreleasePool=YES;
BOOL NSAutoreleaseFreedObjectCheckEnabled=NO;

/* basic object memory allocation and refcount */

typedef struct	// Define a structure to hold data locally before the start of each object
{
	NSUInteger retained;
} _unp;

#define	UNP sizeof(_unp)
#ifdef ALIGN
#undef ALIGN
#endif
#define	ALIGN __alignof__(double)

// Now do the REAL version - using the other version to determine what padding if any is required to get the alignment of the structure correct.

typedef struct _object_layout
{
	NSUInteger retained;
	char padding[ALIGN - ((UNP % ALIGN) ? (UNP % ALIGN) : ALIGN)];
	// the bytes defined by NSObject follow here
} *_object_layout;

NSObject *NSAllocateObject(Class aClass, NSUInteger extra, NSZone *zone)
{ // object allocation
	id newobject=nil;
#if 0
	fprintf(stderr, "NSAllocateObject: aClass = %p %s\n", aClass, class_getName(aClass));
#endif
#if 0
	fprintf(stderr, "  class_isMetaClass = %d\n", class_isMetaClass(aClass));
	fprintf(stderr, "  object_getClass = %p\n", object_getClass(aClass));
	fprintf(stderr, "  class_isMetaClass(object_getClass) = %d\n", class_isMetaClass(object_getClass(aClass)));
	fprintf(stderr, "  class_getInstanceSize = %ld\n", class_getInstanceSize(aClass));
	fprintf(stderr, "  sizeof(_object_layout) = %ld\n", sizeof(_object_layout));
#endif
	if (class_isMetaClass(object_getClass(aClass)))
		{
		NSUInteger size = sizeof(_object_layout) + class_getInstanceSize(aClass) + extra;
#if 1
		// FIXME: this is a hack - there is a mismatch between sizeof(_object_layout) and what is really needed
		// so let's waste a little memory until we find out how much we really need to allocate
		size += 16;
#endif
		if ((newobject = NSZoneMalloc(zone, size)) != nil)
			{
			__NSCountAllocate(aClass);
			memset (newobject, 0, size);
			newobject = (id)&((_object_layout)newobject)[1];
			object_setClass(newobject, aClass);	// install class pointer
#if 0
			fprintf(stderr, "NSAllocateObject(%lu) -> %p [%s alloc]\n", size, &((_object_layout)newobject)[1], class_getName(aClass));
#endif
			}
#if 0
		fprintf(stderr, "%p [%s alloc:%lu]\n", newobject, class_getName(aClass), size);
#endif
		__NSAllocatedObjects++;	// one more
		}
	return newobject;
}

void NSDeallocateObject(NSObject *anObject)
{ // object deallocation
	extern Class __zombieClass;
	objc_check_malloc();
	if (anObject != nil)
		{
		_object_layout o = &((_object_layout)anObject)[-1];
#if 0
		fprintf(stderr, "NSDeallocateObject: %s %p\n", class_getName(object_getClass(anObject)), anObject);
//		if(anObject == 0xbb6c8) abort();
#endif
		__NSCountDeallocate([anObject class]);
//		object_setClass((id)anObject, __zombieClass);	// install zombie class pointer - but that is useless unless we do NOT free the object...
		objc_free(o);
		__NSAllocatedObjects--;	// one less
		}
	objc_check_malloc();
}

NSObject *NSCopyObject(NSObject *obj, NSUInteger extraBytes, NSZone *zone)
{
	id newobject=nil;
	NSUInteger size = sizeof(_object_layout) + class_getInstanceSize(object_getClass((id)obj)) /* + extra */;
	if ((newobject = NSZoneMalloc(zone, size)) != nil)
		{
		newobject = (id)&((_object_layout)newobject)[1];
#if 0
		fprintf(stderr, "NSCopyObject: %p [%s copyObject:%lu]\n", newobject, class_getName(object_getClass((id)obj)), size);
#endif
		object_setClass(newobject, object_getClass((id)obj));	// same as original
		memcpy(newobject, obj, size);
		}
	return newobject;
}

NSUInteger NSGetExtraRefCount(id anObject)
{
	return ((_object_layout)(anObject))[-1].retained;
}

NSUInteger _NSGetRetainCount(id anObject)
{
	return NSGetExtraRefCount(anObject)+1;
}

BOOL													// Increment, decrement
NSDecrementExtraRefCountWasZero(id anObject) 			// reference count
{
	return (((_object_layout)(anObject))[-1].retained-- == 0 ? YES : NO);
}

void
NSIncrementExtraRefCount(id anObject)	{ ((_object_layout)(anObject))[-1].retained++; }

OBJC_ROOT_CLASS
@interface _NSZombie	// internal root class which does not recognize any method
@end

Class __zombieClass;
static NSMapTable *__zombieMap;	// map object addresses to (old) object descriptions

@implementation _NSZombie

#if 0
- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame
{ // called by runtime
	NSString *s=__zombieMap?NSMapGet(__zombieMap, (void *) self):@" (unknown class)";
	fprintf(stderr, "zombied obj=%p sel=%s obj=%s\n", s, sel_getName(aSel), [s UTF8String]);
	NSLog(@"Trying to send selector -%@ to deallocated object: %p %@", NSStringFromSelector(aSel), self, s);
	[NSException raise:NSInternalInconsistencyException format:@"Trying to send selector -%@ to deallocated object: %@", NSStringFromSelector(aSel), s];
	abort();
	return NULL;
}
#endif

#if 0
- (BOOL) isKindOfClass:(Class)aClass
{
	NSString *s=NSMapGet(__zombieMap, (void *) self);
	NSLog(@"asking zombied object %p for isKindOfClass: %@", self, NSStringFromClass(aClass));
	NSLog(@"obj=%@", s);
	abort();
	return NO;
}
#endif

@end


// The Class responsible for handling
static id autorelease_class = nil;		// autorelease's.  This does not need
static SEL autorelease_sel;				// mutex protection, since it is simply
static IMP autorelease_imp = NULL;			// a pointer that gets read and set.

@interface NSObject (NSCopying)	<NSCopying, NSMutableCopying>
// this is defined here to aid the implementation of -copy and -mutableCopy
@end

@implementation NSObject

+ (void) load
{
#if 0
	struct timeval tp;
	gettimeofday(&tp, NULL);
	fprintf(stderr, "did +load NSObject: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
#endif
}

+ (void) initialize
{
#if 0
	fprintf(stderr, "NSObject +initialize self=%p class=%s\n", self, class_getName(self));
	fprintf(stderr, "NSObject class=%p class=%s\n", [NSObject class], class_getName([NSObject class]));
#endif
	if(!autorelease_sel && self == [NSObject class])
		{
		char *z;
#if REPORT_OBJECT_INITIALIZE
		struct timeval tp;
		gettimeofday(&tp, NULL);
		fprintf(stderr, "start +initialize NSObject: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
#endif
		autorelease_class = [NSAutoreleasePool class];
		autorelease_sel = @selector(addObject:);
		autorelease_imp =[autorelease_class methodForSelector:autorelease_sel];
		// Create the global lock
		__NSGlobalLock = [[NSRecursiveLock alloc] init];
		__zombieClass=objc_lookUpClass("_NSZombie");
		z=getenv("NSZombieEnabled");	// made compatible to http://developer.apple.com/technotes/tn2004/tn2124.html
		if(z && (strcmp(z, "YES") == 0 || strcmp(z, "yes") == 0 || atoi(z) == 1))
			NSZombieEnabled=YES;
		if(NSZombieEnabled)
			fprintf(stderr, "### NSZombieEnabled == YES! This disables memory deallocation ###\n");
#if REPORT_OBJECT_INITIALIZE
		gettimeofday(&tp, NULL);
		fprintf(stderr, "finished +initialize NSObject: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
#endif
		}
}

+ (void) setVersion:(NSInteger)aVersion
{
	if(aVersion < 0)
		[NSException raise:NSInvalidArgumentException
					format:@"%s +setVersion: may not set a negative version", class_getName(self)];
	class_setVersion(self, aVersion);
}

+ (id) alloc						{ return [self allocWithZone:NSDefaultMallocZone()]; }
+ (id) allocWithZone:(NSZone *) z;	{ return NSAllocateObject(self, 0, z?z:NSDefaultMallocZone()); }
+ (id) new							{ return [[self allocWithZone:NSDefaultMallocZone()] init]; }
+ (NSInteger) version				{ return class_getVersion(self); }
+ (void) poseAsClass:(Class)aClass	{ NIMP; /* class_pose_as(self, aClass); */ }
+ (Class) class						{ return self; }
- (Class) class						{ return object_getClass(self); }
+ (Class) superclass				{ return class_getSuperclass(self); }
- (Class) superclass				{ return class_getSuperclass(object_getClass(self)); }

+ (BOOL) isSubclassOfClass:(Class)aClass;
{
	while(self != Nil)
		{
		if(self == aClass)
			return YES;
		self=class_getSuperclass(self);
		}
	return NO;
}

- (id) init							{ return self; }
- (id) self							{ return self; }
- (id) copy							{ return [self copyWithZone:nil]; }
- (id) copyWithZone:(NSZone *) z;	{ return SUBCLASS; }   // ignore zone on top level
+ (id) copyWithZone:(NSZone *) z;	{ return self; }   // if called for class
- (id) mutableCopy					{ return [self mutableCopyWithZone:NSDefaultMallocZone()]; }
- (id) mutableCopyWithZone:(NSZone *) z;	{ return SUBCLASS; }	// ignore zone
+ (id) mutableCopyWithZone:(NSZone *) z;	{ return self; }		// if called for class
- (NSZone *) zone;					{ return NSDefaultMallocZone(); }	// no zones implemented

- (NSString *) description
{
	return [NSString stringWithFormat:@"%s <%p>", class_getName([self class]), self];
}

+ (NSString *) description
{
	return [NSString stringWithFormat: @"<@class %s>", class_getName(self)];
}

+ (BOOL) instancesRespondToSelector:(SEL)aSelector
{
	return class_respondsToSelector(self, aSelector);
}

#ifndef __APPLE__
#if 0	// FIXME for __linux__

/**
 * Returns a flag to say whether the receiving class conforms to aProtocol
 **/

/* Testing protocol conformance */
// this should be the method [Protocol * conformsTo:(Protocol *)aProtocolObject]
// but calling methods from the class Protocol ends up in a SIGSEGV

static BOOL objectConformsTo(Protocol *self, Protocol *aProtocolObject);

static BOOL objectConformsTo(Protocol *self, Protocol *aProtocolObject)
{
	int i;
	struct objc_protocol_list* proto_list;
	if(strcmp(aProtocolObject->protocol_name, self->protocol_name) == 0)
		return YES;
	for(proto_list = self->protocol_list; proto_list; proto_list = proto_list->next)
		{
		for(i=0; i < proto_list->count; i++)
			{
			if(objectConformsTo(proto_list->list[i], aProtocolObject))
				return YES;
			}
		}
	return NO;
}
#endif
#endif

+ (BOOL) conformsToProtocol:(Protocol*)aProtocol
{
#if 0
	fprintf(stderr, "+[%s conformsToProtocol: %s]\n", class_getName(self), [aProtocol name]);
#endif
	return class_conformsToProtocol(self, aProtocol);
}

- (BOOL) conformsToProtocol:(Protocol*)aProtocol
{
	//	NSLog(@"-[%@ conformsToProtocol:aProtocol]", self);
	return [[self class] conformsToProtocol:aProtocol];
}

+ (IMP) instanceMethodForSelector:(SEL)aSelector
{
	return class_getMethodImplementation(self, aSelector);
}

- (IMP) methodForSelector:(SEL)aSelector
{
	return class_getMethodImplementation(object_getClass(self), aSelector);
}

- (id) awakeAfterUsingCoder:(NSCoder*)aDecoder			{ return self; }
- (id) initWithCoder:(NSCoder*)aDecoder					{ return self; }
- (void) encodeWithCoder:(NSCoder*)aCoder				{ return; }
- (id) replacementObjectForCoder:(NSCoder*)anEncoder	{ return self; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)anEncoder	{ return SUBCLASS; }	// defined as category in NSPortCoder.m

- (NSString *) className;				{ return NSStringFromClass([self class]); }

// default implementations

- (Class) classForCoder					{ return [self class]; }
- (Class) classForArchiver				{ return [self classForCoder]; }

- (id) replacementObjectForArchiver:(NSArchiver*)anArchiver
{
	return [self replacementObjectForCoder:(NSCoder*)anArchiver];
}

+ (id) autorelease					{ return self; }
+ (id) retain						{ return self; }
+ (oneway void) release				{ return; }
+ (NSUInteger) retainCount			{ return UINT_MAX; }
- (NSUInteger) retainCount			{ return _NSGetRetainCount(self); }

- (id) autorelease
{
	(*autorelease_imp)(autorelease_class, autorelease_sel, self);
	return self;
}

- (void) dealloc
{
	objc_check_malloc();
	if(_NSGetRetainCount(self) != 0)
		{
		NSLog(@"[0x%p dealloc] called instead of [obj release] or [super dealloc] - retain count = %d", self, _NSGetRetainCount(self));
		abort();	// this is a severe bug
		}
#if 0
	fprintf(stderr, "NSObject dealloc %p\n", self);
#endif
	NSDeallocateObject(self);
	objc_check_malloc();
}

- (oneway void) release
{
	if(_NSGetRetainCount(self) == 0)
		{
		fprintf(stderr, "[0x%p release] called for deallocated object - retain count = %lu\n", self, _NSGetRetainCount(self));
		abort();	// this is a severe bug
		}
	if(NSZombieEnabled && _NSGetRetainCount(self) == 1)				// if retain count would zero
		{ // enabling this keeps the object in memory and remembers the object description
			NSAutoreleasePool *arp=[NSAutoreleasePool new];
			NSZombieEnabled=NO;	// don't Zombie temporaries while we get the description
			if(!__zombieMap)
				__zombieMap=NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
											 NSObjectMapValueCallBacks, 200);
#if 0	// debugging some issue
			if([self isKindOfClass:[NSTask class]])
				NSLog(@"zombiing %p: %@", self, [self description]);
#endif
#if 1
			fprintf(stderr, "zombiing %p: %s\n", self, [[self description] UTF8String]);	// NSLog() would recursively call -[NSObject release]
#endif
#if 1
			NSMapInsert(__zombieMap, (void *) self, [self description]);		// retain last object description before making it a zombie
#else
			NSMapInsert(__zombieMap, (void *) self, @"?");		// don't fetch description
#endif
			object_setClass(self, __zombieClass);	// make us a zombie object
			[arp release];
			NSZombieEnabled=YES;
			return;
		}
#if 0	// debugging some issue
		//	if([self isKindOfClass:[NSData class]])
	fprintf(stderr, "release %p\n", self);	// NSLog() would recursively call -[NSObject release]
#endif
	if(NSDecrementExtraRefCountWasZero(self))
		[self dealloc];		// go through the dealloc hierarchy
}

- (void) finalize
{
	return;	// default for garbage collection
}

- (id) retain
{
#if 0	// debugging some issue
	fprintf(stderr, "retain %p\n", self);	// NSLog() would recursively call -[NSObject release]
#endif
	NSAssert(_NSGetRetainCount(self) != 0, @"don't retain object that is already deallocated");
	NSIncrementExtraRefCount(self);
	return self;
}

- (BOOL) isKindOfClass:(Class)aClass
{
	return _classIsKindOfClass([self class], aClass);
}

- (NSUInteger) hash						{ return (NSUInteger)self; }
- (BOOL) isEqual:(id)anObject			{ return (self == anObject); }
- (BOOL) isMemberOfClass:(Class)aClass	{ return [self class] == aClass; }
- (BOOL) isProxy						{ return NO; }

- (BOOL) respondsToSelector:(SEL)aSelector
{
	if(!aSelector) return NO;
#if 0
	NSLog(@"respondsToSelector %@", NSStringFromSelector(aSelector));
#endif
#if 0
	NSLog(@"respondsToSelector +%@", NSStringFromSelector(aSelector));
	NSLog(@"self: %@", self);
	NSLog(@"class: %@", object_getClass(self));	// is the same
												//	NSLog(@"meta: %@", object_get_meta_class((Class) self));	// is the same
	NSLog(@"-method: %p", class_getInstanceMethod(object_getClass(self), aSelector));
	NSLog(@"+method: %p", class_getClassMethod((Class)self, aSelector));
	NSLog(@"+method: %p", class_getInstanceMethod(object_getClass((Class) self), aSelector));
	NSLog(@"-hasAlpha: %p", class_getInstanceMethod(object_getClass(self), @selector(hasAlpha)));
	NSLog(@"+hasAlpha: %p", class_getClassMethod((Class)self, @selector(hasAlpha)));
	NSLog(@"+hasAlpha: %p", class_getInstanceMethod(object_getClass((Class) self), @selector(hasAlpha)));
#endif
	return class_respondsToSelector(object_getClass(self), aSelector);
}

- (void) forwardInvocation:(NSInvocation*)anInvocation
{ // default implementation
	[self doesNotRecognizeSelector:[anInvocation selector]];
}

- (void) doesNotRecognizeSelector:(SEL)aSelector
{
	[NSException raise:NSInvalidArgumentException
				format:@"*** %@[%@ %@]: selector not recognized",
	 class_isMetaClass(object_getClass(self))?@"+":@"-",
	 NSStringFromClass([self class]),
	 NSStringFromSelector(aSelector)];
}

- (id) _subclass:(SEL) cmd;
{
	[NSException raise:NSInvalidArgumentException
				format:@"*** subclass %@ should override %@%@",
	 NSStringFromClass([self class]),
	 class_isMetaClass(object_getClass(self))?@"+":@"-",
	 NSStringFromSelector(cmd)];
	return nil;
}

- (id) _nimp:(SEL) cmd;
{
	[NSException raise:NSInvalidArgumentException
				format:@"*** %@[%@ %@]: not implemented",
	 class_isMetaClass(object_getClass(self))?@"+":@"-",
	 NSStringFromClass([self class]),
	 NSStringFromSelector(cmd)];
	return nil;
}

- (id) performSelector:(SEL)aSelector
{
	IMP msg;
	Class c=object_getClass(self);
	if(class_isMetaClass(c))
		msg=method_getImplementation(class_getClassMethod((Class) self, aSelector));	// if someone calls [[Class class] performSelector...]
	else
		msg=class_getMethodImplementation(c, aSelector);

	if (!msg)
		[NSException raise:NSInvalidArgumentException
					format:@"invalid selector %s passed to %s", sel_getName(aSelector), sel_getName(_cmd)];

	return (*msg)(self, aSelector);
}

- (id) performSelector:(SEL)aSelector withObject:anObject
{
	IMP msg;
#if 0
	NSLog(@"performSelector: %@ for object %@", NSStringFromSelector(aSelector), self);
#endif
	Class c=object_getClass(self);
	//	NSLog(@"class: %@", c);	// fails because the metaclass does not implement -description!
	// this may call mySTEP_objc_msg_forward2 with nil receiver if the method is not implemented!
	if(class_isMetaClass(c))
#if 0
		NSLog(@"isClass: %@", self),
#endif
		msg=method_getImplementation(class_getClassMethod((Class) self, aSelector));	// if someone calls [[Class class] performSelector...]
	else
#if 0
		NSLog(@"isObject: %@", self),
#endif
		msg=class_getMethodImplementation(c, aSelector);

	if (!msg)
		[NSException raise:NSInvalidArgumentException
					format:@"invalid selector %s passed to %s", sel_getName(aSelector), sel_getName(_cmd)];
#if 0
	NSLog(@"performSelector: %@ for object %@ imp=%p", NSStringFromSelector(aSelector), self, msg);
#endif
	return (*msg)(self, aSelector, anObject);
}

- (id) performSelector:(SEL)aSelector withObject:object1 withObject:object2
{
	IMP msg;
	Class c=object_getClass(self);
	if(class_isMetaClass(c))
		msg=method_getImplementation(class_getClassMethod((Class) self, aSelector));	// if someone calls [[Class class] performSelector...]
	else
		msg=class_getMethodImplementation(c, aSelector);

	if (!msg)
		[NSException raise:NSInvalidArgumentException
					format:@"invalid selector %s passed to %s", sel_getName(aSelector), sel_getName(_cmd)];

	return (*msg)(self, aSelector, object1, object2);
}

+ (NSMethodSignature*) instanceMethodSignatureForSelector:(SEL)aSelector
{
	Method m=class_getInstanceMethod(self, aSelector);
	const char *types=m?method_getTypeEncoding(m):NULL;	// default (if we have an implementation)
#if 0
	NSLog(@"-[%@ %@@selector(%@)]", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(aSelector));
	NSLog(@" -> %s", m->method_types);
	NSLog(@"  self=%@ IMP=%p", self, m->method_imp);
#endif
	// CHECKME: should we also check for Protocols?
	return types ? [NSMethodSignature signatureWithObjCTypes:types] : (NSMethodSignature *) nil;
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) aSelector
{
	Method m=class_getInstanceMethod(object_getClass(self), aSelector);
	const char *types=m?method_getTypeEncoding(m):NULL;	// default (if we have an implementation)
#if FIXME
	Class c = object_getClass(self);
	struct objc_protocol_list	*protocols = c?c->protocols:NULL;
	for(; protocols; protocols = protocols?protocols->next:protocols)
		{ // loop through protocol lists to find if they define our selector with more details
			unsigned int i = 0;
#if 0
			NSLog(@"trying protocol list %p (count=%d)", protocols, protocols->count);
#endif
			for(i=0; i < protocols->count; i++)
				{ // loop through individual protocols
					Protocol *p = protocols->list[i];
					struct objc_method_description *desc= (c == (Class)self) ? [p descriptionForClassMethod: aSelector] : [p descriptionForInstanceMethod: aSelector];
#if 0
					NSLog(@"try protocol %s", [p name]);
#endif
					if(desc)
						{ // found
						  // NOTE: here we could also do duplication and contradiction checks
#if 0
							NSLog(@"found");
							if(types)
								NSLog(@"signature %s replaced by %s from protocol %s", types, desc->types, [p name]);
#endif
							types = desc->types;	// overwrite
							protocols = NULL;	// this will break the outer loop as well
							break;	// done with both loops
						}
				}
		}
#endif	// FIXME
#if 0
	NSLog(@"-[%@ %@@selector(%@)]", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(aSelector));
	if(types)
		NSLog(@" -> %s", types);
	else
		NSLog(@" -> selector not found.");
	if(m)
		NSLog(@"  self=%@ IMP=%p", self, method_getImplementation(m));
#endif
	return types ? [NSMethodSignature signatureWithObjCTypes:types] : (NSMethodSignature *) nil;
}

// inofficial default implementation
// it simply wraps the standard NSEnumerator
// NSFastEnumerationState must have been zeroed before first call!
// you should not empty the ARP within a loop!

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *) state
								   objects:(id *) stackbuf
									 count:(NSUInteger) len;
{
	id *s0=stackbuf;
	if(state->state != 0x55aa5a5a || !state->itemsPtr)	// some safety if zeroing was forgotten
		{ // assume we have not been initialized
			state->itemsPtr=(id *) [(NSArray *) self objectEnumerator];	// misuse the items pointer for a primitive NSEnumerator...
			state->state=0x55aa5a5a;
		}
	while(len-- > 0)
		{
		id val=[(NSEnumerator *) state->itemsPtr nextObject];
		if(!val) // fetch elements into array
			break;
		*stackbuf++ = val;
		}
	if(stackbuf != s0)
		return stackbuf-s0;	// return number of elements
	return 0;
}

- (id) forwardingTargetForSelector:(SEL) sel;
{
	return self;
}

+ (BOOL) resolveInstanceMethod:(SEL) sel
{
	return NO;
}

+ (BOOL) resolveClassMethod:(SEL) sel
{
	return NO;
}

@end

/// should we get rid of this (compiler option??)

@implementation NSObject (NEXTSTEP_MISC)			// NEXTSTEP Object class
													// compatibility & misc
- (int) compare:(id)anObject
{
	if (self == anObject)
		return YES;

	if ([self isEqual:anObject])
		return 0;

	return ((char *) self-(char *)anObject) > 0 ? 1 : -1;	// FIXME - this looks quite strange!
}

@end

//*****************************************************************************
//
// 		NSEnumerator  (abstract)
//
//*****************************************************************************

@implementation NSEnumerator

- (id) nextObject							{ return SUBCLASS }
- (NSArray *) allObjects					{ return SUBCLASS }

@end

