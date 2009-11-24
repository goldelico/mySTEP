/* 
   NSDistantObject.m

   Class which defines proxies for objects in other applications

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Rewrite: Richard Frith-Macdonald <richard@brainstorm.co.u>

   changed to encode/decode NSInvocations:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: October 2003
 
   complete rewrite:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: Jan 2006
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
   */

#import <Foundation/NSRunLoop.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSPort.h>
#import <Foundation/NSPortCoder.h>
#import <Foundation/NSPortMessage.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSData.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSObjCRuntime.h>

#import "NSPrivate.h"

#ifndef __APPLE__
// should be moved to runtime specific classes

@interface NSDistantObject (Private)

+ (void) _enableLogging:(BOOL) arg1;
+ (id) newDistantObjectWithCoder:(id) arg1;
- (id) initWithTarget:(id) arg1 connection:(id) arg2;
- (id) initWithLocal:(id) arg1 connection:(id) arg2;
- (id) protocolForProxy;
+ (void) _enableLogging:(BOOL) arg1;
- (void) _releaseWireCount:(unsigned long long) arg1;
- (void) retainWireCount;
- (Class) classForCoder;
- (id) stringByAppendingFormat:(id) arg1;
- (void) appendFormat:(id) arg1;

@end


@implementation Protocol (NSPrivate)

- (NSMethodSignature *) _methodSignatureForInstanceMethod:(SEL)aSel;
{
	const char *types = NULL;
#ifndef __APPLE__
	struct objc_method_description *mth;
	if((mth = [self descriptionForInstanceMethod: aSel]) == NULL)
		return nil;
	types = mth->types;
#endif
#if 0
	NSLog(@"%@ -> %s", NSStringFromSelector(aSel), types);
#endif
	if(types == NULL)
		return nil;
	return [NSMethodSignature signatureWithObjCTypes:types];	// convert into an NSMethodSignature
}

- (NSMethodSignature *) _methodSignatureForClassMethod:(SEL)aSel;
{
	const char *types = NULL;
#ifndef __APPLE__
	struct objc_method_description *mth;
	if((mth = [self descriptionForClassMethod:aSel]) == NULL)
		return nil;
	types = mth->types;
	if(types == NULL)
		return nil;
#endif
	return [NSMethodSignature signatureWithObjCTypes:types];	// convert into an NSMethodSignature
}

@end
#endif

@implementation NSObject (NSDOAdditions)

+ (struct objc_method_description *) methodDescriptionForSelector:(SEL) sel;
{
	return [self descriptionForClassMethod:sel];	// as defined in GNU objc runtime
}

- (struct objc_method_description *) methodDescriptionForSelector:(SEL) sel;
{
	return [self descriptionForInstanceMethod:sel];	// as defined in GNU objc runtime
}

+ (const char *) _localClassNameForClass;
{
#ifdef __APPLE__
	return object_getClassName(self);
#else
	return class_get_class_name(self);
#endif
}

- (const char *) _localClassNameForClass;
{
#ifdef __APPLE__
	return object_getClassName(self);
#else
	return class_get_class_name(isa);
#endif
}

@end

@implementation NSDistantObject		// this object forwards messages to the peer

// more private methods
// + (void)_enableLogging:(BOOL)arg1;
// - (void)_releaseWireCount:(unsigned long long)arg1;

+ (NSDistantObject*) proxyWithLocal:(id)anObject
						 connection:(NSConnection*)aConnection;
{ // this is initialization for vending objects or encoding references so that they can be decoded as remote proxies
	return [[[self alloc] initWithLocal:anObject connection:aConnection] autorelease];
}

+ (NSDistantObject*) proxyWithTarget:(id)anObject
						  connection:(NSConnection*)aConnection;
{ // remoteObject is an id in another thread or another application’s address space!
	return [[[self alloc] initWithTarget:anObject connection:aConnection] autorelease];
}

- (NSConnection *) connectionForProxy; { return _connection; }

- (id) initWithLocal:(id)anObject connection:(NSConnection*)aConnection;
{ // this is initialization for vending objects
	NSDistantObject *proxy;
	_connection=[aConnection retain];	// keep the connection as long as we exist
	proxy=[_connection _getLocal:anObject];
	if(proxy)
			{ // already known
				[self release];
				return proxy;
			}
	// assign a fresh wire-id
	[_connection _addLocal:self forObject:anObject];
	_selectorCache=[NSMutableDictionary dictionaryWithCapacity:10];
	[_selectorCache setObject:[NSObject instanceMethodSignatureForSelector:@selector(methodSignatureForSelector:)] forKey:@"methodSignatureForSelector:"]; 	// predefine NSMethodSignature cache 
	[_selectorCache setObject:[NSConnection instanceMethodSignatureForSelector:@selector(rootObject)] forKey:@"rootObject"]; 	// predefine NSMethodSignature cache
	
#if OLD
	// check if we already know a NSDistantObject for our local object (may be required to correctly handle -replacementObjectForPortCoder:)
	
	// if new, create a new remote object
	
	// we have no superclass!
	_connection=[aConnection retain];	// keep the connection as long as we exist
	_target=anObject;
	[self retain];	// additional retain so that we keep around until remote side deallocates us
	_selectorCache=[NSMutableDictionary dictionaryWithCapacity:10];
	[_selectorCache setObject:[NSObject instanceMethodSignatureForSelector:@selector(methodSignatureForSelector:)] forKey:@"methodSignatureForSelector:"]; 	// predefine NSMethodSignature cache 
	[_selectorCache setObject:[NSConnection instanceMethodSignatureForSelector:@selector(rootObject)] forKey:@"rootObject"]; 	// predefine NSMethodSignature cache 
	[(NSMutableArray *) [aConnection localObjects] addObject:anObject];	// add to list
	_isLocal=YES;
#endif
	return self;
}

- (id) initWithTarget:(id)remoteObject connection:(NSConnection*)aConnection;
{ // remoteObject is an id in another thread or another application’s address space!
	NSDistantObject *p=[aConnection _getRemote:remoteObject];
	if(p)
			{ // we already have a proxy for this target
				[self release];	// release newly allocated object
				return [p retain];	// retain the existing proxy once
			}
	_connection=[aConnection retain];	// keep the connection as long as we exist
	_target=remoteObject;
	_selectorCache=[NSMutableDictionary dictionaryWithCapacity:10];
	[_selectorCache setObject:[NSObject instanceMethodSignatureForSelector:@selector(methodSignatureForSelector:)] forKey:@"methodSignatureForSelector:"]; 	// predefine NSMethodSignature cache 
	[_selectorCache setObject:[NSConnection instanceMethodSignatureForSelector:@selector(rootObject)] forKey:@"rootObject"]; 	// predefine NSMethodSignature cache 
	[aConnection _addRemote:self forTarget:_target];	// add to remote objects
	_isLocal=NO;
	return self;
}

- (void) setProtocolForProxy:(Protocol*)aProtocol;
{
	// FIXME: this is currently broken!
	// methodSignatureForSelector correctly returns the qualifiers while a remote request to the implementation doesn't
	// HACK:
	if(aProtocol)
		*(Class *)aProtocol=[Protocol class];	// isa pointer of @protocol(xxx) is sometimes not properly initialized
#if 0
	NSLog(@"-setProtocolForProxy:");
	NSLog(@"protocol %p", aProtocol);
	// try to dissect the Protocol record...
	NSLog(@"protocol %p[%d]=%p isa", aProtocol, 0, ((long *)aProtocol)[0]);
	NSLog(@"protocol %p[%d]=%p protocol_name", aProtocol, 1, ((long *)aProtocol)[1]);
	NSLog(@"protocol %p[%d]=%p protocol_list", aProtocol, 2, ((long *)aProtocol)[2]);
	NSLog(@"protocol %p[%d]=%p instance_methods", aProtocol, 3, ((long *)aProtocol)[3]);
	NSLog(@"protocol %p[%d]=%p class_methods", aProtocol, 4, ((long *)aProtocol)[4]);
	NSLog(@"protocol %s", [aProtocol name]);
#endif
	_protocol=aProtocol;	// protocols are sort of static objects so we don't have to retain
}

// NOTE: implementing this method makes problems for NSLog(@"object that returns - (byref NSString)", remoteObject)
// since NSLog calls description which does NOT return the represented value but this string
// returning NSString bycopy is no problem

- (NSString *) description
{ // we should use [_protocol name] but that appears to be broken
	return [NSString stringWithFormat:
		@"<%@ %@ %p>\ntarget=%p\nprotocol=%s\nconnection=%@",
		_isLocal?@"local":@"remote",
		NSStringFromClass([self class]), self,
		_target,
		_protocol?[_protocol name]:"<NULL>",
		_connection];
}

- (void) dealloc;
{
	// invalidateProxy
#if 0
	NSLog(@"-dealloc: %@", self);
#endif
	if(!_isLocal && _target)
			{ // send a release request over the connection (except for root proxy)
				static NSInvocation *i;					// can be reused
#if 0
				NSLog(@"send a release request to the remote side: %@", self);
#endif
				if(!i)
						{ // initialize all statically cached invocation to call -release as oneway void
							SEL _sel=@selector(release);
							struct objc_method *m=class_get_instance_method(isa, _sel);	// get signature of our method
#ifdef __APPLE__
							NSMethodSignature *sig=nil;
#else
							NSMethodSignature *sig=[NSMethodSignature signatureWithObjCTypes:m->method_types];
#endif
							[sig _makeOneWay];	// special case - we don't expect an answer
#if 0
							NSLog(@"signature(%@)=%@", NSStringFromSelector(_sel), sig);
#endif
							i=[[NSInvocation alloc] initWithMethodSignature:sig];
							[i setSelector:_sel];			// ask to deallocate proxy
						}
				[i setTarget:self];								// target the remote object
				[self forwardInvocation:i];
				[i _releaseReturnValue];				// no longer needed so that we can reuse the invocation
#if 0
				NSLog(@"did send release request to the remote side: %@", self);
#endif
				[_connection _removeRemote:_target];	// remove from remoteObjects
			}
	[_connection release];	// this will dealloc the connection if we are the last proxy
	[_selectorCache release];
	[super dealloc];
#if 0
	NSLog(@"dealloc done");
#endif
}

- (void) forwardInvocation:(NSInvocation *) invocation;
{ // this encodes the invocation, transmits and waits for a response - exceptions may be rised during communication
#if 0
	NSLog(@"NSDistantObject -forwardInvocation: %@ though %@", invocation, _connection);
#endif
	// look up connection for this distant object
	[_connection sendInvocation:invocation internal:NO];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector;
{
	// FIXME
	NSMethodSignature *ret=[_selectorCache objectForKey:NSStringFromSelector(aSelector)];
	if(ret)
		return ret;	// known
#if 0
	NSLog(@"[NSDistantObject methodSignatureForSelector:\"%@\"]", NSStringFromSelector(aSelector));
#endif
	if(_protocol)
			{
				struct objc_method_description *md;
#if 0
				NSLog(@"[NSDistantObject methodSignatureForSelector:] _protocol=%s", [_protocol name]);
#endif
				md=[_protocol descriptionForInstanceMethod:aSelector];	// ask protocol for the signature
//				ret=[NSMethodSignature signatureWithObjCTypes:md->types];
				ret=nil;
			}
	else if(_isLocal && _target)
		ret=[_target methodSignatureForSelector:aSelector];	// ask local object for its signature
	else
			{
#if __APPLE__
				NSInvocation *i;	// cached invocation
#if 1
				NSLog(@"No protocol defined for NSDistantObject - so try forwarding the message and ask the other side for the signature");
#endif
				i=[NSInvocation invocationWithMethodSignature:[NSObject instanceMethodSignatureForSelector:_cmd]];	// use my own signature
				[i setSelector:_cmd];
				NSAssert([[NSObject instanceMethodSignatureForSelector: _cmd] methodReturnLength] == sizeof(ret), @"return value size problem");
				[i setTarget:self];
				[i setArgument:&aSelector atIndex:2];	// set the selector we want to know about as the argument
				[_connection sendInvocation:i internal:YES];
				[i getReturnValue:&ret];				// fetch signature from invocation
#else
				static NSInvocation *i;	// cached invocation
#if 1
				NSLog(@"No protocol defined for NSDistantObject - so try forwarding the message and ask the other side for the signature");
#endif
				if(!i)
						{ // initialize cached invocation
							i=[[NSInvocation alloc] initWithMethodSignature:[NSObject instanceMethodSignatureForSelector:_cmd]];	// use my own signature
							[i setSelector:_cmd];
							NSAssert([[NSObject instanceMethodSignatureForSelector: _cmd] methodReturnLength] == sizeof(ret), @"return value size problem");
						}
				[i setTarget:self];
				[i setArgument:&aSelector atIndex:2];	// set as the argument the selector we want to know about
				[self forwardInvocation:i];				// and process
				[i getReturnValue:&ret];				// fetch signature from invocation
				[i _releaseReturnValue];				// no longer needed so that we can reuse the invocation
#endif
			}
	[_selectorCache addObject:ret forKey:NSStringFromSelector(aSelector)];	// add to cache
#if 0
	NSLog(@"  methodSignatureForSelector %@ -> %s", NSStringFromSelector(aSelector), ret);
#endif
	return ret;
}

+ (BOOL) respondsToSelector:(SEL)aSelector;
{ // CHEKCKME: is this correct? Should we ask the other side for the class? Who is our class proxy?
//	return [[_target class] respondsToSelector:aSelector];
	return NO;
}

- (BOOL) respondsToSelector:(SEL)aSelector
{
	if(class_get_instance_method([NSDistantObject class], aSelector) != METHOD_NULL)
		return YES;	// it is a method of NSDistantObject
	if(_protocol)
		{ // check if protocol responds
		if([_protocol descriptionForInstanceMethod:aSelector])
			return YES;
		if([_protocol descriptionForClassMethod:aSelector])
			return YES;
		}
	if(_isLocal && [_target respondsToSelector:aSelector])
		return YES;	// yes, the local object responds
	return [super respondsToSelector:aSelector];	// we must ask the remote side
}

- (Class) classForCoder; { return /*isa*/ NSClassFromString(@"NSDistantObject"); }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't ever replace by another proxy

- (void) encodeWithCoder:(NSCoder *) coder;
{
#if maybeneeded
	NSConnection *c=[(NSPortCoder *) coder connection];
	// lookUpConnectionForProxy
	// lookUpWireIDForProxy
#endif
#if 0
	NSLog(@"%@ encodeWithCoder (local=%@ target=%p)", NSStringFromClass(isa), _isLocal?@"YES":@"NO", _target);
#endif
	[coder encodeValueOfObjCType:@encode(int) at:&_target];	// encode as a reference into the address space and not the real object
//	[coder encodeValueOfObjCType:@encode(BOOL) at:&_isLocal];
}

- (id) initWithCoder:(NSCoder *) coder;
{
	id ref;	// reference
	[coder decodeValueOfObjCType:@encode(void *) at:&ref];
	[coder decodeValueOfObjCType:@encode(BOOL) at:&_isLocal];	// NOTE: the meaning if _isLocal is reversed since it is encoded for the proxy side!
#if 1
	NSLog(@"%@ initWithCoder (local(on remote side)=%@ ref=%p)", NSStringFromClass(isa), _isLocal?@"YES":@"NO", ref);
#endif
	if(_isLocal) // local has reversed interpretation when decoding
			{ // local object on remote side - use/create a proxy on our side
				return [self initWithTarget:ref connection:[(NSPortCoder *)coder connection]];	// looks up in cache or creates a new one
			}
	else
			{ // remote proxy on other side - reference our local object
				if(ref == nil)
					ref=[[(NSPortCoder *)coder connection] rootObject];	// remote side asks for our root object - substitute
#if SUPPORTS_64_BIT
				else
						{
							// translate 32 bit reference to real adress
						}
#endif
#if 0
				NSLog(@"received reference to %@", ref);
#endif
				[self release];
				return [ref retain];	// return the referenced object
			}
}

+ (id) newDistantObjectWithCoder:(NSCoder *) coder;
{
	return [[self alloc] initWithCoder:coder];
}

@end

@implementation NSProtocolChecker

+ (id) protocolCheckerWithTarget:(NSObject *)anObject protocol:(Protocol *)aProtocol;
{
	return [[[self alloc] initWithTarget:anObject protocol:aProtocol] autorelease];
}

- (id) initWithTarget:(NSObject *)anObject protocol:(Protocol *)aProtocol;
{
	if((self=[super init]) && !_protocol)	// don't allow remote side to send a new initWithTarget method to me...
		{
		_protocol=aProtocol;
		_target=[anObject retain];
		}
	return self;
}

- (void) dealloc;
{
	[_target release];
	[super dealloc];
}

- (Protocol *) protocol; { return _protocol; }
- (NSObject *) target; { return _target; }

// CHECKME:

- (BOOL) respondsToSelector:(SEL)aSelector;
{
	return [_protocol descriptionForInstanceMethod:aSelector] != NULL;
}

- (void) forwardInvocation:(NSInvocation *) invocation;
{
	if(![self respondsToSelector:[invocation selector]]) 
		[NSException raise:@"NSProtocolCheckerException" format:@"protocol does not permit to call %@", NSStringFromSelector([invocation selector])];
	[invocation invokeWithTarget:_target];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector;
{ // ask protocol
	return [_protocol _methodSignatureForInstanceMethod:aSelector];
}
	
@end
