/* 
   NSConnection.m

   Implementation of connection object for remote object messaging

   Copyright (C) 1994, 1995, 1996, 1997 Free Software Foundation, Inc.

   Created by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date: July 1994
   OPENSTEP rewrite by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: August 1997
 
   Changed to encode/decode NSInvocations:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: October 2003
 
   Complete rewrite:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: Jan 2006
   Some implementation expertise comes from from Crashlogs found on the Internet: Google for "Thread 0 Crashed dispatchInvocation" - and examples of "class dump"
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
 
   Known Bugs:
   * leaks memory since its retains the NSConnection on each received request
   * independendQueueing not implemented
   * does not use the currentConversation token
   * does not implement -localObjects and -remoteObjects
   * does not release/dealloc objects (and connections?)
   * the mechanism of notifying a response to the runloop in sendInvocation appears to work not to be elegant
 
*/

#import <Foundation/NSRunLoop.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSDistantObject.h>

#import "NSPrivate.h"

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

// for statstics...
NSString *NSConnectionRepliesReceived = @"NSConnectionRepliesReceived";
NSString *NSConnectionRepliesSent = @"NSConnectionRepliesSent";
NSString *NSConnectionRequestsReceived = @"NSConnectionRequestsReceived";
NSString *NSConnectionRequestsSent = @"NSConnectionRequestsSent";
// mySTEP extensions
NSString *NSConnectionLocalCount = @"NSConnectionLocalCount";
NSString *NSConnectionProxyCount = @"NSConnectionProxyCount";

NSString *NSFailedAuthenticationException = @"NSFailedAuthenticationException";

@implementation NSDistantObjectRequest

- (NSConnection *) connection; { return [_coder connection]; }
- (id) conversation; { return _conversation; }
- (NSPortCoder *) _portCoder; { return _coder; }

- (NSInvocation *) invocation;
{ // postpone decoding until we really need it
	if(!_invocation)
		_invocation=[[_coder decodeObject] retain];
	return _invocation;
}

- (id) _initWithPortCoder:(NSPortCoder *) coder;
{
#if 0
	NSLog(@"%@ _initWithPortCoder:%@", NSStringFromClass(isa), coder);
#endif
	if((self=[super init]))
		{
		_coder=coder;	// retain??
		_conversation=[[NSConnection currentConversation] retain];	// the current conversation
		}
	return self;
}

- (void) dealloc;
{
	[_invocation release];
	[super dealloc];
}

- (void) replyWithException:(NSException *) exception;
{
#if 0
	NSLog(@"replyWithException: %@", exception);
#endif
	if([[_invocation methodSignature] isOneway])
		{
#if 1
		NSLog(@"*** replyWithException: %@ - oneway ignored", exception);
#endif
		return;	// no response needed!
		}
	[(NSMutableArray *) [_coder _components] removeAllObjects];	// we simply reuse the port coder object!
	if(exception)		// send back exception
		[_coder encodeObject:exception];
	else	// send back return value
		[_coder encodeObject:_invocation];	// encode resulting invocation (i.e. result and out/inout parameters)
	[[_coder connection] _addAuthentication:(NSMutableArray *) [_coder _components]];
	[_coder _setMsgid:1];	// is a response
#if 0
	NSLog(@"*** (conn=%p) send reply to %@", self, [_coder _sendPort]);
#endif
	[_coder sendBeforeTime:[_connection requestTimeout] sendReplyPort:nil];
}

@end

// FIXME: _allConnections should use a NSMapTable with struct { NSPort *recv, *send; } as key/hash
// but as long as we just have 2-3 connection objects this does not really matter
static NSHashTable *_allConnections;	// used as a cache
static id _currentConversation;

NSString *NSConnectionDidDieNotification=@"NSConnectionDidDieNotification";
NSString *NSConnectionDidInitializeNotification=@"NSConnectionDidInitializeNotification";

@implementation NSConnection

+ (NSArray *) allConnections;
{
#if 0
	NSLog(@"allConnections");
#endif
	return NSAllHashTableObjects(_allConnections);
}

+ (NSConnection *) connectionWithReceivePort:(NSPort *)receivePort
									sendPort:(NSPort *)sendPort;
{
	return [[[self alloc] initWithReceivePort:receivePort sendPort:sendPort] autorelease];
}

+ (NSConnection *) connectionWithRegisteredName:(NSString*)n
										   host:(NSString*)h;
{
	return [self connectionWithRegisteredName:n host:h usingNameServer:nil];
}

+ (NSConnection *) connectionWithRegisteredName:(NSString *)name
										   host:(NSString *)hostName
								usingNameServer:(NSPortNameServer *)server;
{
#if 0
	NSLog(@"connectionWithRegisteredName:%@ host:%@ usingNameServer:%@", name, hostName, server);
#endif
	if(!server)
		server=[NSPortNameServer systemDefaultPortNameServer];
#if 0
	NSLog(@"  ->server:%@", server);
#endif
	return [self connectionWithReceivePort:nil sendPort:[server portForName:name host:hostName]];
}

+ (id) currentConversation; { return _currentConversation; }

+ (NSConnection *) defaultConnection;
{ // there is one per thread
	static NSString *key=@"NSPerThreadConnection";
	NSMutableDictionary *dict=[[NSThread currentThread] threadDictionary];
	NSConnection *defaultConnection=[dict objectForKey:key];
	if(!defaultConnection)
		{ // allocate
		NSPort *port=[NSPort new];	// select port by system
		defaultConnection=[[self alloc] initWithReceivePort:port sendPort:port];
		[dict setObject:defaultConnection forKey:key];
		[port release];
		[defaultConnection release];
		}
	return defaultConnection;
}

+ (NSDistantObject *) rootProxyForConnectionWithRegisteredName:(NSString*)name
														  host:(NSString*)host;
{
	return [self rootProxyForConnectionWithRegisteredName:name host:host usingNameServer:nil];
}

+ (NSDistantObject *) rootProxyForConnectionWithRegisteredName:(NSString *)name
														  host:(NSString *)hostName
											   usingNameServer:(NSPortNameServer *)server;
{
	return [[self connectionWithRegisteredName:name host:hostName usingNameServer:server] rootProxy];
}

+ (id) serviceConnectionWithName:(NSString *) name rootObject:(id) root usingNameServer:(NSPortNameServer *) server;
{
	NSPort *port;
	NSConnection *connection;
	if([server isKindOfClass:[NSMessagePortNameServer class]])
		port=[[[NSMessagePort alloc] init] autorelease];	// assign free port
	else
		port=[[[NSSocketPort alloc] init] autorelease];		// assign free IP port number
	if(!port || ![server registerPort:port name:name])	// register
		 return nil;	// did not register
	connection=[NSConnection connectionWithReceivePort:port sendPort:nil];	// create connection
	[connection setRootObject:root];
	return connection;
}

+ (id) serviceConnectionWithName:(NSString *) name rootObject:(id) root;
{
	return [self serviceConnectionWithName:name rootObject:root usingNameServer:[NSPortNameServer systemDefaultPortNameServer]];
}

- (void) _addAuthentication:(NSMutableArray *) components;
{
	if([_delegate respondsToSelector:@selector(authenticationDataForComponents:)])
		{ // ask delegate to create authentication data, e.g. an MD5 hash of all values
		NSData *data=[_delegate authenticationDataForComponents:components];
		if(!data)
			[NSException raise:NSGenericException format:@"authenticationDataForComponents did return nil"];
		[components addObject:data];
		}
#if 0
	NSLog(@"_addedAuthentication %@", components);
#endif
}

- (void) addRequestMode:(NSString *)mode;
{ // schedule additional mode in all known runloops
	if(![_modes containsObject:mode])
		{
		[_modes addObject:mode];
		[_receivePort addConnection:self toRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
		}
}

- (void) addRunLoop:(NSRunLoop *)runLoop;
{ // schedule in new runloop in all known modes
	NSEnumerator *e=[_modes objectEnumerator];
	NSString *mode;
	while((mode=[e nextObject]))
		[_receivePort addConnection:self toRunLoop:runLoop forMode:mode];
}

- (id) delegate; { return _delegate; }
- (void) enableMultipleThreads; { _multipleThreadsEnabled=YES; }
- (BOOL) independentConversationQueueing; { return _independentConversationQueueing; }

+ (NSConnection *) _connectionWithReceivePort:(NSPort *)receivePort
									 sendPort:(NSPort *)sendPort;
{ // look up if we already know this connection
	// FIXME: this should use a NSMapTable with struct { NSPort *recv, *send; } as key/hash
	// but as long as we just have 2-3 connection objects this does not really matter
	if(_allConnections)
		{
		NSHashEnumerator e=NSEnumerateHashTable(_allConnections);
		NSConnection *c;
		while((c=(NSConnection *) NSNextHashEnumeratorItem(&e)))
			{
			if([c receivePort] == receivePort && [c sendPort] == sendPort)
				return c;	// found!
			}
		}
	return nil;	// not found
}

- (void) _portDidBecomeInvalid:(NSNotification *) n;
{
#if 0
	NSLog(@"_portDidBecomeInvalid: %@", n);
#endif
	[self invalidate];
}

- (id) initWithReceivePort:(NSPort *)receivePort
				  sendPort:(NSPort *)sendPort;
{
#if 0
	NSLog(@"-rootProxy disabled because it leaks one NSMessagePort even if we can't connect (check with ls -l /proc/<procid>/fd)");
	return nil;
#endif
	
#if 0
	NSLog(@"NSConnection -initWithReceivePort:%@ sendPort:%@", receivePort, sendPort);
#endif
	if((self=[super init]))
		{
		NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
		NSConnection *c;
		if(!sendPort)
			{
			if(!receivePort)
				{ // neither port is defined
#if 1
				NSLog(@"NSConnection -init: two nil ports detected (recv=%@ send=%@)", receivePort, sendPort);
#endif
				[self release];
				return nil;
				}
			sendPort=receivePort;	// make same
			}
		else if(!receivePort)
			receivePort=[[[sendPort class] new] autorelease];
		if(receivePort != sendPort && (c=[isa _connectionWithReceivePort:receivePort sendPort:receivePort]))
			{ // parent connection exists - copy root object and all configs
#if 0
			NSLog(@"NSConnection -init: parent connection exists");
#endif
			if([_delegate respondsToSelector:@selector(connection:shouldMakeNewConnection:)] &&
				![_delegate connection:c shouldMakeNewConnection:self])
				{ // did veto
				[self release];
				return nil;
				}
			// is this callback deprecated?
			if([_delegate respondsToSelector:@selector(makeNewConnection:sender:)] &&
				![_delegate makeNewConnection:self sender:c])
				{ // did veto
				[self release];
				return nil;
				}
			_rootObject=[c->_rootObject retain];
			_delegate=c->_delegate;
			_modes=[c->_modes mutableCopy];
			_requestTimeout=c->_requestTimeout;
			_replyTimeout=c->_replyTimeout;
			_replyTimeout=c->_replyTimeout;
			_multipleThreadsEnabled=c->_multipleThreadsEnabled;
			_independentConversationQueueing=c->_independentConversationQueueing;
			_isLocal=c->_isLocal;
			}
		else if((c=[isa _connectionWithReceivePort:receivePort sendPort:sendPort]))
			{ // already exists
#if 0
			NSLog(@"NSConnection -init: connection exists");
#endif
			[self release];
			return [c retain];	// use existing
			}
		else if((c=[isa _connectionWithReceivePort:sendPort sendPort:receivePort]))
			{ // reverse direction exists
#if 0
			NSLog(@"NSConnection -init: reverse connection exists");
#endif
			_isLocal=YES;	// local communication
			return self;
			}
		else
			{
#if 0
			NSLog(@"really new connection");
#endif
			// ????		[_sendPort setDelegate:self];	// get notifications
			_modes=[[NSMutableArray alloc] initWithObjects:NSDefaultRunLoopMode, nil];
			_replyTimeout=_requestTimeout=99999999.0;	// set defaults
			_multipleThreadsEnabled=NO;
			_independentConversationQueueing=NO;
			}
		_receivePort=[receivePort retain];
		_sendPort=[sendPort retain];
		_isValid=YES;
		[self retain];	// make us persistent until we are invaldated
#if 0
		NSLog(@"did set valid");
#endif
		[nc addObserver:self selector:@selector(_portDidBecomeInvalid:) name:NSPortDidBecomeInvalidNotification object:_receivePort];
		_localObjects=[[NSMutableArray alloc] initWithCapacity:10];
		_remoteObjects=NSCreateMapTable(NSNonOwnedPointerOrNullMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 10);	// don't retain remote objects
		if(!_allConnections)
			_allConnections=NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 10);	// allocate - don't retain connections in hash table
		NSHashInsertKnownAbsent(_allConnections, self);	// add us to connections list
		[_receivePort setDelegate:self];	// we want to receive NSPort notifications from receive port
		[_receivePort scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSConnectionReplyMode];
		[self addRequestMode:NSDefaultRunLoopMode];		// schedule ports in current runloop
		[nc postNotificationName:NSConnectionDidInitializeNotification object:self];
#if 0
		NSLog(@"initialized: %p:%@", self, self);
#endif
		}
	return self;
}

- (id) init;
{ // init with default ports
	NSPort *port=[NSPort new];
#if 0
	NSLog(@"NSConnection -init: port=%@", port);
#endif
	self=[self initWithReceivePort:port sendPort:port];	// make a connection for vending objects
	[port release];
	return self;
}

#if 0
- (void) release;
{
	NSLog(@"release %p %u:%@", self, [self retainCount], self);
	[super release];
}
#endif

- (void) dealloc;
{
#if 0
	NSLog(@"dealloc %p:%@", self, self);
#endif
	if(_isValid)
		{ // this should not really occur since we are retained as an observer as long as we are valid!
		NSLog(@"dealloc without invalidate: %p %@", self, self);
		abort();
		[self invalidate];		
		}
#if 0
	NSLog(@"proxy connection: %p", _proxy);
	NSLog(@"local objects: %p", _localObjects);
	NSLog(@"local objects count: %u", [_localObjects count]);
	NSLog(@"remote objects: %p", _remoteObjects);
	NSLog(@"remote objects count: %u", NSCountMapTable(_remoteObjects));
	NSLog(@"remote objects: %@", NSAllHashTableValues(_remoteObjects));
#endif
	[_proxy release];
	[_localObjects release];
	if(_remoteObjects) NSFreeMapTable(_remoteObjects);
	// [_delegate release];	// not retained
	[_receivePort release];	// we are already removed as receivePort observer by -invalidate
	[_sendPort release];
	[_modes release];
	[_rootObject release];
	[_requestQueue release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@\n  recv=%@\n  send=%@\n  root=%@\n  delegate=%@\n  modes=%@\n  req=%.2lf\n  reply=%.2lf\n  flags:%@%@%@",
			NSStringFromClass(isa),
			_receivePort,
			_sendPort,
			_rootObject,
			_delegate,
			_modes,
			_requestTimeout, _replyTimeout,
			_multipleThreadsEnabled?@" multiple-threads":@"",
			_isValid?@" valid":@"",
			_independentConversationQueueing?@" indep-queueing":@""
		];
}

- (void) invalidate;
{
#if 0
	NSLog(@"invalidate %p:%@ (_isValid=%d)", self, self, _isValid);
#endif
	if(!_isValid)
		return;	// already invalidated
	_isValid=NO;	// don't loop through notifications...
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPortDidBecomeInvalidNotification object:_receivePort];
	[self removeRunLoop:[NSRunLoop currentRunLoop]];
	[_sendPort removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSConnectionReplyMode];
#if 0
	NSLog(@"send NSConnectionDidDieNotification for %p:%@", self, self);
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:NSConnectionDidDieNotification object:self];
	[_receivePort release];
	_receivePort=nil;		// we don't need it any more
	[_sendPort release];
	_sendPort=nil;
	if(_allConnections) NSHashRemove(_allConnections, self);	// remove us from the connections table
#if 0
	NSLog(@"did invalidate %p", self);
#endif
	[self release];	// this will dealloc when all other retains (e.g. in NSDistantObject) are done
}

- (BOOL) isValid; { return _isValid; }

- (NSArray *) localObjects; { return _localObjects; }

- (NSArray *) remoteObjects; { return NSAllMapTableValues(_remoteObjects); }

- (NSDistantObject *) _getRemote:(id) target;
{ // get remote object for target - if known
#if 1
	NSLog(@"_getRemote: %p", target);
	NSLog(@"   -> %p", NSMapGet(_remoteObjects, (void *) target));
	NSLog(@"   -> %@", NSMapGet(_remoteObjects, (void *) target));
#endif
	return NSMapGet(_remoteObjects, (void *) target);
}

- (void) _addRemote:(NSDistantObject *) obj forTarget:(id) target;
{
#if 1
	NSLog(@"_addRemote: %p -> %@", target, obj);
#endif
	NSMapInsert(_remoteObjects, (void *) target, obj);
}

- (void) _removeRemote:(id) target;
{
#if 1
	NSLog(@"_removeRemote: %p", target);
#endif
	NSMapRemove(_remoteObjects, (void *) target);
}

- (BOOL) multipleThreadsEnabled; { return _multipleThreadsEnabled; }

- (NSPort *) receivePort; { return _receivePort; }

- (BOOL) registerName:(NSString *)name; { return [self registerName:name withNameServer:nil]; }

- (BOOL) registerName:(NSString *)name withNameServer:(NSPortNameServer *)server;
{
	if(!_isValid)
		return NO;
	if(!server)
		server=[NSPortNameServer systemDefaultPortNameServer];
	if(![server registerPort:_receivePort name:name])
		{
		NSLog(@"can't register name %@ with portnameserver", name);
		return NO;
		}
	return YES;
}

- (void) removeRequestMode:(NSString*)mode;
{
	if([_modes containsObject:mode])
		{
		[_modes removeObject:mode];
		[_receivePort removeConnection:self fromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
		}
}

- (void) removeRunLoop:(NSRunLoop *)runLoop;
{
	NSEnumerator *e=[_modes objectEnumerator];
	NSString *mode;
	while((mode=[e nextObject]))
		[_receivePort removeConnection:self fromRunLoop:runLoop forMode:mode];
}

- (NSTimeInterval) replyTimeout; { return _replyTimeout; }

- (NSArray *) requestModes; { return _modes; }

- (NSTimeInterval) requestTimeout; { return _requestTimeout; }

- (id) rootObject;
{
#if 1
	NSLog(@"*** (conn=%p) asked to return root object: %@", self, _rootObject);
#endif
	return _rootObject;
}

- (NSDistantObject *) rootProxy;
{ // this generates a proxy but does not yet connect (this appears to be different from OSX!)
	return [NSDistantObject proxyWithTarget:nil connection:self];
}

- (void) _executeInNewThread;
{
	NSRunLoop *crlp=[NSRunLoop currentRunLoop];
#if 1
	NSLog(@"_executeInNewThread");
#endif
	// anything else to set up?
	[self addRunLoop:crlp];
	[crlp run];	// and run in separate thread to await incoming connections and requests
	NSLog(@"_executeInNewThread run finished");
}

- (void) runInNewThread;
{
	if(!_isValid)
		return;	// rise exception?
	[self removeRunLoop:[NSRunLoop currentRunLoop]];
	[NSThread detachNewThreadSelector:@selector(_executeInNewThread) toTarget:self withObject:nil];
}

- (NSPort *) sendPort; { return _sendPort; }
- (void) setDelegate:(id) anObj; { _delegate=anObj; }

- (void) setIndependentConversationQueueing:(BOOL) flag;
{
	_independentConversationQueueing=flag;
	if(flag)
		NIMP;	// FIXME!
	/*  how it should probably go - some initial thoughts
		well, we could do an sendInovcation: to a server
		the server could in turn send a request to us to fulfill our request
		this request could result in a second sendInvocation: to the sam or another server
		we we end up in waiting for the second response first
		and after it is processed, again for the first one
		this basically results in a reentrant call of sendInvocation
		but it overwrites the _portCoder flag
		and, the request is coming in while we wait for the response
		so, we should either answer immediately to the request or queue it up until - hm. until when?
	*/
}

- (void) setReplyTimeout:(NSTimeInterval)seconds; { _replyTimeout=seconds; }
- (void) setRequestTimeout:(NSTimeInterval)seconds; { _requestTimeout=seconds; }
- (void) setRootObject:(id) anObj; { ASSIGN(_rootObject, anObj); }

- (NSDictionary *) statistics; { return [NSDictionary dictionaryWithObject:@"not implemented" forKey:@"Statistics"]; }

// private methods - some of them have been identified to exist in MacOS X Core Dumps by Googling for core dumps

- (void) sendInvocation:(NSInvocation *) i;
{ // send invocation and handle result - this might be called reentrant!
	BOOL isOneway=NO;
	NSMutableArray *components;
	NSPortCoder *portCoder;
#if 1
	NSLog(@"*** (conn=%p) sendInvocation:%@", self, i);
#if 1
	[i _log:@"sendInvocation"];	// log incl. stack
#endif
#endif
	NSAssert(i, @"missing invocation to send");
	if(_isLocal)
		{ // we have been initialized with reversed ports, i.e. local connection
		[i invoke];
		return;
		}
	if(_multipleThreadsEnabled)
		{
		NSRunLoop *rl=[NSRunLoop currentRunLoop];
		// somehow check if we are already added to this runloop!
		[self addRunLoop:rl];
		}
	components=[NSMutableArray arrayWithCapacity:10];
	isOneway=[[i methodSignature] isOneway];
	portCoder=_portCoder=[[NSPortCoder alloc] initWithReceivePort:_receivePort
														 sendPort:_sendPort
													   components:components];
	[_portCoder _setConnection:self];	// set connection we will be decoding
	[_portCoder encodeObject:i];		// encode invocation
	[self _addAuthentication:components];
	// CHECKME: is the currentConversation really for sending requests or intended for receiving?
	// FIXME: do we need to save previous current conversation token (?)
	if([_delegate respondsToSelector:@selector(createConversationForConnection:)])
		_currentConversation=[[_delegate createConversationForConnection:self] retain];
	else
		_currentConversation=[NSObject new];
	NS_DURING
#if 0
		NSLog(@"*** (conn=%p) send request to %@", self, [_portCoder _sendPort]);
#endif		
		[_portCoder sendBeforeTime:_requestTimeout sendReplyPort:_receivePort];		// encode and send - raises exception on timeout
		if(!isOneway)
			{ // wait for response to arrive
			NSDate *until=[NSDate dateWithTimeIntervalSinceNow:_replyTimeout];
			NSRunLoop *rl=[NSRunLoop currentRunLoop];
			Class class;
#if 0
			NSLog(@"*** (conn=%p) waiting for response before %@ in runloop %@ from %@", self, [NSDate dateWithTimeIntervalSinceNow:_replyTimeout], rl, _receivePort);
#endif
			[_receivePort scheduleInRunLoop:rl forMode:NSConnectionReplyMode];	// schedule our receive port so that we can be connected
			//
			// CHECKME: the reception of a response is notified by replacing the original _portCoder by a NSPortCoder initialized with the received message
			// is this ok or is there a better notification mechanism?
			// Hm, do we even need a better one???
			//
			while(_portCoder == portCoder && [until timeIntervalSinceNow] > 0)
				{ // not yet timed out and current conversation is not yet completed
#if 0
				NSLog(@"*** (Conn=%p) loop for response in %@ at %@: %@", self, NSConnectionReplyMode, _receivePort, rl);
#endif
				if(![_receivePort isValid])
					[NSException raise:NSPortReceiveException format:@"sendInvocation: receive port became invalid"];
				if(![rl runMode:NSConnectionReplyMode beforeDate:until])
					[NSException raise:NSPortReceiveException format:@"sendInvocation: receive runloop error"];
				}
			[_portCoder autorelease];
			[_receivePort removeFromRunLoop:rl forMode:NSConnectionReplyMode];
			if([until timeIntervalSinceNow] < 0)
				[NSException raise:NSPortTimeoutException format:@"did not receive response within %.0f seconds", _replyTimeout];
#if 0
			NSLog(@"*** (conn=%p) runloop done for mode: %@", self, NSConnectionReplyMode);
#endif
#if 0
			NSLog(@"decode response from: %@ -> %@", portCoder, _portCoder);
#endif
			[_portCoder decodeValueOfObjCType:@encode(Class) at:&class];
#if 0
			NSLog(@"Response: Class=%@", NSStringFromClass(class));
			NSLog(@"  obj=%@", class);
#endif
			if([class isSubclassOfClass:[NSInvocation class]])
				{ // we received an invocation - substitute into calling invocation
				if([i initWithCoder:_portCoder] != i)	// should be the received NSInvocation and initWithCoder of NSInvocation knows how to substitute components
					[NSException raise:NSGenericException format:@"could not properly update the sent invocation by the response: %@", _portCoder];
				}
			else if([class isSubclassOfClass:[NSException class]])
				{ //  we received an exception - raise here
				[[[[class alloc] initWithCoder:_portCoder] autorelease] raise]; // will re-raise below
				}
			else
				[NSException raise:NSGenericException format:@"response was unsexpectedly an object of class: %@", NSStringFromClass(class)];
			}
		else
			{
#if 1
			NSLog(@"no need to wait for response because it is a oneway method call");
#endif
			}
	NS_HANDLER
		NSLog(@"Exception in sendInvocation %@: %@", i, [localException reason]);
		[localException raise];		// re-raise exception
	NS_ENDHANDLER
}

- (void) handlePortMessage:(NSPortMessage *) message
{ // handle a port message whereever it came from - handle, and send result back
	NSPortCoder *pc;
//	NSConnection *c;
	NSPort *recv, *send;
	NSMutableArray *components;
#if 0
	NSLog(@"### (conn=%p) handlePortMessage:%@\nmsgid=%d\nrecv=%@\nsend=%@\ncomponents=%@", self, message, [message msgid], [message receivePort], [message sendPort], [message components]);
#endif
	if(!message)
		return;	// no message to handle
	components=(NSMutableArray *) [message components];	// we know it is mutable...
	if([_delegate respondsToSelector:@selector(authenticateComponents:withData:)])
		{ // check authentication data
		NSData *a=[components lastObject];	// get authentication data
		[components removeLastObject];		// and remove
		if(![_delegate authenticateComponents:components withData:a])
			[NSException raise:NSFailedAuthenticationException format:@"authentication failed for message %@", message];	// who receives this exception and/or is it ignored?
		// or should we simply send that back (replyWithException) depending on the message type?
		}
	recv=[message receivePort];
	send=[message sendPort];
//	c=[NSConnection connectionWithReceivePort:recv sendPort:send];	// get the (new) connection - which may be different from self!
//	if(c != self)
//		{ // we are asked to help to spawn a new connection
//		NSLog(@"new connection found!");
//		NSLog(@"self=%@", self);
//		NSLog(@"c=%@", c);
//		}
	pc=[[[NSPortCoder alloc] initWithReceivePort:recv
										sendPort:send
									  components:components] autorelease];
	[pc _setMsgid:[message msgid]];	// save
	[pc _setConnection:self];	// set the connection we will be decoding so that we can create and associate proxy objects
//	[pc _setConnection:c];	// set the connection we will be decoding so that we can create and associate proxy objects
	[pc dispatch];			// this will simply come back to the correct connection object and call handlePortCoder:
}

- (void) handlePortCoder:(NSPortCoder *) coder;
{ // request received on this connection
	NSDistantObjectRequest *req=[[NSDistantObjectRequest alloc] _initWithPortCoder:coder];
	if(![_delegate respondsToSelector:@selector(connection:handleRequest:)]
		|| ![_delegate connection:self handleRequest:req])
		{ // was not handled by delegate's method
		[self handleRequest:req sequence:_sequence++];
		}
	[req release];
}

- (void) handleRequest:(NSDistantObjectRequest *) req sequence:(int) seq;
{ // what can/should we do with the sequence number?
	NSException *exception;	// exception response (an NSException created in the current ARP)
	NSPortCoder *pc;
#if 0
	NSLog(@"handleRequest (seq=%d): %@", seq, req);
#endif
	// FIXME: shouldn't we only queue requests that we receive?
	if(_independentConversationQueueing && _currentConversation != [req conversation])
		{ // enqueue while we are engaged in a conversation
#if 1
		NSLog(@"*** (conn=%p) queued: %@", self, req);
#endif
		if(!_requestQueue)
			_requestQueue=[NSMutableArray new];
		[_requestQueue addObject:req];
		return;
		}
	pc=[req _portCoder];
	if([pc _msgid] != 0)
		{ // it is a response
#if 0
		NSLog(@"*** (conn=%p) response received from %@ on %@", self, [pc _sendPort], [pc _receivePort]);
		NSLog(@"*** send=%@, recv=%@", [self sendPort], [self receivePort]);
#endif
		[_portCoder release];
		_portCoder=[pc retain];	// replace and pass message back to sendInvocation - this will end the runLoop in sendInvocation
		return;
		}
#if 1
	NSLog(@"*** (conn=%p) request received ***", self);
#endif
	NS_DURING
		{
			NSInvocation *i=[req invocation];
#if 1
			[i _log:@"handleRequest"];
#endif
			[i retainArguments];	// don't release the target and other objects earlier than the invocation
			if(SEL_EQ([i selector], @selector(release)))
					{ // special case that we have received a release request
						[_localObjects removeObjectIdenticalTo:[i target]];	// remove from list of local objects
						NS_VOIDRETURN;	// no need to send a response (even if signature says so)
					}
			[self dispatchInvocation:i];	// make a call to the local object(s)
			exception=nil;	// no exception
		}
	NS_HANDLER
		exception=localException;	// dispatching results in an exception
	NS_ENDHANDLER
	[req replyWithException:exception];	// try to reply
}

- (void) dispatchInvocation:(NSInvocation *) i;
{
#if 0
	NSLog(@"--- dispatchInvocation: %@", i);
#endif
	[i invoke];
#if 0
	NSLog(@"--- done with dispatchInvocation: %@", i);
#endif
}

@end