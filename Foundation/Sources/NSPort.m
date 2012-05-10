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

static struct in_addr _current_inaddr;	// used for a terrible hack to replace a received IP addr of 0.0.0.0 by the sender's address

@implementation NSPort

+ (void) initialize
{
	if(self == [NSPort class])
		{
		signal(SIGPIPE, SIG_IGN);
		// If SIGPIPE is not ignored, we will abort 
		// on any attempt to write to a pipe/socket
		// that has been closed by the other end!
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
	switch(family)
		{
		case AF_INET:
			return [NSSocketPort allocWithZone:NSDefaultMallocZone()];
		case AF_UNIX:
			return [NSMessagePort allocWithZone:NSDefaultMallocZone()];
		default:
			NSLog(@"can't handle protocol family %d", family);
			return nil;
		}
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%p:%@ listen=%d connect=%d parent=%@%@%@", self, NSStringFromClass(isa), _fd, _sendfd, _parent, _isValid?@" valid":@"", _isBound?@"":@" not bound"];
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
			_delegate=self;	// appears to be initialized to be its own delegate
		_isValid = YES;
		_fd=-1;
		_sendfd=-1;
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"dealloc:%@", self);
#endif
	[_parent release];
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
#if 0
		NSLog(@"port finally released: %@", self);
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
	if(anObject && ![anObject respondsToSelector: @selector(handlePortMessage:)] && !![anObject respondsToSelector: @selector(handleMachMessage:)])
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

- (void) addConnection:(NSConnection *)connection
			 toRunLoop:(NSRunLoop *)runLoop
			   forMode:(NSString *)mode;
{ // schedule for receiving for the given connection
#if 0
	NSLog(@"addConnection:%@ toRunLoop:%@ forMode:%@", connection, runLoop, mode);
#endif
	[self setDelegate:connection];
	[self scheduleInRunLoop:runLoop forMode:mode];
}

- (void) removeConnection:(NSConnection *)connection
			  fromRunLoop:(NSRunLoop *)runLoop
				  forMode:(NSString *)mode;
{
#if 0
	NSLog(@"removeConnection:%@ fromRunLoop:%@ forMode:%@", connection, runLoop, mode);
#endif
	[self removeFromRunLoop:runLoop forMode:mode];
	[self setDelegate:nil];
}

- (void) removeFromRunLoop:(NSRunLoop *)runLoop
				   forMode:(NSString *)mode;
{
#if 0
	NSLog(@"--- removeFromRunLoop:%@ forMode:%@ - %@", runLoop, mode, self);
#endif
	[runLoop _removeInputWatcher:self forMode:mode];
}

- (void) scheduleInRunLoop:(NSRunLoop *)runLoop
				   forMode:(NSString *)mode;
{
#if 0
	NSLog(@"+++ scheduleInRunLoop:%@ forMode:%@ - %@", runLoop, mode, self);
#endif
	[runLoop _addInputWatcher:self forMode:mode];
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
#if 0
	NSLog(@"%@ sendBeforeDate:%@ msgid:%u components:%@ from:%@ reserved:%u", self, limitDate, msgid, components, receivePort, headerSpaceReserved);
#endif
	if(!_isValid)
		[NSException raise:NSInvalidSendPortException format:@"invalidated: %@", self];
	if(!receivePort || ![receivePort _bindAndListen])	// receive port wasn't bound to a file or socket yet - bind before connect for self-connections
		return NO;
	if(_sendfd < 0 && ![self _connect])	// we are not yet connected
		return NO;
	_sendData=[NSPortMessage _machMessageWithId:msgid forSendPort:self receivePort:receivePort components:components];	// convert to data block
	if(!_sendData)
		[NSException raise:NSPortSendException format:@"could not convert data to machMessage"];
	[_sendData retain];	// NSRunLoop may autorelease pools until everything is sent!
#if 0
	NSLog(@"send length=%u data=%@ to fd=%d", [_sendData length], _sendData, _sendfd);
#endif
	_sendPos=0;
	[loop _addOutputWatcher:self forMode:NSConnectionReplyMode];	// get callbacks when we can send
	[loop _addInputWatcher:self forMode:NSConnectionReplyMode];		// get callbacks for our listen() port even if we are scheduled in NSDefaultRunLoopMode only
#if 0
	NSLog(@"remaining interval %lf", [limitDate timeIntervalSinceNow]);
#endif
	while(_sendData && [limitDate timeIntervalSinceNow] > 0)
		{
#if 0
		NSLog(@"run loop %@ in mode %@", loop, NSConnectionReplyMode);
#endif
		if(!_isValid)
			{
			[loop _removeInputWatcher:self forMode:NSConnectionReplyMode];
			[loop _removeOutputWatcher:self forMode:NSConnectionReplyMode];
			[NSException raise:NSPortSendException format:@"sendBeforeDate: send port became invalid %@", self];
			}
		if(![loop runMode:NSConnectionReplyMode beforeDate:limitDate])
			{ // some runloop error, e.g. not scheduled in this mode
#if 0
			NSLog(@"sendBeforeDate: runloop error");
#endif
			[loop _removeInputWatcher:self forMode:NSConnectionReplyMode];
			[loop _removeOutputWatcher:self forMode:NSConnectionReplyMode];
			[NSException raise:NSPortSendException format:@"sendBeforeDate: runloop error for %@", self];
			break;
			}
#if 0
		NSLog(@"remaining interval %lf", [limitDate timeIntervalSinceNow]);
#endif
		}
	[loop _removeInputWatcher:self forMode:NSConnectionReplyMode];
	[loop _removeOutputWatcher:self forMode:NSConnectionReplyMode];
#if 0
	if(_sendPos == NSNotFound)
		NSLog(@"all sent");
	else
		NSLog(@"### NOT ALL SENT ###");
#endif
	return _sendPos == NSNotFound;		// we did send all bytes?
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
#if 0
		NSLog(@"connect to family=%d %@", _address.addr.ss_family, self);
#endif
		_sendfd=socket(_address.addr.ss_family, SOCK_STREAM, 0);
		if(connect(_sendfd, (struct sockaddr *) &_address.addr, _address.addrlen))
			{
			NSLog(@"%@: could not connect due to %s", self, strerror(errno));
			return NO;
			}
#if 1
		NSLog(@"connected %@", self);
#endif
		}
	return YES;
}

- (BOOL) _bindAndListen;
{
	if(!_isBound)
		{ // not yet bound
		if(!_isValid)
			[NSException raise:NSInvalidReceivePortException format:@"invalidated before bind&listen: %@", self];
		if(bind(_fd, (struct sockaddr *) &_address.addr, _address.addrlen))
			{
			NSLog(@"%@: could not bind due to %s", self, strerror(errno));
			return NO;
			}
		if(_address.addr.ss_family != AF_UNIX)
			{ // get port assigned by system - AF_UNIX does not support this system call
			unsigned addrlen=_address.addrlen;
			// NSMapRemove(__sockets, &_address);
			getsockname(_fd, (struct sockaddr *) &_address.addr, &addrlen);	// read back to know the port number
			_address.addrlen=addrlen;
			// FIXME: may this change cache mapping? 
			// NSMapInsert(__sockets, &_address, self);
			}
#if 0
		NSLog(@"bound %@", self);
#endif
		if(listen(_fd, 10))
			{
			NSLog(@"%@: could not listen due to %s", self, strerror(errno));
			return NO;
			}
#if 0
		NSLog(@"listening");
#endif
		_isBound=YES;
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
	NSPort *recv;	// 'official' receive port
	id d;			// delegate
#if 0
	NSLog(@"_readFileDescriptorReady: %@", self);
#endif
	if(!_isValid)
		{
		NSLog(@"_readFileDescriptorReady: became invalid: %@", self);
		[[NSRunLoop currentRunLoop] _removeWatcher:self];
		return;
		}
	if(_fd >= 0)
		{ // listening was successfull
		struct sockaddr_storage ss;	// FIXME: is this large enough for AF_UNIX?
		socklen_t saddrlen=sizeof(ss);
		NSRunLoop *loop=[NSRunLoop currentRunLoop];
		NSPort *newPort;
		NSData *addr;
		int newfd;
		short family;
		if(!_isBound)
			{
#if 0
			NSLog(@"not yet bound & listening:%@", self);
			return;
#endif
			}
#if 0
		NSLog(@"salen=%d %@", saddrlen, self);
#endif
		memset(&ss, 0, saddrlen);			// clear completely before using
		newfd=accept(_fd, (struct sockaddr *) &ss, &saddrlen);
#if 0
		NSLog(@"accepted on fd=%d newfd=%d salen=%d", _fd, newfd, saddrlen);
#endif
		if(newfd < 0)
			{
			NSLog(@"_readFileDescriptorReady: could not accept on %@ due to %s", self, strerror(errno));
			[self invalidate];
			return;
			}
		family=ss.ss_family;
		*((short *) &ss.ss_family)=htons(family);	// swap family to network byte order (as expected by initRemoteWithProtocolFamily)
		addr=[NSData dataWithBytesNoCopy:&ss length:saddrlen freeWhenDone:NO];
#if 1
		NSLog(@"accepted socket=%d", newfd);
		NSLog(@"  address=%@", addr);
#endif
		newPort=[[isa alloc] initRemoteWithProtocolFamily:family socketType:_address.type protocol:_address.protocol address:addr];
		NSAssert1(newPort->_sendfd < 0, @"Already connected! newport=%@", newPort);
		newPort->_parent=[self retain];
		newPort->_isBound=YES;			// pretend we are already bound
		newPort->_sendfd=newfd;			// we are already connected
#if 0
		NSLog(@"accepted %@ on parent %@", newPort, self);
#endif
		
		// FIXME: should we inherit the watchers from our parent???
		// this is just a temporary hack that appears to make it work...
		
		[loop _addInputWatcher:newPort forMode:NSDefaultRunLoopMode];	// allow us to receive the first packet on this port
		[loop _addInputWatcher:newPort forMode:NSConnectionReplyMode];

		/* CHECKME:
			how do we schedule other modes - and how and when do we unschedule???
			well, we probably carry a new NSConnection and initializing the NSConnection will inherit runloops&modes from the parent-NSConnection
			unscheduling is done automatically when we are set invalid
			*/
		[newPort release];	// should now have been retained as watcher and/or by cache until invalidated
#if 0
		NSLog(@"accept done. retain count=%d", [newPort retainCount]);
#endif
		return;
		}
#if 0
	NSLog(@"_readFileDescriptor:%d ready %@", _sendfd, self);
#endif
	if(!_recvBuffer)
		{ // no buffer allocated so far - receive and check for header
		struct { unsigned long magic, messageLength; } header;	// we know something about the mach message structure, i.e. that there is a header magic and the block length and therefore know how much to read for frame boundaries		
		int len;
//		fcntl(_sendfd, F_SETFL, O_NONBLOCK);	// don't block here or later
		// FIXME: we need a more sophisticated mechanism to properly handle header fragments! Therefore we block until we have received a full header
		if((len=read(_sendfd, &header, sizeof(header))) != sizeof(header))
			{ // should we have a mechanism to resync? This appears to be not required since we assume a reliable transport socket
			// we might have to remember a partial header!
#if 0
			NSLog(@"closed by peer: %@", self);
#endif
			[self invalidate];
			if(len == 0)
				return;	// simply closed by peer (EOF notification)
			[NSException raise:NSPortReceiveException format:@"_readFileDescriptorReady: header read error %s - len=%d", strerror(errno), len];
			}
#if 0
		NSLog(@"did read %u bytes", len);
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
		NSLog(@"header received length=%u on fd=%d", _recvLength, _sendfd);
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
	NSLog(@"pos=%u length=%u", _recvPos, _recvLength);
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
		NSLog(@"did read %u bytes from fd=%d", len, _sendfd);
#endif
		_recvPos+=len;
		if(_recvPos < _recvLength)
			return;	// incomplete
		}
#if 0
	NSLog(@"complete message received on %@: %@", self, [NSData dataWithBytesNoCopy:_recvBuffer length:_recvLength freeWhenDone:NO]);
#endif
	recv=_parent?_parent:self;	// act for parent if we are a child
	d=[recv delegate];
#if 1
	if(!d)
		NSLog(@"no delegate! %@", self);
#endif

	/* FIXME: this is a terrible hack
	 * since we may receive 0.0.0.0 for an encoded NSSocketPort in the MachMessage
	 * which is meant to encode "sender"
	 * we must make us known to the following method 
	 * -initRemoteWithProtocolFamily:socketType:protocol:address:
	 * which subsitutes the address
	 * this is neither thread-safe nor exception-safe
	 */
	
	_current_inaddr=((struct sockaddr_in *) &_address.addr)->sin_addr;	// get receiver's IP address
	// FIXME: should we protect this block against exceptions in the handler
	if([d respondsToSelector:@selector(handleMachMessage:)])
		{
		[d handleMachMessage:_recvBuffer];
		objc_free(_recvBuffer);	// done
		_recvBuffer=NULL;
		}
	else
		{
			NSAutoreleasePool *arp=[NSAutoreleasePool new];
			NSPortMessage *msg=[[NSPortMessage alloc] initWithMachMessage:_recvBuffer];
			[msg _setReceivePort:recv];		// we (or our parent) is the receive port
			objc_free(_recvBuffer);			// done
			_recvBuffer=NULL;
#if 1
			NSLog(@"handlePortMessage:%@ by delegate %@", msg, d);
#endif
			[d handlePortMessage:msg];	// process by delegate
			[msg release];
#if 1
			NSLog(@"msg released");
#endif
			[arp release];
		}
	_current_inaddr.s_addr=INADDR_ANY;	// restore
}

- (void) _writeFileDescriptorReady;
{ // callback
	if(!_isValid)
		{
#if 1
		NSLog(@"_writeFileDescriptorReady: became invalid: %@", self);
#endif
		[[NSRunLoop currentRunLoop] _removeWatcher:self];
		return;
		}
	if(_sendData)
		{ // we have something more to write
		int len;
#if 0
		NSLog(@"_writeFileDescriptorReady %@ (pos=%u len=%u)", self, _sendPos, [_sendData length]);
#endif
		len=[_sendData length]-_sendPos;	// remaining block
		if(len == 0)
			{ // done
			fsync(_sendfd);
#if 0
			NSLog(@"all sent");
#endif
			[_sendData release];
			_sendData=nil;
			_sendPos=NSNotFound;
			return;
			}
		if(len > 512)
			len=512;	// limit to reduce risk of blocking
#if 0
		NSLog(@"write next %u bytes to fd=%d", len, _sendfd);
#endif
		
		// we could/should make the write non-blocking and account for how much was really sent - would prevent from stall
#if 0
		NSLog(@"send byte 0x02d", *(((char *)[_sendData bytes])+_sendPos));
#endif
		if(write(_sendfd, ((char *)[_sendData bytes])+_sendPos, len) != len) // this might block in the kernel if the FIFO becomes filled up!
			{
			NSLog(@"send error %s", strerror(errno));
			[self invalidate];
			return;
			}
		_sendPos+=len;
		}
	else
		; // nothing (more) to write - should we better unscheldule to reduce processor utilization?
}

static NSMapTable *__sockets;	// a map table to associate family, type, protocol, address with a specific socket instance

NSString *__NSDescribeSockets(void *table, const void *addr)
{
	return [[NSData dataWithBytes:addr length:((struct _NSPortAddress *) addr)->addrlen+sizeof(unsigned short)+2*sizeof(unsigned char)] description];
}

unsigned __NSHashSocket(void *table, const void *addr)
{
	register const char *p = (char*)addr;
	register unsigned hash = 0, hash2;
	register int i;
    for(i = 0; i < ((struct _NSPortAddress *) addr)->addrlen+sizeof(unsigned short)+2*sizeof(unsigned char); i++)
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
    return memcmp((char*)addr1, (char*)addr2, ((struct _NSPortAddress *) addr1)->addrlen+sizeof(unsigned short)+2*sizeof(unsigned char)) == 0;
}

static const NSMapTableKeyCallBacks NSSocketMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashSocket,
    (BOOL (*)(NSMapTable *, const void *, const void *))__NSCompareSockets,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeSockets,
    (const void *)NULL
};

- (id) _substituteFromCache;
{ // call only after setting the address
  // FIXME: lock
	if(!__sockets)
		__sockets=NSCreateMapTable(NSSocketMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
	else
		{
		id cached=NSMapGet(__sockets, &_address);	// look up in cache
		if(cached)
			{ // we already have a socket with these specific properties ("data")
#if 0
			NSLog(@"substitute by cached socket: %@ %d+1", cached, [self retainCount]);
#endif
			if(cached != self)
				{ // substitute
				[cached retain];
				_isValid=NO;	// don't explicity invalidate
				[self release];
				// FIXME: unlock
				}
			return cached;
			}
		}
#if 0
	NSLog(@"cache new socket: %@ %d", self, [self retainCount]);
#endif
	NSMapInsertKnownAbsent(__sockets, &_address, self);
#if 0
	NSLog(@"cached new socket: %@ %d", self, [self retainCount]);
#endif
	// FIXME: unlock
	return self;
}

- (void) invalidate
{
	if(_isValid)
		{
#if 1
		NSLog(@"invalidated: %@", self);
#endif
		_isValid = NO;	// we will remove any scheduling for invalid ports!
		[self retain];
		NSMapRemove(__sockets, &_address);
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
static unsigned _portDirectoryLength;

+ (void) initialize;	// called on first real use of this class
{ // this is a system constant...
	const char *fsrep;
	NSAssert(sizeof(struct sockaddr_un) <= sizeof(struct sockaddr_storage), NSInternalInconsistencyException);	// we can't use the sockaddr_storage structure!
	_portDirectory=[[NSTemporaryDirectory() stringByAppendingPathComponent:@".QuantumSTEP"] retain];
	fsrep=[_portDirectory fileSystemRepresentation];
	_portDirectoryLength=strlen(fsrep);
	mkdir(fsrep, 0770);	// create socket temp directory - ignore errors
}

- (NSData *) address;
{ // not defined by the @interface but we need it to encode the socket
	NSData *d;
	int l=_address.addrlen-_portDirectoryLength-1;
	if(l < 0) l=0;
	// FIXME: the first two bytes should be the address family (but is ignored when matching ports in the cache)
	d=[NSData dataWithBytesNoCopy:SUN_PATH+_portDirectoryLength-1 length:l freeWhenDone:NO];
	return d;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ path=%.*s %@", [super description], _address.addrlen-2, SUN_PATH, [self address]];
}

- (id) init
{ // create local socket with unique local name
#if 0
	NSLog(@"NSMessagePort init");
#endif
	if((self=[self _initRemoteWithName:[[NSProcessInfo processInfo] globallyUniqueString]]))
		{
		_fd=socket(SUN_FAMILY, _address.type, 0);
		if(_fd < 0)
			{
			NSLog(@"NSMessagePort: could not create socket due to %s", strerror(errno));
			[self release];
			return nil;
			}
		// note: we do not yet bind&listen like the NSSocketPort - we do that only if we are used for the first time, so that publishing may change the socket name
		}
	return self;
}

- (id) _initRemoteWithName:(NSString *) name;
{ // create socket that will connect to specified remote socket
#if 0
	NSLog(@"NSMessagePort _initRemoteWithName:%@", name);
#endif
	if((self=[super init]))
		{
		_address.type=SOCK_STREAM;
		[self _setName:name];	// insert socket address
		}
	return [self _substituteFromCache];
}

- (id) initRemoteWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
{
	int alen=[address length]-2;
	// FIXME: the first 2 bytes of address should probably be the same as the family!
	// should we substitute a unique local name if alen == 0?
	// i.e. [[NSProcessInfo processInfo] globallyUniqueString]]
#if 0
	NSLog(@"NSMessagePort _initRemoteWithFamily:%d socketType:%d protocol:%d address:%@", family, type, protocol, address);
#endif
	if((self=[super init]))
		{
		SUN_FAMILY=family;
		strncpy(SUN_PATH, [_portDirectory fileSystemRepresentation], sizeof(SUN_PATH));
		SUN_PATH[_portDirectoryLength]='/';
		strncpy(SUN_PATH+_portDirectoryLength+1, (char *)[address bytes]+2, sizeof(SUN_PATH)-_portDirectoryLength-1);
		if(alen+_portDirectoryLength+1 >= sizeof(SUN_PATH))
			NSLog(@"NSMessagePort: name will be truncated!");
		else
			(SUN_PATH+_portDirectoryLength+1)[alen]=0;	// make 0-or-length terminated string
		_address.addrlen=SUN_LEN(SUN_ADDRP);
		_address.type=type;
		_address.protocol=protocol;
		}
	if(alen > 0)
		return [self _substituteFromCache];
	return self;	// accept() returns an empty address - don't merge all these
}

- (NSSocketNativeHandle) socket; { return _fd; }

- (void) _setName:(NSString *) name;
{ // insert file name into the AF_UNIX socket
	NSMutableString *n;
	const char *fn;
	if(_isBound)
		{
		NSLog(@"can't _setName:%@ - already bound: %@", name, self);
		return;
		}
	n=[name mutableCopy];	// make autoreleased mutable copy
	[n replaceOccurrencesOfString:@"%" withString:@"%%" options:0 range:NSMakeRange(0, [name length])];
	[n replaceOccurrencesOfString:@"/" withString:@"%-" options:0 range:NSMakeRange(0, [name length])];	// prevent using / to create or overwrite other files
#if 0
	NSLog(@"setname -> %@", n);
#endif
	fn=[[_portDirectory stringByAppendingPathComponent:n] fileSystemRepresentation];
	if(strlen(fn) >= sizeof(SUN_PATH))
		NSLog(@"NSMessagePort: name will be truncated!");
	SUN_FAMILY = AF_UNIX;
	strncpy(SUN_PATH, fn, sizeof(SUN_PATH));
	_address.addrlen=SUN_LEN(SUN_ADDRP);
	[n release];
}

- (BOOL) _unlink;
{ // delete name
  // shouldn't we close?
	if(unlink(SUN_PATH))	// delete any registration if it still exists
		{
		// check for error != E_NOTFOUND
		return NO;
		}
	return YES;
}

@end

@implementation NSSocketPort

#define SIN_ADDRP	((struct sockaddr_in *) &_address.addr)
#define SIN_FAMILY	(SIN_ADDRP->sin_family)
#define SIN_INADDR	(SIN_ADDRP->sin_addr.s_addr)
#define SIN_PORT	(SIN_ADDRP->sin_port)

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ fam=%d type=%d proto=%d addr=%s:%d", [super description], ((struct sockaddr_in *) &_address.addr)->sin_family, _address.type, _address.protocol, inet_ntoa(((struct sockaddr_in *) &_address.addr)->sin_addr), ntohs(((struct sockaddr_in *) &_address.addr)->sin_port)];
}

- (id) init;
{ // initialize for a local port assigned by the system
	return [self initWithTCPPort:0];
}

- (id) initRemoteWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol address:(NSData *) address;
{
#if 0
	NSLog(@"NSSocketPort _initRemoteWithFamily:%d socketType:%d protocol:%d address:%@", family, type, protocol, address);
#endif
	if((self=[self initWithProtocolFamily:family socketType:type protocol:protocol socket:-1]))	// no listener socket and not connected (yet)
		{
		if(address)
			{
			[address getBytes:((char *)SIN_ADDRP)+2 range:NSMakeRange(2, sizeof(*SIN_ADDRP)-2)];	// initialize with address - but ignore the sin_family from the address
			if(SIN_INADDR == INADDR_ANY)
				{
				// FIXME: we should substitute with the in_addr of the socket we have received the message from which we have decoded a socket!
//				SIN_INADDR = htonl(INADDR_LOOPBACK);	// substitute so that we connect locally
				SIN_ADDRP->sin_addr = _current_inaddr;	// substitute so that we connect back to the sender of the message
				}
			}
		}
	return [self _substituteFromCache];
}

- (id) initRemoteWithTCPPort:(unsigned short) port host:(NSString *) host;
{ // NOTE: this one is not cached!
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
	self=[self initWithProtocolFamily:AF_INET socketType:SOCK_STREAM protocol:IPPROTO_TCP socket:-1];	// no listener socket
	if(self)
		{ // insert address of remote system
		inet_aton([[h address] cString], &SIN_ADDRP->sin_addr);
		SIN_PORT=htons(port);	// swap to network byte order
		}
	return [self _substituteFromCache];
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
	return self;
}

- (id) initWithTCPPort:(unsigned short) port;
{
	self=[self initWithProtocolFamily:AF_INET
						   socketType:SOCK_STREAM
							 protocol:IPPROTO_TCP 
							  address:nil];	// no address
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
	return self;
}

- (id) initWithProtocolFamily:(int) family socketType:(int) type protocol:(int) protocol socket:(NSSocketNativeHandle) sock;
{ // this is the core initializer which makes the socket the listener _fd
	if((self=[super init]))
		{
		_address.addrlen=sizeof(struct sockaddr_in);
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
	short family=*(short *) &SIN_FAMILY;	// fetch in host byte order
	*(short *) &SIN_FAMILY=htons((sizeof(struct sockaddr_in)<<8)+SIN_FAMILY);	// combine with structure length and temporarily (!) swap as word (!)
	d=[NSData dataWithBytes:SIN_ADDRP length:sizeof(struct sockaddr_in)];
	*(short *) &SIN_FAMILY=family;	// restore
	return d;
}

- (int) protocolFamily; { return _address.addr.ss_family; }
- (NSSocketNativeHandle) socket; { return _fd; }
- (int) protocol; { return _address.protocol; }
- (int) socketType; { return _address.type; }

@end
