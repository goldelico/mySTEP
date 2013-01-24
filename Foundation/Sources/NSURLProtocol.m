//
//  NSURLProtocol.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//			Copyright (c) 2006-2009 Golden Delicous Computers. All rights reserved.
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

@class _NSHTTPURLProtocol;

#define CAN_GZIP 0

@interface _NSHTTPSerialization : NSObject
{ // for handling a single protocol entity according to http://www.faqs.org/ftp/rfc/rfc2616.pdf
	NSMutableArray *_requestQueue;		// all queued requests		
	_NSHTTPURLProtocol *_currentRequest;	// current request
	// sending
	NSOutputStream *_outputStream;
	NSInputStream *_headerStream;			// header while sending
	NSInputStream *_bodyStream;				// for sending the body
	BOOL _shouldClose;								// server will close after current request - we must requeue other requests on a new connection
	BOOL _sendChunked;								// sending with transfer-encoding: chunked
	// receiving
	NSInputStream *_inputStream;
	unsigned _statusCode;							// status code defined by response
	NSMutableDictionary *_headers;		// received headers
	unsigned long long _contentLength;		// if explicitly specified by header
	NSMutableString *_headerLine;			// current header line
	unsigned int _chunkLength;				// current chunk length for receiver
	char _lastChr;										// previouds character while reading header
	BOOL _readingBody;								// done with reading header
	BOOL _isChunked;									// transfer-encoding: chunked
	BOOL _willClose;									// server has announced to close the connection	
}

+ (_NSHTTPSerialization *) serializerForProtocol:(_NSHTTPURLProtocol *) protocol;	// get connection queue for handling this request (may create a new one)
- (void) startLoading:(_NSHTTPURLProtocol *) proto;		// add to queue
- (void) stopLoading:(_NSHTTPURLProtocol *) proto;		// remove from queue - may cancel/close connection if it is current request or simply stop notifications

// internal methods

- (BOOL) connectToServer;	// connect to server
- (void) headersReceived;
- (void) bodyReceived;
- (void) trailerReceived;
- (void) endOfUseability;	// connection became invalid

@end

@interface _NSHTTPURLProtocol : NSURLProtocol
{
	_NSHTTPSerialization /* nonretained */ *_connection;	// where we have been queued up
	NSMutableArray *_runLoops;				// additional runloops to schedule
	NSMutableArray *_modes;						// additional modes to schedule
}

- (NSString *) _uniqueKey;	// a key to identify the same server connection

- (void) _setConnection:(_NSHTTPSerialization *) connection;
- (_NSHTTPSerialization *) _connection;

- (void) didFailWithError:(NSError *) error;
- (void) didLoadData:(NSData *) data;
- (void) didFinishLoading;
- (void) didReceiveResponse:(NSHTTPURLResponse *) response;

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

// NOTE: Cocoa has this without _
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
{ // default equivalence check
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
			_client=[(NSObject *) client retain];	// we must retain the client (or it may disappear while we still receive data)
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
			[(NSObject *) _client release];
		}
	[super dealloc];
}

- (void) startLoading; { SUBCLASS; }
- (void) stopLoading; { SUBCLASS; }

// such undocumented methods must exist since NSURLConnection can be scheduled on several runloops and modes in parallel

- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode; { return; }
- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode; { return; }

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

@implementation _NSHTTPSerialization

// see http://www.w3.org/Protocols/rfc2616/rfc2616.html
// or http://www.faqs.org/ftp/rfc/rfc2616.pdf
// and a very good tutorial: http://www.jmarshall.com/easy/http/
// http://www.io.com/~maus/HttpKeepAlive.html
// http://java.sun.com/j2se/1.5.0/docs/guide/net/http-keepalive.html

static NSMutableDictionary *_httpConnections;

- (BOOL) willClose;
{ // we have announced (in request "Connection: close") to close or server has announced (in reply) - i.e. don't queue up more requests
	return _shouldClose || _willClose;
}

+ (_NSHTTPSerialization *) serializerForProtocol:(_NSHTTPURLProtocol *) protocol;
{ // get connection queue for handling this request (may create a new one)
	NSString *key=[protocol _uniqueKey];
	_NSHTTPSerialization *ser=[_httpConnections objectForKey:key];	// could also store an array!
	if(!ser || [ser willClose])
		{ // not found or server has announced to close connection: we need a new connection
			ser=[self new];
#if 1
			NSLog(@"%@: new serializer %@", key, ser);
#endif
			if(!_httpConnections)
				_httpConnections=[[NSMutableDictionary alloc] initWithCapacity:10];
			// we also may open several serializers for the same combination but HTTP 1.1 recommends to use no more than 2 in parallel
			[_httpConnections setObject:ser forKey:key];
			[ser release];
		}
#if 1
	else
		{
		NSLog(@"%@: reuse serializer %@", key, ser);
		}
#endif
	return ser;
}

- (id) init
{
	if((self=[super init]))
		{
		_requestQueue=[NSMutableArray new];
		_headerLine=[[NSMutableString alloc] initWithCapacity:50];	// typical length of a header line
		}
	return self;
}

- (void) dealloc;
{
#if 1
	NSLog(@"dealloc %@", self);
	NSLog(@"  connections: %d", [_httpConnections count]);
#endif
	NSAssert([_requestQueue count] == 0, @"unprocessed requests left over!");	// otherwise we loose requests
	[_currentRequest _setConnection:nil];	// has been processed
	[_currentRequest release];	// if still stored
	[_requestQueue release];		// no longer needed
	[_headerLine release];			// if left over
	[_headers release];					// received headers
	[_headerStream release];		// for sending the header
	[_bodyStream release];			// for sending the body
	[_inputStream close];				// if still open
	[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream release];			// if still sitting around for any reason (e.g. the runloop did no longer run)
	[_outputStream close];
	[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream release];
	[super dealloc];
}

- (void) endOfUseability
{
	NSArray *keys;
#if 1
	NSLog(@"endOfUseability %@", self);
#endif
	[_inputStream close];
	[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream release];
	_inputStream=nil;
	[_outputStream close];
	[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream release];
	_outputStream=nil;
	[self retain];	// the next two lines could otherwise -dealloc and dealloc the request queue
	keys=[_httpConnections allKeysForObject:self];	// get all my keys
	[_httpConnections removeObjectsForKeys:keys];		// remove us from the list of active connections if we are still there
	[_requestQueue makeObjectsPerformSelector:@selector(_restartLoading)];	// this removes any pending requests from the queue and reschedules in a new/different serializer queue
	[self autorelease];
}	

- (BOOL) connectToServer
{ // we have no open connection yet
	NSURLRequest *request=[_currentRequest request];
	NSURL *url=[request URL];
	BOOL isHttps=[[url scheme] isEqualToString:@"https"];	// we assume that ther can't be a http and a https connection in parallel on the same host:port pair
	NSHost *host=[NSHost hostWithName:[url host]];		// try to resolve (NOTE: this may block for some seconds! Therefore, the resolver should be run in a separate thread!
	int port=[[url port] intValue];
	if(!host) host=[NSHost hostWithAddress:[url host]];	// try dotted notation
	if(!host)
		{ // still not resolved
			[_currentRequest didFailWithError:[NSError errorWithDomain:@"NSURLErrorDomain" code:-1003
															  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		url, @"NSErrorFailingURLKey",
																		[url absoluteString], @"NSErrorFailingURLStringKey",
																		@"can't resolve host name", @"NSLocalizedDescription",
																		nil]]];
			return NO;
		}
	if(!port) port=isHttps?433:80;	// default port if none is specified
	[NSStream getStreamsToHost:host port:port inputStream:&_inputStream outputStream:&_outputStream];
	if(!_inputStream || !_outputStream)
		{ // error opening the streams
#if 1
			NSLog(@"could not create streams for %@:%u", host, [[url port] intValue]);
#endif
			[_currentRequest didFailWithError:[NSError errorWithDomain:@"NSURLErrorDomain" code:-1004
															  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		url, @"NSErrorFailingURLKey",
																		host, @"NSErrorFailingURLStringKey",
																		@"can't open connections to host", @"NSLocalizedDescription",
																		nil]]];
			_inputStream=nil;
			_outputStream=nil;
			return NO;
		}
	[_inputStream retain];
	[_outputStream retain];	// endOfUseability will do a release
	[_inputStream setDelegate:self];
	[_outputStream setDelegate:self];
	if(isHttps)
		{ // use SSL
			[_inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
			[_outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
		}
#if 1
	NSLog(@"did initialize streams for %@", self);
	NSLog(@"  input %@", _inputStream);
	NSLog(@" output %@", _outputStream);
#endif
	[_inputStream open];
	[_outputStream open];
	[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];	// and schedule for reception
	return YES;
}		

- (void) startLoadingNextRequest
{
	NSURLProtocol *protocol=[_requestQueue objectAtIndex:0];
	NSURLRequest *request=[protocol request];
	NSURL *url=[request URL];
	NSString *method=[request HTTPMethod];
	NSString *path=[url path];
	NSMutableData *headerData;
	NSMutableDictionary *requestHeaders;
	NSData *body;
	NSEnumerator *e;
	NSString *key;
	NSString *header;
	NSCachedURLResponse *cachedResponse;
	[_currentRequest release];	// release any done request
	_currentRequest=[protocol retain];
	[_requestQueue removeObjectAtIndex:0];	// remove from queue
	if(!_outputStream && ![self connectToServer])	// connect to server
		{
		[self endOfUseability];	// current request will be lost
		return;	// we can't connect
		}
#if 1
	NSLog(@"startLoading: %@ on %@", _currentRequest, self);
#endif
	headerData=[[NSMutableData alloc] initWithCapacity:200];
	header=[NSString stringWithFormat:@"%@ %@ HTTP/1.1\r\n", method, [path length] > 0?[path stringByAddingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding]:(NSString *)@"/"];
#if 1
	NSLog(@"request: %@", header);
#endif
	[headerData appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];	// CHECKME:
	// CHECKME: what about lower/uppercase in the user provided header fields???
	requestHeaders=[[request allHTTPHeaderFields] mutableCopy];		// start with the provided headers first so that we can overwrite and remove spurious headers
	if(!requestHeaders) requestHeaders=[[NSMutableDictionary alloc] initWithCapacity:5];	// no headers provided by request
	if([request HTTPShouldHandleCookies])
		{
		NSHTTPCookieStorage *cs=[NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSDictionary *cdict=[NSHTTPCookie requestHeaderFieldsWithCookies:[cs cookiesForURL:url]];
		[requestHeaders addEntriesFromDictionary:cdict];	// add to headers
		}
	if([url port])
		header=[NSString stringWithFormat:@"%@:%u", [url host], [[url port] intValue]];	// non-default port
	else
		header=[url host];
	[requestHeaders setObject:header forKey:@"Host"];
	if((cachedResponse=[_currentRequest cachedResponse]) && ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"]))
		{ // ask server to send a new version or a 304 so that we use the cached response
			NSHTTPURLResponse *resp=(NSHTTPURLResponse *) [cachedResponse response];
			NSString *lastModified=[[resp allHeaderFields] objectForKey:@"last-modified"];
#if 1
			NSLog(@"last-modified -> if-modified-since %@", lastModified);
#endif
			if(lastModified)
				[requestHeaders setObject:lastModified forKey:@"If-Modified-Since"];	// copy into the new request
		}
#if CAN_GZIP
	[requestHeaders setObject:@"identity, gzip" forKey:@"Accept-Encoding"];	// set what we can uncompress
#else
	[requestHeaders setObject:@"identity" forKey:@"Accept-Encoding"];
#endif
	if((_bodyStream=[request HTTPBodyStream]))
		{	// is provided by a stream object
			[_bodyStream retain];
			[_bodyStream setProperty:[NSNumber numberWithInt:0] forKey:NSStreamFileCurrentOffsetKey];	// rewind (if possible)
			[requestHeaders setObject:@"chunked" forKey:@"Transfer-Encoding"];	// we must send chunked because we don't know the length in advance
		}
	else if((body=[request HTTPBody]))
		{ // fixed NSData object
			unsigned long bodyLength=[body length];
			[requestHeaders setObject:[NSString stringWithFormat:@"%lu", bodyLength] forKey:@"Content-Length"];
			_bodyStream=[[NSInputStream alloc] initWithData:body];	// prepare to send request body from NSData object
		}
	else
		[requestHeaders removeObjectForKey:@"Date"];	// must not send a Date: header if we have no body
	//	[requestHeaders setObject:@"identity" forKey:@"TE"];	// what we accept in responses
	[requestHeaders removeObjectForKey:@"Keep-Alive"];	// HHTP 1.0 feature
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
#if 1
	NSLog(@"header=%@\n", headerData, [[[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding] autorelease]);
#endif
	_headerStream=[[NSInputStream alloc] initWithData:headerData];	// convert into a stream
	[headerData release];
	[_headerStream open];
	_shouldClose=(header=[requestHeaders objectForKey:@"Connection"]) && [header caseInsensitiveCompare:@"close"] == NSOrderedSame;	// close after sending the request
	_sendChunked=(header=[requestHeaders objectForKey:@"Transfer-Encoding"]) && [header caseInsensitiveCompare:@"chunked"] == NSOrderedSame;
	[requestHeaders release];	// dictionary no more needed
	[_bodyStream open];				// if any
#if 1
	NSLog(@"ready to send");
#endif
	[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];	// start handling output
	_lastChr=0;	// prepare for reading response
	[_headerLine setString:@""];
}

- (void) startLoading:(_NSHTTPURLProtocol *) proto;
{ // add to queue
	[[proto _connection] stopLoading:proto];	// remove from other queue (if any)
	[_requestQueue addObject:proto];	// append to our queue
	[proto _setConnection:self];
	if(!_currentRequest)
		[self startLoadingNextRequest];	// is the first request we are waiting for
}

- (void) stopLoading:(_NSHTTPURLProtocol *) proto;
{ // remove from queue - may cancel/close connection if it is current request or simply stop notifications
	[proto _setConnection:nil];
	if(_currentRequest == proto)
		{
		// FIXME: really cancel
		// at least stop from delivering any notifications to the client
		}
	[_requestQueue removeObject:proto];
}

- (void) headersReceived
{ // end of header block received
	NSURLRequest *request=[_currentRequest request];
	NSURL *url=[request URL];
	NSString *header;
#if 1
	NSLog(@"headers received %@", self);
#endif
	if([request HTTPShouldHandleCookies])
		{ // auto-process cookies if requested
			NSArray *cookies=[NSHTTPCookie cookiesWithResponseHeaderFields:_headers forURL:url];
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:url];
		}
	if((header=[_headers objectForKey:@"content-encoding"]))
		{ // handle header compression
			if([header isEqualToString:@"gzip"])
				NSLog(@"body is gzip compressed");
			// we have the private method [NSData inflate]
			// we must do that here since we receive the stream here
			// NOTE: this may be a , separated list of encodings to be applied in sequence!
			// so we have to loop over [encoding componentsSeparatedByString:@","] - trimmed and compared case-insensitive
		}
	_contentLength = [[_headers objectForKey:@"content-length"] longLongValue];
	_isChunked=(header=[_headers objectForKey:@"transfer-encoding"]) && [header caseInsensitiveCompare:@"chunked"] == NSOrderedSame;
	_willClose=(header=[_headers objectForKey:@"Connection"]) && [header caseInsensitiveCompare:@"close"] == NSOrderedSame;	// will close after completing the request
	if(!_isChunked)	// ??? must we notify (partial) response before we send any data ???
		{
		NSHTTPURLResponse *response=[[[NSHTTPURLResponse alloc] _initWithURL:url headerFields:_headers andStatusCode:_statusCode] autorelease];
		[_currentRequest didReceiveResponse:response];
		}
	_readingBody = !(_statusCode/100 == 1 || _statusCode == 204 || _statusCode == 304 || [[request HTTPMethod] isEqualToString:@"HEAD"]);		// decide if we expect to receive a body
}

- (void) bodyReceived
{
#if 1
	NSLog(@"body received %@", self);
#endif
	_readingBody=NO;	// start over reading headers/trailer
	// apply MD5 checking [_headers objectForKey:@"Content-MD5"]
	// apply content-encoding (after MD5)
	if(!_isChunked)
		[self trailerReceived];	// there is no trailer if not chunked
}

- (void) trailerReceived
{
#if 1
	NSLog(@"trailers received %@", self);
#endif
	if(_isChunked)
		{ // notify all headers after receiving trailer
			NSHTTPURLResponse *response=[[[NSHTTPURLResponse alloc] _initWithURL:[[_currentRequest request] URL] headerFields:_headers andStatusCode:_statusCode] autorelease];
			[_currentRequest didReceiveResponse:response];
			_isChunked=NO;
		}
	[_currentRequest didFinishLoading];
	[_headers release];	// have been stored in NSHTTPURLResponse
	_headers=nil;
	[_currentRequest _setConnection:nil];	// has been processed
	[_currentRequest release];
	_currentRequest=nil;
	if(_shouldClose)
		[self endOfUseability];
	else if([_requestQueue count] > 0)
		[self startLoadingNextRequest];	// send next request from queue
}

- (void) processHeaderLine:(NSString *) line;
{ // process header line
	NSString *key, *val;
	NSRange colon;
#if 1
	NSLog(@"process header line %@", line);
#endif
	if([line length] == 0)
		{ // empty line received
			if(_isChunked)
				[self trailerReceived];
			else if(_headers)
				[self headersReceived];
			return;	// else CRLF before header - be tolerant according to chapter 19.3
		}
	if(!_headers)
		{ // should be/must be the header line
			unsigned major, minor;
			if(sscanf([line UTF8String], "HTTP/%u.%u %u", &major, &minor, &_statusCode) == 3)
				{ // response header line
					if(major != 1 || minor > 1)
						{
						[_currentRequest didFailWithError:[NSError errorWithDomain:@"Bad HTTP version received" code:0 userInfo:nil]];
						}
					_headers=[[NSMutableDictionary alloc] initWithCapacity:10];	// start collecting headers
#if 1
					NSLog(@"Received response: %@", line);
#endif
					return;	// process next line
				}
			else
				{
#if 1
				NSLog(@"Received instead of header line: %@", line);
#endif
				[_currentRequest didFailWithError:[NSError errorWithDomain:@"Invalid HTTP response" code:0 userInfo:nil]];
				[self endOfUseability];
				}
			return;	// process next line
		}
	colon=[line rangeOfString:@":"];
	if(colon.location == NSNotFound)
		return; // no colon found! Ignore to prevent DoS attacks...
	key=[[[line substringToIndex:colon.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];	// convert key to all lowercase
	val=[[line substringFromIndex:colon.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([_headers objectForKey:key])
		val=[NSString stringWithFormat:@"%@, %@", [_headers objectForKey:key], val];	// merge multiple headers with same key into a single one - comma separated
	[_headers setObject:val forKey:key];
	if([key isEqualToString:@"warning"])
		NSLog(@"HTTP Warning: %@", val);	// print on console log
#if 1
	NSLog(@"header: %@:%@", key, val);
#endif
}

- (void) handleInputEvent:(NSStreamEvent) event
{
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
		if(_readingBody && (!_isChunked || _chunkLength > 0))
			{
			if(_isChunked && _chunkLength < maxLength)
				maxLength=_chunkLength;	// limit to current chunk size
			if(_contentLength > 0 && _contentLength < maxLength)
				maxLength=_contentLength;	// limit to expected size
			}
		else
			maxLength=1;	// so that we don't miss the Content-Length: header entry even if it directly precedes the \r\n\r\nbody
		len=[_inputStream read:buffer maxLength:maxLength];
		if(len == 0)
			return;	// ignore (or when does this occur? - if EOF by server?)
		if(len <= 0)
			{
			NSDictionary *info=[NSDictionary
								dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:strerror(errno)], @"Error", nil];
#if 1
			NSLog(@"receive error %s", strerror(errno));
#endif
			[_currentRequest didFailWithError:[NSError errorWithDomain:@"receive error" code:errno userInfo:info]];
			[self endOfUseability];
			return;
			}
#if 0
		NSLog(@"received %d bytes", len);
#endif
		if(_readingBody)
			{
			if(_isChunked && _chunkLength == 0)
				{ // reading chunk size
#if 0
					NSLog(@"will process %02x into %@", buffer[0], _headerLine);
#endif
					if(buffer[0] == '\r')
						return;	// ignore CR
					if(buffer[0] == '\n')
						{ // decode chunk length
							if([_headerLine length] > 0)
								{ // there should follow a CRLF after the body resulting in a empty line
									NSScanner *sc=[NSScanner scannerWithString:_headerLine];
#if 1
									NSLog(@"chunk length=%@", _headerLine);
#endif
									_chunkLength=0;
									if(![sc scanHexInt:&_chunkLength])	// is hex coded (we even ignore an optional 0x)
										{
										NSLog(@"invalid chunk length %@", _headerLine);
										[_currentRequest didFailWithError:[NSError errorWithDomain:@"invalid chunk length" code:0 userInfo:0]];
										[self endOfUseability];
										return;
										}
									// may be followed by ; name=var
									if(_chunkLength == 0)
										[self bodyReceived];	// done reading body - continue with trailer
									[_headerLine setString:@""];	// has been processed
								}
						}
					else
						[_headerLine appendFormat:@"%c", buffer[0]&0xff];	// we should try to optimize that...
					return;
				}
			[_currentRequest didLoadData:[NSData dataWithBytes:buffer length:len]];	// notify
			if(_chunkLength > 0)
				_chunkLength-=len;	// if this becomes 0 we are looking for the next chunk length
			if(_contentLength > 0)
				{
				_contentLength -= len;
				if(_contentLength == 0)
					{ // we have received as much as expected
						[self bodyReceived];
					}
				}
			return;
			}
#if 0
		NSLog(@"will process %02x _lastChr=%02x into %@", buffer[0], _lastChr, _headerLine);
#endif
		if(_lastChr == '\n')
			{ // first character in new line received
				if(buffer[0] != ' ' && buffer[0] != '\t')
					{ // process what we have (even if empty)
						[self processHeaderLine:_headerLine];
						[_headerLine setString:@""];	// has been processed
					}
			}
		if(buffer[0] == '\r')
			return;	// ignore in headers
		if(buffer[0] != '\n')
			[_headerLine appendFormat:@"%c", buffer[0]&0xff];	// we should try to optimize that...
		_lastChr=buffer[0];
#if 0
		NSLog(@"did process %02x _lastChr=%02x into", buffer[0], _lastChr, _headerLine);
#endif
		return;
		}
		case NSStreamEventEndEncountered:
		{
#if 1
		NSLog(@"input connection closed by server: %@", self);
#endif
		if(!_readingBody)
			[_currentRequest didFailWithError:[NSError errorWithDomain:@"incomplete header received" code:0 userInfo:nil]];
		if([_headers objectForKey:@"content-length"])
			{
			if(_contentLength > 0)
				{
				[_currentRequest didFailWithError:[NSError errorWithDomain:@"connection closed by server while receiving body" code:0 userInfo:nil]];	// we did not receive the announced contentLength
				}
			}
		else
			[self bodyReceived];	// implicit content length defined by EOF
		[self endOfUseability];
		return;
		}
		default:
		break;
	}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [_inputStream streamError], event, _inputStream, self);
	[_currentRequest didFailWithError:[_inputStream streamError]];
	[self endOfUseability];
}

- (void) handleOutputEvent:(NSStreamEvent) event
{ // send header & body of current request (if any)
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
							NSDictionary *info=[NSDictionary
												dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:strerror(errno)], @"Error"];
#if 1
							NSLog(@"error while reading from HTTPHeader stream %s", strerror(errno));
#endif
							[_currentRequest didFailWithError:[NSError errorWithDomain:@"HTTPHeaderStream" code:errno userInfo:info]];
							[self endOfUseability];
							}
						else
							{
							[_outputStream write:buffer maxLength:len];	// send
#if 1
							NSLog(@"%d bytes header sent", len);
#endif
							}
						return;	// done sending next chunk
					}
#if 1
				NSLog(@"header completely sent");
#endif
				[_headerStream close];
				[_headerStream release];	// done sending header, continue with body (if available)
				_headerStream=nil;
			}
		if(_bodyStream)
			{ // we are still sending the body
				if([_bodyStream hasBytesAvailable])	// FIXME: if we send chunked this is not the correct indication and we should stall sending until new data becomes available
					{ // send next part until done
						int len=[_bodyStream read:buffer maxLength:sizeof(buffer)];	// read next block from stream
						if(len < 0)
							{
							NSDictionary *info=[NSDictionary
												dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:strerror(errno)], @"Error"];
#if 1
							NSLog(@"error while reading from HTTPBody stream %s", strerror(errno));
#endif
							[_currentRequest didFailWithError:[NSError errorWithDomain:@"HTTPBodyStream" code:errno userInfo:info]];
							[self endOfUseability];
							return;	// done
							}
						else
							{
							if(_sendChunked)
								{
								char chunkLen[32];
								sprintf(chunkLen, "%x\r\n", len);
								[_outputStream write:(unsigned char *) chunkLen maxLength:strlen(chunkLen)];	// send length
								[_outputStream write:buffer maxLength:len];	// send what we have
								[_outputStream write:(unsigned char *) "\r\n" maxLength:2];	// and a CRLF
#if 1
								NSLog(@"chunk with %d bytes sent\nHeader: %s", len, chunkLen);
#endif
								if(len != 0)
									return;	// more to send (at least a 0-length header)
								}
							else
								{
								[_outputStream write:buffer maxLength:len];	// send what we have
#if 1
								NSLog(@"%d bytes body sent", len);
#endif
								return;	// done
								}
							}
					}
#if 1
				NSLog(@"body completely sent");
#endif
				[_bodyStream close];	// close body stream (if open)
				[_bodyStream release];
				_bodyStream=nil;
				// we might send additional headers according to the protocol - but we have already sent them
				// this would only be useful if we want to allow the client to add/modify headers while generating the body stram
				// in that case we would have to mark all headers if they are sent before or after the chunked body and send only the minimum headers before
			}
		if(_shouldClose)
			{	// we have announced Connection: close
#if 1
				NSLog(@"can't keep connection alive because we announced Connection: close");
#endif
				[_outputStream close];
				[_outputStream release];
				_outputStream=nil;
			}
		else
			[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];	// unschedule until we send the next request
		return;
		}
		case NSStreamEventEndEncountered:
		if([_headerStream hasBytesAvailable])
			[_currentRequest didFailWithError:[NSError errorWithDomain:@"connection closed by server while sending header" code:errno userInfo:nil]];
		else if([_bodyStream hasBytesAvailable])
			[_currentRequest didFailWithError:[NSError errorWithDomain:@"connection closed by server while sending body" code:errno userInfo:nil]];
		else
			{
#if 1
			NSLog(@"server has disconnected - can't keep alive: %@", self);
#endif
			}
		[_headerStream close];
		[_headerStream release];	// done sending header
		_headerStream=nil;
		[_bodyStream close];	// close body stream (if open)
		[_bodyStream release];
		_bodyStream=nil;
		[self endOfUseability];
		return;
		default:
		break;
	}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [_outputStream streamError], event, _outputStream, self);
	[_currentRequest didFailWithError:[_outputStream streamError]];
	[self endOfUseability];
}

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event
{
#if 0
	NSLog(@"stream:%@ handleEvent:%x for:%@", stream, event, self);
#endif
	if(stream == _inputStream) 
		[self handleInputEvent:event];
	else if(stream == _outputStream)
		[self handleOutputEvent:event];
}

@end

@implementation _NSHTTPURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
{
	NSString *scheme = [[request URL] scheme];
	return [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request;
{
	NSURL *url=[request URL];
	NSString *frag=[url fragment];
	if([frag length] > 0)
		{ // map different fragments to same base file
			NSString *s=[url absoluteString];
			s=[s substringToIndex:[s length]-[frag length]];	// remove fragment
			return [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:s]] autorelease];
		}
	return request;
}

- (void) dealloc;
{
#if 1
	NSLog(@"dealloc %@", self);
#endif
	[self stopLoading];		// if still running
	[super dealloc];
}

- (NSString *) _uniqueKey;
{ // all requests with the same uniqueKey *can* be multiplexed over a kept-alive HTTP 1.1 channel
	NSURL *url=[_request URL];
	return [NSString stringWithFormat:@"%@://%@:%@", [url scheme], [url host], [url port]];	// we can ignore user&password since HTTP does
}

- (void) _setConnection:(_NSHTTPSerialization *) c; { _connection=c; }	// our shared connection
- (_NSHTTPSerialization *) _connection; { return _connection; }

- (void) _restartLoading
{
#if 1
	NSLog(@"_restartLoading %@", self);
#endif
	[_connection stopLoading:self];	// remove from current queue
	[[_NSHTTPSerialization serializerForProtocol:self] startLoading:self];	// and reschedule (on same or other some other queue)
}

- (void) startLoading;
{
	static NSDictionary *methods;
	if(_connection)
		return;	// already queued
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
	if(_cachedResponse)
		{
		/* FIXME:
		 if we have a cached response
		 and that one has an "Expires" date or a "Cache-Control" with a max-age parameter
		 and it is still valid,
		 directly respond from the cached response without contacting the server
		 check with [_request cachePolicy]
		 */
		}
	[[_NSHTTPSerialization serializerForProtocol:self] startLoading:self];	// add our request to (new) queue
}

- (void) stopLoading;
{
	[_connection stopLoading:self];	// interrupt and/or remove us from the queue
}

- (void) didFailWithError:(NSError *) error;
{ // forward to client as last message...
	[_client URLProtocol:self didFailWithError:error];
	[(NSObject *)_client release];
	_client=nil;
}

- (void) didLoadData:(NSData *) data;
{ // forward to client
	[_client URLProtocol:self didLoadData:data];
}

- (void) didFinishLoading;
{ // forward to client as last message...
	[_client URLProtocolDidFinishLoading:self];
	[(NSObject *)_client release];
	_client=nil;
}

- (void) didReceiveResponse:(NSHTTPURLResponse *) response;
{
	NSDictionary *headers=[response allHeaderFields];
	NSString *loc;
	switch([response statusCode])
	{
		case 100:
		return;	// continue - ignore
		case 401:
		{
		// FIXME: read auth challenge from HTTP headers
		NSURLAuthenticationChallenge *chall=nil;
		[_client URLProtocol:self didReceiveAuthenticationChallenge:chall];
		// retry or abort?
		return;
		}
		case 407:
		// notify client and add authentication info + repeat
		break;
		case 503:	// retry
		// check if within reasonable future (retry-after) and then repeat
		break;
		// case 206:	// optional
		case 304:
		[_client URLProtocol:self cachedResponseIsValid:_cachedResponse];	// will get data from cache
		[_client URLProtocol:self didLoadData:[_cachedResponse data]];	// and pass data from cache
		return;
	}
	if(([response statusCode]/100 == 3) && (loc=[headers objectForKey:@"Location"]))
		{ // redirect
			NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:loc relativeToURL:[_request URL]]];	// may be relative to current URL
			[_client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];	// this may trigger a retry for the new request
			return;
		}
	// FIXME: there are response-headers that control how the response should be cached, i.e. translate into cacheStoragePolicy
	[_client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:0];	// notify client
	
	/* how do we generate these:
	 - (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
	 */
	
}

- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	// FIXME
	// we should store each pair in a mutable array
	// and use them by HTTPSerialization on demand
	// but documentation says that it is possible to change them after download has started loading (and only delegate messages may arrive in the wrong thread)
	// therefore, we should just forward this to the HTTPSerialization objects
	// NOTE: latest documentation (10.7) appears to have removed this description
}

- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	// FIXME
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
{ // data:[<mediatype>][;base64],<data>
	NSURLResponse *r;
	NSString *mime=@"text/plain";
	NSString *encoding=@"US-ASCII";
	NSData *data;
	NSString *path=[[_request URL] resourceSpecifier];
	NSRange comma=[path rangeOfString:@","];	// position of the ,
	NSEnumerator *types;
	NSString *type;
	BOOL base64=NO;
	if(comma.location == NSNotFound)
		{
		[_client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"can't load data" 
																	   code:0
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [_request URL], @"URL",
																			 path, @"path", nil]
													]];
		return;
		}
	types=[[[path substringToIndex:comma.location] componentsSeparatedByString:@";"] objectEnumerator];
	while((type=[types nextObject]))
		{ // process mediatype etc.
		if([type isEqualToString:@"base64"])
			base64=YES;
		else if([type hasPrefix:@"charset="])
			encoding=[type substringFromIndex:8];
		else if([type length] > 0)
			mime=type;
		}
	path=[path substringFromIndex:comma.location+1];	// part after ,
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
