//
//  NSURLConnection.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 DSITRI. All rights reserved.
//

#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURLProtocol.h>

@interface _NSURLConnectionDataCollector : NSObject // used as internal delegate for synchronous requests
{
	NSMutableData **_data;
	NSError **_error;
	NSURLResponse **_response;
	BOOL _done;
}

- (id) initWithDataPointer:(NSMutableData **) data responsePointer:(NSURLResponse **) response errorPointer:(NSError **) error;
- (void) run;

@end

@implementation _NSURLConnectionDataCollector

- (id) initWithDataPointer:(NSMutableData **) data responsePointer:(NSURLResponse **) response errorPointer:(NSError **) error;
{
	if((self=[super init]))
		{
			_response=response;
			*response=nil;
			_error=error;
			*error=nil;
			_data=data;
			*data=nil;
			_done=NO;
		}
	return self;
}

- (void) run;
{
		while(!_done)
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]; // run loop until we are finished (or we could introduce some timeout!)
}

// notification handler

- (void) connection:(NSURLConnection *) conn didReceiveResponse:(NSURLResponse *) resp; { *_response=resp; }
- (void) connection:(NSURLConnection *) conn didFailWithError:(NSError *) error; { *_error=error; *_data=nil; _done=YES; }
- (void) connectionDidFinishLoading:(NSURLConnection *) conn; { _done=YES; }

- (void) connection:(NSURLConnection *) conn didReceiveData:(NSData *) data;
{
	if(!*_data)
		*_data=[[data mutableCopy] autorelease];
	else
		[*_data appendData:data];
}

#if 0	// not required!!!
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
#endif

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
	NSMutableData *data;
	NSError *dummy;
	_NSURLConnectionDataCollector *dc=[[_NSURLConnectionDataCollector alloc] initWithDataPointer:&data responsePointer:response errorPointer:error?error:&dummy];
	NSURLConnection *c=[self connectionWithRequest:request delegate:dc];
	[dc run];
	[dc release];
	return data;
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
// do we really need this?

- (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	[_delegate connection:self didReceiveAuthenticationChallenge:chall];
}

- (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	[_delegate connection:self didCancelAuthenticationChallenge:chall];
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

