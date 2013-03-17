/* 
 NSPort.m
 
 Implementation of abstract superclass port for use with NSConnection
 
 Copyright (C) 1997, 1998 Free Software Foundation, Inc.
 
 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	July 1994
 Rewrite: Richard Frith-Macdonald <richard@brainstorm.co.u>
 Date:	August 1997
 
 NSSocketPort & Complete Rewrite: H. Nikolaus Schaller <hns@computer.org>
 Date:	Dec 2005 - Jan 2007
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#define DEFAULT_PORT_CLASS NSMessagePort
// #define DEFAULT_PORT_CLASS NSSocketPort

#include <signal.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>


#import <Foundation/NSPort.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSByteOrder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSPortMessage.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSPortCoder.h>			// for Coding protocol in Object category
#import <Foundation/NSPortNameServer.h>
#import <Foundation/NSStream.h>

#import "NSPrivate.h"

NSString *const NSPortDidBecomeInvalidNotification = @"NSPortDidBecomeInvalidNotification";

NSString *NSObjectInaccessibleException=@"NSObjectInaccessibleException";
NSString *NSObjectNotAvailableException=@"NSObjectNotAvailableException";
NSString *NSDestinationInvalidException=@"NSDestinationInvalidException";
NSString *NSPortTimeoutException=@"NSPortTimeoutException";
NSString *NSInvalidSendPortException=@"NSInvalidSendPortException";
NSString *NSInvalidReceivePortException=@"NSInvalidReceivePortException";
NSString *NSPortSendException=@"NSPortSendException";
NSString *NSPortReceiveException=@"NSPortReceiveException";

static NSMapTable *__sockets;	// a map table to associate family, type, protocol, address with a specific socket instance

@implementation NSPort

NSString *__NSDescribeSockets(void *table, const void *addr)
{
	return [[NSData dataWithBytes:addr length:((struct _NSPortAddress *) addr)->addrlen+sizeof(uint16_t)+2*sizeof(uint8_t)] description];
}

unsigned __NSHashSocket(void *table, const void *addr)
{
	register const char *p = (char*)addr;
	register unsigned hash = 0, hash2;
	register int i;
    for(i = 0; i < ((struct _NSPortAddress *) addr)->addrlen+sizeof(uint16_t)+2*sizeof(uint8_t); i++)
		{
        hash <<= 4;
        hash += *p++;
        if((hash2 = hash & 0xf0000000))
            hash ^= (hash2 >> 24) ^ hash2;
		}
#if 0
	NSLog(@"hash=%u for %@", hash, __NSDescribeSockets(table, addr));
#endif
	return hash;
}

BOOL __NSCompareSockets(void *table, const void *addr1, const void *addr2)
{
#if 0
	NSLog(@"compare %@", __NSDescribeSockets(table, addr1));
	NSLog(@"     to %@", __NSDescribeSockets(table, addr2));
#endif
	if(((struct _NSPortAddress *) addr1)->addrlen != ((struct _NSPortAddress *) addr2)->addrlen)
		return NO;	// different address length
    return memcmp((char*)addr1, (char*)addr2, ((struct _NSPortAddress *) addr1)->addrlen+sizeof(uint16_t)+2*sizeof(uint8_t)) == 0;
}

static const NSMapTableKeyCallBacks NSSocketMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashSocket,
    (BOOL (*)(NSMapTable *, const void *, const void *))__NSCompareSockets,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeSockets,
    (const void *)NULL
};

+ (void) initialize
{
	if(self == [NSPort class])
		{
		signal(SIGPIPE, SIG_IGN);
		// If SIGPIPE is not ignored, we will abort 
		// on any attempt to write to a pipe/socket
		// that has been closed by the other end!
		__sockets=NSCreateMapTable(NSSocketMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
		}
}

// this should create two local ports to communicate between threads

+ (NSPort *) port							{ return [[self new] autorelease]; }

+ (id) allocWithZone:(NSZone *) z;
{
	if(self == [NSPort class])
		return [DEFAULT_PORT_CLASS allocWithZone:z];	// should be NSMachPort but we don't have that one
	return [super allocWithZone:z];	// concrete subclass
}

+ (id) _allocForProtocolFamily:(int) family;
{
	switch(family) {
		case AF_INET:
		case AF_INET6:
			return [NSSocketPort allocWithZone:NSDefaultMallocZone()];
		case AF_UNIX:
			return [NSMessagePort allocWithZone:NSDefaultMallocZone()];
		default:
			NSLog(@"### can't handle protocol family %d", family);
			return nil;
	}
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%p:%@ listen=%d connect=%d%@%@", self, NSStringFromClass(isa), _fd, _sendfd, _isValid?@" valid":@"", _isBound?@"":@" not bound"];
}

- (id) copyWithZone:(NSZone *) zone			{ return [self retain]; }
- (id) delegate								{ return _delegate; }

- (BOOL) isEqual:(id) port;
{
	return self == port;
}

- (id) init
{
	if((self=[super init]))
		{
		_isValid = YES;
		_fd=-1;
		_sendfd=-1;
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"### dealloc:%@", self);
#endif
	[_sendData release];	// if not nil
	if(_fd > 0)
		close(_fd);			// assume we never use fd=0 - this ivar may be 0 if we alloc/release without init
	if(_sendfd > 0)
		close(_sendfd);		// assume we never use fd=0 - this ivar may be 0 if we alloc/release without init
	if(_recvBuffer)
		objc_free(_recvBuffer);	// just to be sure
	[super dealloc];
}

- (void) release
{
	if(_isValid && [self retainCount] == 1)
		{
		NSAutoreleasePool *arp;
		// If the port is about to have a final release deallocate it
		// we must invalidate it.  Use a local autorelease pool when
		// invalidating so that we know that anything refering to this
		// port during the invalidation process is released immediately
		// Also bracket with retain/release pair to prevent recursion.
#if 1
		NSLog(@"### port finally released: %@", self);
#endif
		[super retain];
		arp = [NSAutoreleasePool new];
		[self invalidate];
		[arp release];
		[super release];
		}
	[super release];
}

- (BOOL) isValid							{ return _isValid; }

- (void) setDelegate:(id)anObject
{
	if(anObject && ![anObject respondsToSelector: @selector(handlePortMessage:)] && ![anObject respondsToSelector: @selector(handleMachMessage:)])
		[NSException raise:NSInvalidArgumentException format:@"does not provide handlePortMessage or handleMachMessage: %@", anObject];
	_delegate = anObject;	// remember
}

// should we really override?

- (id) replacementObjectForPortCoder:(NSPortCoder *)aCoder	{ return self; }	// never replace

- (void) encodeWithCoder:(NSCoder *) coder
{
	[(NSPortCoder *) coder encodePortObject:self];
}

- (id) initWithCoder:(NSCoder *) coder
{
	[self release];
	return [(NSPortCoder *) coder decodePortObject];
}

// UNDERSTANDME: why do we need to know the connection object here?

- (void) addConnection:(NSConnection *) connection
			 toRunLoop:(NSRunLoop *) runLoop
			   forMode:(NSString *) mode;
{ // schedule for receiving for the given connection
//	if(!_isValid)
//		[connection invalidate];
#if 1
	NSLog(@"### +++ addConnection:%@ toRunLoop:%@ forMode:%@", connection, runLoop, mode);
#endif
	[self scheduleInRunLoop:runLoop forMode:mode];
}

- (void) removeConnection:(NSConnection *) connection
			  fromRunLoop:(NSRunLoop *) runLoop
				  forMode:(NSString *) mode;
{
#if 1
	NSLog(@"### --- removeConnection:%@ fromRunLoop:%@ forMode:%@", connection, runLoop, mode);
#endif
	[self removeFromRunLoop:runLoop forMode:mode];
}

- (void) removeFromRunLoop:(NSRunLoop *)runLoop
				   forMode:(NSString *)mode;
{
#if 1
	NSLog(@"### --- removeFromRunLoop:%@ forMode:%@ - %@", runLoop, mode, self);
#endif
	[runLoop _removeInputWatcher:self forMode:mode];
}

- (void) scheduleInRunLoop:(NSRunLoop *)runLoop
				   forMode:(NSString *)mode;
{
	if(_isValid)
		{
#if 1
		NSLog(@"### +++ scheduleInRunLoop:%@ forMode:%@ - %@", runLoop, mode, self);
#endif
		[runLoop _addInputWatcher:self forMode:mode];
		}
}

- (unsigned) reservedSpaceLength; { return 0; }

- (BOOL) sendBeforeDate:(NSDate *)limitDate
			 components:(NSMutableArray *)components
				   from:(NSPort *)receivePort
			   reserved:(unsigned)headerSpaceReserved;
{ // default message id
	return [self sendBeforeDate:limitDate
						  msgid:0	// default message
					 components:components
						   from:receivePort
					   reserved:headerSpaceReserved];
}

- (BOOL) sendBeforeDate:(NSDate *)limitDate
				  msgid:(unsigned)msgid
			 components:(NSMutableArray *)components
				   from:(NSPort *)receivePort
			   reserved:(unsigned)headerSpaceReserved;	// ignored...
{ // make us generically work as an NSPort based on UNIX file descriptors (sockets)
	NSRunLoop *loop=[NSRunLoop currentRunLoop];
#if 1
	NSLog(@"### %@ sendBeforeDate:%@ msgid:%u components:%@ from:%@ reserved:%u", self, limitDate, msgid, components, receivePort, headerSpaceReserved);
#endif
	if(!_isValid)
		[NSException raise:NSInvalidSendPortException format:@"invalidated: %@", self];
	if(!receivePort)
		return NO;	// raise exception? Or can we even send in this case?
	if(![receivePort _bindAndListen])	// receive port wasn't bound to a file or socket yet (should happen only for NSMessagePorts)
		return NO;
	if(_sendfd < 0 && ![self _connect])	// we are not yet connected
		return NO;
	_sendData=[NSPortMessage _machMessageWithId:msgid forSendPort:self receivePort:receivePort components:components];	// convert to data block
	if(!_sendData)
		[NSException raise:NSPortSendException format:@"could not convert data to machMessage"];
	[_sendData retain];	// NSRunLoop may autorelease pools before everything is sent! Will be released in _writeFileDescriptorReady
#if 1
	NSLog(@"### send length=%u data=%@ to fd=%d on %@", [_sendData length], _sendData, _sendfd, self);
#endif
	_sendPos=0;
	[loop _addOutputWatcher:self forMode:NSConnectionReplyMode];	// get callbacks when we can send
#if 0
	NSLog(@"### remaining interval %lf", [limitDate timeIntervalSinceNow]);
#endif
	while(_sendData && [limitDate timeIntervalSinceNow] > 0)
		{
#if 0
		NSLog(@"### run loop %@ in mode %@", loop, NSConnectionReplyMode);
#endif
		if(!_isValid)
			{
			[loop _removeOutputWatcher:self forMode:NSConnectionReplyMode];
			[NSException raise:NSPortSendException format:@"sendBeforeDate: send port became invalid %@", self];
			}
		if(![loop runMode:NSConnectionReplyMode beforeDate:limitDate])
			{ // some runloop error, e.g. not scheduled in this mode
#if 0
				NSLog(@"### sendBeforeDate: runloop error");
#endif
				[loop _removeOutputWatcher:self forMode:NSConnectionReplyMode];
				[NSException raise:NSPortSendException format:@"sendBeforeDate: runloop error for %@", self];
				break;
			}
#if 0
		NSLog(@"### remaining interval %lf", [limitDate timeIntervalSinceNow]);
#endif
		}
	[loop _removeOutputWatcher:self forMode:NSConnectionReplyMode];
#if 0
	if(_sendPos == NSNotFound)
		NSLog(@"### all sent");
	else
		NSLog(@"### NOT ALL SENT ###");
#endif
	return _sendPos == NSNotFound;		// did we send all bytes?
}

- (int) _readFileDescriptor;
{ // communicate with runloop for read() and accept()
	return _fd >= 0?_fd:_sendfd;	// if _fd >= 0 we are listening; otherwise we are receiving
}

- (int) _writeFileDescriptor;
{ // communicate with runloop for write() and connect()
	return _sendfd;
}

- (BOOL) _connect;
{
	if(_sendfd < 0)
		{ // needs to connect to peer first
			if(!_isValid)
				[NSException raise:NSInvalidSendPortException format:@"invalidated before connect: %@", self];
#if 1
			NSLog(@"### connect to family=%d %@", _address.addr.ss_family, self);
#endif
			_sendfd=socket(_address.addr.ss_family, SOCK_STREAM, 0);
			if(connect(_sendfd, (struct sockaddr *) &_address.addr, _address.addrlen))
				{
				NSLog(@"### could not connect due to %s: %@", strerror(errno), self);
				if(errno == ECONNREFUSED && [self isKindOfClass:[NSMessagePort class]])
					{ // nobody is listening on this message port name i.e. the named socked is stale
						NSLog(@"### trying to connect stale socket: %@", self);
					}
				return NO;
				}
			_isBound=YES;
#if 0
			NSLog(@"** connected %@", self);
#endif
		}
	return YES;
}

- (BOOL) _bindAndListen;
{
#if 1
	NSLog(@"### bindandlisten %@", self);
#endif
	if(!_isBound && _fd >= 0)
		{ // not yet bound
			int flag=1;
			if(!_isValid)
				[NSException raise:NSInvalidReceivePortException format:@"invalidated before bind&listen: %@", self];
			setsockopt(_fd, SOL_SOCKET, SO_REUSEADDR, (char*)&flag, sizeof(flag));	// reuse address
			// NOTE: if we have INADDR_ANY the address remains INADDR_ANY! Only an accepted() connection is bound to a specific interface
			if(bind(_fd, (struct sockaddr *) &_address.addr, _address.addrlen))
				{
				NSLog(@"### could not bind due to %s: %@: ", strerror(errno), self);
				return NO;
				}
#if 1
			NSLog(@"### bound %@", self);
#endif
			if(_address.addr.ss_family != AF_UNIX)
				{ // get port assigned by system - AF_UNIX does not support this system call
					unsigned addrlen=_address.addrlen;
					NSMapRemove(__sockets, &_address);
					getsockname(_fd, (struct sockaddr *) &_address.addr, &addrlen);	// read back to know the port number
					_address.addrlen=addrlen;
					NSMapInsert(__sockets, &_address, self);
#if 0
					NSLog(@"### rebound %@", self);
#endif
				}
			if(listen(_fd, 10))
				{
				NSLog(@"### could not listen due to %s: %@", strerror(errno), self);
				return NO;
				}
			_isBound=YES;
#if 1
			NSLog(@"### listening %@", self);
#endif
		}
	return YES;
}

/*
 FIXME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows.
 This might also be some very large constant for record length which wraps around the 32bit address limit (e.g. a negative record length).
 Ending up in infinite loops blocking the system.
 */

- (void) _readFileDescriptorReady;
{ // callback
#if 1
	NSLog(@"### _readFileDescriptorReady: %@", self);
#endif
	if(!_isValid)
		{
#if 1
		NSLog(@"### _readFileDescriptorReady: became invalid: %@", self);
#endif
		[[NSRunLoop currentRunLoop] _removeWatcher:self];
		return;
		}
	if(_fd >= 0)
		{ // listening was successful
			struct sockaddr_storage ss;	// this should be large enough to hold any address incl. AF_UNIX
			socklen_t saddrlen=sizeof(ss);
			NSRunLoop *loop=[NSRunLoop currentRunLoop];
			NSPort *newPort;
			NSData *addr;
			int newfd;
			short family;
			if(!_isBound)
				{ // someone has scheduled this socket but it is not yet bound - so it must be a NSMessagePort that is not registered with a public name
#if 1
				NSLog(@"### not yet bound & listening: %@", self);
				if(![self _bindAndListen])	// try to bind
					{
					[self invalidate];	// failed
					return;
					}
#endif
				}
#if 1
			NSLog(@"### accept salen=%d %@", saddrlen, self);
#endif
			memset(&ss, 0, saddrlen);			// clear completely before using
			ss.ss_family=_address.addr.ss_family;
			newfd=accept(_fd, (struct sockaddr *) &ss, &saddrlen);
#if 1
			NSLog(@"### accepted on fd=%d newfd=%d salen=%d", _fd, newfd, saddrlen);
#endif
			if(newfd < 0)
				{
				NSLog(@"### could not accept on %@ due to %s", self, strerror(errno));
				[self invalidate];
				return;
				}
			family=ss.ss_family;
			*((short *) &ss.ss_family)=htons(family);	// swap family to network byte order (as expected by initRemoteWithProtocolFamily)
			addr=[NSData dataWithBytesNoCopy:&ss length:saddrlen freeWhenDone:NO];
#if 0
			NSLog(@"### accepted socket=%d", newfd);
			NSLog(@"  address=%@", addr);
#endif
			newPort=[[isa alloc] initRemoteWithProtocolFamily:family socketType:_address.type protocol:_address.protocol address:addr];
			NSAssert1(newPort->_sendfd < 0, @"Already connected! newport=%@", newPort);
			NSAssert(newPort->_fd < 0, @"Already listening!");
			newPort->_isBound=YES;			// pretend we are already bound
			newPort->_sendfd=newfd;			// we are already connected
			newPort->_delegate=_delegate;	// same delegate
#if 1
			NSLog(@"### accepted %@ on parent %@", newPort, self);
#endif
			
			// FIXME: should we inherit the watchers/modes from our parent???
			// this is just a temporary hack that appears to make it work...
						
			[loop _addInputWatcher:newPort forMode:NSDefaultRunLoopMode];	// allow us to receive the first packet on this port
			[loop _addInputWatcher:newPort forMode:NSConnectionReplyMode];

			[newPort release];	// should now have been retained as watcher and/or by cache until invalidated
#if 0
			NSLog(@"### accept done. retain count=%d", [newPort retainCount]);
#endif
			return;
		}
#if 0
	NSLog(@"### _readFileDescriptor:%d ready %@", _sendfd, self);
#endif
	if(!_recvBuffer)
		{ // no buffer allocated so far - receive and check for header
			struct { uint32_t magic, messageLength; } header;	// we know something about the mach message structure, i.e. that there is a header magic and the block length and therefore know how much to read for frame boundaries		
			int len;
			//		fcntl(_sendfd, F_SETFL, O_NONBLOCK);	// don't block here or later
			// FIXME: we need a more sophisticated mechanism to properly handle header fragments! Therefore we block until we have received a full header
			if((len=read(_sendfd, &header, sizeof(header))) != sizeof(header))
				{ // should we have a mechanism to resync? This appears to be not required since we assume a reliable transport socket
					// we might have to remember a partial header!
#if 1
					NSLog(@"### closed by peer: %@", self);
#endif
					[self invalidate];
					if(len == 0)
						return;	// simply closed by peer (EOF notification)
					[NSException raise:NSPortReceiveException format:@"_readFileDescriptorReady: header read error %s - len=%d", strerror(errno), len];
				}
#if 0
			NSLog(@"### did read %u bytes from fd %d", len, _sendfd);
#endif
			if(header.magic != NSSwapHostLongToBig(0xd0cf50c0))
				{
				[self invalidate];
				[NSException raise:NSPortReceiveException format:@"sendBeforeDate: bad header magic %08x", header.magic];
				}
			_recvLength=NSSwapBigLongToHost(header.messageLength);
			// FIXME: limit _recvLength to a reasonable value
			if(_recvLength > 64000)
				{
				[self invalidate];
				return;
				}
#if 0
			NSLog(@"### header received length=%u on fd=%d", _recvLength, _sendfd);
#endif
			_recvBuffer=objc_malloc(_recvLength);
			if(!_recvBuffer)
				{
				[self invalidate];
				[NSException raise:NSPortReceiveException format:@"_readFileDescriptorReady: could not allocate header for message of length %u", header.messageLength];
				}
			memcpy(_recvBuffer, &header, sizeof(header));
			_recvPos=sizeof(header);	// include header in the buffer
			return;
		}
#if 0
	NSLog(@"### pos=%u length=%u", _recvPos, _recvLength);
#endif
	if(_recvPos < _recvLength)
		{ // read next fragment - as much as we can get from the missing part
			int len=_recvLength-_recvPos;	// how much we still expect (we know from the header)
			len=read(_sendfd, _recvBuffer+_recvPos, len);
			if(len < 0)
				{ // we received an error
					if(errno == EWOULDBLOCK)
						return;	// ignore
					[self invalidate];
					[NSException raise:NSPortReceiveException format:@"_readFileDescriptorReady: read error %s", strerror(errno)];
				}
#if 0
			NSLog(@"### did read %u bytes from fd=%d", len, _sendfd);
#endif
			_recvPos+=len;
			if(_recvPos < _recvLength)
				return;	// incomplete
		}
#if 0
	NSLog(@"### complete message received on %@: %@", self, [NSData dataWithBytesNoCopy:_recvBuffer length:_recvLength freeWhenDone:NO]);
#endif
#if 1
	if(!_delegate)
		NSLog(@"### no delegate! %@", self);
#endif
	NS_DURING
	if([_delegate respondsToSelector:@selector(handleMachMessage:)])
		{
		[_delegate handleMachMessage:_recvBuffer];
		objc_free(_recvBuffer);	// done
		_recvBuffer=NULL;
		}
	else
		{
		NSAutoreleasePool *arp=[NSAutoreleasePool new];
		NSPortMessage *msg=[[NSPortMessage alloc] initWithMachMessage:_recvBuffer];
		objc_free(_recvBuffer);			// done
		if(![msg receivePort])	[msg _setReceivePort:self];
		if(![msg sendPort])		[msg _setSendPort:self];
		_recvBuffer=NULL;
#if 0
		NSLog(@"### handlePortMessage:%@ by delegate %@", msg, _delegate);
#endif
#if 0
		printf("### r: %s d:%s\n", [[msg description] UTF8String], [[_delegate description] UTF8String]);
#endif	
		[_delegate handlePortMessage:msg];	// process by delegate
		[msg release];
#if 0
		NSLog(@"### received msg released");
#endif
		[arp release];
		}
	NS_HANDLER
		NSLog(@"exception while trying handleMachMessage/handlePortMessage: %@", localException);
	NS_ENDHANDLER
}

- (void) _writeFileDescriptorReady;
{ // callback
	if(!_isValid)
		{
#if 1
		NSLog(@"### _writeFileDescriptorReady: became invalid: %@", self);
#endif
		[[NSRunLoop currentRunLoop] _removeWatcher:self];
		return;
		}
	if(_sendData)
		{ // we have something more to write
			int len;
#if 0
			NSLog(@"### _writeFileDescriptorReady %@ (pos=%u len=%u)", self, _sendPos, [_sendData length]);
#endif
			len=[_sendData length]-_sendPos;	// remaining block
			if(len == 0)
				{ // done
					fsync(_sendfd);
#if 1
					NSLog(@"### all sent to fd %d", _sendfd);
#endif
					[_sendData release];
					_sendData=nil;
					_sendPos=NSNotFound;
					return;
				}
			if(len > 512)
				len=512;	// limit to reduce risk of blocking
#if 0
			NSLog(@"### write next %u bytes to fd=%d", len, _sendfd);
#endif
			
			// we could/should make the write non-blocking and account for how much was really sent - would prevent from stall
#if 0
			NSLog(@"### send byte 0x02d", *(((char *)[_sendData bytes])+_sendPos));
#endif
			if(write(_sendfd, ((char *)[_sendData bytes])+_sendPos, len) != len) // this might block in the kernel if the FIFO becomes filled up!
				{
				NSLog(@"### send error %s", strerror(errno));
				[self invalidate];
				return;
				}
			_sendPos+=len;
		}
	else
		; // nothing (more) to write - should we better unscheldule to reduce processor utilization?
}

- (id) _substituteFromCache;
{ // call only after setting the address
	// FIXME: lock
	id cached=NSMapGet(__sockets, &_address);	// look up in cache
	if(cached)
		{ // we already have a socket with these specific properties ("data")
#if 1
			NSLog(@"### substitute by cached socket: %@ %d+1", cached, [self retainCount]);
#endif
			if(cached != self)
				{ // substitute
					[cached retain];
					_isValid=NO;	// the allocated and replaced socket may have been set to valid
					[self release];
				}
			// FIXME: unlock
			return cached;
		}
#if 0
	NSLog(@"### cache new socket: %@ %d", self, [self retainCount]);
#endif
	NSMapInsertKnownAbsent(__sockets, &_address, self);
#if 0
	NSLog(@"### cached new socket: %@ %d", self, [self retainCount]);
#endif
	// FIXME: unlock
	return self;
}

- (void) invalidate
{
	if(_isValid)
		{
#if 1
		NSLog(@"### invalidated: %@", self);
#endif
		_isValid = NO;	// we will remove any scheduling for invalid ports!
		[self retain];
		NSMapRemove(__sockets, &_address);
		// FIXME: this will notify the accepted socket that is not officially known!?!
		// i.e. we may have to substitute by the _delegate
		[[NSNotificationCenter defaultCenter] postNotificationName:NSPortDidBecomeInvalidNotification object:self];
		[self release];
		}
}

- (int) protocol; { return _address.protocol; }
- (int) protocolFamily; { return _address.addr.ss_family; }
- (int) socketType; { return _address.type; }

@end /* NSPort */

@implementation NSMessagePort

#define SUN_ADDRP	((struct sockaddr_un *) &_address.addr)
#define SUN_FAMILY	(SUN_ADDRP->sun_family)
#define SUN_PATH	(SUN_ADDRP->sun_path)

static NSString *_portDirectory;
static char _portDirectoryPath[50];
static unsigned _portDirectoryLength;

+ (void) initialize;	// called on first real use of this class
{ // initialize system wide constants
	NSAssert(sizeof(struct sockaddr_un) <= sizeof(struct sockaddr_storage), NSInternalInconsistencyException);	// we can't use the sockaddr_storage structure!
	_portDirectory=[[NSTemporaryDirectory() stringByAppendingPathComponent:@".QuantumSTEP"] retain];
	strncpy(_portDirectoryPath, [_portDirectory fileSystemRepresentation], sizeof(_portDirectoryPath)-1);
	_portDirectoryLength=strlen(_portDirectoryPath);
	mkdir(_portDirectoryPath, 0770);	// create socket temp directory - ignore errors (e.g. if it already exists)
}

- (NSData *) address;
{ // not officilly defined by the @interface but we need it to encode the socket; returns the basename only
	NSData *d;
	// FIXME: the first two bytes should be the address family (but ignored when matching ports in the cache)
	if(SUN_PATH[0] == 0)
		{ // abstract
			d=[NSData dataWithBytesNoCopy:SUN_PATH length:_address.addrlen freeWhenDone:NO];	// should include leading 0-byte
		}
	else
		{
			int l=_address.addrlen-_portDirectoryLength-1;
			if(l < 0) l=0;
			d=[NSData dataWithBytesNoCopy:SUN_PATH+_portDirectoryLength-1 length:l freeWhenDone:NO];
		}
	return d;
}

- (NSString *) description;
{
	if(SUN_PATH[0] == 0)
		return [NSString stringWithFormat:@"%@ uuid=%.*s %@", [super description], _address.addrlen-1, SUN_PATH+1, [self address]];
	return [NSString stringWithFormat:@"%@ path=%.*s %@", [super description], _address.addrlen-2, SUN_PATH, [self address]];
}

- (id) init
{ // create local socket with unique name in abstract name space
#if 1
	NSLog(@"### NSMessagePort init %p", self);
#endif
	NSMutableData *addr=[[NSMutableData alloc] initWithLength:1];	// initialize with single 0 byte (abstract namespace)
	[addr appendData:[[[NSProcessInfo processInfo] globallyUniqueString] dataUsingEncoding:NSUTF8StringEncoding]];
	self=[self initRemoteWithProtocolFamily:AF_UNIX socketType:SOCK_STREAM protocol:0 address:addr];
	if(self)
		{
		_fd=socket(SUN_FAMILY, _address.type, _address.protocol);
		if(_fd < 0)
			{
#if 1
			NSLog(@"### NSMessagePort: could not create socket due to %s", strerror(errno));
#endif
			[self release];
			return nil;
			}
		// NOTE: we do not yet bind&listen like a NSSocketPort does
		// We postpone this until the port is really used for the first
		// time, so that publishing may change the socket name
		// and name space to a public name (visible in the file system)
		// and port objects used as tokens only don't create UNIX sockets		
		}
	return self;
}

- (id) initRemoteWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
{
	// FIXME: the first 2 bytes of address should probably be the same as the family!
#if 1
	NSLog(@"### NSMessagePort %p _initRemoteWithFamily:%d socketType:%d protocol:%d address:%@", self, family, type, protocol, address);
#endif
	if((self=[super init]))
		{
		SUN_FAMILY=family;
		if([address length] > 0 && ((char *)[address bytes])[0] == 0)
			{ // abstract name space
			_address.addrlen=((size_t) (((struct sockaddr_un *) 0)->sun_path)) + MIN([address length], sizeof(SUN_PATH));
				// FIXME: just fill bytes after address?
			memset(SUN_PATH, 0, sizeof(SUN_PATH));			// clear completely before using
			memcpy(SUN_PATH, ((char *)[address bytes]), _address.addrlen);	// copy incl. leading 0x00 but not more than sizeof(SUN_PATH)
			}
		else if([address length] >= 2)
			{ // file system name space - prefix with directory path
			unsigned int alen=[address length]-2;
			strncpy(SUN_PATH, _portDirectoryPath, sizeof(SUN_PATH));
			SUN_PATH[_portDirectoryLength]='/';
			strncpy(SUN_PATH+_portDirectoryLength+1, (char *)[address bytes]+2, sizeof(SUN_PATH)-_portDirectoryLength-1);
			if(alen+_portDirectoryLength+1 >= sizeof(SUN_PATH))
				{
#if 1
				NSLog(@"### NSMessagePort: name will be truncated!");
#endif
				}
			else
				(SUN_PATH+_portDirectoryLength+1)[alen]=0;	// make 0-or-length terminated string			
			_address.addrlen=SUN_LEN(SUN_ADDRP);	// set length after storing the path
			}
		_address.type=type;
		_address.protocol=protocol;
		}
	if([address length] == 0)
		return self;	// accept() returns an empty address - don't merge all these
	return [self _substituteFromCache];
}

- (NSSocketNativeHandle) socket; { return _fd; }

- (BOOL) _setName:(NSString *) name;
{ // insert concrete file name into the AF_UNIX socket - may substitute from cache
	NSMutableString *n;
	const char *fn;
	unsigned int alen;
	if(_isBound)
		{
		NSLog(@"### can't _setName:%@ - already bound: %@", name, self);
		// raise exception
		return NO;
		}
	NSMapRemove(__sockets, &_address);	// remove old name from in cache (if known)
	n=[name mutableCopy];	// make autoreleased mutable copy
	[n replaceOccurrencesOfString:@"%" withString:@"%%" options:0 range:NSMakeRange(0, [name length])];
	// FIXME: it could be sufficient to check for names beginning with .
	[n replaceOccurrencesOfString:@"." withString:@"%." options:0 range:NSMakeRange(0, [name length])];	// prevent using .. to try harmful things
	[n replaceOccurrencesOfString:@"/" withString:@"%-" options:0 range:NSMakeRange(0, [name length])];	// prevent using / to create or overwrite other files
#if 1
	NSLog(@"### setname %@ for %@", n, self);
#endif
	fn=[[_portDirectory stringByAppendingPathComponent:n] fileSystemRepresentation];
	alen=strlen(fn);
	SUN_FAMILY = AF_UNIX;
	strncpy(SUN_PATH, fn, sizeof(SUN_PATH));
	if(alen >= sizeof(SUN_PATH))
		{
#if 1
		NSLog(@"### NSMessagePort: name will be truncated!");
#endif
		}
	else
		SUN_PATH[alen]=0;	// make 0-or-length terminated string
	_address.addrlen=SUN_LEN(SUN_ADDRP);
	[n release];
#if 1
	NSLog(@"### did setname %@", self);
#endif
	return YES;
}

- (BOOL) _exists;
{ // check if name exists
	return access(SUN_PATH, R_OK | W_OK | X_OK) >= 0;
}

- (BOOL) _inUse;
{ // check if any process uses this name
	NSString *cmd=[NSString stringWithFormat:@"fuser -s '%s'", SUN_PATH];
	void (*save)(int)=signal(SIGCHLD, SIG_DFL);	// reset to default
	int r=system([cmd UTF8String]);
	if(r == -1)
		NSLog(@"### error %s", strerror(errno));
	signal(SIGCHLD, save);	// restore
#if 1
	NSLog(@"### %@ -> %d (%d %d)", cmd, r, WIFEXITED(r), WEXITSTATUS(r));
#endif
	return WIFEXITED(r) && WEXITSTATUS(r) == 0;	// process did exit(0)
}

- (BOOL) _unlink;
{ // delete name
	if(unlink(SUN_PATH) < 0)	// delete any registration if it still exists
		{
#if 1
		NSLog(@"### NSMessagePort: could not unlink socket due to %s", strerror(errno));
#endif
		return NO;
		}
#if 1
	NSLog(@"### unlinked %@", self);
#endif
	return YES;	// ok
}

@end

@implementation NSSocketPort

#define SIN_ADDRP	((struct sockaddr_in *) &_address.addr)
#define SIN_FAMILY	(SIN_ADDRP->sin_family)
#define SIN_INADDR	(SIN_ADDRP->sin_addr.s_addr)
#define SIN_PORT	(SIN_ADDRP->sin_port)
#define SIN_ADDRP6	((struct sockaddr_in6 *) &_address.addr)
#define SIN_PORT6	(SIN_ADDRP->sin6_port)

// add macros that check for SIN_FAMILY

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ fam=%u type=%u proto=%u addr=%s:%u",
			[super description],
			SIN_FAMILY,
			_address.type,
			_address.protocol,
			// make dependent on SIN_FAMILY == AF_INET or AF_INET6
			inet_ntoa(SIN_ADDRP->sin_addr),
			ntohs(SIN_PORT)];
}

- (id) init;
{ // initialize for a local (receive) port assigned by the system
	return [self initWithTCPPort:0];
}

- (id) initRemoteWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
{
#if 0
	NSLog(@"NSSocketPort _initRemoteWithFamily:%u socketType:%u protocol:%u address:%@", family, type, protocol, address);
#endif
	if((self=[self initWithProtocolFamily:family socketType:type protocol:protocol socket:-1]))	// no listener socket and not connected (yet)
		{
			[address getBytes:((char *)SIN_ADDRP)+2 range:NSMakeRange(2, sizeof(*SIN_ADDRP)-2)];	// initialize with address - but ignore the sin_family from the address
		}
	self=[self _substituteFromCache];
#if 1
	NSLog(@"new %@:%p", NSStringFromClass(isa), self);
#endif
	return self;
}

- (id) initRemoteWithTCPPort:(unsigned short) port host:(NSString *) host;
{
	NSHost *h;
	h=[NSHost hostWithName:host];	// use NSHost to do the address resolution
	if(!h)
		h=[NSHost hostWithAddress:host];	// try dotted notation
	if(!h)
		{ // could not resolve
			// CHECKME: Cocoa appears to use the "localhost" in this case
			[self release];
			return nil;
		}
// FIXME: check for IPv6 host address and pass AF_INET6
	self=[self initWithProtocolFamily:AF_INET socketType:SOCK_STREAM protocol:IPPROTO_TCP socket:-1];	// no listener socket
	if(self)
		{ // insert address of remote system
			// handle IPv6
			inet_aton([[h address] cString], &SIN_ADDRP->sin_addr);
			SIN_PORT=htons(port);	// swap to network byte order
		}
	self=[self _substituteFromCache];
#if 1
	NSLog(@"new %@:%p", NSStringFromClass(isa), self);
#endif
	return self;
}

- (id) initWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
{
	int s=socket(family, type, protocol);
	if(s < 0)
		{
		[self release];
		return nil;	// some error
		}
	self=[self initWithProtocolFamily:family
						   socketType:type
							 protocol:protocol
							   socket:s];	// allocate new socket first
	if(self)
		{
		if(address)
			{
			[address getBytes:SIN_ADDRP+2 range:NSMakeRange(2, sizeof(*SIN_ADDRP)-2)];	// initialize with address - but ignore the sin_family from the address
			self=[self _substituteFromCache];
			if(self && !_isBound && ![self _bindAndListen])
				{ // can't bind or listen
					[self release];
					return nil;
				}
			}
		}
#if 1
	if(self)
		NSLog(@"new %@:%p", NSStringFromClass(isa), self);
#endif
	return self;
}

- (id) initWithTCPPort:(unsigned short) port;
{
	self=[self initWithProtocolFamily:AF_INET	 // defaults to IPv4!
						   socketType:SOCK_STREAM
							 protocol:IPPROTO_TCP 
							  address:nil];	// no address - this represents INADDR_ANY and does not substitute from cache
	if(self)
		{ // set local port (or 0)
			SIN_PORT = htons(port);	// to network byte order
			self=[self _substituteFromCache];
			if(self && !_isBound && ![self _bindAndListen])
				{ // can't bind or listen
					[self release];
					return nil;
				}
		}
#if 1
	if(self)
		NSLog(@"new %@:%p", NSStringFromClass(isa), self);
#endif
	return self;
}

- (id) initWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol socket:(NSSocketNativeHandle) sock;
{ // this is the core initializer which makes the socket the listener _fd
	if((self=[super init]))
		{
		_address.addrlen=(family == AF_INET6)?sizeof(struct sockaddr_in6):sizeof(struct sockaddr_in);
		SIN_FAMILY=family;
		_address.type=type;
		_address.protocol=protocol;
		_fd=sock;
		}
#if 0
	NSLog(@"initialized with socket %d", sock);
#endif
	return self;
}

- (NSData *) address;
{ // return everything in network byte order compatible to MacOS X format
	NSData *d;
	// handle IPv6
	struct sockaddr_in addr=*(SIN_ADDRP);	// copy
#if 0
	NSLog(@"get address of %@", self);
#endif
	addr.sin_family=htons((sizeof(struct sockaddr_in)<<8)+SIN_FAMILY);	// swap into Mac expected byte order
	d=[NSData dataWithBytes:&addr length:sizeof(addr)];	// pack into NSData
	return d;
}

- (int) protocolFamily; { return _address.addr.ss_family; }
- (NSSocketNativeHandle) socket; { return _fd; }
- (int) protocol; { return _address.protocol; }
- (int) socketType; { return _address.type; }

@end

@implementation NSPortMessage

/*
 Mach defines:
 port_t				NSPort object	type=2
 MSG_TYPE_BYTE		NSData object	type=1
 MSG_TYPE_CHAR	
 MSG_TYPE_INTEGER_32	
 
 According to experiments and descriptions in Amit Singh´s book, a message appears to look like this:
 
 msgid=17, components=([NSData dataWithBytes:"1" length:1], [NSData data], [NSData dataWithBytes:"1" length:1]) result on a Mac in:
 d0cf50c0 0000003a 00000011 02010610 100211c7 00000000 00000000 00000000 00000001 00000001 31000000 01000000 00000000 01000000 0132
 msgid=12, components=([NSData dataWithBytes:"123" length:3], [NSData data], [NSData dataWithBytes:"987654321" length:9]) result on a Mac in:
 d0cf50c0 00000044 0000000c 02010610 100211c7 00000000 00000000 00000000 00000001 00000003 31323300 00000100 00000000 00000100 00000939 38373635 34333231
 h_bits   size     msgid    response expected on this sockadr            |type=1? |len=3   |"123"|type?   |len=0     |type=1? |len=9    |"987654321
 msgid=12, components=([NSData dataWithBytes:"123" length:3], <some NSSocketPort>) result on a Mac in:
 d0cf50c0 00000047 0000000c 02010610 100211c7 00000000 00000000 00000000 00000001 00000003 31323300 00000200 00001402 01061010 0211c700 00000000 00000000 000000
 h_bits   size     msgid    response expected on this sockadr            |type=1? |len=3   |"123"|type=2? |len=14  |AF_INET socket PF=2, type=1, AF=6, ?:<101002>, port=4551 (11c7) addr=0.0.0.0
 magic                      PF=2, type=1, AF=6, addrlen=10??
 i.e. the "receive port" is always encoded into the message
 
 h_bits might look constant but may be the two local&remote status bit short-ints. I.e. d0cf and 50c0 are flags which indicate if a receive or send port itself is part of the Mach message.
 
 */

// see also http://www.gnu.org/software/hurd/gnumach-doc/Message-Format.html

struct MachHeader {
	uint32_t magic;	// well, some header bits
	uint32_t len;		// total packet length
	uint32_t msgid;
};

struct PortFlags {
	uint8_t family;
	uint8_t type;
	uint8_t protocol;
	uint8_t len;
};

+ (NSData *) _machMessageWithId:(unsigned) msgid forSendPort:(NSPort *)sendPort receivePort:(NSPort *)receivePort components:(NSArray *)components
{ // encode components as a binary message
	struct PortFlags port;
	NSMutableData *d=[NSMutableData dataWithCapacity:64+16*[components count]];	// some reasonable initial allocation
	NSEnumerator *e=[components objectEnumerator];
	id c;
	uint32_t value;
	value=NSSwapHostLongToBig(0xd0cf50c0);
	[d appendBytes:&value length:sizeof(value)];	// header flags
	[d appendBytes:&value length:sizeof(value)];	// we insert real length later on
	value=NSSwapHostLongToBig(msgid);
	[d appendBytes:&value length:sizeof(value)];	// message ID
	if(1 /* encode the receive port address */)
		{
		NSData *saddr=[(NSSocketPort *) receivePort address];
		port.protocol=[(NSSocketPort *) receivePort protocol];
		port.type=[(NSSocketPort *) receivePort socketType];
		port.family=[(NSSocketPort *) receivePort protocolFamily];
		port.len=[saddr length];
		[d appendBytes:&port length:sizeof(port)];	// write socket flags
		[d appendData:saddr];
#if 0
		NSLog(@"encoded receive port address: %@", [d subdataWithRange:NSMakeRange(12, [d length]-12)]);
#endif
		}
	while((c=[e nextObject]))
		{ // serialize objects
			if([c isKindOfClass:[NSData class]])
				{
					value=NSSwapHostLongToBig(1);	// MSG_TYPE_BYTE
					[d appendBytes:&value length:sizeof(value)];	// record type
					value=NSSwapHostLongToBig([c length]);
					[d appendBytes:&value length:sizeof(value)];	// total record length
					[d appendData:c];								// the data or port address
				}
			else
				{ // serialize an NSPort
					NSData *saddr=[(NSSocketPort *) c address];
					value=NSSwapHostLongToBig(2);	// port_t
					[d appendBytes:&value length:sizeof(value)];	// record type
					value=NSSwapHostLongToBig([saddr length]+sizeof(port));
					[d appendBytes:&value length:sizeof(value)];	// total record length
					port.protocol=[(NSSocketPort *) c protocol];
					port.type=[(NSSocketPort *) c socketType];
					port.family=[(NSSocketPort *) c protocolFamily];
					port.len=[saddr length];
					[d appendBytes:&port length:sizeof(port)];	// write socket flags
					[d appendData:saddr];
				}
		}
	value=NSSwapHostLongToBig([d length]);
	[d replaceBytesInRange:NSMakeRange(sizeof(value), sizeof(value)) withBytes:&value];	// insert total record length
#if 0
	NSLog(@"machmessage=%@", d);
#endif
	return d;
}

/*
 FIXME/CHECKME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows and Denial of Service.
 This might also be some very large constant for record length which wraps around the 32bit address limit (e.g. a negative record length). This would
 end up in infinite loops blocking or crashing the application or service.
 */

// FIXME: this method may be thought for a real Mach Message - here we assume an encoded port message for

- (id) initWithMachMessage:(void *) buffer;
{ // decode a binary encoded message - for some details see e.g. http://objc.toodarkpark.net/Foundation/Classes/NSPortMessage.htm
	if((self=[super init]))
		{
		struct MachHeader header;
		struct PortFlags port;
		char *bp, *end;
		NSData *addr;
		memcpy(&header, buffer, sizeof(header));
		if(header.magic != NSSwapHostLongToBig(0xd0cf50c0))
			{
#if 1
			NSLog(@"-initWithMachMessage: bad magic");
#endif
			[self release];
			return nil;
			}
		header.len=NSSwapBigLongToHost(header.len);
		if(header.len > 0x80000000)
			{
#if 1
			NSLog(@"-initWithMachMessage: unreasonable length");
#endif
			[self release];
			return nil;
			}
		_msgid=NSSwapBigLongToHost(header.msgid);
		end=(char *) buffer+header.len;	// total length
		bp=(char *) buffer+sizeof(header);						// start reading behind header
#if 0
		NSLog(@"msgid=%d len=%u", _msgid, end-(char *) buffer);
#endif
		if(0 /* this is the send port */)
			{ // decode send port that has been supplied by the sender as sendbeforeDate:from:
				memcpy(&port, bp, sizeof(port));
				if(bp+sizeof(port)+port.len > end)
					{ // goes beyond total length
						[self release];
						return nil;
					}
				addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];	// we don't need to copy since we know that initRemoteWithProtocolFamily makes its own private copy
#if 0
				NSLog(@"decoded _send addr %@ %p", addr, addr);
#endif
				_send=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
#if 0
				NSLog(@"decoded _send %@", _send);
#endif
				bp+=sizeof(port)+port.len;
			}
		if(1 /* recv port */)
			{ // decode receive port that has been supplied by the sender as sendbeforeDate:from:
				memcpy(&port, bp, sizeof(port));
				if(bp+sizeof(port)+port.len > end)
					{ // goes beyond total length
						[self release];
						return nil;
					}
				addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];	// we don't need to copy since we know that initRemoteWithProtocolFamily makes its own private copy
#if 0
				NSLog(@"decoded _recv addr %@ %p", addr, addr);
#endif
				_recv=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
#if 0
				NSLog(@"decoded _recv %@", _recv);
#endif
				bp+=sizeof(port)+port.len;
			}
		_components=[[NSMutableArray alloc] initWithCapacity:5];
		while(bp < end)
			{ // more component records to come
				struct MachComponentHeader {
					uint32_t type;
					uint32_t len;
				} record;
				memcpy(&record, bp, sizeof(record));
#if 0
				NSLog(@"  pos=%u type=%u len=%u", bp-(char *) buffer, record.type, record.len);	// before byte swapping
#endif
				record.type=NSSwapBigLongToHost(record.type);
				record.len=NSSwapBigLongToHost(record.len);
#if 0
				NSLog(@"  pos=%u type=%u len=%u", bp-(char *) buffer, record.type, record.len);
#endif
				bp+=sizeof(record);
				if(record.len > end-bp)
					{ // goes beyond available data
#if 0
						NSLog(@"length error: pos=%u len=%u remaining=%u", bp-(char *) buffer, record.len, end-bp);
#endif
						[self release];
						return nil;
					}
				switch(record.type) {
					case 1: { // NSData
#if 0
						NSLog(@"decode component with length %u", record.len); 
#endif
						[_components addObject:[NSData dataWithBytes:bp length:record.len]];	// cut out and save a copy of the data fragment
						break;
					}
					case 2: { // decode NSPort
						NSData *addr;
						NSPort *p=nil;
						memcpy(&port, bp, sizeof(port));
						if(bp+sizeof(port)+port.len > end)
							{ // goes beyond total length
								[self release];
								return nil;
							}
						addr=[NSData dataWithBytesNoCopy:bp+sizeof(port) length:port.len freeWhenDone:NO];
#if 0
						NSLog(@"decode NSPort family=%u addr=%@ %p", port.family, addr, addr);
#endif
						p=[[NSPort _allocForProtocolFamily:port.family] initRemoteWithProtocolFamily:port.family socketType:port.type protocol:port.protocol address:addr];
						[_components addObject:p];
						[p release];
						break;
					}
					default: {
#if 1
						NSLog(@"unexpected record type %u at pos=%u", record.type, bp-(char *) buffer);
#endif
						[self release];
						return nil;
					}
				}
				bp+=record.len;	// go to next record
#if 0
				NSLog(@"pos=%u", bp-(char *) buffer);
#endif
			}
		if(bp != end)
			{
#if 1
			NSLog(@"length error bp=%p end=%p", bp, end);
#endif
			[self release];
			return nil;
			}
		}
	return self;
}

- (id) initWithSendPort:(NSPort *) aPort
			receivePort:(NSPort *) anotherPort
			 components:(NSArray *) items;
{
	if((self=[super init]))
		{
		_recv=[anotherPort retain];
		_send=[aPort retain];
		_components=[items retain];
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"pm dealloc");
#endif
	[_recv release];
	[_send release];
	[_components release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"NSPortMessage msgid:%u r:%@ s:%@ c:%@", _msgid, _recv, _send, _components];
}

- (NSArray*) components; { return _components; }
- (unsigned) msgid; { return _msgid; }
- (NSPort *) receivePort; { return _recv; }
- (void) _setReceivePort:(NSPort *) p; { ASSIGN(_recv, p); }
- (NSPort *) sendPort; { return _send; }
- (void) _setSendPort:(NSPort *) p; { ASSIGN(_send, p); }
- (void) setMsgid: (unsigned)anId; { _msgid=anId; }

- (BOOL) sendBeforeDate:(NSDate*) when;
{
	if(!_send || ![_send isValid])
		[NSException raise:NSInvalidSendPortException format:@"invalid send port for message %@", self];
	if(!_recv || ![_recv isValid])
		[NSException raise:NSInvalidReceivePortException format:@"invalid receive port for message %@", self];
#if 0
	NSLog(@"sendBeforeDate:%@ %@", when, self);
#endif
#if 0
	printf("s: %s\n", [[self description] UTF8String]);
#endif
	return [_send sendBeforeDate:when msgid:_msgid components:_components from:_recv reserved:[_send reservedSpaceLength]];
}

@end
