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

@interface NSDistantObject (Private)	// derived from classdumps found on the net but partially not implemented

+ (void) _enableLogging:(BOOL) flag;	// NIMP
+ (id) newDistantObjectWithCoder:(NSCoder *) arg1;
- (id) initWithTarget:(id) arg1 connection:(NSConnection *) arg2;
- (id) initWithLocal:(id) arg1 connection:(NSConnection *) arg2;
- (id) protocolForProxy;
- (void) _releaseWireCount:(unsigned long long) cnt;	// NIMP
- (void) retainWireCount;	// NIMP
- (Class) classForCoder;

// obviously varargs need special handling on DO
- (NSString *) stringByAppendingFormat:(NSString *) arg1, ...;
- (void) appendFormat:(NSString *) arg1, ...;

@end

@interface Protocol (NSPrivate)

- (NSMethodSignature *) _methodSignatureForInstanceMethod:(SEL)aSel;
- (NSMethodSignature *) _methodSignatureForClassMethod:(SEL)aSel;

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

// this are very old Obj-C methods now completely wrapped but still used as the backbone of DO

+ (struct objc_method_description *) methodDescriptionForSelector:(SEL) sel;
{
	struct objc_method_description *r=class_get_instance_method(self, sel);
#if 0
	r.types=translateSignatureToNetwork(r.types);	// translate to network representation, i.e. strip off offsets and transcode some encodings
#endif
	return r;
}

- (struct objc_method_description *) methodDescriptionForSelector:(SEL) sel;
{ // the result is compatible to because the struct is defined in GNU libobjc as { SEL sel, char *types; } */
	struct objc_method_description *r=class_get_instance_method(self->isa, sel);
#if 1
	NSLog(@"- methodDescriptionForSelector:'%@'", NSStringFromSelector(sel));
#endif
#if 0
	r.types=translateSignatureToNetwork(r.types);	// translate to network representation, i.e. strip off offsets and transcode some encodings
#endif
	return r;
}

// this is listed in http://www.opensource.apple.com/source/objc4/objc4-371/runtime/objc-sel-table.h

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
	const char *n;
#ifdef __APPLE__
	n=object_getClassName(self);
#else
	n=class_get_class_name(isa);
#endif
#if 1
	NSLog(@"_localClassNameForClass -> %p %s", n, n);
#endif	
	return n;
}

@end

static NSHashTable *distantObjects;	// collects all NSDistantObjects to make them exist only once

// FIXME: we still need to separate name/number spaces of different connections!!!
// therefore we need a different trick to look up by remote id

static NSMapTable *distantObjectsByRef;	// maps all existing NSDistantObjects to access them by remote reference

@implementation NSDistantObject		// this object forwards messages to the peer

static Class _doClass;

// more private methods
// + (void) _enableLogging:(BOOL)arg1;
// - (void) _releaseWireCount:(unsigned long long)arg1;

+ (void) initialize
{
	_doClass=[NSDistantObject class];
	distantObjects=NSCreateHashTable(NSNonRetainedObjectHashCallBacks, 100);
	distantObjectsByRef=NSCreateMapTable(NSIntMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks, 100);
}

+ (NSDistantObject*) proxyWithLocal:(id)anObject
						 connection:(NSConnection*)aConnection;
{ // this is initialization for vending objects or encoding references so that they can be decoded as remote proxies
	return [[[self alloc] initWithLocal:anObject connection:aConnection] autorelease];
}

+ (NSDistantObject*) proxyWithTarget:(id)anObject
						  connection:(NSConnection*)aConnection;
{ // remoteObject is an id in another thread or another applicationâ or address space!
	return [[[self alloc] initWithTarget:anObject connection:aConnection] autorelease];
}

- (BOOL) isEqual:(id)anObject
{ // used for finding copies that reference the same local object
	NSDistantObject *other=anObject;
	if(other->_connection != _connection)
		return NO;	// different connection
	if(_local)
		return _local == other->_local;	// same local object
	return _remote == _remote;	// same reference
}

- (unsigned int) hash
{ // if the objects are the same they must have the same hash value! - if they are different, some overlap is allowed
	NSLog(@"hash %p", self);
	if(_local)
		return (unsigned int) _connection + (unsigned int) _local;	// it is sufficient to reference the same object and connection
	return (unsigned int) _connection + (unsigned int) _remote;	// same remote id
}

- (NSConnection *) connectionForProxy; { return _connection; }

- (id) init
{ // no need to [super init] because we are subclass of NSProxy
	_selectorCache=[[NSMutableDictionary alloc] initWithCapacity:10];
	// fixme: should there be a global cache? If yes, how to handle conflicting signatures for different classes?
	[_selectorCache setObject:[NSObject instanceMethodSignatureForSelector:@selector(methodDescriptionForSelector:)] forKey:@"methodDescriptionForSelector:"]; 	// predefine NSMethodSignature cache
	//	[_selectorCache setObject:[NSObject instanceMethodSignatureForSelector:@selector(methodSignatureForSelector:)] forKey:@"methodSignatureForSelector:"]; 	// predefine NSMethodSignature cache
	[_selectorCache setObject:[NSObject instanceMethodSignatureForSelector:@selector(respondsToSelector:)] forKey:@"respondsToSelector:"]; 	// predefine NSMethodSignature cache
	return self;
}

- (id) initWithLocal:(id)localObject connection:(NSConnection*)aConnection;
{ // this is initialization for vending objects
	id remoteObjectId;
	static unsigned int nextReference=1;	// shared between all connections and unique for this address space
	NSDistantObject *proxy;
	if(!aConnection || !localObject)
		{
		[self release];
		return nil;
		}
	_connection=aConnection;
	_local=localObject;
	proxy=NSHashGet(distantObjects, self);	// returns nil or any object that -isEqual:
	if(proxy)
		{ // already known
#if 1
			NSLog(@"local proxy for %@ already known: %@", localObject, proxy);
#endif
			_local=nil;	// avoid that the proxy is deleted from the NSHashTable!
			[self release];	// release current object
			return [proxy retain];	// retain and substitute the existing proxy
		}
	[aConnection _incrementLocalProxyCount];
	[_local retain];	// retain the local object as long as we exist
	self=[self init];	// initialize more parts
#if 1	// this enables mixing 32 and 64 bit address spaces
	remoteObjectId=(id) nextReference++;	// assign serial numbers to be able to mix 32 and 64 bit address spaces
#else	// this is most likely a very old OpenSTEP behaviour stimulated by using an object address for proxyWithLocal:
	remoteObjectId=localObject;	// use a unique 32 bit object address as descibed in the manual
#endif
	_remote=remoteObjectId;
	NSHashInsertKnownAbsent(distantObjects, self);
	NSMapInsertKnownAbsent(distantObjectsByRef, (void *) _remote, self);
#if 1
	NSLog(@"new local proxy (ref=%u) initialized: %@", _remote, self);
#endif
	return self;
}

- (id) initWithTarget:(id)remoteObject connection:(NSConnection*)aConnection;
{ // remoteObject is an id (without local meaning!) in another thread or another applicationâ in their address space!
	NSDistantObject *proxy;
	if(!aConnection)
		{
		[self release];
		return nil;
		}
	_connection=aConnection;	// we are retained by the connection so don't leak
	_remote=remoteObject;
	proxy=NSHashGet(distantObjects, self);	// returns nil or any object that -isEqual:
	if(proxy)
		{ // we already have a proxy for this target
#if 1
			NSLog(@"remote proxy for %p already known: %@", remoteObject, proxy);
#endif
			[self release];	// release newly allocated object
			return [proxy retain];	// retain the existing proxy once
		}
	self=[self init];
	if(remoteObject == nil)	// root proxy
		{
		NSMethodSignature *ms=[aConnection methodSignatureForSelector:@selector(rootObject)];
		if(ms)	// don't assume it exists
			[_selectorCache setObject:ms forKey:@"rootObject"]; 	// predefine NSMethodSignature cache
		}
	NSHashInsertKnownAbsent(distantObjects, self);
#if 1
	NSLog(@"new remote proxy (ref=%u) initialized: %@", (unsigned int) remoteObject, self);
#endif
	return self;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	unsigned int ref;
	BOOL flag1, flag2=NO;
	NSDistantObject *proxy;
	NSConnection *c=[(NSPortCoder *) coder connection];
#if 0
	NSLog(@"NSDistantObject initWithCoder:%@", coder);
#endif
	[coder decodeValueOfObjCType:@encode(unsigned int) at:&ref];
	_remote=(id) ref;
	[coder decodeValueOfObjCType:@encode(char) at:&flag1];
//	[coder decodeValueOfObjCType:@encode(char) at:&flag2];	// latest unittesting shows that there is no flag2!?!
#if 1
	NSLog(@"NSDistantObject %p initWithCoder -> ref=%p flag1=%d flag2=%d", self, _remote, flag1, flag2);
#endif
	if(flag1)
		{ // local (i.e. remote seen from sender's perspective)
			proxy=NSMapGet(distantObjectsByRef, (void *) _remote);
			if(proxy)
				{ // local proxy for this target found
#if 1
					NSLog(@"replace (ref=%u) by local proxy %@", ref, proxy);
#endif
					[self release];	// release newly allocated object
					return [proxy retain];	// retain the existing proxy once
				}
#if 1
			NSLog(@"unknown object (ref=%u) referenced by peer", ref);
#endif
			// unknown - refers to connection (to get rootObject)
			// do we check for _remote==nil?
			[self release];	// release newly allocated object
			return [c retain];	// unknown remote id refers to the connection object (???)
		}
	else
		{ // clients sends us a handle to access its remote object
			proxy=NSMapGet(distantObjectsByRef, (void *) _remote);
			if(proxy)
				{ // local proxy for this target found
#if 1
					NSLog(@"replace (ref=%u) by remote proxy %@", ref, proxy);
#endif
					[self release];	// release newly allocated object
					return [proxy retain];	// retain the existing proxy once
				}
#if 1
			NSLog(@"new remote object (ref=%u) received", ref);
#endif
			self=[self initWithTarget:_remote connection:c];	// initialize and install reference in _getRemote
			return self;
		}
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

- (id) protocolForProxy;
{
	return _protocol;
}

- (bycopy NSString *) description
{ // we should use [_protocol name] but that appears to be broken
	if(_local)
		return [_local description];
	return [NSString stringWithFormat:
			@"<%@ %p>\ntarget/local=%p remote=%p\nprotocol=%s\nconnection=%@",
			NSStringFromClass([self class]), self,
			_local,	_remote,
			_protocol?[_protocol name]:"<NULL>",
			_connection];
}

- (void) dealloc;
{
#if 1
	NSLog(@"NSDistantObject %p dealloc", self);
#endif
	/*
	if(_local)
		{
		[self _removeLocalDistantObjectForLocal:_local andRemote:_remote connection:_connection];
		[_local release];		
		}
	else
		[self _removeRemoteDistantObjectForRemote:_remote connection:_connection];
	 */
	NSHashRemove(distantObjects, self);
	NSMapRemove(distantObjectsByRef, (void *) _remote);
	if(_local)
		{
		[_local release];
		[_connection _decrementLocalProxyCount];
		}
	[_selectorCache release];
	[super dealloc];
#if 1
	NSLog(@"NSDistantObject %p dealloc done", self);
#endif
}

- (void) forwardInvocation:(NSInvocation *) invocation;
{ // this encodes the invocation, transmits and waits for a response - exceptions may be raised during communication
#if 1
	[invocation description];
	NSLog(@"NSDistantObject %p -forwardInvocation: %@ through %@", self, invocation, _connection);
#endif
	if(_local)
		[invocation invokeWithTarget:_local];	// have our local target receive the message for which we are the original target
	else
		[_connection sendInvocation:invocation internal:NO];	// send to peer and insert return value
#if 1
	NSLog(@"forwardInvocation done");
#endif
}

#if 0	// we can use the normal forwardInvocation: strategy

// FIXME: which of the following methods is 'basic' and forwarded to the peers and which is 'derived'?
// it appears that DO always uses a remote methodDescriptionForSelector even to get a methodSignatureForSelector
// so we must implement this method for local objects (so that a client can ask us)

- (struct objc_method_description *) methodDescriptionForSelector:(SEL)aSelector;
{ // returns NULL if unknown
	if(_local)
		{
		struct objc_method_description *md=[_local methodDescriptionForSelector:aSelector]; // forward to wrapped object
#if 1
		NSLog(@"md=%p", md);
		if(md)
			{ // exists
				NSLog(@"md.name=%s", md->name);
				NSLog(@"md.types=%p", md->types);			
			}
#endif
		return md;
		}
	// FIXME: forward!
	NIMP;
	return NULL;
#if 0
	// Hm. This implementation assumes that we get a NSMethodSignature for the selector
	NSMethodSignature *ret=[_selectorCache objectForKey:NSStringFromSelector(aSelector)];
	if(ret)
		return ret;	// known from cache
	struct objc_method_description *md;
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[_selectorCache objectForKey:_cmd]];
	[i setTarget:self];
	[i setSelector:_cmd];
	[i setArgument:&aSelector atIndex:2];
	[_connection sendInvocation:i internal:YES];
	[i getReturnValue:&md];
	// get the type
	return md;
#endif
}
#endif

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector;
{
	struct objc_method_description *md;
	NSMethodSignature *ret=[_selectorCache objectForKey:NSStringFromSelector(aSelector)];
	if(ret)
		return ret;	// known from cache
	// FIXME: what about methodSignature of the methods in NSDistantObject/NSProxy?
#if 1
	NSLog(@"[NSDistantObject methodSignatureForSelector:\"%@\"]", NSStringFromSelector(aSelector));
#endif
	if(_local)
		{
		ret=[_local methodSignatureForSelector:aSelector];	// ask local object for its signature
		if(!ret)
			[NSException raise:NSInternalInconsistencyException format:@"local object does not define @selector(%@): %@", NSStringFromSelector(aSelector), _local];
		}
	else if(_protocol)
		{ // ask protocol
#if 1
			NSLog(@"[NSDistantObject methodSignatureForSelector:] _protocol=%s", [_protocol name]);
#endif
			md=[_protocol descriptionForInstanceMethod:aSelector];	// ask protocol for the signature
			if(!md)
				[NSException raise:NSInternalInconsistencyException format:@"@protocol %s does not define @selector(%@)", [_protocol name], NSStringFromSelector(aSelector)];
		}
	else
		{	// we must ask the peer for a methodDescription
			NSMethodSignature *sig=[_selectorCache objectForKey:@"methodDescriptionForSelector:"];
			NSInvocation *i=[NSInvocation invocationWithMethodSignature:sig];
			NSAssert(sig, @"methodsignature for methodDescriptionForSelector: must be known");
#if 1
			NSLog(@"_selectorCache=%@", _selectorCache);
			NSLog(@"ask peer: %@", i);
#endif
			[i setTarget:self];
			[i setSelector:@selector(methodDescriptionForSelector:)];
			[i setArgument:&aSelector atIndex:2];
			[_connection sendInvocation:i internal:YES];
			[i getReturnValue:&md];
#if 1
			NSLog(@"md=%p", md);
			if(md)
				{
				NSLog(@"md->sel=%p %s", md->name, md->name);		// SEL
				NSLog(@"md->types=%p %s", md->types, md->types);	// char *				
				}
#endif
#if 0
			// NOTE: we do not need this if our NSMethodSignature understands the network signature encoding - but it doesn't because we can use our local @encode()
			if(md)
				md->types=translateSignatureFromNetwork(md->types);
#endif
			if(!md)
				[NSException raise:NSInternalInconsistencyException format:@"peer does not know methodSignatureForSelector:@selector(%@)", NSStringFromSelector(aSelector)];
		}
	if(md)
		{
		ret=[NSMethodSignature signatureWithObjCTypes:md->types];	// a NSMethodSignature is always a local object and never a NSDistantObject
		[_selectorCache setObject:ret forKey:NSStringFromSelector(aSelector)];	// add to cache
		}
#if 1
	NSLog(@"  methodSignatureForSelector %@ -> %@", NSStringFromSelector(aSelector), ret);
#endif
	return ret;
}

+ (BOOL) respondsToSelector:(SEL)aSelector;
{
	return (class_get_instance_method(self, aSelector) != METHOD_NULL);
}

// this is officially only available in NSObject class (not protocol!)

+ (BOOL) instancesRespondToSelector:(SEL)aSelector;
{ // CHECKME: how can we know that?
	if(class_get_instance_method(self, aSelector) != METHOD_NULL)
		return YES;	// this is a method of NSDistantObject
	// we don't know a remote object or protocols here!
	return NO;
}

- (BOOL) respondsToSelector:(SEL)aSelector;
{ // ask if peer provides a methodSignature
	NS_DURING
		NS_VALUERETURN([self methodSignatureForSelector:aSelector] != nil, BOOL);
	NS_HANDLER
		return NO;
	NS_ENDHANDLER
}

- (Class) classForCoder; { return _doClass; }	// for compatibility

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't ever replace by another proxy


- (void) encodeWithCoder:(NSCoder *) coder;
{ // just send the reference number
	BOOL flag;
	unsigned int ref=(unsigned int) _remote;	// reference addresses/numbers are encoded as 32 bit unsigned integers although the API declares them as id
#if 1
	NSLog(@"NSDistantObject encodeWithCoder (%@ ref=%u): %@", _local==nil?@"remote":@"local", ref, self);
#endif
	[coder encodeValueOfObjCType:@encode(unsigned int) at:&ref];	// encode as a reference into the address space and not the real object
	flag=(_local == nil);	// local(0) vs. remote(1) flag
	[coder encodeValueOfObjCType:@encode(char) at:&flag];
//	flag=YES;	// always 1 -- is this a "keep alive" flag?
//	[coder encodeValueOfObjCType:@encode(char) at:&flag];
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
