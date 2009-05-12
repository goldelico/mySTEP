//
//  NSURLTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSURLTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit


@implementation NSURLTest

- (void) test1
{
	NSURL *url=[NSURL URLWithString:@"file%20name.htm;param1;param2?something=other&andmore=more#fragments"
										relativeToURL:[NSURL URLWithString:@"scheme://user:password@host.domain.org:888/path/absfile.htm"]];
	STAssertEqualObjects(@"%K like $single+$b+$c", [url description], nil);
	STAssertEqualObjects(@"%K like $single+$b+$c", [url absoulteString], nil);
	STAssertEqualObjects(@"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", [url absoulteURL], nil);
	STAssertEqualObjects(@"scheme://user:password@host.domain.org:888/path/absfile.htm", [url baseURL], nil);
	STAssertEqualObjects(@"fragments", [url fragment], nil);
	STAssertEqualObjects(@"host.domain.org", [url host], nil);
//	STAssertTrue([url isFileURL], nil);
	STAssertEqualObjects(@"scheme://user:password@host.domain.org:888/path/absfile.htm", [url parameterString], nil);
	STAssertEqualObjects(@"password", [url password], nil);
	STAssertEqualObjects(@"path", [url path], nil);
	STAssertEqualObjects(@"888", [url port], nil);
	STAssertEqualObjects(@"something=other&andmore=more", [url query], nil);
	STAssertEqualObjects(@"888", [url relativePath], nil);
	STAssertEqualObjects(@"888", [url relativeString], nil);
	STAssertEqualObjects(@"888", [url resourceSpecifier], nil);
	STAssertEqualObjects(@"scheme", [url scheme], nil);
	STAssertEqualObjects(@"scheme", [url standardizedURL], nil);
	STAssertEqualObjects(@"user", [url user], nil);
#if 0
	NSLog(@"*** NSURL demo ***");
	NSLog(@"description: %@", [url description]);
	NSLog(@"absoluteString: %@", [url absoluteString]);
	NSLog(@"absoluteURL: %@", [url absoluteURL]);
	NSLog(@"baseURL: %@", [url baseURL]);
	NSLog(@"fragment: %@", [url fragment]);
	NSLog(@"host: %@", [url host]);
	NSLog(@"isFile: %@", [url isFileURL]?@"YES":@"NO");
	NSLog(@"parameterString: %@", [url parameterString]);
	NSLog(@"password: %@", [url password]);
	NSLog(@"path: %@", [url path]);
	NSLog(@"port: %@", [url port]);
	NSLog(@"query: %@", [url query]);
	NSLog(@"relativePath: %@", [url relativePath]);
	NSLog(@"relativeString: %@", [url relativeString]);
	NSLog(@"resourceSpecifier: %@", [url resourceSpecifier]);
	NSLog(@"scheme: %@", [url scheme]);
	NSLog(@"standardizedURL: %@", [url standardizedURL]);
	NSLog(@"user: %@", [url user]);
#endif
}

- (void) test2
{
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note"];
}

- (void) test3
{
	NSURL *url=[NSURL URLWithString:@"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"];
}

// add many more such tests


@end
