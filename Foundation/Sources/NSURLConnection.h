/*
    NSURLConnection.h
    mySTEP

  	H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

    Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
    Copyright (c) 2004 DSITRI. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURLResponse.h>

@class NSError;
@class NSCachedURLResponse;
@class NSURLAuthenticationChallenge;
@class NSURLRequest;
@class NSURLResponse;

@interface NSURLConnection : NSObject
{
	id _delegate;
	NSURLProtocol *_protocol;
	BOOL _done;
}

+ (BOOL) canHandleRequest:(NSURLRequest *) request;
+ (NSURLConnection *) connectionWithRequest:(NSURLRequest *) request delegate:(id) delegate;
+ (NSData *) sendSynchronousRequest:(NSURLRequest *) request returningResponse:(NSURLResponse **) response error:(NSError **) error;

- (void) cancel;
- (id) initWithRequest:(NSURLRequest *) request delegate:(id) delegate;
- (void) scheduleInRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;
- (void) start;
- (void) unscheduleFromRunLoop:(NSRunLoop *) runLoop forMode:(NSString *) mode;

@end

@interface NSObject (NSURLConnectionDelegate)

- (void) connection:(NSURLConnection *) conn didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) connection:(NSURLConnection *) conn didFailWithError:(NSError *) error;
- (void) connection:(NSURLConnection *) conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) connection:(NSURLConnection *) conn didReceiveData:(NSData *) data;
- (void) connection:(NSURLConnection *) conn didReceiveResponse:(NSURLResponse *) resp;
- (NSCachedURLResponse *) connection:(NSURLConnection *) conn willCacheResponse:(NSCachedURLResponse *) resp;
- (NSURLRequest *) connection:(NSURLConnection *) conn willSendRequest:(NSURLRequest *) req redirectResponse:(NSURLResponse *) resp;
- (void) connectionDidFinishLoading:(NSURLConnection *) conn;

@end
