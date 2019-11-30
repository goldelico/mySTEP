/*
 NSXPCConnection.h
 Foundation
 
 Created by H. Nikolaus Schaller on 03.09.16.
 Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
  */

#import <Foundation/NSObject.h>

enum _NSXPCConnectionOptions
{
	NSXPCConnectionPrivileged = (1 << 12UL),
};

typedef NSUInteger NSXPCConnectionOptions;

typedef NSUInteger au_asid_t;

@protocol NSXPCProxyCreating
- (id) remoteObjectProxy;
- (void) setRemoteObjectProxy:(id) proxy;
// - (id)remoteObjectProxyWithErrorHandler:(void (^)(NSError *error)) handler;

@end

@class NSXPCListener;
@class NSXPCConnection;

@protocol NSXPCListenerDelegate

- (BOOL) listener:(NSXPCListener *) listener
		shouldAcceptNewConnection:(NSXPCConnection *) newConnection;

@end

@interface NSXPCInterface : NSObject
{

}

+ (NSXPCInterface *) interfaceWithProtocol:(Protocol *) protocol;

- (NSSet *) classesForSelector:(SEL) sel
				 argumentIndex:(NSUInteger) arg
					   ofReply:(BOOL) ofReply;

- (NSXPCInterface *) interfaceForSelector:(SEL) sel
							argumentIndex:(NSUInteger) arg
								  ofReply:(BOOL) ofReply;

- (void) setClasses:(NSSet *) classes
		forSelector:(SEL) sel
	  argumentIndex:(NSUInteger) arg
			ofReply:(BOOL) ofReply;

- (void) setInterface:(NSXPCInterface *) ifc
		  forSelector:(SEL) sel
		argumentIndex:(NSUInteger) arg
			  ofReply:(BOOL) ofReply;

@end

@interface NSXPCListenerEndpoint : NSObject /* <NSecureCoding> */
@end

@interface NSXPCListener : NSObject
{
	id <NSXPCListenerDelegate> _delegate;
}

+ (NSXPCListener *) anonymousListener;
+ (NSXPCListener *) serviceListener;

- (NSXPCListenerEndpoint *) endpoint;

- (id) initWithMachServiceName:(NSString *) name;

- (void) invalidate;
- (void) resume;
- (void) suspend;

- (id <NSXPCListenerDelegate>) delegate;
- (void) setDelegate:(id <NSXPCListenerDelegate>) delegate;

@end

@interface NSXPCConnection : NSObject <NSXPCProxyCreating>
{
	id _remoteObjectProxy;
	id _exportedObject;
	NSBLOCK_POINTER(void, invaldationHandler, void);
	NSBLOCK_POINTER(void, _errorHandler, void);
	NSInteger _suspendCount;
	NSXPCInterface *exportedInterface;
	NSXPCListenerEndpoint *_endpoint;

}

- (id) initWithListenerEndpoint:(NSXPCListenerEndpoint *) endpoint;
- (id) initWithMachServiceName:(NSString *) name options:(NSXPCConnectionOptions) options;	/* not available */
- (id) initWithServiceName:(NSString *) serviceName;

- (void) invalidate;
- (void) resume;
- (void) suspend;

- (NSString *) serviceName;
- (pid_t) processIdentifier;
- (uid_t) effectiveUserIdentifier;
- (gid_t) effectiveGroupIdentifier;
- (au_asid_t) auditSessionIdentifier;

- (NSBLOCK_POINTER(void,, void)) invaldationHandler;
- (void) setInvaldationHandler:(NSBLOCK_POINTER(void,, void)) block;

- (id) exportedObject;
- (void) setExportedObject:(id) anObject;

- (NSXPCInterface *) exportedInterface;
- (void) setExportedInterface:(NSXPCInterface *) interface;

- (NSXPCListenerEndpoint *) endpoint;

@end
