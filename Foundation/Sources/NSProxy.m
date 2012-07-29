/* 
   NSProxy.m

   Abstract class of objects that act as stand-ins for other objects

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1997

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSInvocation.h>
#import <Foundation/NSProxy.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>

#import "NSPrivate.h"

@implementation NSProxy

+ (id) allocWithZone:(NSZone *) z;	{ return NSAllocateObject(self, 0, z?z:NSDefaultMallocZone()); }
+ (id) alloc					{ return [self allocWithZone:NSDefaultMallocZone()]; }
- (NSZone *) zone;				{ return NSDefaultMallocZone(); }	// no zones implemented
+ (void) release				{ return; }
+ (id) autorelease				{ return self; }
+ (id) retain					{ return self; }
+ (Class) superclass			{ return class_get_super_class(self); }
+ (Class) class					{ return self; }
+ (void) load					{ return; }

+ (NSString *) description
{
	return [NSString stringWithFormat: @"<@class %s>", object_get_class_name(self)];
}

+ (BOOL) respondsToSelector:(SEL)aSelector
{
	return (class_get_class_method(self, aSelector) != METHOD_NULL);
}

+ (unsigned) retainCount		{ return UINT_MAX; }
- (unsigned int) retainCount	{ return (((_object_layout)(self))[-1].retained)+1; }

// NOTE: it appears that init is not defined on OSX!

- (id) init						{ return self; }
- (id) copyWithZone:(NSZone *) zone	{ return [self retain]; }
- (id) self						{ return self; }
- (Class) superclass			{ return object_get_super_class(self);}
- (Class) class					{ return object_get_class(self); }
- (void) dealloc				{ NSDeallocateObject((NSObject*)self); }
- (void) finalize			{ return; }

- (id) autorelease
{
	[NSAutoreleasePool addObject:self];
	return self;
}

- (void) release
{
	if (((_object_layout)(self))[-1].retained == 0)				// if ref count becomes zero (was 1)
			{
				((_object_layout)(self))[-1].retained--;
				[self dealloc];
			}
	else
		((_object_layout)(self))[-1].retained--;
}

- (id) retain
{
	((_object_layout)(self))[-1].retained++;
	return self;
}

#if 0	// forwarded automatically if we don't implement this here...
- (BOOL) conformsToProtocol:(Protocol*)aProtocol
{ // default: pack into a request and forward
	NSInvocation *inv;
	NSMethodSignature *sig;
	BOOL result;
//	sig = [self methodSignatureForSelector:@selector(conformsToProtocol:)];
	sig = [NSObject instanceMethodSignatureForSelector:@selector(conformsToProtocol:)];
	inv = [NSInvocation invocationWithMethodSignature:sig];
	[inv setSelector:@selector(conformsToProtocol:)];
	[inv setArgument:aProtocol atIndex:2];
	[self forwardInvocation:inv];
	[inv getReturnValue:&result];
	return result;
}
#endif

+ (BOOL) conformsToProtocol:(Protocol*)aProtocol;
{
//	NIMP;
	return NO;
}

- (NSString*) descriptionWithLocale:(id)locale indent:(unsigned int)indent;
{ // called in decription of NSArray etc. - don't bother the distant object with that
	return [self descriptionWithLocale:locale];
}

- (NSString*) descriptionWithLocale:(id)locale;
{ // called in decription of NSArray etc. - don't bother the distant object with that
	return [self description];
}

- (NSString*) description
{
	return [NSString stringWithFormat: @"<%@ %lx>", NSStringFromClass([self class]), (unsigned long)self];
}

- (void) forwardInvocation:(NSInvocation*)anInvocation
{ // default NSProxy can't forward anything
	[NSException raise: NSInvalidArgumentException
				format:@"NSProxy can't forwardInvocation:%@", anInvocation];
}

// convert runtime forwarding arguments into NSInvocation

- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame
{
	NSInvocation *inv;
#if 1
	NSLog(@"NSProxy forward:@selector(%@) :... through %@", NSStringFromSelector(aSel), self);
#endif
	if(aSel == 0)
		[NSException raise:NSInvalidArgumentException
					format:@"NSProxy forward:: %@ NULL selector", NSStringFromSelector(_cmd)];
	// FIXME: Cocoa is said to discard the call if methodSignature returns nil - but how do we get a retval_t??
	inv=[[NSInvocation alloc] _initWithMethodSignature:[self methodSignatureForSelector:aSel] andArgFrame:argFrame];
	if(!inv)
		{ // unknown to system
		[NSException raise:NSInvalidArgumentException
					format:@"NSProxy forward:: [%@ -%@]: selector not recognized", 
					NSStringFromClass([self class]), 
					NSStringFromSelector(aSel)];
		return nil;
		}
	[self forwardInvocation:inv];
#if 0	// WARNING: this will destroy the stack and the return value! So, we have to fetch it twice in debugging mode.
	NSLog(@"invocation forwarded. Returning result");
	NSLog(@"returnFrame=%08x", [inv _returnValue]);
#endif
	return [inv _returnValue];	// this also invalidates the argFrame
}

- (BOOL) isKindOfClass:(Class)aClass
{
	return _classIsKindOfClass(isa, aClass);
}

- (BOOL) isMemberOfClass:(Class)aClass		{ return (isa == aClass); }

- (id) _nimp:(SEL) cmd;
{
	[NSException raise:NSInvalidArgumentException
				format:@"*** %@[%@ %@]: not implemented",
						object_is_instance(self)?@"-":@"+",
		NSStringFromClass([self class]),
		NSStringFromSelector(cmd)];
	return nil;
}

- (id) notImplemented:(SEL)aSel
{
	return [self _nimp:aSel];
}

- (BOOL) isProxy							{ return YES; }

// which of these should be forwarded...

#if 0	// all these...
- (unsigned int) hash						{ return (unsigned int)self; }
- (BOOL) isEqual:(id)anObject				{ return (self == anObject); }
#endif

#if 0
- (struct objc_method_description *) methodDescriptionForSelector:(SEL) sel;
{
	[NSException raise: NSInvalidArgumentException format: @"-[NSProxy %s] called!", sel_get_name(_cmd)];
	return NULL;
}

#endif

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector
{ // default implementation raises exception
	[NSException raise: NSInvalidArgumentException format: @"-[NSProxy %s] called!", sel_get_name(_cmd)];
	return nil;
}

#if 0	// simply forward as well
// FIXME: this does not properly forward!

- (id) performSelector:(SEL)aSelector
{
	IMP msg = objc_msg_lookup(self, aSelector);
	if(!msg)
		{
		[NSException raise: NSGenericException 
					 format: @"invalid selector passed to %s",
						sel_get_name(_cmd)];
		return nil;
		}
	return (*msg)(self, aSelector);
}

- (id) performSelector:(SEL)aSelector withObject:(id)anObject
{
	IMP msg = objc_msg_lookup(self, aSelector);

	if(!msg)
		{
		[NSException raise: NSGenericException
					 format: @"invalid selector passed to %s",
								sel_get_name(_cmd)];
		return nil;
		}
	return (*msg)(self, aSelector, anObject);
}

- (id) performSelector:(SEL)aSelector
	    withObject:(id)anObject
	    withObject:(id)anotherObject
{
	IMP msg = objc_msg_lookup(self, aSelector);

	if (!msg)
		{
		[NSException raise: NSGenericException
					 format: @"invalid selector passed to %s",
							sel_get_name(_cmd)];
		return nil;
		}
	return (*msg)(self, aSelector, anObject, anotherObject);
}

- (BOOL) respondsToSelector:(SEL)aSelector
{
	[NSException raise: NSInvalidArgumentException format: @"-[NSProxy %s] called!", sel_get_name(_cmd)];
	return NO;
}
#endif

@end
