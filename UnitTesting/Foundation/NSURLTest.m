//
//  NSURLTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSURLTest.h"


@implementation NSURLTest

- (void) test1
{
	NSURL *url=[NSURL URLWithString:@"file%20name.htm;param1;param2?something=other&andmore=more#fragments"
										relativeToURL:[NSURL URLWithString:@"scheme://user:password@host.domain.org:888/path/absfile.htm"]];
	STAssertEqualObjects(@"file%20name.htm;param1;param2?something=other&andmore=more#fragments -- scheme://user:password@host.domain.org:888/path/absfile.htm", [url description], nil);
	STAssertEqualObjects(@"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", [url absoluteString], nil);
	STAssertEqualObjects(@"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", [[url absoluteURL] description], nil);
	STAssertEqualObjects(@"scheme://user:password@host.domain.org:888/path/absfile.htm", [[url baseURL] description], nil);
	STAssertEqualObjects(@"fragments", [url fragment], nil);
	STAssertEqualObjects(@"host.domain.org", [url host], nil);
	STAssertTrue(![url isFileURL], nil);
	STAssertEqualObjects(@"param1;param2", [url parameterString], nil);
	STAssertEqualObjects(@"password", [url password], nil);
	STAssertEqualObjects(@"/path/file name.htm", [url path], nil);
	STAssertEqualObjects([NSNumber numberWithInt:888], [url port], nil);
	STAssertEqualObjects(@"something=other&andmore=more", [url query], nil);
	STAssertEqualObjects(@"file name.htm", [url relativePath], nil);
	STAssertEqualObjects(@"file%20name.htm;param1;param2?something=other&andmore=more#fragments", [url relativeString], nil);
	STAssertEqualObjects(@"file%20name.htm;param1;param2?something=other&andmore=more#fragments", [url resourceSpecifier], nil);
	STAssertEqualObjects(@"scheme", [url scheme], nil);
	STAssertEqualObjects(@"file%20name.htm;param1;param2?something=other&andmore=more#fragments -- scheme://user:password@host.domain.org:888/path/absfile.htm", [[url standardizedURL] description], nil);
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
	STAssertEqualObjects(@"data:,A%20brief%20note", [url absoluteString], @"data:,A%20brief%20note");
}

- (void) test3
{
	NSURL *url=[NSURL URLWithString:@"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"];
	// assert something
}

- (void) test4
{ // data: and file: URLs
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"data:other"]];
	STAssertEqualObjects(@"data", [url scheme], @"scheme");
	STAssertEqualObjects(@"data:,A%20brief%20note", [url absoluteString], @"absoluteString");
	url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"file://localhost/"]];
	STAssertEqualObjects(@"data:,A%20brief%20note", [url absoluteString], @"absoluteString");
	url=[NSURL fileURLWithPath:@"/this#is a Path with % < > ?"];
	STAssertEqualObjects(@"file", [url scheme], @"scheme");
	STAssertEqualObjects(@"localhost", [url host], @"host");
	STAssertNil([url user], @"user");
	STAssertNil([url password], @"password");
	STAssertEqualObjects(@"//localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", [url resourceSpecifier], @"resourceSpecifier");
	STAssertEqualObjects(@"/this#is a Path with % < > ?", [url path], @"path");
	STAssertNil([url query], @"query");
	STAssertNil([url parameterString], @"parameterString");
	STAssertNil([url fragment], @"fragment");
	STAssertEqualObjects(@"file://localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", [url absoluteString], @"absoluteString");
	STAssertEqualObjects(@"/this#is a Path with % < > ?", [url relativePath], @"relativePath");
	STAssertEqualObjects(@"file://localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", [url description], @"description");
	url=[NSURL URLWithString:@"file:///pathtofile;parameters?query#anchor"];
	STAssertNil([url host], @"host");
	STAssertNil([url user], @"user");
	STAssertNil([url password], @"password");
	STAssertEqualObjects(@"/pathtofile;parameters?query#anchor", [url resourceSpecifier], @"resourceSpecifier");
	STAssertEqualObjects(@"/pathtofile", [url path], @"path");
	STAssertEqualObjects(@"query", [url query], @"query");
	STAssertEqualObjects(@"parameters", [url parameterString], @"parameterString");
	STAssertEqualObjects(@"anchor", [url fragment], @"fragment");
	STAssertEqualObjects(@"file:///pathtofile;parameters?query#anchor", [url absoluteString], @"absoluteString");
	STAssertEqualObjects(@"/pathtofile", [url relativePath], @"relativePath");
	STAssertEqualObjects(@"file:///pathtofile;parameters?query#anchor", [url description], @"description");
	url=[NSURL URLWithString:@"file:///pathtofile; parameters? query #anchor"];	// can't initialize with spaces (must be %20)
	STAssertNil(url, @"url");
	url=[NSURL URLWithString:@"file:///pathtofile;%20parameters?%20query%20#anchor"];
	STAssertNotNil(url, @"url");
}

- (void) test5
{
	NSURL *url=[NSURL URLWithString:@""];	// empty string is invalid - should return nils
	STAssertEqualObjects(nil, [url path], nil);
}


// add many more such tests


@end
