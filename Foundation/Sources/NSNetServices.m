//
//  NSNetServices.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Aug 20 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#import "Foundation/Foundation.h"
#import "Foundation/NSNetServices.h"
#import "Foundation/NSStream.h"
#import "Foundation/NSObject.h"
#import "NSPrivate.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>

NSString *NSNetServicesErrorCode=@"NetServicesErrorCode";
NSString *NSNetServicesErrorDomain=@"NetServicesErrorDomain";

struct DNSHeader
{
	unsigned short identifier;
	unsigned short flags;
#define DNS_RESPONSE ((flags>>15)&1)
#define DNS_OPCODE ((flags>>13)&0xf)
#define DNS_AA ((flags>>15)&1)
	// usw.
	unsigned short qdcount;
	unsigned short ancount;
	unsigned short nscount;
	unsigned short arcount;
};

@implementation NSNetService

+ (NSData *) dataFromTXTRecordDictionary:(NSDictionary *) txt;
{
	NSMutableData *d=[NSMutableData dataWithCapacity:512];	// should not become larger!
	NSEnumerator *e=[txt keyEnumerator];
	NSString *key;
	while((key=[e nextObject]))
		{
		const char *k=[key UTF8String];
		unsigned int klen=strlen(k);
		id val=[txt objectForKey:key];
		const char *v;
		unsigned int len;
		unsigned char clen;
		if([val isKindOfClass:[NSData class]])
			v=[val bytes], len=[val length];
		else
			v=[val UTF8String], len=strlen(v);
		clen=klen;
		if(len > 254)
			return nil;	// should we raise exception?
		if(len>0)
			clen+=1+len;
		// check for overflow!
		[d appendBytes:&clen length:1];	// record length
		[d appendBytes:k length:klen];
		if(len > 0)
			{
			[d appendBytes:"=" length:1];
			[d appendBytes:v length:len];
			}
		}
	if([d length] == 0)
		{
		static char null=0;
		[d appendBytes:&null length:1];	// make empty record (key length=0)
		}
	else if([d length] > 512)
		return nil; // became too long
	return d;
}

+ (NSDictionary *) dictionaryFromTXTRecordData:(NSData *) txt;
{
	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:10];
	const unsigned char *bytes=[txt bytes];
	const unsigned char *end=bytes+[txt length];
	while(bytes < end)
		{
		unsigned int len=*bytes++;
		const unsigned char *kp=bytes;	// start of key
		NSString *key;
		NSData *val;
		while(len > 0 && *bytes != '=')
			bytes++, len--;
		key=[[NSString _stringWithUTF8String:(char *) kp length:bytes-kp] lowercaseString];	// key isn't case sensitive
#if 1
		NSLog(@"key=%@ len=%d", key, bytes-kp);
#endif
		if(len > 0 && *bytes == '=')
			{ // with value
			val=[NSData dataWithBytes:++bytes length:--len];	// value starts behind =
			bytes+=len;	// skip all
			}
		else
			{ // no = i.e. a boolean value
			val=[NSData data];	// use empty value but present - should be interpreted as 'true' for a boolean value
			}
		if([key length] > 0 && ![dict objectForKey:key])	// ignore empty and duplicates
			[dict setObject:val forKey:key];	// store
		}
	return dict;
}

- (void) _notifyErrorDomain:(int) domain code:(int) code
{
	if([_delegate respondsToSelector:@selector(netService:didNotResolve:)])
		[_delegate netService:self didNotResolve:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:code], NSNetServicesErrorCode,
			[NSNumber numberWithInt:domain], NSNetServicesErrorDomain,
			nil]];
}

static NSString *parseDomainName(unsigned char *buffer, int len, unsigned int *pos)
{
	int clen;
	NSString *domain=@"";
	while(*pos < len && (clen=buffer[(*pos)++]) > 0)
		{ // get next component
#if 0
		NSLog(@"pos=%d len=%d clen=%d", *pos, len, clen);
#endif
		domain=[domain stringByAppendingFormat:@"%@.", [NSString _stringWithUTF8String:(char *)(buffer+*pos) length:clen]];
		(*pos)+=clen;
		}
	return domain;
}

static unsigned short parseShort(unsigned char *buffer, int len, unsigned int *pos)
{
	unsigned short val=0;
	if(*pos < len-2)
		{
		val=buffer[(*pos)++]<<8;	// Bigendian network order
		val+=buffer[(*pos)++];
		}
	return val;
}

static unsigned long parseLong(unsigned char *buffer, int len, unsigned int *pos)
{
	unsigned long val=0;
	if(*pos < len-4)
		{
		val=buffer[(*pos)++]<<24;	// Bigendian network order
		val+=buffer[(*pos)++]<<16;
		val+=buffer[(*pos)++]<<8;
		val+=buffer[(*pos)++];
		}
	return val;
}

/*
 FIXME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows.
 This might also be some very lage constant for record length which wraps around the 32bit address limit (e.g. a negative record length).
 Ending up in infinite loops blocking the system.
 */

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event;
{
#if 1
	NSLog(@"NSNetService stream:%@ handleEvent:%d", stream, event);
#endif
	if(stream == _inputStream)
		{
		switch(event)
			{
			case NSStreamEventOpenCompleted:
				return;
			case NSStreamEventHasBytesAvailable:
				{
					int len;
					// FIXME: static/malloc? - what is the maximum packet size we expect? 512 or 9000 or 65535?
					unsigned char buffer[512];
					int i;
					unsigned int pos;
#if 0
					NSLog(@"looks like a packet arrived");
#endif
					len=[_inputStream read:buffer maxLength:sizeof(buffer)];
#if 1
					NSLog(@"len=%d data=%@", len, [NSData dataWithBytesNoCopy:buffer length:len freeWhenDone:NO]);
#endif
					if(len < sizeof(struct DNSHeader))
						return;	// ignore
					((struct DNSHeader *)buffer)->identifier=NSSwapBigShortToHost(((struct DNSHeader *)buffer)->identifier);
					((struct DNSHeader *)buffer)->flags=NSSwapBigShortToHost(((struct DNSHeader *)buffer)->flags);
					((struct DNSHeader *)buffer)->qdcount=NSSwapBigShortToHost(((struct DNSHeader *)buffer)->qdcount);
					((struct DNSHeader *)buffer)->ancount=NSSwapBigShortToHost(((struct DNSHeader *)buffer)->ancount);
					((struct DNSHeader *)buffer)->nscount=NSSwapBigShortToHost(((struct DNSHeader *)buffer)->nscount);
					((struct DNSHeader *)buffer)->arcount=NSSwapBigShortToHost(((struct DNSHeader *)buffer)->arcount);
#if 1
					NSLog(@"%d question records", ((struct DNSHeader *)buffer)->qdcount);
#endif
					pos=sizeof(struct DNSHeader);
					for(i=0; i<((struct DNSHeader *)buffer)->qdcount; i++)
						{ // process question records
						NSString *qname;
						unsigned short qtype;
						unsigned short qclass;
						qname=parseDomainName(buffer, len, &pos);
#if 1
						NSLog(@"qname=%@", qname);
#endif
						qtype=parseShort(buffer, len, &pos);
						qclass=parseShort(buffer, len, &pos);
						}
#if 1
					NSLog(@"%d answer records", ((struct DNSHeader *)buffer)->ancount);
#endif
					for(i=0; i<((struct DNSHeader *)buffer)->ancount; i++)
						{ // process response records
						NSString *name;
						unsigned short type;
						unsigned short class;
						unsigned long ttl;
						unsigned short rdlen;
						NSData *record;
						name=parseDomainName(buffer, len, &pos);						
#if 1
						NSLog(@"name=%@", name);
#endif
						type=parseShort(buffer, len, &pos);
						class=parseShort(buffer, len, &pos);
						ttl=parseLong(buffer, len, &pos);
						rdlen=parseShort(buffer, len, &pos);
#if 1
						NSLog(@"type=%d", type);
						NSLog(@"class=%d", class);
						NSLog(@"ttl=%d", ttl);
						NSLog(@"rdlen=%d", rdlen);
#endif
						if(rdlen+pos <= len)
							{
							record=[NSData dataWithBytesNoCopy:(char *)(buffer+pos) length:rdlen freeWhenDone:NO];
							pos+=rdlen;
							}
						else
							record=nil;	// some error
						if(type == 33)
							{
							// process - otherwise ignore
							}
#if 1
						NSLog(@"TXT record=%@", record);
						NSLog(@"dict=%@", [isa dictionaryFromTXTRecordData:record]);
#endif
						}
				// if packet received
				// parse and decode
				// if monitoring: [_delegate netService:self didUpdateTXTRecordData:data];
				// if yes, notify [_delegate netServiceDidResolveAddress:self];
				// [_timer release], _timer=nil;
					return;
				}
			case NSStreamEventEndEncountered:
			case NSStreamEventHasSpaceAvailable:
			case NSStreamEventNone:
			default:
				break;
			}
		}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [stream streamError], event, stream, self);
}

- (NSArray *) addresses; { return _addresses; }
- (id) delegate; { return _delegate; }
- (NSString *) domain; { return _domain; }

- (BOOL) getInputStream:(NSInputStream **) input outputStream:(NSOutputStream **) output;
{
	if([_addresses count] == 0)
		return NO;	// not yet resolved successfully
	// FIXME: get host&port from found service(s)
	[NSStream getStreamsToHost:[NSHost hostWithName:_hostName] port:12345 inputStream:input outputStream:output];
	return *input && *output;
}

- (NSString *) hostName; { return _hostName; }

- (id) initWithDomain:(NSString *) domain type:(NSString *) type name:(NSString *) name;
{ // adaequate to resolve a net service
	return [self initWithDomain:domain type:type name:name port:-1];
}

- (id) initWithDomain:(NSString *) domain type:(NSString *) type name:(NSString *) name port:(int) port;
{ // adaequate to publish a net service
	if((self=[super init]))
		{
		int s;	// the socket
		struct sockaddr_in saddr;	// socket address
		struct ip_mreq mc;			// socket options
		int flag = 1;
		int ittl = 255;
		char ttl = 255;
#if 1
		NSLog(@"%@ initWithDomain:%@ type:%@ name:%@ port:%d", NSStringFromClass(isa), domain, type, name, port);
#endif
		_addresses=[[NSMutableArray alloc] initWithCapacity:10];	// store NSData objects with struct sockaddr
		if([domain length] == 0)
			_domain=@"local.";	// use local domain
		else
			_domain=[domain retain];
		_type=[type retain];
		_name=[name retain];
		_port=port;
		if(port < 0)
			{ // we want to resolve
			saddr.sin_family = AF_INET;
			saddr.sin_port = htons(5353);
			saddr.sin_addr.s_addr = 0;
			}
		else
			{ // we (probably) want to publish a service
			saddr.sin_family = AF_INET;
			saddr.sin_port = htons(5353);
			saddr.sin_addr.s_addr = 0;
			}
		s=socket(saddr.sin_family, SOCK_DGRAM, PF_UNSPEC);
		if(s < 0)
			{
			NSLog(@"NSNetService: could not create multicast socket due to %s", strerror(errno));
			[self release];
			return nil;
			}
#ifdef SO_REUSEPORT
		setsockopt(s, SOL_SOCKET, SO_REUSEPORT, (char*)&flag, sizeof(flag));	// reuse port
#endif
		setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (char*)&flag, sizeof(flag));	// reuse address
		if(bind(s, (struct sockaddr *) &saddr, sizeof(saddr)) != 0)
			{
			close(s); 
			NSLog(@"NSNetService: could not bind multicast socket due to %s", strerror(errno));
			[self release];
			return nil;
			}
		inet_aton("224.0.0.251", &mc.imr_multiaddr);
		mc.imr_interface.s_addr = INADDR_ANY;
		setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mc, sizeof(mc)); 
		setsockopt(s, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl));
		setsockopt(s, IPPROTO_IP, IP_MULTICAST_TTL, &ittl, sizeof(ittl));
		flag =  fcntl(s, F_GETFL, 0);
		flag |= O_NONBLOCK;
		fcntl(s, F_SETFL, flag);
		// shouldn't we check for errors?
		_inputStream=[[NSInputStream alloc] _initWithFileDescriptor:s];
		_outputStream=[[NSOutputStream alloc] _initWithFileDescriptor:s];
		[_inputStream setDelegate:self];	// make us receive packet notifications
		[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_inputStream open];
		[_outputStream open];
		}
	return self;
}

- (void) dealloc;
{
	[self removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[_inputStream close];
//	[_outputStream close];
	[_inputStream release];
	[_outputStream release];
	[_addresses release];
	[_domain release];
	[_type release];
	[_hostName release];
	[_txt release];
	[_timer release];
	[super dealloc];
}

- (NSString *) name; { return _name; }

- (NSInteger) port; { return _port; }

- (NSString *) protocolSpecificInformation;
{ // deprecated
	NIMP;
	return nil;
}

- (void) publish;
{
	[self publishWithOptions:0];
}

- (void) publishWithOptions:(NSNetServiceOptions) opts;
{
	if(_timer)
		return;	// should raise exception because we are resolving
	if(_isPublishing)
		return;	// already
	if(_port < 0)
		return;	// initialized for resolving
	[_delegate netServiceWillPublish:self];
	// send publish record
	// handle timers (?)
}

- (void) removeFromRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
{
	[_inputStream removeFromRunLoop:loop forMode:mode];
}

- (void) resolve;
{ // deprecated!
	[self resolveWithTimeout:5.0];
}

- (void) _resolveTimedOut:(NSTimer *) timer;
{
	[_timer release];
	_timer=nil;
	[self _notifyErrorDomain:0 code:NSNetServicesTimeoutError];
}

- (void) resolveWithTimeout:(NSTimeInterval) interval;
{
#if 1
	NSLog(@"NSNetService -resolveWithTimeout:%.0lf", interval);
#endif
	if(_isPublishing)
		return;	// raise exception
	if(_timer)
		return;	// already resolving
	if(_port > 0)
		return;	// initialized for publishing
	_timer=[[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(_resolveTimedOut:) userInfo:nil repeats:NO] retain];
	[_delegate netServiceWillResolve:self];
	// send resolve request
}

- (void) scheduleInRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
{
#if 1
	NSLog(@"schedule %@ in %@", _inputStream, mode);
#endif
	[_inputStream scheduleInRunLoop:loop forMode:mode];
}

- (void) setDelegate:(id) obj;
{
	_delegate=obj;
}

- (void) setProtocolSpecificInformation:(NSString *) info;
{
	// deprecated
	NIMP;
}

- (BOOL) setTXTRecordData:(NSData *) txt;
{
	// check for valid data
	ASSIGN(_txt, txt);
	return YES;
}

- (void) startMonitoring;
{
#if 1
	NSLog(@"NSNetService -startMonitoring");
#endif
	_isMonitoring=YES;
}

- (void) stop;
{
	_isPublishing=NO;
	if(_timer)
		{
		[_timer release];
		_timer=nil;
		[self _notifyErrorDomain:0 code:NSNetServicesCancelledError];
		}
	[_delegate netServiceDidStop:self];
}

- (void) stopMonitoring;
{
	_isMonitoring=NO;
}

- (NSString *) type; { return _type; }

- (NSData *) TXTRecordData; { return _txt; }

@end

@implementation NSNetServiceBrowser

- (void) netService:(NSNetService *) sender didNotPublish:(NSDictionary *) error; {} // ignore since we never publish
- (void) netServiceDidPublish:(NSNetService *) sender; {} // ignore since we never publish
- (void) netServiceWillPublish:(NSNetService *) sender; {} // ignore since we never publish

- (void) netService:(NSNetService *) sender didNotResolve:(NSDictionary *) error;
{
}

- (void) netServiceDidResolveAddress:(NSNetService *) sender;
{
	//
}

- (void) netServiceDidStop:(NSNetService *) sender;
{
	return;	// ignore
}

- (void) netService:(NSNetService *) sender didUpdateTXTRecordData:(NSData *) txt;
{
}

- (void) netServiceWillResolve:(NSNetService *) sender;
{
#if 1
	NSLog(@"netServiceWillResolve:%@", sender);
#endif
	[_delegate netServiceBrowserWillSearch:self];	
}

- (id) delegate; { return _delegate; }

- (id) init;
{
	if((self=[super init]))
		{
#if 1
		NSLog(@"%@ %@", NSStringFromClass(isa), NSStringFromSelector(_cmd));
#endif
		}
	return self;
}

- (void) dealloc;
{
	[self stop];
	[super dealloc];
}

- (void) removeFromRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
{
	NIMP;
}

- (void) scheduleInRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
{
	NIMP;
}

- (void) searchForBrowsableDomains;
{
	[self searchForServicesOfType:@"browseable" inDomain:@""];
}

- (void) searchForRegistrationDomains;
{
	[self searchForServicesOfType:@"registration" inDomain:@""];
}

- (void) searchForServicesOfType:(NSString *) type inDomain:(NSString *) domain;
{
#if 1
	NSLog(@"NSNetService -searchForServicesOfType:%@ inDomain:%@", type, domain);
#endif
	_netService=[[NSNetService alloc] initWithDomain:domain type:type name:@"?"];
	[_netService setDelegate:self];	// make us receive notifications
	[_netService startMonitoring];	// FIXME: do we need that?
	[_netService resolveWithTimeout:30.0];
}

- (void) setDelegate:(id) obj;
{
	_delegate=obj;
}

- (void) stop;
{
	if(_netService)
		{
		[_netService stop];
		[_netService release];
		_netService=nil;
		}
	[_delegate netServiceBrowserDidStopSearch:self];	
}

@end
