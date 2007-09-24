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

#import "NSPrivate.h"

// should be moved to runtime specific classes

@implementation Protocol (NSPrivate)

- (NSMethodSignature *) _methodSignatureForInstanceMethod:(SEL)aSel;
{
	const char *types = NULL;
#ifndef __APPLE__
	struct objc_method_description *mth;
	if((mth = [self descriptionForInstanceMethod: aSel]) == NULL)
		return nil;
	types = mth->types;
	if(types == NULL)
		return nil;
#endif
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

@implementation NSDistantObject

// this object forwards messages to the peer

+ (NSDistantObject*) proxyWithLocal:(id)anObject
						 connection:(NSConnection*)aConnection;
{ // this is initialization for vending objects
	return [[[self alloc] initWithLocal:anObject connection:aConnection] autorelease];
}

+ (NSDistantObject*) proxyWithTarget:(id)anObject
						  connection:(NSConnection*)aConnection;
{ // remoteObject is an id in another thread or another application’s address space!
	return [[[self alloc] initWithTarget:anObject connection:aConnection] autorelease];
}

- (NSConnection*) connectionForProxy; { return _connection; }

- (id) initWithLocal:(id)anObject connection:(NSConnection*)aConnection;
{ // this is initialization for vending objects
#if OLD
	id obj=[aConnection _getLocal:anObject];
#if 0
	NSLog(@"NSDistantObject: initWithLocal:%p connection:%@", anObject, aConnection);
#endif
	if(obj)
		{ // already known, return distant object instead
#if 1
		NSLog(@"  known: %@", obj);
#endif
		[self release];
		return [obj retain];
		}
#endif
	_connection=[aConnection retain];	// keep the connection as long as we exist
	_target=[anObject retain];
	_isLocal=YES;
//	[aConnection _mapLocal:self forRef:anObject];
	return self;
}

- (id) _localObject; { return NIMP /*_object*/; }

- (id) initWithTarget:(id)anObject connection:(NSConnection*)aConnection;
{ // remoteObject is an id in another thread or another application’s address space!
#if OLD
	id obj;
#if 1
	NSLog(@"NSDistantObject: initWithTarget:%p connection:%@ obj:%@", anObject, aConnection);
#endif
	obj=[aConnection _getRemote:anObject];
	if(obj)
		{ // already known, return existing distant object instead
#if 1
		NSLog(@"  known: %@", obj);
#endif
		[self release];
		return [obj retain];
		}
#endif
	_connection=[aConnection retain];	// keep the connection as long as we exist
	_target=anObject;
//	if(anObject)
//		[aConnection _mapRemote:self forRef:anObject];
	_isLocal=NO;
	return self;
}

- (void) setProtocolForProxy:(Protocol*)aProtocol;
{
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

- (NSString *) description
{ // we should use [_protocol name] but that appears to be broken
	return [NSString stringWithFormat:
		@"<%@ %p>\nconnection=%@\ntarget=%p\n%@\nprotocol=%s",
		NSStringFromClass([self class]), self,
		_connection,
		_target,
		_isLocal?@"local":@"remote",
		   _protocol?[_protocol name]:"<NULL>"];
}

+ (BOOL) respondsToSelector:(SEL)aSelector;
{
	NIMP;
	// translate to [[target class] classRespondsToSelector]
	return NO;
}

- (void) dealloc;
{
	if(_target)
		{ // send a request over the connection to remove the proxy there!
		NSLog(@"??? should we send a -dealloc to the remote side: %@", self);
		}
	if(_isLocal)
		[_target release];
//	if(_object)
//		[_connection _mapLocal:nil forRef:_object];
//	else
//		[_connection _mapRemote:nil forRef:_target];
//	[_object release];
	[_connection release];	// dealloc the connection if we are the last proxy
	[super dealloc];
}

- (void) forwardInvocation:(NSInvocation *) invocation;
{ // this encodes the invocation, transmits and waits for a response - exceptions may be rised during communication
#if 0
	NSLog(@"NSDistantObject -forwardInvocation: %@ though %@", invocation, _connection);
#endif
	[_connection sendInvocation:invocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector;
{
	static NSInvocation *i;	// cached invocation
	NSMethodSignature *ret;
#if 1
	NSLog(@"[NSDistantObject methodSignatureForSelector:\"%@\"]", NSStringFromSelector(aSelector));
#endif
	//	NSLog(@"%s %s %08x", sel_get_name(aSelector), sel_get_name(@selector(_forwardMethodSignatureForSelector:)), @selector(_forwardMethodSignatureForSelector:));
	if(SEL_EQ(aSelector, @selector(methodSignatureForSelector:)))
		{ // asking for my own signature! Must be a system-wide constant to avoid recursion
		return [NSObject instanceMethodSignatureForSelector:aSelector];	// ask NSObject
		}
	
	// FIXME: use a local Cache for method signatures of remote objects!!!
	// might depend on server we are communicating with - so index by selector&[connection sendPort]
#if 1
	NSLog(@"[NSDistantObject methodSignatureForSelector:] _protocol=%s", [_protocol name]);
#endif
	if(_protocol)
		return [_protocol _methodSignatureForInstanceMethod:aSelector];	// ask protocol for the signature
	if(_isLocal && _target)
		return [_target methodSignatureForSelector:aSelector];	// ask local object for its signature
#if 1
	NSLog(@"No protocol defined for NSDistantObject - so try forwarding the message");
#endif
	if(!i)
		{ // initialize cached invocation
		i=[[NSInvocation invocationWithMethodSignature:[NSObject instanceMethodSignatureForSelector:_cmd]] retain];	// use my own signature
		[i setSelector:_cmd];
		// should check [[NSObject instanceMethodSignatureForSelector: _cmd] methodReturnLength] == sizeof(ret)
		}
	// FIXME:
	// shouldn't we better ask the distant object for the @encode() as an NSString and
	// convert it into a local NSMethodSignature
	// instead of trying to encode a remote methodSignature???
	[i setTarget:self];
	[i setArgument:&aSelector atIndex:2];	// set as the argument the selector we want to know about
	[self forwardInvocation:i];				// and process
	[i getReturnValue:&ret];				// fetch from invocation
	return ret;
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

- (Class) classForPortCoder; { return isa; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't ever replace by another proxy

- (void) encodeWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"%@ encodeWithCoder (local=%@ target=%p)", NSStringFromClass(isa), _isLocal?@"YES":@"NO", _target);
#endif
	[coder encodeValueOfObjCType:@encode(BOOL) at:&_isLocal];
	[coder encodeValueOfObjCType:@encode(void *) at:&_target];	// encode as a reference into the address space and not the object
}

- (id) initWithCoder:(NSCoder *) coder;
{
	id ref;	// reference
	[coder decodeValueOfObjCType:@encode(BOOL) at:&_isLocal];
	[coder decodeValueOfObjCType:@encode(void *) at:&ref];
#if 0
	NSLog(@"%@ initWithCoder (local=%@ ref=%p)", NSStringFromClass(isa), _isLocal?@"NO":@"YES", ref);	// local has reversed interpretation when decoding
#endif
	if(ref == nil)
		{ // remote side asks for our connection object - substitute
		return [[(NSPortCoder *)coder connection] retain];
		}
	if(_isLocal)
		return [self initWithTarget:ref connection:[(NSPortCoder *)coder connection]];	// look up in cache or create
	else
		return [ref retain];
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
