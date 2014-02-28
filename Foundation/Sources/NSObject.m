/* 
   NSObject.m

   Implementation of NSObject

   Copyright (C) 1994, 1995, 1996 Free Software Foundation, Inc.
   
   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	August 1994
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#include <limits.h>
#include <time.h>
#include <sys/time.h>

#include <objc/objc-api.h>

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

@interface _NSZombie	// internal root class which does not recognize any method
@end

Class __zombieClass;
static NSMapTable *__zombieMap;	// map object addresses to (old) object descriptions

@implementation _NSZombie

- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame
{ // called by runtime
	NSString *s=__zombieMap?NSMapGet(__zombieMap, (void *) self):@" (unknown class)";
//	fprintf(stderr, "obj=%p sel=%s\n", s, sel_get_name(aSel));
	NSLog(@"Trying to send selector -%@ to deallocated object: %p %@", NSStringFromSelector(aSel), self, s);
	[NSException raise:NSInternalInconsistencyException format:@"Trying to send selector -%@ to deallocated object: %@", NSStringFromSelector(aSel), s];
	abort();
	return NULL;
}

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

BOOL													// Increment, decrement
NSDecrementExtraRefCountWasZero(id anObject) 			// reference count
{
	return (((_object_layout)(anObject))[-1].retained-- == 0 ? YES : NO);
}

void
NSIncrementExtraRefCount(id anObject)	{ ((_object_layout)(anObject))[-1].retained++; }

										// The Class responsible for handling 
static id autorelease_class = nil;		// autorelease's.  This does not need
static SEL autorelease_sel;				// mutex protection, since it is simply
static IMP autorelease_imp = 0;			// a pointer that gets read and set.

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
	if(!autorelease_sel && self == [NSObject class])
		{
		char *z;
#if 0
		struct timeval tp;
		gettimeofday(&tp, NULL);
		fprintf(stderr, "start +initialize NSObject: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
#endif
		autorelease_class = [NSAutoreleasePool class];
		autorelease_sel = @selector(addObject:);
      	autorelease_imp =[autorelease_class methodForSelector:autorelease_sel];
		// Create the global lock
		__NSGlobalLock = [[NSRecursiveLock alloc] init];
		__zombieClass=objc_lookup_class("_NSZombie");
		z=getenv("NSZombieEnabled");	// made compatible to http://developer.apple.com/technotes/tn2004/tn2124.html
		if(z && (strcmp(z, "YES") == 0 || strcmp(z, "yes") == 0 || atoi(z) == 1))
			NSZombieEnabled=YES;
		if(NSZombieEnabled)
			fprintf(stderr, "### NSZombieEnabled == YES! This disables memory deallocation ###\n");
#if 0
		gettimeofday(&tp, NULL);
		fprintf(stderr, "finished +initialize NSObject: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
#endif
		}
}

+ (void) setVersion:(int)aVersion
{
	if(aVersion < 0)
		[self _error:"%s +setVersion: may not set a negative version", object_get_class_name(self)];
	class_set_version(self, aVersion);
}

+ (id) alloc						{ return [self allocWithZone:NSDefaultMallocZone()]; }
+ (id) allocWithZone:(NSZone *) z;	{ return NSAllocateObject(self, 0, z?z:NSDefaultMallocZone()); }
+ (id) new							{ return [[self allocWithZone:NSDefaultMallocZone()] init]; }
+ (int) version						{ return class_get_version(self); }
+ (void) poseAsClass:(Class)aClass	{ class_pose_as(self, aClass); }
+ (Class) class						{ return self; }
- (Class) class						{ return object_get_class(self); }
+ (Class) superclass				{ return class_get_super_class(self); }
- (Class) superclass				{ return object_get_super_class(self); }

+ (BOOL) isSubclassOfClass:(Class)aClass;
	{
	while(self != Nil)
		{
		if(self == aClass)
			return YES;
		self=class_get_super_class(self);
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
	return [NSString stringWithFormat:@"%s <%p>", object_get_class_name(self), self];
}

+ (NSString *) description
{
	return [NSString stringWithFormat: @"<@class %s>", object_get_class_name(self)];
}

+ (BOOL) instancesRespondToSelector:(SEL)aSelector
{
	return (class_get_instance_method(self, aSelector) != METHOD_NULL);
}

/**
* Returns a flag to say whether the receiving class conforms to aProtocol
**/

/* Testing protocol conformance */
// this should be the method [Protocol * conformsTo:(Protocol *)aProtocolObject]
// but calling methods from the class Protocol ends up in a SIGSEGV

static BOOL objectConformsTo(Protocol *self, Protocol *aProtocolObject);

static BOOL objectConformsTo(Protocol *self, Protocol *aProtocolObject)
{
#ifndef __APPLE__
#if 0	// FIXME for __linux__
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
#endif
#endif
	return NO;
}

+ (BOOL) conformsToProtocol:(Protocol*)aProtocol
{
	struct objc_protocol_list* proto_list;
#if 0 && !defined(__APPLE__)
	fprintf(stderr, "+[%s conformsToProtocol: %s]\n", class_get_class_name(self), [aProtocol name]);
#endif
	for(proto_list = ((struct objc_class*)self)->protocols;
		 proto_list; proto_list = proto_list->next)
		{
		unsigned int i;		
		for(i = 0; i < proto_list->count; i++)
			{
//			if ([proto_list->list[i] conformsTo:aProtocol]) // that one crashes for unknown reasons
			if(objectConformsTo(proto_list->list[i], aProtocol))
				return YES;
			}
		}
	return object_get_super_class(self) && [object_get_super_class(self) conformsToProtocol: aProtocol];
}

- (BOOL) conformsToProtocol:(Protocol*)aProtocol
{
//	NSLog(@"-[%@ conformsToProtocol:aProtocol]", self);
	return [isa conformsToProtocol:aProtocol];
}

+ (IMP) instanceMethodForSelector:(SEL)aSelector
{
	return (IMP)method_get_imp(class_get_instance_method(self, aSelector));
}
  
- (IMP) methodForSelector:(SEL)aSelector
{
	return (IMP)(method_get_imp(object_is_instance(self)
                         ? class_get_instance_method(isa, aSelector)
                         : class_get_class_method(isa, aSelector)));
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
+ (unsigned int) retainCount			{ return UINT_MAX; }
- (unsigned int) retainCount			{ return (((_object_layout)(self))[-1].retained)+1; }

- (id) autorelease
{
	(*autorelease_imp)(autorelease_class, autorelease_sel, self);
	return self;
}

- (void) dealloc
{
#if 0 && defined(__mySTEP__)
	free(malloc(128));	// segfaults???
#endif
	if(((_object_layout)(self))[-1].retained != -1)
		{
		NSLog(@"[obj dealloc] called instead of [obj release] or [super dealloc]");
		abort();	// this is a severe bug
		}
#if 0
	fprintf(stderr, "dealloc %p\n", self);
#endif
	NSDeallocateObject(self);
}

- (oneway void) release
{
	if (((_object_layout)(self))[-1].retained == 0)				// if ref count becomes zero (was 1)
		{
		if(NSZombieEnabled)
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
			fprintf(stderr, "zombiing %p\n", self);	// NSLog() would recursively call -[NSObject release]
#endif
#if 1
			NSMapInsert(__zombieMap, (void *) self, [self description]);		// retain last object description before making it a zombie
#else
			NSMapInsert(__zombieMap, (void *) self, @"?");		// don't fetch description
#endif
			isa=__zombieClass;	// make us a zombie object
			[arp release];
			NSZombieEnabled=YES;
			}
		else
			{
#if 0	// debugging some issue
			if([self isKindOfClass:[NSData class]])
				fprintf(stderr, "dealloc %p\n", self);	// NSLog() would recursively call -[NSObject release]
#endif
			((_object_layout)(self))[-1].retained--;
			[self dealloc];		// go through the dealloc hierarchy
			}
		}
	else
		((_object_layout)(self))[-1].retained--;
}

- (void) finalize
{
	return;	// default for garbage collection
}

- (id) retain
{
	NSAssert(((_object_layout)(self))[-1].retained+1 != 0, @"don't retain object that is already deallocated");
	((_object_layout)(self))[-1].retained++;
	return self;
}

- (BOOL) isKindOfClass:(Class)aClass
{
	return _classIsKindOfClass(isa, aClass);
}

- (unsigned) hash						{ return (unsigned)self; }
- (BOOL) isEqual:(id)anObject			{ return (self == anObject); }
- (BOOL) isMemberOfClass:(Class)aClass	{ return isa == aClass; }
- (BOOL) isProxy						{ return NO; }

- (BOOL) respondsToSelector:(SEL)aSelector
{
	if(!aSelector) return NO;
	if (CLS_ISCLASS(((Class)self)->class_pointer))
		return (class_get_instance_method(isa, aSelector) != METHOD_NULL);
	return (class_get_class_method(isa, aSelector) != METHOD_NULL);
}

- (void) forwardInvocation:(NSInvocation*)anInvocation
{ // default implementation
	[self doesNotRecognizeSelector:[anInvocation selector]];
}

- (void) doesNotRecognizeSelector:(SEL)aSelector
{
	[NSException raise:NSInvalidArgumentException
				format:@"NSObject %@[%@ %@]: selector not recognized", 
						object_is_instance(self)?@"-":@"+",
						NSStringFromClass([self class]), 
						NSStringFromSelector(aSelector)];
}

- (id) _subclass:(SEL) cmd;
{
	[NSException raise:NSInvalidArgumentException
				format:@"*** subclass %@ should override %@%@",
						NSStringFromClass([self class]),
						object_is_instance(self)?@"-":@"+",
						NSStringFromSelector(cmd)];
	return nil;
}

- (id) _nimp:(SEL) cmd;
{
	[NSException raise:NSInvalidArgumentException
				format:@"*** %@[%@ %@]: not implemented",
						object_is_instance(self)?@"-":@"+",
						NSStringFromClass([self class]),
						NSStringFromSelector(cmd)];
	return nil;
}

- (id) performSelector:(SEL)aSelector
{
	IMP msg = objc_msg_lookup(self, aSelector);

	if (!msg)
		return [self _error:"invalid selector passed to %s", sel_get_name(_cmd)];

	return (*msg)(self, aSelector);
}

- (id) performSelector:(SEL)aSelector withObject:anObject
{
	IMP msg = objc_msg_lookup(self, aSelector);

	if (!msg)
		return [self _error:"invalid selector passed to %s",sel_get_name(_cmd)];

	return (*msg)(self, aSelector, anObject);
}

- (id) performSelector:(SEL)aSelector withObject:object1 withObject:object2
{
	IMP msg = objc_msg_lookup(self, aSelector);

	if (!msg)
		return [self _error:"invalid selector passed to %s",sel_get_name(_cmd)];

	return (*msg)(self, aSelector, object1, object2);
}

+ (NSMethodSignature*) instanceMethodSignatureForSelector:(SEL)aSelector
{
	struct objc_method *m = class_get_instance_method(self, aSelector);
#if 0
	NSLog(@"-[%@ %@@selector(%@)]", NSStringFromClass(isa), NSStringFromSelector(_cmd), NSStringFromSelector(aSelector));
	NSLog(@" -> %s", m->method_types);
	NSLog(@"  self=%@ IMP=%p", self, m->method_imp);
#endif
	// CHECKME: should we also check for Protocols?
    return m ? [NSMethodSignature signatureWithObjCTypes:m->method_types] : (NSMethodSignature *) nil;
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) aSelector
{
	struct objc_method *m = (object_is_instance(self) 
													 ? class_get_instance_method(isa, aSelector)
													 : class_get_class_method(isa, aSelector));
	const char *types=m?m->method_types:NULL;	// default (if we have an implementation)
	Class c = object_get_class(self);
	struct objc_protocol_list	*protocols = c?c->protocols:NULL;
	for(; protocols; protocols = protocols?protocols->next:protocols)
			{ // loop through protocol lists to find if they define our selector with more details
				unsigned int i = 0;
#if 1
				NSLog(@"trying protocol list %p (count=%d)", protocols, protocols->count);
#endif
				for(i=0; i < protocols->count; i++)
						{ // loop through individual protocols
							Protocol *p = protocols->list[i];
							struct objc_method_description *desc= (c == (Class)self) ? [p descriptionForClassMethod: aSelector] : [p descriptionForInstanceMethod: aSelector];
#if 1
							NSLog(@"try protocol %s", [p name]);
#endif
							if(desc)
									{ // found
										// NOTE: here we could also do duplication and contradiction checks
#if 1
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
#if 1
	NSLog(@"-[%@ %@@selector(%@)]", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(aSelector));
	if(types)
		NSLog(@" -> %s", types);
	else
		NSLog(@" -> selector not found.");
	if(m)
		NSLog(@"  self=%@ IMP=%p", self, m->method_imp);
#endif
	return types ? [NSMethodSignature signatureWithObjCTypes:types] : (NSMethodSignature *) nil;
}

- (id) forwardingTargetForSelector:(SEL) sel;
{
	return self;
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

+ (BOOL) resolveInstanceMethod:(SEL) sel
{
	return NO;
}

+ (BOOL) resolveClassMethod:(SEL) sel
{
	return NO;
}

@end

@implementation NSObject (NSObjCRuntime)					// special

- (BOOL) resolveClassMethod:(SEL) sel; { return NO; }
- (BOOL) resolveInstanceMethod:(SEL) sel; { return NO; }

/* convert runtime forwarding arguments into NSInvocation */

/* basically we come here by:
 
 static id __objc_word_forward (id rcv, SEL op, ...)
	{
	void *args, *res;
	args = __builtin_apply_args ();
	res = __objc_forward (rcv, op, args);
	if (res)
		__builtin_return (res);
	else
		return res;
 }

 static retval_t __objc_forward (id object, SEL sel, arglist_t args)
	{
	IMP imp;
	static SEL frwd_sel = 0;

	if (! frwd_sel)
		frwd_sel = sel_get_any_uid ("forward::");

	if (__objc_responds_to (object, frwd_sel))
		{
		imp = get_imp (object->class_pointer, frwd_sel);
		return (*imp) (object, frwd_sel, sel, args);
		}
	...

 so we are called here between __builtin_apply_args() and __builtin_return()
*/

- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame
{ // called by runtime
	retval_t r;
	NSMethodSignature *ms;
	NSInvocation *inv;
	BOOL resolved;
#if 1
	NSLog(@"NSObject -forward:@selector(%@):%p", NSStringFromSelector(aSel), argFrame);
	NSLog(@"  self=%p %@", self, self);
	NSLog(@"  _cmd=%p %s", _cmd, sel_getName(_cmd));
	NSLog(@"  sel=%p %s", aSel, sel_getName(aSel));
	NSLog(@"  &r=%p", &r);	// local stack within forward::
	NSLog(@"  frame=%p", argFrame);
#endif	
	if(aSel == 0)
		[NSException raise:NSInvalidArgumentException
					format:@"NSObject forward:: %@ NULL selector", NSStringFromSelector(_cmd)];
	// FIXME: class or instance?
	resolved=[self resolveInstanceMethod:aSel];	// give a chance to add to runtime methods before invoking
	ms=[self methodSignatureForSelector:aSel];
#if 1
	[ms _logFrame:argFrame target:self selector:_cmd];
#endif
#if 1
	NSLog(@"method signature=%@", ms);
#endif
	if(ms)
		inv=[[NSInvocation alloc] _initWithMethodSignature:ms andArgFrame:argFrame];
	if(!ms || !inv)
		{ // unknown to system
			[self doesNotRecognizeSelector:aSel];
			return 0;	// if it did NOT raise an exception - a retval of 0 can be returned
		}
	if(resolved)
		{ // was resolved, call directly
			[inv invoke];
		}
	else
		{ // ask forwardingTarget
		id target=[self forwardingTargetForSelector:aSel];
		if(target != self)
			[inv setTarget:target];	// update target
		[self forwardInvocation:inv];
#if 1
		NSLog(@"invocation forwarded. Now returning result");
		[ms _logFrame:argFrame target:self selector:_cmd];
#endif
		}
	[inv autorelease];		// don't release immediately since r is pointer to an iVar of NSInvocation (!)
	r=[inv _returnValue];	// get the retval_t
#if 1
	fprintf(stderr, "  forward:: retval_t=%p\n", r);
#endif
	return r;
}

@end

/// should we get rid of this (compiler option??)

@implementation NSObject (NEXTSTEP_MISC)			// NEXTSTEP Object class 
													// compatibility & misc
#if OLD

- (id) _error:(const char *)aString, ...
{
char fmtStr[] = "error: %s (%s)\n%s\n";
int a = strlen((char*)fmtStr);
int b = strlen((char*)object_get_class_name(self));
char fmt[(a + b + ((aString != NULL) ? strlen((char*)aString) : 0) + 8)];
va_list ap;

	sprintf(fmt, fmtStr, object_get_class_name(self),
						 object_is_instance(self) ? "instance" : "class",
						 (aString != NULL) ? aString : "");
	va_start(ap, aString);
	objc_verror (self, 0, fmt, ap);					// What should `code' 
	va_end(ap);										// argument be?  Current 0.
	
	return nil;
}

- (BOOL) isMemberOf:(Class)aClassObject
{
	return [self isMemberOfClass:aClassObject];
}

+ (BOOL) instancesRespondTo:(SEL)aSel
{
	return [self instancesRespondToSelector:aSel];
}

- (BOOL) respondsTo:(SEL)aSel
{
	if (CLS_ISCLASS(((Class)self)->class_pointer))
		return (class_get_instance_method(isa, aSel) != METHOD_NULL);

	return (class_get_class_method(isa, aSel) != METHOD_NULL);
}

+ (BOOL) conformsTo:(Protocol*)aProtocol
{
	return [self conformsToProtocol:aProtocol];
}

- (BOOL) conformsTo:(Protocol*)aProtocol
{
	return [self conformsToProtocol:aProtocol];
}

+ (IMP) instanceMethodFor:(SEL)aSel
{
	return [self instanceMethodForSelector:aSel];
}

- (BOOL) isMetaClass				{ return NO; }
- (BOOL) isClass					{ return object_is_class(self); }
- (BOOL) isInstance					{ return object_is_instance(self); }

- (BOOL) isMemberOfClassNamed:(const char *)aClassName
{
	return ((aClassName!=NULL)
			&&!strcmp(class_get_class_name(isa), aClassName));
}

+ (struct objc_method_description *) descriptionForInstanceMethod:(SEL)aSel
{
	return ((struct objc_method_description *) 
			class_get_instance_method(self, aSel));
}

- (struct objc_method_description *) descriptionForMethod:(SEL)aSel
{
	return ((struct objc_method_description *) (object_is_instance(self)
								? class_get_instance_method(isa, aSel)
								: class_get_class_method(isa, aSel)));
}

- (Class) transmuteClassTo:(Class)aClassObject
{
Class old_isa = nil;

	if (object_is_instance(self) && (class_is_class(aClassObject)))
      if(class_get_instance_size(aClassObject) == class_get_instance_size(isa))
        if ([self isKindOfClass:aClassObject])
			{
            old_isa = isa;
            isa = aClassObject;
			}

	return old_isa;
}

#endif

- (int) compare:(id)anObject
{
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

