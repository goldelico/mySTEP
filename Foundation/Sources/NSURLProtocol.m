//
//  NSURLProtocol.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSURLProtocol.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import "NSPrivate.h"

@interface _NSHTTPURLProtocol : NSURLProtocol
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
	NSMutableDictionary *_headers;		// received headers
	NSEnumerator *_headerEnumerator;	// enumerates headers while sending
	NSInputStream *_body;				// for sending the body
	unsigned char *_receiveBuf;			// buffer while receiving header fragments
	unsigned int _receiveBufLength;		// how much is really used in the current buffer
	unsigned int _receiveBufCapacity;	// how much is allocated
	unsigned _statusCode;
	BOOL _readingBody;
}

@end

@interface _NSHTTPSURLProtocol : _NSHTTPURLProtocol
@end

@interface _NSFTPURLProtocol : NSURLProtocol
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}

@end

@interface _NSFileURLProtocol : NSURLProtocol
{
}

@end

@interface _NSAboutURLProtocol : NSURLProtocol
{
}

@end

@interface _NSDataURLProtocol : NSURLProtocol
{
}

@end

static NSMutableArray *_registeredClasses;

@implementation NSURLProtocol

+ (void) initialize;
{
	_registeredClasses=[[NSMutableArray alloc] initWithCapacity:10];
	[self registerClass:[_NSHTTPURLProtocol class]];
	[self registerClass:[_NSHTTPSURLProtocol class]];
	[self registerClass:[_NSFTPURLProtocol class]];
	[self registerClass:[_NSFileURLProtocol class]];
	[self registerClass:[_NSAboutURLProtocol class]];
	[self registerClass:[_NSDataURLProtocol class]];
}

+ (BOOL) canInitWithRequest:(NSURLRequest *) request; { SUBCLASS; return NO; }
+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { SUBCLASS; return nil; }
+ (id) propertyForKey:(NSString *) key inRequest:(NSURLRequest *) request; { SUBCLASS; return nil; }
+ (void) setProperty:(id) value forKey:(NSString *) key inRequest:(NSMutableURLRequest *) request; { SUBCLASS; }

+ (BOOL) registerClass:(Class) protocolClass;
{
	if(![protocolClass isSubclassOfClass:[NSURLProtocol class]])
		return NO;
	[_registeredClasses addObject:protocolClass];	// find most recent version first
	return YES;
}

+ (BOOL) requestIsCacheEquivalent:(NSURLRequest *) a toRequest:(NSURLRequest *) b;
{
	// ???
	// return [[a URL] isEqual:[b URL]]; ???
	a=[self canonicalRequestForRequest:a];
	b=[self canonicalRequestForRequest:b];
	return [a isEqual:b];
}

+ (void) unregisterClass:(Class) protocolClass;
{
	[_registeredClasses removeObject:protocolClass];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ %@", NSStringFromClass(isa), _request];
}

- (NSCachedURLResponse *) cachedResponse; { return _cachedResponse; }
- (id <NSURLProtocolClient>) client; { return _client; }
- (NSURLRequest *) request; { return _request; }

- (id) initWithRequest:(NSURLRequest *) request
		cachedResponse:(NSCachedURLResponse *) cachedResponse
				client:(id <NSURLProtocolClient>) client;
{
	NSEnumerator *e=[_registeredClasses reverseObjectEnumerator];	// go through classes starting with last one first
	Class c;
#if 0
	NSLog(@"%@ initWithRequest:%@ client:%@", NSStringFromClass(isa), request, client);
#endif
	if(isa == [NSURLProtocol class])
		{ // not a subclass
		[self release];
		while((c=[e nextObject]))
			{
#if 0
			NSLog(@"check %@", NSStringFromClass(c));
#endif
			if([c canInitWithRequest:request])
				{ // found!
				return [[c alloc] initWithRequest:request cachedResponse:nil client:client];
				}
			}
		return nil;
		}
	if((self=[super init]))
		{
		_request=[request copy];	// save a copy of the request
		_cachedResponse=[cachedResponse retain];
		_client=client;
		}
#if 0
	NSLog(@"  -> %@", self);
#endif
	return self;
}

- (void) dealloc;
{
	if(isa != [NSURLProtocol class])
		{ // has been initialized
		[self stopLoading];
		[_request release];
		[_cachedResponse release];
		//	[(NSObject *) _client release];
		}
	[super dealloc];
}

- (void) startLoading; { SUBCLASS; }
- (void) stopLoading; { SUBCLASS; }

@end

/*
- (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
- (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
- (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
- (void) URLProtocol:(NSURLProtocol *) proto wasRedirectedToRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;
	*/

@implementation _NSHTTPURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"http"];
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) _didInitializeOutputStream:(NSOutputStream *) stream; { return; }	// default

- (void) dealloc;
{
	[_headers release];			// received headers
	[_body release];			// for sending the body
	[super dealloc];
}

- (void) _schedule;
{
	[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
							forMode:NSDefaultRunLoopMode];
	[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
							 forMode:NSDefaultRunLoopMode];
}

- (void) startLoading;
{
	static NSDictionary *methods;
	if(!methods)
		{ // initialize
		methods=[[NSDictionary alloc] initWithObjectsAndKeys:
			self, @"HEAD",
			self, @"GET",
			self, @"POST",
			self, @"PUT",
			self, @"DELETE",
			self, @"TRACE",
			self, @"OPTIONS",
			self, @"CONNECT",
			nil];
		}
	if(![methods objectForKey:[_request HTTPMethod]])
		{ // unknown method
		NSLog(@"Invalid HTTP Method: %@", _request);
		[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"Invalid HTTP Method" code:0 userInfo:nil]];
		return;
		}
#if 0
	NSLog(@"startLoading: %@", self);
#endif
	if(0 && _cachedResponse)
		{ // handle from cache
		}
	else
		{
		NSURL *url=[_request URL];
		NSHost *host=[NSHost hostWithName:[url host]];		// try to resolve
		int port=[[url port] intValue];
		if(!host) host=[NSHost hostWithAddress:[url host]];	// try dotted notation
		if(!host) host=[NSHost hostWithAddress:@"127.0.0.1"];	// final default
		if(!port) port=[[url scheme] isEqualToString:@"https"]?433:80;	// default if not specified
		[NSStream getStreamsToHost:host
							  port:port
					   inputStream:&_inputStream
					  outputStream:&_outputStream];
		if(!_inputStream || !_outputStream)
			{ // error
#if 1
			NSLog(@"did not create streams for %@:%u", host, [[url port] intValue]);
#endif
			[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"can't connect" code:0 userInfo:
				[NSDictionary dictionaryWithObjectsAndKeys:
					url, @"NSErrorFailingURLKey",
					host, @"NSErrorFailingURLStringKey",
					@"can't find host", @"NSLocalizedDescription",
					nil]]];
			return;
			}
#if 0
		NSLog(@"did initialize streams for %@", self);
#endif
		[self _didInitializeOutputStream:_outputStream];	// a chance to update the stream properties
		[_inputStream retain];
		[_outputStream retain];
		[_inputStream setDelegate:self];
		[_outputStream setDelegate:self];
		[self _schedule];
#if 0
		NSLog(@"open streams for %@", self);
#endif
		[_inputStream open];
		[_outputStream open];
		}
}

- (void) _unschedule;
{
	[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
							forMode:NSDefaultRunLoopMode];
	[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
							 forMode:NSDefaultRunLoopMode];
}

- (void) stopLoading;
{
#if 1
	NSLog(@"stopLoading: %@", self);
#endif
	if(_inputStream)
		{ // is running
		[self _unschedule];
		[_inputStream close];
		[_outputStream close];
		[_inputStream release];
		[_outputStream release];
		_inputStream=nil;
		_outputStream=nil;
#if 0
		// CHECKME - or does this come if the other side rejects the request?
		[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"cancelled" code:0 userInfo:
			[NSDictionary dictionaryWithObjectsAndKeys:
				url, @"NSErrorFailingURLKey",
				host, @"NSErrorFailingURLStringKey",
				@"cancelled", @"NSLocalizedDescription",
				nil]]];
#endif
		}
}

- (BOOL) _processHeaderLine:(unsigned char *) buffer length:(int) len;
{ // process header line
	unsigned char *c, *end;
	NSString *key, *val;
#if 0
	NSLog(@"process header line len=%d", len);
#endif
	// if it begins with ' ' or '\t' it is a continuation line to the previous header field
	if(!_headers)
		{ // should be/must be the header line
		unsigned major, minor;
		if(sscanf((char *) buffer, "HTTP/%u.%u %u", &major, &minor, &_statusCode) == 3)
			{ // response header line
			if(major != 1 || minor > 1)
				[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"Bad HTTP version" code:0 userInfo:nil]];
			// must be first - but must also be present and valid before we go to receive the body!
			_headers=[[NSMutableDictionary alloc] initWithCapacity:10];	// start collecting headers
	//		if(_statusCode >= 400 && _statusCode <= 499)
#if 1
				NSLog(@"Client header: %.*s", len, buffer);
#endif
			return NO;	// process next line
			}
		else
			; // invalid header
		return NO;	// process next line
		}
	if(len == 0)
		{ // empty line, i.e. end of header
		NSString *loc;
		NSHTTPURLResponse *response;
		response=[[NSHTTPURLResponse alloc] _initWithURL:[_request URL] headerFields:_headers andStatusCode:_statusCode];
		// [_request HTTPShouldHandleCookies];
		if([[_headers objectForKey:@"content-encoding"] isEqualToString:@"gzip"])
			{ // handle header compression
			NSLog(@"header is gzip compressed");
			}
		// Connection = "Keep-Alive"; 
		// "Keep-Alive" = "timeout=3, max=100"; 
		[_headers objectForKey:@"last-modified"];
		loc=[_headers objectForKey:@"location"];
		[_headers release];
		_headers=nil;
		if([loc length])
			{ // Location: entry exists
			NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:loc]];
			if(!request)
				[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"Invalid redirect request" code:0 userInfo:nil]]; // error
			[_client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
			}
		else
			{
			NSURLCacheStoragePolicy policy=NSURLCacheStorageAllowed;	// default
			// read from [_request cachePolicy];
			/*
			 NSURLCacheStorageAllowed,
			 NSURLCacheStorageAllowedInMemoryOnly
			 NSURLCacheStorageNotAllowed
			 */			 
			if([self isKindOfClass:[_NSHTTPSURLProtocol class]])
				policy=NSURLCacheStorageNotAllowed;	// never
			[_client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:policy];
			}
		return YES;
		}
	for(c=buffer, end=c+len; *c != ':'; c++)
		{
		if(c == end)
			{ // no colon found!
			// raise bad header error or simply ignore?
			return NO;	// keep processing header lines
			}
		}
	key=[NSString stringWithCString:(char *) buffer length:c-buffer];
	while(++c < end && (*c == ' ' || *c == '\t'))
		;	// skip spaces
	val=[NSString stringWithCString:(char *) c length:end-c];
	[_headers setObject:val forKey:[key lowercaseString]];	// convert key to all lowercase
	return NO;	// not yet done
}

- (void) _processHeader:(unsigned char *) buffer length:(int) len;
{ // next header fragment received
	unsigned char *ptr, *end;
#if 0
	NSLog(@"received %d bytes", len);
#endif
	if(len <= 0)
		return;	// ignore
	if(_receiveBufLength + len > _receiveBufCapacity)
		{ // needs to increase capacity
		_receiveBuf=objc_realloc(_receiveBuf, _receiveBufCapacity=_receiveBufLength+len+1);	// creates new one if NULL
		if(!_receiveBuf)
			; // FIXME allocation did fail: stop reception
		}
	memcpy(_receiveBuf+_receiveBufLength, buffer, len);		// append to last partial block
	_receiveBufLength+=len;
#if 0
	NSLog(@"len=%u capacity=%u buf=%.*s", _receiveBufLength, _receiveBufCapacity, _receiveBufLength, _receiveBuf);
#endif
	ptr=_receiveBuf;	// start of current line
	end=_receiveBuf+_receiveBufLength;
	while(YES)
		{ // look for complete lines
		unsigned char *eol=ptr;
		while(!(eol[0] == '\r' && eol[1] == '\n'))
			{ // search next line end
			eol++;
			if(eol == end)
				{ // no more lines found
#if 0
				NSLog(@"no CRLF");
#endif
				if(ptr != _receiveBuf)
					{ // remove already processed lines from buffer
					memmove(_receiveBuf, ptr, end-ptr);
					_receiveBufLength-=(end-ptr);
					}
				return;
				}
			}
		if([self _processHeaderLine:ptr length:eol-ptr])
			{ // done
			if(_inputStream)
				{ // is still open, i.e. hasn't been stopped in a client callback
				if(eol+2 != end)
					{ // we have already received the first fragment of the body
					[_client URLProtocol:self didLoadData:[NSData dataWithBytes:eol+2 length:(end-eol)-2]];	// notify
					}
				}
			objc_free(_receiveBuf);
			_receiveBuf=NULL;
			_receiveBufLength=0;
			_receiveBufCapacity=0;
			_readingBody=YES;
			return;
			}				
		ptr=eol+2;	// go to start of next line
		}
}

/*
 FIXME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows.
 This might also be some very lage constant for record length which wraps around the 32bit address limit (e.g. a negative record length).
 Ending up in infinite loops blocking the system.
 */

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event
{
#if 0
	NSLog(@"stream:%@ handleEvent:%x for:%@", stream, event, self);
#endif
    if(stream == _inputStream) 
		{
		switch(event)
			{
			case NSStreamEventHasBytesAvailable:
				{
					unsigned char buffer[512];
					int len=[(NSInputStream *) stream read:buffer maxLength:sizeof(buffer)];
					if(len < 0)
						{
#if 1
						NSLog(@"receive error %s", strerror(errno));
#endif
						[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"receive error" code:errno userInfo:nil]];
						[self _unschedule];
						return;
						}
					if(_readingBody)
						[_client URLProtocol:self didLoadData:[NSData dataWithBytes:buffer length:len]];	// notify
					else
						[self _processHeader:buffer length:len];
					return;
				}
			case NSStreamEventEndEncountered:	// can this occur in parallel to NSStreamEventHasBytesAvailable???
				{
#if 0
					NSLog(@"end of response");
#endif
					if(!_readingBody)
						[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"incomplete header" code:0 userInfo:nil]];
					[_client URLProtocolDidFinishLoading:self];
					_readingBody=NO;
					[self _unschedule];
					return;
				}
			case NSStreamEventOpenCompleted:
				{ // prepare to receive header
#if 0
					NSLog(@"HTTP input stream opened");
#endif
					return;
				}
			default:
				break;
			}
		}
	else if(stream == _outputStream)
		{
		unsigned char *msg;
#if 0
		NSLog(@"An event occurred on the output stream.");
#endif
		/* e.g.
		POST /wiki/Spezial:Search HTTP/1.1
		Host: de.wikipedia.org
		Content-Type: application/x-www-form-urlencoded
		Content-Length: 24
		
		search=Katzen&go=Artikel  <- body
		*/
		switch(event)
			{
			case NSStreamEventOpenCompleted:
				{
					NSString *header;
					NSURL *url=[_request URL];
					NSString *path=[url path];
#if 0
					NSLog(@"HTTP output stream opened");
#endif
					if([path length] == 0)
						path=@"/";	// root
					header=[NSString stringWithFormat:@"%@ %@ HTTP/1.1\r\nHost: %@\r\n",
						[_request HTTPMethod],
						[path stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding],
						[url host]
						];
					msg=(unsigned char *) [header cString];	// FIXME: UTF8???
					[(NSOutputStream *) stream write:msg maxLength:strlen((char *) msg)];
#if 1
					NSLog(@"sent %@ -> %s", url, msg);
#endif
					_headerEnumerator=[[[_request allHTTPHeaderFields] objectEnumerator] retain];
					return;
				}
			case NSStreamEventHasSpaceAvailable:
				{
					// FIXME: should also send out relevant Cookies
					if(_headerEnumerator)
						{ // send next header
						NSString *key;
						key=[_headerEnumerator nextObject];
						if(key)
							{ // attributes
#if 1
							NSLog(@"sending %@: %@", key, [_request valueForHTTPHeaderField:key]);
#endif
							msg=(unsigned char *)[[NSString stringWithFormat:@"%@: %@\r\n", key, [_request valueForHTTPHeaderField:key]] stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
							}
						else
							{ // was last header entry
							[_headerEnumerator release];
							_headerEnumerator=nil;
							msg=(unsigned char *) "\r\n";				// send empty line
							_body=[[_request HTTPBodyStream] retain];	// if present
							if(!_body && [_request HTTPBody])
								_body=[[NSInputStream alloc] initWithData:[_request HTTPBody]];	// prepare to send request body
							[_body open];
							}
						[(NSOutputStream *) stream write:msg maxLength:strlen((char *) msg)];	// NOTE: we might block here if header value is too long
#if 1
						NSLog(@"sent %s", msg);
#endif
						return;
						}
					else if(_body)
						{ // send (next part of) body until done
						if([_body hasBytesAvailable])
							{
							unsigned char buffer[512];
							int len=[_body read:buffer maxLength:sizeof(buffer)];	// read next block from stream
							if(len < 0)
								{
#if 1
								NSLog(@"error reading from HTTPBody stream %s", strerror(errno));
#endif
								[self _unschedule];
								return;
								}
							[(NSOutputStream *) stream write:buffer maxLength:len];	// send
							}
						else
							{ // done
#if 0
							NSLog(@"request sent");
#endif
							[self _unschedule];	// well, we should just unschedule the send stream
							[_body close];
							[_body release];
							_body=nil;
							}
						}
					return;	// done
				}
			default:
				break;
			}
		}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [stream streamError], event, stream, self);
	[_client URLProtocol:self didFailWithError:[stream streamError]];
}

@end

@implementation _NSHTTPSURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"https"];
}

- (void) _didInitializeOutputStream:(NSOutputStream *) stream;
{ // make us use a SSL socket
	[stream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
}

@end

@implementation _NSFTPURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"ftp"];
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) startLoading;
{
	if(_cachedResponse)
		{ // handle from cache
		}
	else
		{
		NSURL *url=[_request URL];
		NSHost *host=[NSHost hostWithName:[url host]];
		if(!host)
			host=[NSHost hostWithAddress:[url host]];
		[NSStream getStreamsToHost:host
							  port:[[url port] intValue]
					   inputStream:&_inputStream
					  outputStream:&_outputStream];
		if(!_inputStream || !_outputStream)
			{ // error
			[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"can't connect" code:0 userInfo:nil]];
			return;
			}
		[_inputStream retain];
		[_outputStream retain];
		[_inputStream setDelegate:self];
		[_outputStream setDelegate:self];
		[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
								forMode:NSDefaultRunLoopMode];
		[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
								 forMode:NSDefaultRunLoopMode];
		// set socket options for ftps requests
		[_inputStream open];
		[_outputStream open];
		}
}

- (void) stopLoading;
{
	if(_inputStream)
		{
		[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
								forMode:NSDefaultRunLoopMode];
		[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
								 forMode:NSDefaultRunLoopMode];
		[_inputStream close];
		[_outputStream close];
		[_inputStream release];
		[_outputStream release];
		_inputStream=nil;
		_outputStream=nil;
		}
}

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event
{
    if(stream == _inputStream) 
		{
		switch(event)
			{
			case NSStreamEventHasBytesAvailable:
				{
				NSLog(@"FTP input stream has bytes available");
				// implement FTP protocol
	//			[_client URLProtocol:self didLoadData:[NSData dataWithBytes:buffer length:len]];	// notify
				return;
				}
			case NSStreamEventEndEncountered:	// can this occur in parallel to NSStreamEventHasBytesAvailable???
				NSLog(@"FTP input stream did end");
				[_client URLProtocolDidFinishLoading:self];
				return;
			case NSStreamEventOpenCompleted:
				// prepare to receive header
				NSLog(@"FTP input stream opened");
				return;
			default:
				break;
			}
		}
	else if(stream == _outputStream)
		{
		NSLog(@"An event occurred on the output stream.");
		// if successfully opened, send out FTP request header
		}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [stream streamError], event, stream, self);
	[_client URLProtocol:self didFailWithError:[stream streamError]];
}

@end

@implementation _NSFileURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"file"];
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) startLoading;
{
	// check for GET/PUT/DELETE etc so that we can also write to a file
	NSData *data=[NSData dataWithContentsOfFile:[[_request URL] path] /* options: error: - don't use that because it is based on self */];
	NSURLResponse *r;
	if(!data)
		{
		[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"can't load file" 
																																	 code:0
																															 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																																					[_request URL], @"URL",
																																					[[_request URL] path], @"path", nil]
			]];
		return;
		}
	r=[[NSURLResponse alloc] initWithURL:[_request URL]
		// FIXME: we might try to deduce from contents
								MIMEType:@"text/html"
				   expectedContentLength:[data length]
		// FIXME: we might try to check for BOM bytes
						textEncodingName:@"unknown"];	
	[_client URLProtocol:self didReceiveResponse:r cacheStoragePolicy:NSURLRequestUseProtocolCachePolicy];
	[_client URLProtocol:self didLoadData:data];
	[_client URLProtocolDidFinishLoading:self];
	[r release];
}

- (void) stopLoading; { return; }	// we do it in one large junk...

@end

@implementation _NSAboutURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"about"];
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) startLoading;
{
	NSURLResponse *r;
	NSData *data=[NSData data];	// no data
	// we could pass different content depending on the [url path]
	r=[[NSURLResponse alloc] initWithURL:[_request URL]
								MIMEType:@"text/html"
				   expectedContentLength:[data length]
						textEncodingName:@"utf-8"];	
	[_client URLProtocol:self didReceiveResponse:r cacheStoragePolicy:NSURLRequestUseProtocolCachePolicy];
	[_client URLProtocol:self didLoadData:data];
	[_client URLProtocolDidFinishLoading:self];
	[r release];
}

- (void) stopLoading; { return; }	// we do it in one large junk...

@end

@implementation _NSDataURLProtocol	// RFC2397

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"data"];
	// could check for well-formed URL
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) startLoading;
{
	NSURLResponse *r;
	NSString *mime=@"text/plain";
	NSString *encoding=@"US-ASCII";
	NSData *data=[NSData data];	// no data
	// get other mime from path
	// get encoding from charset= part
	// check for base64 part
	// somehow handle the ,
	// extract and convert data
	r=[[NSURLResponse alloc] initWithURL:[_request URL]
								MIMEType:mime
				   expectedContentLength:[data length]
						textEncodingName:encoding];	
	[_client URLProtocol:self didReceiveResponse:r cacheStoragePolicy:NSURLRequestUseProtocolCachePolicy];
	[_client URLProtocol:self didLoadData:data];
	[_client URLProtocolDidFinishLoading:self];
	[r release];
}

- (void) stopLoading; { return; }	// we do it in one large junk...

@end
