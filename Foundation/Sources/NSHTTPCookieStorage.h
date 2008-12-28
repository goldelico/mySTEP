/*
    NSHTTPCookieStorage.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
    Copyright (c) 2006 DSITRI. All rights reserved.
 
    Fabian Spillner, May 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSHTTPCookie.h>

@class NSMutableArray, NSMutableDictionary, NSDistributedLock, NSDate, NSTimer;

typedef enum _NSHTTPCookieAcceptPolicy
{
	NSHTTPCookieAcceptPolicyAlways=0,
	NSHTTPCookieAcceptPolicyNever,
	NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain
} NSHTTPCookieAcceptPolicy;

extern NSString *NSHTTPCookieStorageCookiesChangedNotification;
extern NSString *NSHTTPCookieStorageAcceptPolicyChangedNotification;

@interface NSHTTPCookieStorage : NSObject
{
	NSMutableDictionary *_cookies;
	NSDistributedLock *_lock;
	NSDate *_lastModification;
	NSHTTPCookieAcceptPolicy _cookieAcceptPolicy;
	NSTimer *_timer;
	BOOL _touched;
}

+ (NSHTTPCookieStorage *) sharedHTTPCookieStorage;

- (NSHTTPCookieAcceptPolicy) cookieAcceptPolicy;
- (NSArray *) cookies;
- (NSArray *) cookiesForURL:(NSURL *) url;
- (void) deleteCookie:(NSHTTPCookie *) cookie;
- (void) setCookie:(NSHTTPCookie *) cookie;
- (void) setCookieAcceptPolicy:(NSHTTPCookieAcceptPolicy) policy;
- (void) setCookies:(NSArray *) cookies forURL:(NSURL *) url mainDocumentURL:(NSURL *) mainURL;

@end
