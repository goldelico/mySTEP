//
//  NSHTTPCookieStorage.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSHTTPCookieStorage.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDistributedLock.h>
#import <Foundation/NSTimer.h>

#define COOKIE_DATABASE @"~/Library/Cookies/Cookies.plist"	// Array of Dictionaries
#define COOKIE_DATABASE_LOCK COOKIE_DATABASE@".lock"

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
	BOOL changed=NO;
	while(![_lock tryLock])
		sleep(1);	// we could also skip this sync attempt and modify the timer by some random value
	if(!_cookies || [[[[NSFileManager defaultManager] fileAttributesAtPath:COOKIE_DATABASE traverseLink:YES] fileModificationDate] compare:_lastModification] == NSOrderedDescending)
			{ // update local cookies (if added or changed externally)
				NSArray *a=[NSArray arrayWithContentsOfFile:COOKIE_DATABASE];	// read all properties
				NSEnumerator *e=[a objectEnumerator];
				NSDictionary *props;
				if(!_cookies)
						_cookies=[[NSMutableDictionary alloc] initWithCapacity:100];
				while((props=[e nextObject]))
						{ // merge changes
							NSString *key=[NSString stringWithFormat:@"%@/%@/%@", [props objectForKey:NSHTTPCookieDomain], [props objectForKey:NSHTTPCookiePath], [props objectForKey:NSHTTPCookieName]];
							NSHTTPCookie *cookie=[_cookies objectForKey:key];
							if(cookie)
									{
							// if we already know this cookie and have changed it locally, keep local copy
							// otherwise apply external change (and set changed) or add
							// so that the latest version survives - set _touched flag if we have to write any changes
									}
							cookie=[NSHTTPCookie cookieWithProperties:props];	// create a new one
							[_cookies setObject:cookie forKey:key];	// add to database
						}
			}
	if(_touched || !_lastModification)
			{
				NSMutableArray *a=[NSMutableArray arrayWithCapacity:[_cookies count]];
				NSEnumerator *e=[_cookies objectEnumerator];
				NSHTTPCookie *cookie;
				while((cookie=[e nextObject]))
					[a addObject:[cookie properties]];	// just save the properties
				[a writeToFile:COOKIE_DATABASE atomically:YES];	// should we write a binary property list???
				_lastModification=[[[[NSFileManager defaultManager] fileAttributesAtPath:COOKIE_DATABASE traverseLink:YES] fileModificationDate] retain];	// modified
			}
	[_lock unlock];
	if(changed)
		[[NSNotificationCenter defaultCenter] postNotificationName:NSHTTPCookieStorageCookiesChangedNotification object:self];
}

- (NSArray *) cookies;
{
	if(!_cookies)
		[self _sync];
	return [_cookies allValues];
}

- (NSArray *) cookiesForURL:(NSURL *) url;
{
	NSMutableArray *r=[NSMutableArray arrayWithCapacity:[[self cookies] count]];
	NSEnumerator *c=[_cookies objectEnumerator];
	NSHTTPCookie *cookie;
	while((cookie=[c nextObject]))
			{
				NSString *domain=[cookie domain];
				NSString *path;
				NSArray *portList;
				if([domain hasPrefix:@"."])
						{
							if(![[url host] hasSuffix:domain])
								continue;	// does not match suffix
						}
				else if(![[url host] isEqualToString:domain])
					continue;	// does not match exact domain
				path=[cookie path];
				if(![path isEqualToString:@"/"] && ![[url path] isEqualToString:path])
					continue;	// neither "all paths" nor specific path
				if([cookie isSecure] && ![[url scheme] hasSuffix:@"s"])
					continue;	// not requested by secure protocol
				if((portList=[cookie portList]) && ![portList containsObject:[url port]])
					continue;	// no match with port list
				[r addObject:cookie];	// exact match
			}
	return r;
}

- (void) deleteCookie:(NSHTTPCookie *) cookie;
{ // compare cookie and delete if found
	[_cookies removeObjectForKey:[NSString stringWithFormat:@"%@/%@/%@", [cookie domain], [cookie path], [cookie name]]];
	// Hm. what if the cookie was added/deleted locally and added externally before we did sync?
	_touched=YES;
}

- (void) setCookie:(NSHTTPCookie *) cookie;
{
	NSString *key;
	if(_cookieAcceptPolicy == NSHTTPCookieAcceptPolicyNever)
		return;
	key=[NSString stringWithFormat:@"%@/%@/%@", [cookie domain], [cookie path], [cookie name]];
	if(!_cookies)
		[self _sync];
	[_cookies setObject:cookie forKey:key];
	_touched=YES;
}

- (void) setCookies:(NSArray *) cookies forURL:(NSURL *) url mainDocumentURL:(NSURL *) mainURL;
{
	NSEnumerator *c;
	NSHTTPCookie *cookie;
	if(_cookieAcceptPolicy == NSHTTPCookieAcceptPolicyNever)
		return;
	c=[_cookies objectEnumerator];
	while((cookie=[c nextObject]))
			{
				// [cookie setMainDocumentURL:mainURL]
				[self setCookie:cookie];
			}
}

- (NSHTTPCookieAcceptPolicy) cookieAcceptPolicy; { return _cookieAcceptPolicy; }

- (void) setCookieAcceptPolicy:(NSHTTPCookieAcceptPolicy) policy;
{
	if(_cookieAcceptPolicy != policy)
			{
				_cookieAcceptPolicy=policy;
				_touched=YES;
			}
}

- (id) init;
{
	if((self=[super init]))
		{
			_lock=[[NSDistributedLock alloc] initWithPath:COOKIE_DATABASE_LOCK];
			_timer=[[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(_sync) userInfo:nil repeats:YES] retain];
		}
	return self;
}

- (void) dealloc;
{
	[_timer invalidate];
	[_timer release];
	if(_touched)
		[self _sync];	// final sync
	[_lock release];
	[_cookies release];
	[_lastModification release];
	[super dealloc];
}

@end
