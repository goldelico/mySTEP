/* 
   NSConnection.h

   Interface to GNU Objective-C version of NSConnection

   Copyright (C) 1997 Free Software Foundation, Inc.
   
   Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   GNUstep:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1997
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   NSConnection, NSDistantObjectRequest - aligned with 10.5 by Fabian Spillner 28.04.2008
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSConnection
#define _mySTEP_H_NSConnection

#import <Foundation/NSObject.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>

@class NSData;
@class NSDictionary;
@class NSMutableArray;
@class NSString;
@class NSException;
@class NSRunLoop;
@class NSDistantObject;
@class NSInvocation;
@class NSPort;
@class NSPortCoder;
@class NSPortNameServer;

//	Keys for the NSDictionary returned by [NSConnection -statistics]

extern NSString *NSConnectionRepliesReceived;			// OPENSTEP 4.2
extern NSString *NSConnectionRepliesSent;
extern NSString *NSConnectionRequestsReceived;
extern NSString *NSConnectionRequestsSent;

// NSRunLoop modes, NSNotification names and NSException strings.

extern NSString	*const NSConnectionReplyMode;

extern NSString *const NSConnectionDidDieNotification;
extern NSString *const NSConnectionDidInitializeNotification;

extern NSString *const NSFailedAuthenticationException;

@interface NSConnection : NSObject
{
	NSPort *_receivePort;
	NSPort *_sendPort;
	id _delegate;
	id _rootObject;						// the root object to vend
	NSMapTable *_localObjects;			// map of local objects -> proxy
	NSMapTable *_localObjectsByRemote;	// map or remote target (reference number) -> proxy - numbers assigned by local connection
	NSMapTable *_remoteObjects;			// map of remote target (reference number) -> proxy - numbers assigned by remote connection
	NSMutableArray *_modes;				// all modes
	NSMutableArray *_runLoops;			// all runloops
	NSMutableArray *_requestQueue;		// queue of pending NSDistantObjectRequests (this should be one queue per thread!)
	NSMapTable *_responses;				// (unprocessed) responses (NSPortCoder) indexed by sequence number
	NSTimeInterval _requestTimeout;
	NSTimeInterval _replyTimeout;
	unsigned _localProxyCount;
//	NSDistantObject *_proxy;			// (cached) the proxy that represents the remote NSConnection object
	unsigned int _repliesReceived;
	unsigned int _repliesSent;
	unsigned int _requestsReceived;
	unsigned int _requestsSent;
	BOOL _multipleThreadsEnabled;
	BOOL _isValid;
	BOOL _independentConversationQueueing;
//	BOOL _isLocal;
}

+ (NSArray *) allConnections;
+ (NSConnection *) connectionWithReceivePort:(NSPort *) receivePort
									sendPort:(NSPort *) sendPort;
+ (NSConnection *) connectionWithRegisteredName:(NSString *) n
										   host:(NSString *) h;
+ (NSConnection *) connectionWithRegisteredName:(NSString *) name
										   host:(NSString *) hostName
								usingNameServer:(NSPortNameServer *) server;
+ (id) currentConversation;
+ (NSConnection *) defaultConnection;
+ (NSDistantObject *) rootProxyForConnectionWithRegisteredName:(NSString *) name
														  host:(NSString *) host;
+ (NSDistantObject *) rootProxyForConnectionWithRegisteredName:(NSString *) name
														  host:(NSString *) hostName
											   usingNameServer:(NSPortNameServer *) server;
+ (id) serviceConnectionWithName:(NSString *) name rootObject:(id) root usingNameServer:(NSPortNameServer *) server;
+ (id) serviceConnectionWithName:(NSString *) name rootObject:(id) root;

- (void) addRequestMode:(NSString *) mode;
- (void) addRunLoop:(NSRunLoop *) loop;
- (id) delegate;
- (void) enableMultipleThreads;
- (BOOL) independentConversationQueueing;
- (id) initWithReceivePort:(NSPort *) receivePort
				  sendPort:(NSPort *) sendPort;
- (void) invalidate;
- (BOOL) isValid;
- (NSArray *) localObjects;
- (BOOL) multipleThreadsEnabled;
- (NSPort *) receivePort;
- (BOOL) registerName:(NSString *) name;
- (BOOL) registerName:(NSString *) name withNameServer:(NSPortNameServer *) server;
- (NSArray *) remoteObjects;
- (void) removeRequestMode:(NSString *) mode;
- (void) removeRunLoop:(NSRunLoop *) runloop;
- (NSTimeInterval) replyTimeout;
- (NSArray *) requestModes;
- (NSTimeInterval) requestTimeout;
- (id) rootObject;
- (NSDistantObject *) rootProxy;
- (void) runInNewThread;
- (NSPort *) sendPort;
- (void) setDelegate:(id) anObj;
- (void) setIndependentConversationQueueing:(BOOL) flag;
- (void) setReplyTimeout:(NSTimeInterval) seconds;
- (void) setRequestTimeout:(NSTimeInterval) seconds;
- (void) setRootObject:(id) anObj;
- (NSDictionary *) statistics;

@end

@interface NSDistantObjectRequest : NSObject
{
	NSConnection *_connection;
	NSInvocation *_invocation;
	id _conversation;
	NSMutableArray *_imports;
	unsigned int _sequence;
}

// undocumented initializer - see http://opensource.apple.com/source/objc4/objc4-208/runtime/objc-sel.m
- (id) initWithInvocation:(NSInvocation *) inv conversation:(NSObject *) conv sequence:(unsigned int) seq importedObjects:(NSMutableArray *) obj connection:(NSConnection *) conn;

- (NSConnection *) connection;
- (id) conversation;
- (NSInvocation *) invocation;
- (void) replyWithException:(NSException *) exception;

@end

@interface NSObject (NSConnectionDelegate)

- (BOOL) authenticateComponents:(NSArray *) components withData:(NSData *) authenticationData;
- (NSData *) authenticationDataForComponents:(NSArray *) components;
- (BOOL) connection:(NSConnection *) conn handleRequest:(NSDistantObjectRequest *) doReq;
- (BOOL) connection:(NSConnection *) parentConnection shouldMakeNewConnection:(NSConnection *) conn;
- (id) createConversationForConnection:(NSConnection *) conn;	// do not autorelease this new object!
- (BOOL) makeNewConnection:(NSConnection *) newConnection sender:(NSConnection *) conn;

@end

#endif /* _mySTEP_H_NSConnection */
