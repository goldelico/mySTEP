//
//  NSURLHandle.m
//  mySTEP
//
//  this class is deprecated in MacOS X 10.4 - but we still need it for the implementation of e.g. [NSData dataWithContentsOfURL:]
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSURLHandle.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURLProtocol.h>
#import "NSPrivate.h"

NSString *const NSHTTPPropertyStatusCodeKey=@"HTTPPropertyStatusCode";
NSString *const NSHTTPPropertyStatusReasonKey=@"HTTPPropertyStatusReason";
NSString *const NSHTTPPropertyServerHTTPVersionKey=@"HTTPPropertyServerHTTPVersion";
NSString *const NSHTTPPropertyRedirectionHeadersKey=@"HTTPPropertyRedirectionHeaders";
NSString *const NSHTTPPropertyErrorPageDataKey=@"HTTPPropertyErrorPageData";

@implementation NSURLHandle

+ (NSURLHandle *) cachedHandleForURL:(NSURL *) url;
{
	return NIMP;
}

+ (BOOL) canInitWithURL:(NSURL *) url;
{
	return [NSURLProtocol canInitWithRequest:[NSURLRequest requestWithURL:url]];
}

+ (void) registerURLHandleClass:(Class) urlHandleSubclass; { NIMP; }	// we do not implement handler classes

+ (Class) URLHandleClassForURL:(NSURL *) url; { return self; }	// I handle everything myself

- (void) addClient:(id <NSURLHandleClient>) client; { [_clients addObject:client]; }

- (NSData *) availableResourceData; { return _resourceData; }

- (void) backgroundLoadDidFailWithReason:(NSString *) reason;
{
	ASSIGN(_resourceData, nil);
	_status=NSURLHandleLoadFailed;
	ASSIGN(_failure, reason);
	// notify clients
}

- (void) beginLoadInBackground;
{
	_status=NSURLHandleLoadInProgress;
	// notify clients
}

- (void) cancelLoadInBackground;
{
	[_protocol stopLoading];
	[self backgroundLoadDidFailWithReason:@"cancelled"];
	// notify clients
}

- (void) didLoadBytes:(NSData *) newData loadComplete:(BOOL) loadComplete;
{
	// notify clients
	if(newData)
		{
		if(!_resourceData && _expectedDataLength > 0)
			;	// we shuld preallocate memory according to expected content length
		if(_resourceData)
			[_resourceData appendData:newData];
		else
			_resourceData=[newData mutableCopy];		// first block
		}
	if(loadComplete)
		[self endLoadInBackground];
}

- (void) endLoadInBackground;
{
	_status=NSURLHandleLoadSucceeded;
	/* cache data here */
}

- (long long) expectedResourceDataSize; { return _expectedDataLength; }

- (NSString *) failureReason; { return _failure; }

- (void) flushCachedData; { NIMP; }

- (id) initWithURL:(NSURL *) url cached:(BOOL) cached;
{
	if((self=[super init]))
		{
		NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url cachePolicy:cached?NSURLRequestUseProtocolCachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
		_expectedDataLength=-1;	// not yet known
		_protocol=[[NSURLProtocol alloc] initWithRequest:request cachedResponse:nil client:(id <NSURLProtocolClient>) self];	// we will handle that
		}
	return self;
}

- (void) dealloc;
{
	[_failure release];
	[_protocol release];
	[_resourceData release];
	[super dealloc];
}

- (void) loadInBackground;
{
	if(_status == NSURLHandleNotLoaded)
		; // error
	[self beginLoadInBackground];
	[_protocol startLoading];
}

- (NSData *) loadInForeground;
{
	if(_status != NSURLHandleNotLoaded)
		; // error
	[self loadInBackground];
	while(_status == NSURLHandleLoadInProgress)
		;	// run loop here
	return _resourceData;
}

- (id) propertyForKey:(NSString*)propertyKey; { return NIMP; }

- (id) propertyForKeyIfAvailable:(NSString*)propertyKey; { return NIMP; }

- (void) removeClient:(id <NSURLHandleClient>)client; { [_clients removeObject:client]; }

- (NSData *) resourceData;
{
	// look into cache
	if(_status == NSURLHandleNotLoaded)
		[self loadInForeground];
	return _resourceData;
}

- (NSURLHandleStatus) status; { return _status; }

- (BOOL) writeData:(NSData *) data;
{
	NSMutableURLRequest *request=(NSMutableURLRequest *) [_protocol request];
	if(_status != NSURLHandleNotLoaded)
		return NO; // error
	[request setHTTPBody:data];
	[request setHTTPMethod:@"PUT"];
	[_protocol startLoading];
	while(_status == NSURLHandleLoadInProgress)
		;	// run loop here
	return _status == NSURLHandleLoadSucceeded;
}

- (BOOL) writeProperty:(id) propertyValue forKey:(NSString *) propertyKey;
{
	// CHECKME: or does this handle NSURLProtocol's properties?
	NSMutableURLRequest *request=(NSMutableURLRequest *) [_protocol request];
	[request addValue:propertyValue forHTTPHeaderField:propertyKey];
	return YES;
}

// NSURLProtocolClient methods

// - (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
// - (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;

- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
{
}

- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
{
	[self didLoadBytes:data loadComplete:NO];
}

// - (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
{
	// header arrived
	_expectedDataLength=[response expectedContentLength];
}

- (void) URLProtocol:(NSURLProtocol *) proto wasRedirectedToRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
{
	// should we redirect?
}

- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;
{
	[self didLoadBytes:nil loadComplete:YES];
}

@end
