//
//  NSHTTPCookie.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSObject.h>

@class NSArray;
@class NSDate;
@class NSDictionary;
@class NSURL;

extern NSString *NSHTTPCookieComment;
extern NSString *NSHTTPCookieCommentURL;
extern NSString *NSHTTPCookieDiscard;
extern NSString *NSHTTPCookieDomain; 
extern NSString *NSHTTPCookieExpires; 
extern NSString *NSHTTPCookieMaximumAge;
extern NSString *NSHTTPCookieName;
extern NSString *NSHTTPCookieOriginURL; 
extern NSString *NSHTTPCookiePath;
extern NSString *NSHTTPCookiePort;
extern NSString *NSHTTPCookieSecure;
extern NSString *NSHTTPCookieValue;
extern NSString *NSHTTPCookieVersion;

@interface NSHTTPCookie : NSObject <NSCopying>
{
	NSDictionary *_properties;
}

+ (NSArray *) cookiesWithResponseHeaderFields:(NSDictionary *) fields
									   forURL:(NSURL *) url;
+ (id) cookieWithProperties:(NSDictionary *) properties;
+ (NSDictionary *) requestHeaderFieldsWithCookies:(NSArray *) cookies;

- (NSString *) comment;
- (NSURL *) commentURL;
- (NSString *) domain;
- (NSDate *) expiresDate;
- (id) initWithProperties:(NSDictionary *) properties;
- (BOOL) isSecure;
- (BOOL) isSessionOnly;
- (NSString *) name;
- (NSString *) path;
- (NSArray *) portList;
- (NSDictionary *) properties;
- (NSString *) value;
- (unsigned) version;

@end
