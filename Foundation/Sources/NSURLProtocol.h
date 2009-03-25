/*
    NSURLProtocol.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
    Copyright (c) 2006 DSITRI. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be coompatible to 10.5
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSURLCache.h>

@class NSData;
@class NSError;
@class NSURLAuthenticationChallenge;
@class NSURLProtocol;
@class NSURLRequest, NSMutableURLRequest;
@class NSURLResponse;

@protocol NSURLProtocolClient

- (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
- (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
- (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
- (void) URLProtocol:(NSURLProtocol *) proto wasRedirectedToRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;

@end

@interface NSURLProtocol : NSObject
{
	NSCachedURLResponse *_cachedResponse;
	id <NSURLProtocolClient> _client;
	NSURLRequest *_request;
}

+ (BOOL) canInitWithRequest:(NSURLRequest *) request;
+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *) request;
+ (id) propertyForKey:(NSString *) key inRequest:(NSURLRequest *) request;
+ (BOOL) registerClass:(Class) protocolClass;
+ (void) removePropertyForKey:(NSString *) key inReq:(NSMutableURLRequest *) req;
+ (BOOL) requestIsCacheEquivalent:(NSURLRequest *) a toRequest:(NSURLRequest *) b;
+ (void) setProperty:(id) value forKey:(NSString *) key inRequest:(NSMutableURLRequest *) request;
+ (void) unregisterClass:(Class) protocolClass;

- (NSCachedURLResponse *) cachedResponse;
- (id <NSURLProtocolClient>) client;
- (id) initWithRequest:(NSURLRequest *) request
		cachedResponse:(NSCachedURLResponse *) cachedResponse
				client:(id <NSURLProtocolClient>) client;
- (NSURLRequest *) request;
- (void) startLoading;
- (void) stopLoading;

@end
