//
//  NSURLConnection.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSURLConnection.h>

@interface _NSURLConnectionDataCollector : NSObject <NSURLProtocolClient>
{
	NSURLConnection *_connection;
	NSMutableData *_data;
	NSError **_error;
	NSURLResponse **_response;
	BOOL _done;
}

- (void) _setConnection:(NSURLConnection *) c;
- (BOOL) _done;
- (NSData *) _getDataAndRelease;

@end

@implementation _NSURLConnectionDataCollector

- (id) initWithResponsePointer:(NSURLResponse **) response andErrorPointer:(NSError **) error;
{
	if((self=[super init]))
		{
		_response=response;
		_error=error;
		}
	return self;
}

- (void) dealloc;
{
	[_data release];
	[super dealloc];
}

- (void) _setConnection:(NSURLConnection *) c; { _connection=c; }
- (BOOL) _done; { return _done; }
- (NSData *) _getDataAndRelease; { NSData *d=_data; [self release]; return d; }

// notification handler

- (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto wasRedirectedToRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
{
	*_error=error;
	_done=YES;
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
{
	*_response=response;
}

- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;
{
	_done=YES;
}

- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
{
	if(!_data)
		_data=[data mutableCopy];
	else
		[_data appendData:data];
}

@end

@implementation NSURLConnection

+ (BOOL) canHandleRequest:(NSURLRequest *) request;
{
	return [NSURLProtocol canInitWithRequest:request];
}

+ (NSURLConnection *) connectionWithRequest:(NSURLRequest *) request delegate:(id) delegate;
{
#if 0
	NSLog(@"NSURLConnection connectionWithRequest:%@", request);
#endif
	return [[[self alloc] initWithRequest:request delegate:delegate startImmediately:YES] autorelease];
}

+ (NSData *) sendSynchronousRequest:(NSURLRequest *) request returningResponse:(NSURLResponse **) response error:(NSError **) error;
{
	_NSURLConnectionDataCollector *dc=[[_NSURLConnectionDataCollector alloc] initWithResponsePointer:response andErrorPointer:error];
	NSURLConnection *c=[self connectionWithRequest:request delegate:dc];
	[dc _setConnection:c];
	while(![dc _done])
		; // run loop until we are finished
	return [dc _getDataAndRelease];
}

- (id) initWithRequest:(NSURLRequest *) request delegate:(id) delegate;
{
	return [self initWithRequest:request delegate:delegate startImmediately:YES];
}

- (id) initWithRequest:(NSURLRequest *) request delegate:(id) delegate startImmediately:(BOOL) flag;
{
	self=[super init];
#if 0
	NSLog(@"%@ initWithRequest:%@ delegate:%@", self, request, delegate);
#endif
	if(self)
		{
		_delegate=delegate;
		_protocol=[[NSURLProtocol alloc] initWithRequest:request cachedResponse:nil client:(id <NSURLProtocolClient>) self];
#if 0
		NSLog(@"  -> protocol %@", _protocol);
#endif
			if(flag)
				[self start];	// and start loading
		}
	return self;
}

- (void) dealloc;
{
	[_protocol release];
	[super dealloc];
}

- (void) cancel;
{ // stop loading
	[_protocol stopLoading];
}

- (void) start;
{ // start loading
	[_protocol startLoading];
}

- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	[_protocol scheduleInRunLoop:runLoop forMode:mode];
}

- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	[_protocol unscheduleFromRunLoop:runLoop forMode:mode];
}

// notification handlers just forward those our client wants to know

- (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto wasRedirectedToRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
{
	NSURLRequest *r=[_delegate connection:self willSendRequest:request redirectResponse:redirectResponse];
	if(!r)
		[proto stopLoading];
	NSLog(@"wasRedirectedToRequest:%@", request);
	// send new request for r
}

- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
{
	[_delegate connection:self didFailWithError:error];
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
{
	[_delegate connection:self didReceiveResponse:response];
}

- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;
{
	[_delegate connectionDidFinishLoading:self];
}

- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
{
	[_delegate connection:self didReceiveData:data];
}

@end

@implementation NSObject (NSURLConnectionDelegate)

- (void) connection:(NSURLConnection *) conn didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge; { return; }
- (void) connection:(NSURLConnection *) conn didFailWithError:(NSError *) error; { NIMP; }
- (void) connection:(NSURLConnection *) conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge; { return; }
- (void) connection:(NSURLConnection *) conn didReceiveData:(NSData *) data; { NIMP; }
- (void) connection:(NSURLConnection *) conn didReceiveResponse:(NSURLResponse *) resp; { NIMP; }
- (NSCachedURLResponse *) connection:(NSURLConnection *) conn willCacheResponse:(NSCachedURLResponse *) resp; { return resp; }
- (NSURLRequest *) connection:(NSURLConnection *) conn willSendRequest:(NSURLRequest *) req redirectResponse:(NSURLResponse *) resp; { return req; }
- (void) connectionDidFinishLoading:(NSURLConnection *) conn; { return; }

@end

