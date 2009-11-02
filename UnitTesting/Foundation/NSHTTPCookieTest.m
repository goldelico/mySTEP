//
//  NSHTTPCookieTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSHTTPCookieTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit


@implementation NSHTTPCookieTest

- (void) test1
{
	c1=[NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
																													 // mandatory
																													 @"name with", NSHTTPCookieName,
																													 @"cookie value with ;", NSHTTPCookieValue,
																													 @"www.origin.org", NSHTTPCookieDomain,	// required
																													 @"/path", NSHTTPCookiePath,	// required
																													 // optional
																													 //		 @"http://www.origin.org", NSHTTPCookieOriginURL,	// or should we define NSHTTPCookieDomain
																													 //		 @"0", NSHTTPCookieVersion,
																													 //		 @"FALSE", NSHTTPCookieDiscard,
																													 //		 @"FALSE", NSHTTPCookieSecure,
																													 nil]];
	STAssertTrue(c1 != nil, nil);		// assert that cookie exists
}

- (void) test2
{
	c2=[NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
																													 @"0", NSHTTPCookieVersion,
																													 @"name;2", NSHTTPCookieName,		// may not contain \n
																													 @"cookie;%value2", NSHTTPCookieValue,	// may not contain \n
																													 @"www.origin.org", NSHTTPCookieDomain,
																													 @"/", NSHTTPCookiePath,
																													 @"FALSE", NSHTTPCookieDiscard,
																													 @"FALSE", NSHTTPCookieSecure,
																													 //	 @"http://www.origin.org", NSHTTPCookieOriginURL,
																													 nil]];
	STAssertTrue(c2 != nil, nil);		// assert that cookie exists
}

// well, tests should NOT depend on the results of previous tests (c1, c2)...

- (void) test3
{
	NSDictionary *have=[NSHTTPCookie requestHeaderFieldsWithCookies:
											[NSArray arrayWithObjects:c1, c2, nil]];
	NSDictionary *want=@"{\n}";
	STAssertEqualObjects(want, have, nil);

	// WARNING: a cookie name or value with a ; is NOT encoded here!
	
#if 0
			NSLog(@"saved cookies %@", [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]);
			NSLog(@"saved cookies headers %@", [NSHTTPCookie requestHeaderFieldsWithCookies:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]]);
#endif
}

// add many more such tests


@end
