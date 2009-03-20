//
//  NSHTTPCookie.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSHTTPCookie.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDate.h>


@implementation NSHTTPCookie

// NSString *NSHTTPCookieCreated=@"Created";	// this one should exist... also to help NSCookieStorage to handle merges
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

+ (NSArray *) cookiesWithResponseHeaderFields:(NSDictionary *) fields forURL:(NSURL *) url;
{
	// Set-Cookie: <name>=<value>[; <name>=<value>]...	[; expires=<date>][; domain=<domain_name>] [; path=<some_path>][; secure]
	// extract cookies from header fields (how are multiple cookies separated in the header fields???)
	// lines without cookies are ignored
	// how do we convert date/time cookies to NSNumber/NSDate?
	// "DD-MMM-YYYY HH:MM:SS GMT"
	return NIMP;
}

+ (id) cookieWithProperties:(NSDictionary *) properties;
{
	return [[[self alloc] initWithProperties:properties] autorelease];
}

+ (NSDictionary *) requestHeaderFieldsWithCookies:(NSArray *) cookies;
{ // create request headers
	NSString *s=nil;
	NSEnumerator *e=[cookies objectEnumerator];
	NSHTTPCookie *c;
	while((c=[e nextObject]))
		{
		NSString *ss=[NSString stringWithFormat:@"%@=%@", [c name], [c value]];	// On MacOS this method is not protected against = and ; characters in cookie name or value - only \n can't occur
		if(s)
			s=[s stringByAppendingFormat:@"; %@", ss];
		else
			s=ss;	// first
		}
	if(s)
		return [NSDictionary dictionaryWithObject:s forKey:@"Cookie"];	// put them all into a single header line
	else
		return [NSDictionary dictionary];	// empty
}

/*
 - (NSString *) description
 {
			version:0 name:@"name with" value:@"cookie value with ;" expiresDate:@"(null)" created:@"259183734.953839" sessionOnly:TRUE domain:@"www.origin.org" path:@"/path" secure:FALSE comment:@"(null)" commentURL:@"(null)" portList:(null)
 }
 */

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
			// FIXME: check and set defaults according to definition of the properties contants
		if([[properties objectForKey:NSHTTPCookieName] length] < 1 ||
		   ![properties objectForKey:NSHTTPCookieValue] ||
		   ![properties objectForKey:NSHTTPCookiePath] ||
		   ![properties objectForKey:NSHTTPCookieDomain] ||
			// WARNING: this does not forbit = and ; characters in name and value!
			[[properties objectForKey:NSHTTPCookieName] rangeOfString:@"\n"].length > 0 ||	// does not allow embedded newline characters
			[[properties objectForKey:NSHTTPCookieValue] rangeOfString:@"\n"].length > 0)
			{ // these are mandatory
			[self release];
			return nil;
			}
		_properties=[properties mutableCopy];
			[(NSMutableDictionary *) _properties setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:@"Created"];
			if(![_properties objectForKey:NSHTTPCookieDiscard])
				[(NSMutableDictionary *) _properties setObject:([[_properties objectForKey:NSHTTPCookieVersion] intValue] >= 1 && ![_properties objectForKey:NSHTTPCookieMaximumAge])?@"TRUE":@"FALSE" forKey:NSHTTPCookieDiscard];
			if(![_properties objectForKey:NSHTTPCookieDomain])
				[(NSMutableDictionary *) _properties setObject:[[_properties objectForKey:NSHTTPCookieOriginURL] host] forKey:NSHTTPCookieDomain];
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
