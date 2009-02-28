//
//  NSURLProtocol.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

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
	// sending
	NSOutputStream *_outputStream;
	NSInputStream *_headerStream;						// headers while sending
	NSInputStream *_bodyStream;							// for sending the body
	BOOL _canKeepAlive;								// if we did determine and send the Content-Length: header
	// receiving
	NSInputStream *_inputStream;
	NSMutableDictionary *_headers;		// received headers
	NSMutableString *_headerLine;
	unsigned _statusCode;
	unsigned long long _contentLength;		// if explicitly specified by header (in that case, we can leave the connection open)
	int _eol;													// end of line status
	BOOL _readingBody;								// done with reading header
	BOOL _hasContentLength;						// server did specify a content-length
	BOOL _isLoading;									// startLoading called
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
	BOOL _stopLoading;
}

@end

@interface _NSAboutURLProtocol : NSURLProtocol
{
	BOOL _stopLoading;
}

@end

@interface _NSDataURLProtocol : NSURLProtocol
{
	BOOL _stopLoading;
}

@end


@implementation NSURLProtocol

static NSMutableArray *_registeredClasses;

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
+ (void) removePropertyForKey:(NSString *) key inReq:(NSMutableURLRequest *) req; { SUBCLASS; }

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
	if([self class] == [NSURLProtocol class])
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
			{ // here we are called for a subclass
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

// not public?

- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode; { SUBCLASS; }
- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode; { SUBCLASS; }

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

// see http://www.w3.org/Protocols/rfc2616/rfc2616.html
// and a very good tutorial: http://www.jmarshall.com/easy/http/

static NSMutableArray *keptAliveConnections;

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"http"];
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (id) initWithRequest:(NSURLRequest *) request
				cachedResponse:(NSCachedURLResponse *) cachedResponse
								client:(id <NSURLProtocolClient>) client
{
	NSEnumerator *e=[keptAliveConnections objectEnumerator];
	_NSHTTPURLProtocol *p;
	NSString *host=[[request URL] host];
	NSNumber *port=[[request URL] port];
	while((p=[e nextObject]))
			{
				NSURL *other=[[p request] URL];
				if([[other host] isEqualToString:host] && [[other port] isEqual:port])
						{ // found - reuse existing object
							[self release];
							self=[p retain];
#if 1
							NSLog(@"initialized for re-use");
#endif
							[keptAliveConnections removeObjectIdenticalTo:p];	// remove
							[_request release];
							_request=[request copy];	// save a copy of the request
							[_cachedResponse release];
							_cachedResponse=[cachedResponse retain];
							_client=client;
							_isLoading=NO;
							_eol=0;
							return self;
						}
			}
	return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}

- (void) dealloc;
{
	[self stopLoading];		// if still running
	[_headerLine release];	// if left over
	[_headers release];		// received headers
	[_headerStream release];			// for sending the header
	[_bodyStream release];			// for sending the body
	[super dealloc];
}

- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	[_inputStream scheduleInRunLoop:runLoop forMode:mode];
	[_outputStream scheduleInRunLoop:runLoop forMode:mode];
}

- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	[_inputStream removeFromRunLoop:runLoop forMode:mode];
	[_outputStream removeFromRunLoop:runLoop forMode:mode];
}

- (void) _unschedule;
{
	[self unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void) _getStreamsToHost:(NSHost *)host port:(NSInteger)port inputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream
{
	[NSStream getStreamsToHost:host port:port inputStream:inputStream outputStream:outputStream];
#if 1
	NSLog(@"did initialize streams for %@", self);
	NSLog(@"  input %@", *inputStream);
	NSLog(@" output %@", *outputStream);
#endif
}

- (void) startLoading;
{
	// KEEPALIVE allows and/or requires us to cache and reuse the sockets/streams!
	// http://www.io.com/~maus/HttpKeepAlive.html
	// http://java.sun.com/j2se/1.5.0/docs/guide/net/http-keepalive.html
	// 
	NSURL *url=[_request URL];
	NSString *path=[url path];
	NSMutableData *headerData;
	NSMutableDictionary *requestHeaders;
	NSEnumerator *e;
	NSString *key;
	static NSDictionary *methods;
	if(_isLoading)
		return;	// already runing
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
#if 1
	NSLog(@"startLoading: %@", self);
#endif
	if(!_outputStream)
			{ // we must connect first (we are not reusing the connection)
				NSHost *host=[NSHost hostWithName:[url host]];		// try to resolve
				int port=[[url port] intValue];
				if(!host) host=[NSHost hostWithAddress:[url host]];	// try dotted notation
				if(!host) host=[NSHost hostWithAddress:@"127.0.0.1"];	// final default
				if(!port) port=[[url scheme] isEqualToString:@"https"]?433:80;	// default port if not specified
				[self _getStreamsToHost:host
													 port:port
										inputStream:&_inputStream
									 outputStream:&_outputStream];
				if(!_inputStream || !_outputStream)
						{ // error opening the streams
#if 1
							NSLog(@"could not create streams for %@:%u", host, [[url port] intValue]);
#endif
							[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"can't connect" code:0 userInfo:
																													[NSDictionary dictionaryWithObjectsAndKeys:
																													 url, @"NSErrorFailingURLKey",
																													 host, @"NSErrorFailingURLStringKey",
																													 @"can't find host", @"NSLocalizedDescription",
																													 nil]]];
							return;
						}
#if 1
				NSLog(@"open input stream %@ for %@", _inputStream, self);
				NSLog(@"open output stream %@ for %@", _outputStream, self);
#endif
				[_inputStream retain];
				[_outputStream retain];
				[_inputStream setDelegate:self];
				[_outputStream setDelegate:self];
				[_inputStream open];
				[_outputStream open];
			}
	if([path length] == 0)
		path=@"/";	// root
	headerData=[[NSMutableData alloc] initWithCapacity:200];
	_headerStream=[[NSInputStream alloc] initWithData:headerData];
	[headerData release];
	[headerData appendData:[[NSString stringWithFormat:@"%@ %@ HTTP/1.1\r\n",
												[_request HTTPMethod],
												[path stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding]
												] dataUsingEncoding:NSUTF8StringEncoding]];
	requestHeaders=[[NSMutableDictionary alloc] initWithObjectsAndKeys:[url host], @"Host", nil];
	[requestHeaders addEntriesFromDictionary:[_request allHTTPHeaderFields]];	// add to headers
	if([_request HTTPShouldHandleCookies])
			{
				NSHTTPCookieStorage *cs=[NSHTTPCookieStorage sharedHTTPCookieStorage];
				NSDictionary *cdict=[NSHTTPCookie requestHeaderFieldsWithCookies:[cs cookiesForURL:url]];
				[requestHeaders addEntriesFromDictionary:cdict];	// add to headers
			}
	_canKeepAlive=[_request HTTPBody] != nil;
	if(_canKeepAlive)
			{ // we should know the body length
				unsigned long bodyLength=[[_request HTTPBody] length];
				[requestHeaders setObject:[NSNumber numberWithUnsignedLong:bodyLength] forKey:@"Content-Length"];
			}
#if 1
	NSLog(@"headers to send: %@", requestHeaders);
#endif
	e=[requestHeaders keyEnumerator];
	while((key=[e nextObject]))
			{ // attributes
				NSString *val=[requestHeaders objectForKey:key];
#if 1
				NSLog(@"sending %@: %@", key, val);
#endif
				val=[val stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
				[headerData appendData:[[NSString stringWithFormat:@"%@: %@\r\n", key, val] dataUsingEncoding:NSUTF8StringEncoding]];
			}
	[headerData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_headerStream open];
	_bodyStream=[[_request HTTPBodyStream] retain];	// if provided as a stream object
	if(!_bodyStream && [_request HTTPBody])
		_bodyStream=[[NSInputStream alloc] initWithData:[_request HTTPBody]];	// prepare to send request body NSData object
	[_bodyStream open];
	[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
#if 1
	NSLog(@"ready to send");
#endif
	_isLoading=YES;
}

- (void) stopLoading;
{
#if 1
	NSLog(@"stopLoading: %@", self);
#endif
	if(_outputStream)
			{ // communication is running - close connection
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

- (void) _headersReceived
{ // end of header block received
	NSHTTPURLResponse *response;
	NSString *loc;	// redirect location
	NSString *clen;	// content length
	if([_request HTTPShouldHandleCookies])
			{ // auto-process cookies
				NSArray *cookies=[NSHTTPCookie cookiesWithResponseHeaderFields:_headers forURL:[_request URL]];
				[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[_request URL] mainDocumentURL:[_request URL]];
			}
	if([[_headers objectForKey:@"content-encoding"] isEqualToString:@"gzip"])
			{ // handle header compression
				// we should simply add _zip / _unzip / _inflate / _deflate for GZIP to NSData
				NSLog(@"body is gzip compressed");
			}
	/*
	 * HTTP 1.0 defines (but we ignore!)
	 * Connection = "Keep-Alive";
	 * "Keep-Alive" = "timeout=3, max=100";
	 */
	/** FIXME: check with cachedResponse **/  [_headers objectForKey:@"last-modified"];
	clen=[_headers objectForKey:@"content-length"];
	_hasContentLength=(clen != nil);
	_contentLength = [clen longLongValue];
	loc=[_headers objectForKey:@"location"];
	response=[[NSHTTPURLResponse alloc] _initWithURL:[_request URL] headerFields:_headers andStatusCode:_statusCode];
	[_headers release];	// have been stored in NSHTTPURLResponse
	_headers=nil;
	// decide here if we want to read the body or get the value from the _cachedResponse
	// if we don't want to receive the body, [_inputStream close] and remove us from being reuseable
	if([loc length])
			{ // Location: entry exists
				NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:loc]];
				if(!request)
						{
							[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"Invalid redirect request" code:0 userInfo:nil]]; // error
							_client=nil;
						}
				[_client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
			}
	else
			{
				NSURLCacheStoragePolicy policy;
				if([self isKindOfClass:[_NSHTTPSURLProtocol class]])
					policy=NSURLCacheStorageNotAllowed;	// never
				else
					policy=[_request cachePolicy];	// default
				[_client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:policy];
			}
	[response release];
	_readingBody=YES;	// start reading body
}

- (void) _processHeaderLine:(NSString *) line;
{ // process header line
	NSString *key, *val;
	NSRange colon;
#if 0
	NSLog(@"process header line %@", line);
#endif
	if(!_headers)
			{ // should be/must be the header line
				unsigned major, minor;
				if(sscanf([line UTF8String], "HTTP/%u.%u %u", &major, &minor, &_statusCode) == 3)
						{ // response header line
							if(major != 1 || minor > 1)
									{
										[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"Bad HTTP version" code:0 userInfo:nil]];
										_client=nil;
									}
							_headers=[[NSMutableDictionary alloc] initWithCapacity:10];	// start collecting headers
							// if(_statusCode >= 400 && _statusCode <= 499)
#if 1
							NSLog(@"Received header: %@", line);
#endif
							return;	// process next line
						}
				else
						{
							[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"Invalid HTTP response" code:0 userInfo:nil]];
							_client=nil;
						}
				return;	// process next line
			}
	colon=[line rangeOfString:@":"];
	if(colon.location == NSNotFound)
		return; // no colon found! Ignore to prevent DoS attacks...
	key=[line substringToIndex:colon.location];
	key=[key lowercaseString];	// convert key to all lowercase
	val=[[line substringFromIndex:colon.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([_headers objectForKey:key])
		val=[NSString stringWithFormat:@"%@; %@", [_headers objectForKey:key], val];	// merge multiple headers with same key into a single one
	[_headers setObject:val forKey:key];
#if 1
	NSLog(@"header: %@:%@", key, val);
#endif
}

- (void) _processHeaderChar:(char) chr
{
	switch(_eol)
		{
			case 2:
				if(chr != ' ' && chr != '\t')
						{ // process previous header line
							[self _processHeaderLine:_headerLine];
							[_headerLine setString:@""];	// processed
							_eol=0;
						}
				else
					break;	// continuation line
			case 0:
				if(chr == '\r')
					_eol=1;
				else if(chr == '\n')
					_eol=2;
				else
						{
							if(!_headerLine)
								_headerLine=[[NSMutableString alloc] initWithCapacity:50];	// typical length of a header line
							[_headerLine appendFormat:@"%c", chr];
						}
				break;
			case 1:
				if(chr == '\n')
						{
							_eol=2;
							if([_headerLine length] == 0)
								[self _headersReceived];	// empty line received
						}
				else
					_eol=0;	// was single \r
				break;
		}
#if 0
	NSLog(@"did process %02x state=%d", chr, _eol);
#endif
}

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event
{
#if 0
	NSLog(@"stream:%@ handleEvent:%x for:%@", stream, event, self);
#endif
	if(stream == _inputStream) 
			{
#if 0
				NSLog(@"An event %d occurred on the input stream.", event);
#endif
				switch(event)
					{
						case NSStreamEventOpenCompleted:
						{ // ready to receive header
#if 1
							NSLog(@"HTTP input stream opened");
#endif
							return;
						}
						case NSStreamEventHasBytesAvailable:
							{
								unsigned char buffer[512];
								unsigned maxLength=sizeof(buffer);
								int len;
								if(_readingBody)
										{
											if(_contentLength > 0 && _contentLength < maxLength)
												maxLength=_contentLength;	// limit to expected size
										}
								else
									maxLength=1;	// so that we don't miss the Content-Length: header entry even if it directly precedes the \r\n\r\nbody
								len=[(NSInputStream *) stream read:buffer maxLength:maxLength];
								if(len == 0)
									break;	// ignore (or when does this occur?)
								if(len <= 0)
										{
#if 1
											NSLog(@"receive error %s", strerror(errno));
#endif
											[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"receive error" code:errno userInfo:nil]];
											_client=nil;
											[self _unschedule];
											return;
										}
#if 0
								NSLog(@"received %d bytes", len);
#endif
								if(_readingBody)
										{
											[_client URLProtocol:self didLoadData:[NSData dataWithBytes:buffer length:len]];	// notify
											if(_contentLength > 0)
													{
														_contentLength -= len;
														if(_contentLength == 0)
																{ // we have received as much as expected
																	[_client URLProtocolDidFinishLoading:self];
																	_readingBody=NO;	// start over reading headers
#if 1
																	NSLog(@"keeping alive: %@", self);
#endif
																	if(!keptAliveConnections)
																		keptAliveConnections=[[NSMutableArray alloc] initWithCapacity:5];
																	[keptAliveConnections addObject:self];	// allow to reuse our connection
																}
													}
											return;
										}
								[self _processHeaderChar:buffer[0]];	// process the received character
								return;
							}
						case NSStreamEventEndEncountered:
							{
#if 1
								NSLog(@"input connection closed by server");
#endif
								if(!_readingBody)
										{
									[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"incomplete header received" code:0 userInfo:nil]];
											_client=nil;
										}
								if(_hasContentLength)
										{
											if(_contentLength > 0)
													{
														[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"connection closed by server while receiving body" code:0 userInfo:nil]];	// we did not receive the announced contentLength
														_client=nil;
													}
										}
								else
									[_client URLProtocolDidFinishLoading:self];	// implicit content length defined by EOF
#if 1
								NSLog(@"can't keep alive: %@", self);
#endif
								[keptAliveConnections removeObject:self];	// no longer available for reuse (this event may come before we are trying to reuse)
								[self _unschedule];
								[_inputStream close];
								return;
							}
						default:
							break;
					}
			}
	else if(stream == _outputStream)
			{
#if 0
				NSLog(@"An event %d occurred on the output stream.", event);
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
						{ // ready to send header
#if 1
							NSLog(@"HTTP output stream opened");
#endif
							return;
						}
						case NSStreamEventHasSpaceAvailable:
							{
								unsigned char buffer[512];	// max size of chunks to send to TCP subsystem to avoid blocking
								if(_headerStream)
										{ // we are still sending the header
											if([_headerStream hasBytesAvailable])
													{ // send next part until done
														int len=[_headerStream read:buffer maxLength:sizeof(buffer)];	// read next block from stream
														if(len < 0)
																{
#if 1
																	NSLog(@"error while reading from HTTPHeader stream %s", strerror(errno));
#endif
																	[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"HTTPHeaderStream" code:errno userInfo:nil]];
																	_client=nil;
																	[self _unschedule];
																}
														else
																{
																	[(NSOutputStream *) stream write:buffer maxLength:len];	// send
#if 1
																	NSLog(@"%d bytes header sent", len);
#endif
																}
														return;	// done sending next chunk
													}
											[_headerStream close];
											[_headerStream release];	// done sending header
											_headerStream=nil;
										}
								if(_bodyStream)
										{ // we are still sending the body
											if([_bodyStream hasBytesAvailable])
													{ // send next part until done
														int len=[_bodyStream read:buffer maxLength:sizeof(buffer)];	// read next block from stream
														if(len < 0)
																{
#if 1
																	NSLog(@"error while reading from HTTPBody stream %s", strerror(errno));
#endif
																	[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"HTTPBodyStream" code:errno userInfo:nil]];
																	_client=nil;
																	[self _unschedule];
																}
														else
																{
																	[(NSOutputStream *) stream write:buffer maxLength:len];	// send
#if 1
																	NSLog(@"%d bytes body sent", len);
#endif
																}
														return;	// done
													}
#if 1
											NSLog(@"request sent completely");
#endif
											[_bodyStream close];	// close body stream (if open)
											[_bodyStream release];
											_bodyStream=nil;
										}
								if(!_canKeepAlive)
									[_outputStream close];
								else
									; // unschedule output stream
								return;
							}
						case NSStreamEventEndEncountered:
							if([_headerStream hasBytesAvailable])
								[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"connection closed by server while sending header" code:errno userInfo:nil]], _client=nil;
							else if([_bodyStream hasBytesAvailable])
								[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"connection closed by server while sending body" code:errno userInfo:nil]], _client=nil;
							else
									{
#if 1
										NSLog(@"can't keep alive: %@", self);
#endif
										[keptAliveConnections removeObjectIdenticalTo:self];	// server has disconnected
									}
							[_headerStream close];
							[_headerStream release];	// done sending header
							_headerStream=nil;
							[_bodyStream close];	// close body stream (if open)
							[_bodyStream release];
							_bodyStream=nil;
							return;
						default:
							break;
					}
			}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [stream streamError], event, stream, self);
	[_client URLProtocol:self didFailWithError:[stream streamError]];
	_client=nil;
}

@end

@implementation _NSHTTPSURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return [[[request URL] scheme] isEqualToString:@"https"];
}

- (void) _getStreamsToHost:(NSHost *)host port:(NSInteger)port inputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream
{
	[super _getStreamsToHost:host port:port inputStream:inputStream outputStream:outputStream];
	[*inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
	[*outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
}

@end

@implementation _NSFTPURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	return NO;	// FIXME:
	return [[[request URL] scheme] isEqualToString:@"ftp"];
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	[_inputStream scheduleInRunLoop:runLoop forMode:mode];
	[_outputStream scheduleInRunLoop:runLoop forMode:mode];
	// should we save this list?
}

- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	[_inputStream removeFromRunLoop:runLoop forMode:mode];
	[_outputStream removeFromRunLoop:runLoop forMode:mode];
}

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
				[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
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
	_client=nil;
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
	NSString *path=[[_request URL] path];
	NSData *data=[NSData dataWithContentsOfFile:path /* options: error: - don't use that because it is based on self */];
	NSURLResponse *r;
	NSString *enc=@"unknown";
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
															MIMEType:nil	// should try to substitute from file extension
								 expectedContentLength:[data length]
											textEncodingName:enc];	
	[_client URLProtocol:self didReceiveResponse:r cacheStoragePolicy:NSURLRequestUseProtocolCachePolicy];
	if(!_stopLoading)
		[_client URLProtocol:self didLoadData:data];
	if(!_stopLoading)
		[_client URLProtocolDidFinishLoading:self];
	[r release];
}

- (void) stopLoading; { _stopLoading=YES; }

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
	NSData *data=[NSData data];	// about provides no data
	// we could pass different content depending on the [url path]
	r=[[NSURLResponse alloc] initWithURL:[_request URL]
															MIMEType:@"text/html"
								 expectedContentLength:[data length]
											textEncodingName:@"utf-8"];	
	[_client URLProtocol:self didReceiveResponse:r cacheStoragePolicy:NSURLRequestUseProtocolCachePolicy];
	if(!_stopLoading)
		[_client URLProtocol:self didLoadData:data];
	if(!_stopLoading)
		[_client URLProtocolDidFinishLoading:self];
	[r release];
}

- (void) stopLoading; { _stopLoading=YES; }

@end

@implementation _NSDataURLProtocol	// RFC2397 http://www.ietf.org/rfc/rfc2397.txt

/* examples
 
 data:,A%20brief%20note
 
 data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAw
 AAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFz
 ByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSp
 a/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJl
 ZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uis
 F81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PH
 hhx4dbgYKAAA7
 
 data:text/plain;charset=iso-8859-7,%be%fg%be

 */

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{ // data:[<mediatype>][;base64],<data>
	return [[[request URL] scheme] isEqualToString:@"data"];
	// could also check for well-formed URL
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request; { return request; }

- (void) startLoading;
{
	NSURLResponse *r;
	NSString *mime=@"text/plain";
	NSString *encoding=@"US-ASCII";
	NSData *data;
	NSString *path=[[_request URL] path];
	NSRange comma=[path rangeOfString:@","];
	NSEnumerator *types;
	NSString *type;
	BOOL base64=NO;
	if(comma.location == NSNotFound)
			{
				[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"can't load data" 
																																			 code:0
																																	 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																																						 [_request URL], @"URL",
																																						 [[_request URL] path], @"path", nil]
																										]];
				return;
			}
	types=[[[path substringToIndex:comma.location] componentsSeparatedByString:@";"] objectEnumerator];
	while((type=[types nextObject]))
			{
				if([type isEqualToString:@"base64"])
					base64=YES;
				else if([type hasPrefix:@"charset="])
					encoding=[type substringFromIndex:8];
				else if([type length] > 0)
					mime=type;
			}
	path=[path substringFromIndex:comma.location+1];	// data after ,
	if(base64)
		data=[[[NSData alloc] _initWithBase64String:path] autorelease]; // decode base64 (private extension of NSData)
	else
		data=[[path stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
	r=[[NSURLResponse alloc] initWithURL:[_request URL]
															MIMEType:mime
								 expectedContentLength:[data length]
											textEncodingName:encoding];	
	[_client URLProtocol:self didReceiveResponse:r cacheStoragePolicy:NSURLRequestUseProtocolCachePolicy];
	if(!_stopLoading)
		[_client URLProtocol:self didLoadData:data];
	if(!_stopLoading)
		[_client URLProtocolDidFinishLoading:self];
	[r release];
}

- (void) stopLoading; { _stopLoading=YES; }

@end
