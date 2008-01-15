//
//  NSHTTPCookie.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSHTTPCookie.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSValue.h>


@implementation NSHTTPCookie

// NSString *NSHTTPCookieCreated=@"Created";
NSString *NSHTTPCookieComment=@"Comment";
NSString *NSHTTPCookieCommentURL=@"CommentURL";
NSString *NSHTTPCookieDiscard=@"Discard";
NSString *NSHTTPCookieDomain=@"Domain";
NSString *NSHTTPCookieExpires=@"Expires";
NSString *NSHTTPCookieMaximumAge;
NSString *NSHTTPCookieName=@"Name";
NSString *NSHTTPCookieOriginURL=@"OriginalURL"; 
NSString *NSHTTPCookiePath=@"Path";
NSString *NSHTTPCookiePort=@"Port";
NSString *NSHTTPCookieSecure=@"Secure";
NSString *NSHTTPCookieValue=@"Value";
NSString *NSHTTPCookieVersion=@"Version";

+ (NSArray *) cookiesWithResponseHeaderFields:(NSDictionary *) fields
									   forURL:(NSURL *) url;
{
	// extract cookies from header fields (how are multiple cookies separated in the header fields???)
	// how do we convert date/time cookies to NSNumber/NSDate?
	return NIMP;
}

+ (id) cookieWithProperties:(NSDictionary *) properties;
{
	return [[[self alloc] initWithProperties:properties] autorelease];
}

+ (NSDictionary *) requestHeaderFieldsWithCookies:(NSArray *) cookies;
{
	NSString *s=nil;
	NSEnumerator *e=[cookies objectEnumerator];
	NSHTTPCookie *c;
	while((c=[e nextObject]))
		{
		// fixme: handle embedded ; characters
		NSString *ss=[NSString stringWithFormat:@"%@=%@", [c name], [c value]];
		if(s)
			s=[s stringByAppendingFormat:@"; %@", ss];
		else
			s=ss;	// first
		}
	if(s)
		return [NSDictionary dictionaryWithObject:s forKey:@"Cookie"];	// single header line
	else
		return [NSDictionary dictionary];	// empty
}

- (NSString *) comment; { return [_properties objectForKey:NSHTTPCookieComment]; }
- (NSURL *) commentURL; { return [_properties objectForKey:NSHTTPCookieCommentURL]; }
- (NSString *) domain; { return [_properties objectForKey:NSHTTPCookieDomain]; }
- (NSDate *) expiresDate; { return [_properties objectForKey:NSHTTPCookieExpires]; }
- (BOOL) isSecure; { return [[_properties objectForKey:NSHTTPCookieSecure] isEqualToString:@"TRUE"]; }
- (BOOL) isSessionOnly; { NIMP; return NO; }
- (NSString *) name; { return [_properties objectForKey:NSHTTPCookieName]; }
- (NSString *) path; { return [_properties objectForKey:NSHTTPCookiePath]; }
- (NSArray *) portList; { return [[_properties objectForKey:NSHTTPCookiePort] componentsSeparatedByString:@","]; }
- (NSDictionary *) properties; { return _properties; }
- (NSString *) value; { return [_properties objectForKey:NSHTTPCookieValue]; }
- (unsigned) version; { return [[_properties objectForKey:NSHTTPCookieVersion] unsignedIntValue]; }

- (id) initWithProperties:(NSDictionary *) properties;
{
	if((self=[super init]))
		{
		if([[properties objectForKey:NSHTTPCookieName] length] < 1 ||
		   ![properties objectForKey:NSHTTPCookieValue] ||
		   (![properties objectForKey:NSHTTPCookieOriginURL] && ![properties objectForKey:NSHTTPCookieDomain]))
			{ // this is a minimalistic check
			[self release];
			return nil;
			}
		_properties=[properties retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	return [self retain];	// we are not really mutable
}

- (void) dealloc;
{
	[_properties release];
	[super dealloc];
}

// isEqual???
// based on URL & name

// coding???

@end
