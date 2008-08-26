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
#endif
#if 1
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

@implementation NSDistantObject

// this object forwards messages to the peer

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
	// we have no superclass!
	_connection=[aConnection retain];	// keep the connection as long as we exist
	_target=anObject;
	[(NSMutableArray *) [aConnection localObjects] addObject:anObject];	// add to list
	[self retain];	// additional retain so that we keep around until remote side deallocates us
	_isLocal=YES;
	return self;
}

- (id) initWithTarget:(id)anObject connection:(NSConnection*)aConnection;
{ // remoteObject is an id in another thread or another application’s address space!
	NSDistantObject *p=[aConnection _getRemote:anObject];
	if(p)
			{ // we already have a proxy for this target
				[self release];
				return [p retain];
			}
	_connection=[aConnection retain];	// keep the connection as long as we exist
	_target=anObject;
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
#if 0
	NSLog(@"-dealloc: %@", self);
#endif
	if(!_isLocal && _target)
			{ // send a release request over the connection
				static NSInvocation *i;					// can be reused
#if 0
				NSLog(@"send a release request to the remote side: %@", self);
#endif
				if(!i)
						{ // initialize all statically cached invocation to call -release as oneway void
#ifndef __Apple__
							SEL _sel=@selector(release);
							struct objc_method *m=class_get_instance_method(isa, _sel);	// get signature of our method
							NSMethodSignature *sig=[NSMethodSignature signatureWithObjCTypes:m->method_types];
							[sig _makeOneWay];	// special case - we don't expect an answer
#if 0
							NSLog(@"signature(%@)=%@", NSStringFromSelector(_sel), sig);
#endif
							i=[[NSInvocation alloc] initWithMethodSignature:sig];
							[i setSelector:_sel];			// ask to deallocate proxy
#endif
						}
				[i setTarget:self];								// target the remote object
				[self forwardInvocation:i];
				[i _releaseReturnValue];				// no longer needed so that we can reuse the invocation
#if 0
				NSLog(@"did send release request to the remote side: %@", self);
#endif
				[_connection _removeRemote:self];	// remove from remoteObjects
			}
	[_connection release];	// this will dealloc the connection if we are the last proxy
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
	[_connection sendInvocation:invocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector;
{
	// FIXME: we should bulld a local Cache for method signatures of remote objects!!!
	// since it might also depend on the server we are communicating with, we have to index by aSelector AND [connection sendPort]
	NSMethodSignature *ret;
#if 0
	NSLog(@"[NSDistantObject methodSignatureForSelector:\"%@\"]", NSStringFromSelector(aSelector));
#endif
	//	NSLog(@"%s %s %08x", sel_get_name(aSelector), sel_get_name(@selector(_forwardMethodSignatureForSelector:)), @selector(_forwardMethodSignatureForSelector:));
	if(SEL_EQ(aSelector, _cmd))	// asking for my own signature! This must be a system-wide constant to avoid recursions
		ret=[NSObject instanceMethodSignatureForSelector:aSelector];	// ask NSObject
	else if(_protocol)
			{
#if 0
				NSLog(@"[NSDistantObject methodSignatureForSelector:] _protocol=%s", [_protocol name]);
#endif
				ret=[_protocol _methodSignatureForInstanceMethod:aSelector];	// ask protocol for the signature
			}
	else if(_isLocal && _target)
		ret=[_target methodSignatureForSelector:aSelector];	// ask local object for its signature
	else
			{
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
			}
	// add to cache
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

- (Class) classForPortCoder; { return isa; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't ever replace by another proxy

/*
 * the mechanics behind this is as follows:
 *
 * if we refer to a remoteObject, this is a remove proxy and we just encode it
 * if we send a localObject byref, it is replaced through replacementObjectForPortCoder by a local NSDistantObject
 * this local distant object is temporary and used only during encoding
 * when decoding a local NSDistantObject, it will generate a new remoteObject proxy on the other side
 * when decoding a remote distant object, it will be simply replaced by a reference to the real object
 * there is a special case for the rootObject / rootProxy which is a proxy generated on the client side refering nil
 * this is received as a local distant object at address nil
 */

- (void) encodeWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"%@ encodeWithCoder (local=%@ target=%p)", NSStringFromClass(isa), _isLocal?@"YES":@"NO", _target);
#endif
	[coder encodeValueOfObjCType:@encode(BOOL) at:&_isLocal];
#if SUPPORTS_64_BIT
	if(_isLocal)
			{ //
				// translate from 64 bit local object address to 32 bit remote reference
			}
#endif
	[coder encodeValueOfObjCType:@encode(void *) at:&_target];	// encode as a reference into the address space and not the object
}

- (id) initWithCoder:(NSCoder *) coder;
{
	id ref;	// reference
	[coder decodeValueOfObjCType:@encode(BOOL) at:&_isLocal];	// NOTE: the meaning if _isLocal is reversed since it is encoded for the proxy side!
	[coder decodeValueOfObjCType:@encode(void *) at:&ref];
#if 0
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
