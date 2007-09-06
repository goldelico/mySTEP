//
//  NSHTTPCookieStorage.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSHTTPCookieStorage.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSValue.h>

// FIXME: we must find a mechanism where several processes access the shared cookie storage => lock file...

#define COOKIE_DATABASE @"~/Library/Cookies/Cookies.plist"	// Array of Dictionaries

@implementation NSHTTPCookieStorage

NSString *NSHTTPCookieStorageCookiesChangedNotification=@"NSHTTPCookieStorageCookiesChangedNotification";
NSString *NSHTTPCookieStorageAcceptPolicyChangedNotification=@"NSHTTPCookieStorageAcceptPolicyChangedNotification";

+ (NSHTTPCookieStorage *) sharedHTTPCookieStorage;
{
	static NSHTTPCookieStorage *_shared;
	if(!_shared)
		_shared=[[self alloc] init];
	return _shared;
}

- (void) _sync;
{
	NSMutableArray *a=[NSMutableArray arrayWithCapacity:[_cookies count]];
	NSEnumerator *e=[_cookies objectEnumerator];
	NSHTTPCookie *cookie;
	while((cookie=[e nextObject]))
		[a addObject:[cookie properties]];
	[a writeToFile:COOKIE_DATABASE atomically:YES];	// should we write a binary property list???
	// post a global NSHTTPCookieStorageCookiesChangedNotification so that other processes can read back the database
}

- (void) _touch;
{
	// cancel performWithDelay:
	// performWithDelay:1-2 seconds to call _sync
}

- (NSArray *) cookies;
{
	if(!_cookies)
		{ // read cookies from file
		NSArray *cookies=[NSArray arrayWithContentsOfFile:COOKIE_DATABASE];
		NSEnumerator *e;
		NSDictionary *prop;
		_cookies=[[NSMutableArray alloc] initWithCapacity:[cookies count]];
		e=[cookies objectEnumerator];
		while((prop=[e nextObject]))
			[_cookies addObject:[NSHTTPCookie cookieWithProperties:prop]];
		}
	return _cookies;
}

- (NSArray *) cookiesForURL:(NSURL *) url;
{
	// filter by URL
	return NIMP;
}

- (void) deleteCookie:(NSHTTPCookie *) cookie;
{ // compare cookie and delete if found
	[_cookies removeObject:cookie];	// this will call isEqual to locate the matching cookie
	[self _touch];
	NIMP;
}

- (void) setCookie:(NSHTTPCookie *) cookie;
{
	// look for duplicates and apply policy
	[self _touch];
	NIMP;
}

- (void) setCookies:(NSArray *) cookies forURL:(NSURL *) url mainDocumentURL:(NSURL *) mainURL;
{
	// look for duplicates and apply policy
	[self _touch];
	NIMP;
}

- (NSHTTPCookieAcceptPolicy) cookieAcceptPolicy; { return _cookieAcceptPolicy; }
- (void) setCookieAcceptPolicy:(NSHTTPCookieAcceptPolicy) policy; { _cookieAcceptPolicy=policy; }

- (id) init;
{
	if((self=[super init]))
		{
		[self cookies];	// load database
		}
	return self;
}

- (void) dealloc;
{
	// if touched, sync
	[_cookies release];
	[super dealloc];
}

@end
