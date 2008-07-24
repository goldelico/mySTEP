/*
    NSURLRequest.h
    mySTEP

  	H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

    Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
    Copyright (c) 2004 DSITRI. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/Foundation.h>

enum
{
	NSURLRequestUseProtocolCachePolicy = 0,
	NSURLRequestReloadIgnoringLocalCacheData = 1,
	NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4,
	NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,
	NSURLRequestReturnCacheDataElseLoad = 2,
	NSURLRequestReturnCacheDataDontLoad = 3,
	NSURLRequestReloadRevalidatingCacheData = 5
};

typedef NSUInteger NSURLRequestCachePolicy;

@interface NSURLRequest : NSObject <NSCopying, NSMutableCopying, NSCoding>
{
@public
	NSURL *_url;
	NSMutableDictionary *_headerFields;
	NSString *_method;
	NSTimeInterval _timeout;
	NSURLRequestCachePolicy	_policy;
	BOOL _handleCookies;
}


+ (NSURLRequest *) requestWithURL:(NSURL *) url;	// create request
+ (id) requestWithURL:(NSURL *) url 
		  cachePolicy:(NSURLRequestCachePolicy) policy 
	  timeoutInterval:(NSTimeInterval) timeout;

- (NSDictionary *) allHTTPHeaderFields;
- (NSURLRequestCachePolicy) cachePolicy;
- (NSData *) HTTPBody;
- (NSInputStream *) HTTPBodyStream;
- (NSString *) HTTPMethod;
- (BOOL) HTTPShouldHandleCookies;
- (id) initWithURL:(NSURL *) url;
- (id) initWithURL:(NSURL *) url cachePolicy:(NSURLRequestCachePolicy) policy timeoutInterval:(NSTimeInterval) timeout;
- (NSURL *) mainDocumentURL;
- (NSTimeInterval) interval;
- (NSURL *) URL;
- (NSString *) valueForHTTPHeaderField:(NSString *) field;

@end

@interface NSMutableURLRequest : NSURLRequest

- (void) addValue:(NSString *) value forHTTPHeaderField:(NSString *) field;
- (void) setAllHTTPHeaderFields:(NSDictionary *) headers;
- (void) setCachePolicy:(NSURLRequestCachePolicy) policy;
- (void) setHTTPBody:(NSData *) data;
- (void) setHTTPBodyStream:(NSInputStream *) stream;
- (void) setHTTPMethod:(NSString *) method;
- (void) setHTTPShouldHandleCookies:(BOOL) flag;
- (void) setMainDocumentURL:(NSURL *) url;
- (void) setTimeoutInterval:(NSTimeInterval) interval;
- (void) setURL:(NSURL *) url;
- (void) setValue:(NSString *) value forHTTPHeaderField:(NSString *) field;

@end