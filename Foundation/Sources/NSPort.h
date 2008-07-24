/* 
   NSPort.h

   Objects representing a communication channel to or from another 
   NSPort, which typically resides in a different thread or task.

   Copyright (C) 1994, 1995, 1996, 1997 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	July 1994
   Rewrite: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1997
   NSSocketPort: H. Nikolaus Schaller <hns@computer.org>
   Date:	Dec 2005

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSPort
#define _mySTEP_H_NSPort

#include <sys/socket.h>
#include <sys/un.h>	// sockaddr_un
#include <arpa/inet.h>
#include <netinet/in.h>

#import <Foundation/NSObject.h>

@class NSArray;
@class NSConnection;
@class NSData;
@class NSDate;
@class NSMutableArray;
@class NSPortMessage;
@class NSRunLoop;
@class NSString;
@class NSEnumerator;

extern NSString *NSPortDidBecomeInvalidNotification;

typedef int NSSocketNativeHandle;

@interface NSPort : NSObject  <NSCoding, NSCopying>
{
	id _delegate;
	NSPort *_parent;
	NSData *_sendData;
	char *_recvBuffer;
	unsigned long _recvLength;
	unsigned long _recvPos;
	unsigned long _sendPos;
	NSSocketNativeHandle _fd;		// the official fd (the one we listen on - may be -1)
	NSSocketNativeHandle _sendfd;	// an inofficial socket() where we (did) connect through
	struct _NSPortAddress {	// this is used as the key to find already existing ports
		unsigned short addrlen;		// length of used part of addr
		unsigned char type;
		unsigned char protocol;
		struct sockaddr_storage addr;	// large enough (except AF_UNIX?)
		} _address;
	BOOL _isValid;
	BOOL _isBound;
}

+ (id) allocWithZone:(NSZone *) zone;
+ (NSPort *) port;

- (void) addConnection:(NSConnection *) connection
			 toRunLoop:(NSRunLoop *) runLoop
			   forMode:(NSString *) mode;
- (id) delegate;
- (void) invalidate;
- (BOOL) isValid;
- (void) removeConnection:(NSConnection *) connection
			  fromRunLoop:(NSRunLoop *) runLoop
				  forMode:(NSString *) mode;
- (void) removeFromRunLoop:(NSRunLoop *) runLoop
				   forMode:(NSString *) mode;
- (NSUInteger) reservedSpaceLength;
- (void) scheduleInRunLoop:(NSRunLoop *) runLoop
				   forMode:(NSString *) mode;
- (BOOL) sendBeforeDate:(NSDate *) limitDate
			 components:(NSMutableArray *) components
				   from:(NSPort *) receivePort
			   reserved:(NSUInteger) headerSpaceReserved;
- (BOOL) sendBeforeDate:(NSDate *) limitDate
				  msgid:(NSUInteger) msg
			 components:(NSMutableArray *) components
				   from:(NSPort *) receivePort
			   reserved:(NSUInteger) headerSpaceReserved;
- (void) setDelegate:(id) anObject;

@end

@interface NSObject (NSPortDelegate)

- (void) handleMachMessage:(void *) message;
- (void) handlePortMessage:(NSPortMessage *) message;

@end

@interface NSMessagePort : NSPort
@end

@interface NSSocketPort : NSPort

- (NSData *) address;
- (id) initRemoteWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
- (id) initRemoteWithTCPPort:(unsigned short) port host:(NSString *) host;
- (id) initWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
- (id) initWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol socket:(NSSocketNativeHandle) sock;
- (id) initWithTCPPort:(unsigned short) port;
- (int) protocol;
- (int) protocolFamily;
- (NSSocketNativeHandle) socket;
- (int) socketType;

@end

enum {
    NSMachPortDeallocateNone = 0,
    NSMachPortDeallocateSendRight = (1 << 0),
    NSMachPortDeallocateReceiveRight = (1 << 1)
};

@interface NSMachPort : NSPort

+ (NSPort *) portWithMachPort:(uint32_t) port;
+ (NSPort *) portWithMachPort:(uint32_t) port options:(NSUInteger) opts;

- (id) initWithMachPort:(uint32_t) port;
- (id) initWithMachPort:(uint32_t) port options:(NSUInteger) opts;
- (uint32_t) machPort;
- (void) removeFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;

@end

@interface NSObject (NSMachPortDelegate)

- (void) handleMachMessage:(void *) machMessage

@end

#endif /* _mySTEP_H_NSPort */
