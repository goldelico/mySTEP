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
		*(_response=response)=nil;
		*(_error=error)=nil;
		*(_data=data)=nil;
		_done=NO;
		}
	return self;
}

- (void) dealloc
{
#if 1
	NSLog(@"dealloc %@", self);
#endif
	[*_data autorelease];	// put in ARP that is active when we dealloc this object
	[*_error autorelease];
	[*_response autorelease];
	[super dealloc];
}

- (void) run;
{ // NOTE: runMode may have an internal ARP. Therefore, objects allocated in callbacks are already autoreleased when runMode returns
#if 1
	NSLog(@"loop for data %@", self);
#endif
	while(!_done)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]; // run loop until we are finished (or we could introduce some timeout!)
#if 1
	NSLog(@"data received %@", self);
#endif
}

// notification handler

- (void) connection:(NSURLConnection *) conn didReceiveResponse:(NSURLResponse *) resp; { [*_response release]; *_response=[resp retain]; }
- (void) connection:(NSURLConnection *) conn didFailWithError:(NSError *) error; { *_error=[error retain]; [*_data release]; *_data=nil; _done=YES; }
- (void) connectionDidFinishLoading:(NSURLConnection *) conn; { _done=YES; }

- (void) connection:(NSURLConnection *) conn didReceiveData:(NSData *) data;
{
#if 0
	NSLog(@"did receive %lu bytes %@", [data length], self);
#endif
	if(!*_data)
		*_data=[data mutableCopy];	// first data block
	else
		[*_data appendData:data];	// n-th
#if 0
	NSLog(@"  have now %lu bytes in %p", [*_data length], *_data);
#endif
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
	NSMutableData *data;
	NSError *dummy;
	_NSURLConnectionDataCollector *dc=[[_NSURLConnectionDataCollector alloc] initWithDataPointer:&data responsePointer:response errorPointer:error?error:&dummy];
	NSURLConnection *c=[self connectionWithRequest:request delegate:dc];
	[c start];	// start loading
	[dc run];		// collect
	[dc release];
#if 1
	NSLog(@"received data: %p (%lu bytes)", data, [data length]);
#endif
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
		NSURLResponse *cachedResponse=[[NSURLCache sharedURLCache] cachedResponseForRequest:request];
		if(!cachedResponse && [request cachePolicy] == NSURLRequestReturnCacheDataDontLoad)
			{ [self release]; return nil; }
		_delegate=delegate;
		_protocol=[[NSURLProtocol alloc] initWithRequest:request cachedResponse:cachedResponse client:(id <NSURLProtocolClient>) self];
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
	NSLog(@"warning: -[NSURLConnection scheduleInRunLoop:forMode:] is not recommended unless you know what you do!");
	[_protocol scheduleInRunLoop:runLoop forMode:mode];
}

- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
{
	NSLog(@"warning: -[NSURLConnection unscheduleFromRunLoop:forMode:] is not recommended unless you know what you do!");
	[_protocol unscheduleFromRunLoop:runLoop forMode:mode];
}

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
	NSURLRequest *r=[_delegate connection:self willSendRequest:request redirectResponse:redirectResponse];	// allow to modify
	if(r)
		{
		[_protocol autorelease];	// release previous protocol handler and start a new one
		_protocol=[[NSURLProtocol alloc] initWithRequest:r cachedResponse:[[NSURLCache sharedURLCache] cachedResponseForRequest:r] client:(id <NSURLProtocolClient>) self];
#if 1
		NSLog(@"redirected to protocol %@", _protocol);
#endif
		// check in redirect response if we should wait some time ("retry-after")
		[_protocol startLoading];
		}
}

- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
{
	[_delegate connection:self didFailWithError:error];
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
{
#if 0	// FIXME
	if(policy != NSURLCacheStorageNotAllowed)
		{ // create a cached response and try to store
			NSData *data=nil;	// where do we get that from unless we collect all data???
			NSCachedURLResponse *cachedResponse=[[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:policy];
			[[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:[_protocol request]];
			[cachedResponse release];
		}
#endif
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
- (void) connection:(NSURLConnection *) conn didFailWithError:(NSError *) error; { NIMP; }	// otherwise the delegate can't work properly
- (void) connection:(NSURLConnection *) conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge; { return; }
- (void) connection:(NSURLConnection *) conn didReceiveData:(NSData *) data; { NIMP; }	// otherwise the delegate can't work properly
- (void) connection:(NSURLConnection *) conn didReceiveResponse:(NSURLResponse *) resp; { return; }
- (NSCachedURLResponse *) connection:(NSURLConnection *) conn willCacheResponse:(NSCachedURLResponse *) resp; { return resp; }
- (NSURLRequest *) connection:(NSURLConnection *) conn willSendRequest:(NSURLRequest *) req redirectResponse:(NSURLResponse *) resp; { return req; }
- (void) connectionDidFinishLoading:(NSURLConnection *) conn; { return; }

@end

