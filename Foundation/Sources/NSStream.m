//
//  NSStream.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 14 2005.
//  Copyright (c) 2005 DSITRI.
//  
//  libOpenSSL integration taken partially from GNUstep-Base
//  refer to http://www.openssl.org/docs/ssl/ssl.html for SSL API
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <Foundation/Foundation.h>

#import "NSPrivate.h"

#include <signal.h>

NSString *NSStreamDataWrittenToMemoryStreamKey=@"NSStreamDataWrittenToMemoryStreamKey";
NSString *NSStreamFileCurrentOffsetKey=@"NSStreamFileCurrentOffsetKey";
NSString *NSStreamSocketSecurityLevelKey=@"NSStreamSocketSecurityLevelKey";
NSString *NSStreamSOCKSProxyConfigurationKey=@"NSStreamSOCKSProxyConfigurationKey";

NSString *NSStreamSocketSecurityLevelNone=@"NSStreamSocketSecurityLevelNone";
NSString *NSStreamSocketSecurityLevelSSLv2=@"NSStreamSocketSecurityLevelSSLv2";
NSString *NSStreamSocketSecurityLevelSSLv3=@"NSStreamSocketSecurityLevelSSLv3";
NSString *NSStreamSocketSecurityLevelTLSv1=@"NSStreamSocketSecurityLevelTLSv1";
NSString *NSStreamSocketSecurityLevelNegotiatedSSL=@"NSStreamSocketSecurityLevelNegotiatedSSL";

NSString *NSStreamSocketSSLErrorDomain=@"NSStreamSocketSSLErrorDomain";
NSString *NSStreamSOCKSErrorDomain=@"NSStreamSOCKSErrorDomain";

NSString *NSStreamSOCKSProxyHostKey=@"NSStreamSOCKSProxyHostKey";
NSString *NSStreamSOCKSProxyPortKey=@"NSStreamSOCKSProxyPortKey";
NSString *NSStreamSOCKSProxyVersionKey=@"NSStreamSOCKSProxyVersionKey";
NSString *NSStreamSOCKSProxyUserKey=@"NSStreamSOCKSProxyUserKey";
NSString *NSStreamSOCKSProxyPasswordKey=@"NSStreamSOCKSProxyPasswordKey";

NSString *NSStreamSOCKSProxyVersion4=@"NSStreamSOCKSProxyVersion4";
NSString *NSStreamSOCKSProxyVersion5=@"NSStreamSOCKSProxyVersion5";

// class cluster internal classes

@implementation NSStream

+ (void) getStreamsToHost:(NSHost *) host
					 port:(NSInteger) port
			  inputStream:(NSInputStream **) inp 
			 outputStream:(NSOutputStream **) outp;
{
	int s=socket(AF_INET, SOCK_STREAM, PF_UNSPEC);
	if(s < 0)
		{
#if 0
		NSLog(@"stream creation error:%s", strerror(errno));
#endif
		*inp=nil;
		*outp=nil;
		return;	// ignore
		}
	*inp=[[[_NSSocketInputStream alloc] _initWithFileDescriptor:dup(s)] autorelease];	// provide two independent file descriptors so that we can close() separately
	*outp=[[[_NSSocketOutputStream alloc] _initWithFileDescriptor:s] autorelease];
	((_NSSocketInputStream *) *inp)->_output=((_NSSocketOutputStream *) *outp);		// establish cross-link
	[((_NSSocketOutputStream *) *outp) _setHost:host andPort:port];	// set host and port
#if 1
	NSLog(@"inp=%@", *inp);
	NSLog(@"outp=%@", *outp);
#endif
}

- (id) init;
{
	if((self=[super init]))
		{
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"NSStream dealloc %@", self);
#endif
	if(_streamStatus != NSStreamStatusClosed)
		[self close];	// if not yet...
	// [_delegate release];
	[super dealloc];
}

- (id) delegate { return _delegate; }
- (void) setDelegate:(id) delegate { _delegate=delegate; }

- (void) close
{
	_streamStatus=NSStreamStatusClosed;
}

- (void) open
{
	if(_streamStatus != NSStreamStatusNotOpen)
		{
		[self _setStreamErrorWithDomain:@"already open" code:0];
		return;
		}
	_streamStatus=NSStreamStatusOpening;	// until we really handle the event in the runloop
}

- (id) propertyForKey:(NSString *) key { return SUBCLASS; }
- (BOOL) setProperty:(id) property forKey:(NSString *) key { SUBCLASS; return NO; }

- (NSError *) streamError { return _streamError; }

- (void) _setStreamError:(NSError *) err;
{
	_streamStatus=NSStreamStatusError;
	ASSIGN(_streamError, err);
}

// deprecate?

- (void) _setStreamErrorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *) dict;
{
	[self _setStreamError:[NSError errorWithDomain:domain code:code userInfo:dict]];
}

- (void) _setStreamErrorWithDomain:(NSString *)domain code:(NSInteger)code;
{
	[self _setStreamError:[NSError errorWithDomain:domain code:code userInfo:nil]];
}

- (NSStreamStatus) streamStatus { return _streamStatus; }

// this should be the only interaction with internals of NSRunLoop!

- (void) removeFromRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode { SUBCLASS; }

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode { SUBCLASS; }

// default implementation

- (int) _readFileDescriptor; { return -1; }
- (int) _writeFileDescriptor; { return -1; }

@end

@implementation NSInputStream

+ (id) inputStreamWithFileAtPath:(NSString *) path; { return [[[self alloc] initWithFileAtPath:path] autorelease]; }
+ (id) inputStreamWithData:(NSData *) data; { return [[[self alloc] initWithData:data] autorelease]; }

- (id) _initWithFileDescriptor:(int) fd;
{
#if 0
	NSLog(@"%@ _initWithFileDescriptor:%d", NSStringFromClass([self class]), fd);
#endif
	if(fd < 0)
		{
		[self release];
		return nil;
		}
	if((self=[super init]))
		{
		_fd=fd;
		}
	return self;
}

- (int) _readFileDescriptor; { return _streamStatus == NSStreamStatusAtEnd?-1:_fd; }	// don't schedule after EOF detected

- (id) initWithFileAtPath:(NSString *) path
{
	return [self _initWithFileDescriptor:open([path fileSystemRepresentation], O_RDONLY)];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@(%p) fd=%d status=%d", NSStringFromClass([self class]), self, _fd, _streamStatus];
}

- (id) initWithData:(NSData *) data
{
	[self release];
	return [[_NSMemoryInputStream alloc] initWithData:data];
}

- (void) close;
{
	if(_streamStatus != NSStreamStatusNotOpen && _streamStatus != NSStreamStatusClosed)
		{
		// FIXME: how can we be removed from ALL runloops?
		// _removeWatcher should be a class method of NSRunLoop!
		[[NSRunLoop currentRunLoop] _removeWatcher:self];
#if 0
		NSLog(@"close(%d) %@", _fd, self);
#endif
		close(_fd);
		_fd=-1;
		}
	[super close];
}

- (BOOL) hasBytesAvailable;
{ // how do we check for empty files or pipes? special call to select()? should we read some bytes in advance?
	return _streamStatus != NSStreamStatusAtEnd;
}

- (BOOL) getBuffer:(unsigned char **) buffer length:(NSUInteger *) len;
{
	return NO;
}

- (NSInteger) read:(unsigned char *) buffer maxLength:(NSUInteger) len;
{
	NSInteger n;
	int oldStatus=_streamStatus;
#if 0
	NSLog(@"read:maxLength:");
#endif
	_streamStatus=NSStreamStatusReading;
	n=read(_fd, buffer, len);
	if(n < 0)
		{
#if 0
		NSLog(@"read:maxLength: error %d %s", errno, strerror(errno));
#endif
		if(errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR)
			{
			_streamStatus=oldStatus;
			return 0;	// did fall through in non-blocking mode or was interrupted by signal
			}
		[self _setStreamErrorWithDomain:@"read error" code:errno];
		return n;	// error
		}
	if(n == 0)
		_streamStatus=NSStreamStatusAtEnd;
	else
		_streamStatus=oldStatus;
	return n;
}

- (id) propertyForKey:(NSString *) key
{
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		return [NSNumber numberWithUnsignedLong:lseek(_fd, 0l, SEEK_CUR)];
	return nil;
}

- (BOOL) setProperty:(id) property forKey:(NSString *) key
{
	// do we allow to fseek?
	return NO;
}

- (void) removeFromRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode
{
	[aRunLoop _removeInputWatcher:self forMode:mode];	// read watcher
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode
{
	[aRunLoop _addInputWatcher:self forMode:mode];	// read watcher
}

- (void) _readFileDescriptorReady
{ //called from NSRunLoop if we are scheduled and there is something to read
#if 0
	NSLog(@"_readFileDescriptorReady: status=%d", _streamStatus);
#endif
	if(_streamStatus == NSStreamStatusOpening)
		{
		_streamStatus=NSStreamStatusOpen;
		[_delegate stream:self handleEvent:NSStreamEventOpenCompleted];
		}
	else if(_streamStatus == NSStreamStatusError)
		[_delegate stream:self handleEvent:NSStreamEventErrorOccurred];
	else if(_streamStatus == NSStreamStatusAtEnd)
		// FIXME: should this be done exactly once?
		[_delegate stream:self handleEvent:NSStreamEventEndEncountered];
	else
		[_delegate stream:self handleEvent:NSStreamEventHasBytesAvailable];
}

@end

@implementation _NSSocketInputStream

- (id) propertyForKey:(NSString *) key
{
	return [_output propertyForKey:key];
}

- (BOOL) setProperty:(id) property forKey:(NSString *) key
{
	return [_output setProperty:property forKey:key];
}

/*
 - (void) open
 {
 #if 1
 NSLog(@"open %@", self);
 #endif
 if(_streamStatus != NSStreamStatusNotOpen)
 {
 [self _setStreamErrorWithDomain:@"already open" code:0];
 return;
 }
 //	_streamStatus=NSStreamStatusOpening;
 // listen(destination, 128);
 [super open];
 }
 
 - (void) close;
 {
 [super close];
 }
 */

- (NSInteger) read:(unsigned char *) buffer maxLength:(NSUInteger) len;
{
	NSInteger n;
	if(_output->ssl)
		{
		int oldStatus=_streamStatus;
#if 1
		NSLog(@"ssl read:maxLength:");
#endif
		_streamStatus=NSStreamStatusReading;
		n=SSL_read(_output->ssl, buffer, len);
		if(n < 0)
			{
			_streamStatus=NSStreamStatusError;
			return n;	// error
			}
		if(n == 0)
			_streamStatus=NSStreamStatusAtEnd;
		else
			_streamStatus=oldStatus;
		return n;
		}
	return [super read:buffer maxLength:len];
}

@end

@implementation _NSMemoryInputStream

- (id) initWithData:(NSData *) data
{
	if((self=[super init]))
		{
		if([data isKindOfClass:[NSMutableData class]])
			data=[[data copy] autorelease];
		_data=[data retain];	// protect from being deallocated
		_buffer=[data bytes];	// shouldn't we copy???
		_capacity=[data length];
		_fd=-1;
		}
	return self;
}

- (void) dealloc
{
	[_data release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@(%p) buffer=%p[%d:%d]", NSStringFromClass([self class]), self, _buffer, _position, _capacity];
}

- (BOOL) hasBytesAvailable; { return _position < _capacity; }

- (BOOL) getBuffer:(unsigned char **) buffer length:(NSUInteger *) len;
{
	*buffer=(unsigned char *) (_buffer+_position);
	*len=_capacity-_position;
	return YES;
}

- (NSInteger) read:(unsigned char *) buffer maxLength:(NSUInteger) len;
{
	NSInteger remain=_capacity-_position;
	if(remain == 0)
		_streamStatus=NSStreamStatusAtEnd;
	if(len > remain)
		len=remain;	// limit
	memcpy(buffer, _buffer+_position, len);
	_position+=len;
	return len;
}

- (id) propertyForKey:(NSString *) key
{
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		return [NSNumber numberWithUnsignedLong:_position];
	return nil;
}

- (BOOL) setProperty:(id) property forKey:(NSString *) key
{
	if(!property) return NO;
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		{
		int pos=[property unsignedLongValue];
		if(pos > _capacity)
			return NO;
		_position=pos;
		return YES;
		}
	return NO;
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode { NIMP; }

@end

@implementation NSOutputStream

+ (void) initialize;
{  
	if(self == [NSStream class])
		{
		signal(SIGPIPE, SIG_IGN);	// If SIGPIPE is not ignored, we will abort on any attempt to write to a pipe/socket that has been closed by the other end!
		signal(SIGSTOP, SIG_IGN);	// some devices might send a SIGSTOP if they become inactive
		}
}

+ (id) outputStreamToBuffer:(unsigned char *) buffer capacity:(NSUInteger) len;
{
	return [[[self alloc] initToBuffer:buffer capacity:len] autorelease];
}

+ (id) outputStreamToFileAtPath:(NSString *) path append:(BOOL) flag;
{
	return [[[self alloc] initToFileAtPath:path append:flag] autorelease];
}

+ (id) outputStreamToMemory;
{
	return [[[self alloc] initToMemory] autorelease];
}

- (id) _initWithFileDescriptor:(int) fd;
{
	return [self _initWithFileDescriptor:fd append:NO];
}

- (id) _initWithFileDescriptor:(int) fd append:(BOOL) flag;
{
#if 0
	NSLog(@"%@ _initWithFileDescriptor:%d", NSStringFromClass([self class]), fd);
#endif
	if(fd < 0)
		{
		[self release];
		return nil;
		}
	if((self=[super init]))
		{
		_fd=fd;
		if(flag)
			lseek(fd, 0l, SEEK_END);	// seek to EOF
		}
	return self;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@(%p) fd=%d status=%d", NSStringFromClass([self class]), self, _fd, _streamStatus];
}

- (int) _writeFileDescriptor; { NSLog(@"writefd=%d", _fd); return _fd; }

- (id) initToFileAtPath:(NSString *) path append:(BOOL) flag
{
	return [self _initWithFileDescriptor:open([path fileSystemRepresentation], (O_WRONLY|O_CREAT|(flag?O_APPEND:O_TRUNC)), 0755) append:flag];
}

- (id) initToMemory;
{
	[self release];
	return [[_NSMemoryOutputStream alloc] initToMemory];
}

- (id) initToBuffer:(unsigned char *) buffer capacity:(NSUInteger) len;
{
	[self release];
	return [[_NSBufferOutputStream alloc] initToBuffer:buffer capacity:len];
}

- (void) close;
{
	if(_streamStatus != NSStreamStatusNotOpen && _streamStatus != NSStreamStatusClosed)
		{
		// FIXME: how can we be removed from ALL runloops?
		[[NSRunLoop currentRunLoop] _removeWatcher:self];
#if 0
		NSLog(@"close(%d) %@", _fd, self);
#endif
		close(_fd);
		_fd=-1;
		}
	[super close];
}

- (BOOL) hasSpaceAvailable; { return _streamStatus != NSStreamStatusAtEnd; }

- (NSInteger) write:(const unsigned char *) buffer maxLength:(NSUInteger) len;
{
	NSInteger n;
	int oldStatus=_streamStatus;
#if 0
	NSLog(@"write:maxLength:");
#endif
	_streamStatus=NSStreamStatusWriting;
	n=write(_fd, buffer, len);
	if(n < 0)
		{
#if 1
		NSLog(@"write error %s", strerror(errno));
#endif
		_streamStatus=NSStreamStatusError;
		return n;	// error
		}
	_streamStatus=oldStatus;
	return n;
}

- (void) removeFromRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode
{
	[aRunLoop _removeOutputWatcher:self forMode:mode];	// write watcher
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode
{
	[aRunLoop _addOutputWatcher:self forMode:mode];	// write watcher
}

- (void) _writeFileDescriptorReady
{ //called from NSRunLoop if we are scheduled and can can write
#if 0
	NSLog(@"_writeFileDescriptorReady: status=%d", _streamStatus);
#endif
	if(_streamStatus == NSStreamStatusOpening)
		{
		_streamStatus=NSStreamStatusOpen;
		[_delegate stream:self handleEvent:NSStreamEventOpenCompleted];
		}
	else if(_streamStatus == NSStreamStatusError)
		[_delegate stream:self handleEvent:NSStreamEventErrorOccurred];
	else
		[_delegate stream:self handleEvent:NSStreamEventHasSpaceAvailable];
}

- (id) propertyForKey:(NSString *) key
{
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		return [NSNumber numberWithUnsignedLong:lseek(_fd, 0l, SEEK_CUR)];
	return nil;
}

- (BOOL) setProperty:(id) property forKey:(NSString *) key
{
	if(!property) return NO;
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		return lseek(_fd, [property unsignedLongValue], SEEK_SET) >= 0;
	return NO;
}

@end

@implementation _NSBufferOutputStream

- (id) initToBuffer:(unsigned char *) buffer capacity:(NSUInteger) len;
{
	if((self=[super init]))
		{
		_buffer=buffer;
		_capacity=len;
		_fd=-1;
		}
	return self;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@(%p) buffer=%p[%d:%d]", NSStringFromClass([self class]), self, _buffer, _position, _capacity];
}

- (BOOL) hasSpaceAvailable; { return _position < _capacity; }

- (NSInteger) write:(const unsigned char *) buffer maxLength:(NSUInteger) len;
{
	NSInteger room=_capacity-_position;
	if(room == 0)
		_streamStatus=NSStreamStatusAtEnd;
	if(room > len)
		room=len;	// limit to request
	memcpy(_buffer+_position, buffer, room);
	_position+=room;
	return room;
}

- (id) propertyForKey:(NSString *) key
{
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		return [NSNumber numberWithUnsignedLong:_position];
	if([key isEqualToString:NSStreamDataWrittenToMemoryStreamKey])
		return [NSData dataWithBytes:_buffer length:_position];
	return nil;
}

- (BOOL) setProperty:(id) property forKey:(NSString *) key
{
	if(!property) return NO;
	if([key isEqualToString:NSStreamFileCurrentOffsetKey])
		{
		int pos=[property unsignedLongValue];
		if(pos > _capacity)
			return NO;
		_position=pos;
		if(pos > _capacity)
			; // must we expand here to fill with 0 if someone wants to look at NSStreamDataWrittenToMemoryStreamKey?
		return YES;
		}
	return NO;
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode { NIMP; }

@end

@implementation _NSMemoryOutputStream

- (id) initToMemory;
{
	return [self initToBuffer:NULL capacity:0];
}

- (void) dealloc
{
	if(_buffer)
		objc_free(_buffer);
	[super dealloc];
}

- (BOOL) hasSpaceAvailable; { return YES; }	// grows as long as we can get memory...

- (NSInteger) write:(const unsigned char *) buffer maxLength:(NSUInteger) len;
{
	if(_position + len > _capacity)
		_buffer=objc_realloc(_buffer, _capacity=2*_capacity+len);	// enlarge buffer
	return [super write:buffer maxLength:len];
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode { NIMP; }

@end

@implementation _NSSocketOutputStream

- (id) propertyForKey:(NSString *) key
{
	if([key isEqualToString:NSStreamSocketSecurityLevelKey])
		return _securityLevel;
	if([key isEqualToString:NSStreamSOCKSProxyConfigurationKey])
		return @"?";
	return [super propertyForKey:key];
}

- (BOOL) setProperty:(id) property forKey:(NSString *) key
{
	if([key isEqualToString:NSStreamSocketSecurityLevelKey])
		{
		ASSIGN(_securityLevel, property);
		return YES;
		}
	if([key isEqualToString:NSStreamSOCKSProxyConfigurationKey])
		return NO;
	return [super setProperty:property forKey:key];
}

- (void) _setHost:(NSHost *) host andPort:(int) port;	// called from getStreamsToHost:port:
{
	_host=[host retain];
	_port=port;
}

- (void) dealloc
{
	[_host release];
	[super dealloc];	// will also close
}

- (void) open
{
	static BOOL sslInitialized=NO;
	struct sockaddr_in _addr;
	socklen_t addrlen=sizeof(_addr);
#if 0
	NSLog(@"open %@", self);
#endif
	if(_streamStatus != NSStreamStatusNotOpen)
		{
#if 0
		NSLog(@"status %lu for %@", (unsigned long)_streamStatus, self);
#endif
		[self _setStreamErrorWithDomain:@"already open" code:0];
		return;
		}
#if 0
	NSLog(@"open NSSocketOutputStream to %@:%u", _host, _port);
#endif
	if(!_host)
		{
		[self _setStreamErrorWithDomain:@"nil host for stream socket open" code:0];
		return;
		}
	[super open];
	_addr.sin_family=AF_INET;
	inet_aton([[_host address] cString], &_addr.sin_addr);
	_addr.sin_port=htons(_port);
	fcntl(_fd, F_SETFL, O_NONBLOCK);	// don't block and run connect() in the background
	if(connect(_fd, (struct sockaddr *) &_addr, addrlen) < 0 && errno != EINPROGRESS)
		{
		NSLog(@"connect error %s", strerror(errno));
		[self _setStreamErrorWithDomain:@"can't connect socket" code:0];
		return;
		}
	fcntl(_fd, F_SETFL, O_ASYNC);	// block during normal operation - but not while waiting for connection
	// we should set up a timeout here (? or should that be done by the delegate?)
	if(_securityLevel && ![_securityLevel isEqualToString:NSStreamSocketSecurityLevelNone])
		{
		const SSL_METHOD *method;
		// lock
		if(!sslInitialized)
			{ // initialize ssl library
				SSL_library_init();
				if (![[NSFileManager defaultManager] fileExistsAtPath: @"/dev/urandom"])
					{ // If there is no /dev/urandom for ssl to use, we must seed the random number generator ourselves.
						const char	*seed = [[[NSProcessInfo processInfo] globallyUniqueString] UTF8String];
						RAND_seed(seed, strlen(seed));
					}
				sslInitialized=YES;
			}
		// unlock
		if(NO);	// hack to allow to start over with else if()
#ifndef __APPLE__
		else if([_securityLevel isEqualToString:NSStreamSocketSecurityLevelSSLv2])
			method=SSLv2_client_method();
		else if([_securityLevel isEqualToString:NSStreamSocketSecurityLevelSSLv3])
			method=SSLv3_client_method();
#endif
		else if([_securityLevel isEqualToString:NSStreamSocketSecurityLevelTLSv1])
			method=TLSv1_client_method();
		else if([_securityLevel isEqualToString:NSStreamSocketSecurityLevelNegotiatedSSL])
			method=SSLv23_client_method();
		else
			{
			NSLog(@"unimplemented security level %@", _securityLevel);
			return;	// error
			}
		ctx = SSL_CTX_new(method);
		ssl = SSL_new(ctx);
		if(SSL_set_fd(ssl, _fd))
			{ // error
				[self _setStreamErrorWithDomain:NSStreamSocketSSLErrorDomain code:0];
			}
		if(SSL_connect(ssl))
			{ // error
				[self _setStreamErrorWithDomain:NSStreamSocketSSLErrorDomain code:0];
			}
		}
}

- (void) close;
{
	if(_streamStatus != NSStreamStatusClosed)
		{
		if(ssl)
			{
			SSL_shutdown(ssl);
			SSL_clear(ssl);	// really required if we free?
			SSL_free(ssl);
			ssl = NULL;
			}
		if(ctx)
			{
			SSL_CTX_free(ctx);
			ctx = NULL;
			}
		}
	[super close];
}

- (void) _writeFileDescriptorReady
{
	if(_streamStatus == NSStreamStatusOpening)
		{ // connect is successfull
			// cancel timeout
			// FIXME: handle ssl connection setup
		}
	[super _writeFileDescriptorReady];
}

- (NSInteger) write:(const unsigned char *) buffer maxLength:(NSUInteger) len;
{
	if(ssl)
		{
		NSInteger n;
		// FIXME handle status writing etc.
		n=SSL_write(ssl, buffer, len);	// SSL
		if(n == 0)
			;
		if(n < 0)
			;
		return n;
		}
	return [super write:buffer maxLength:len];
}

@end
