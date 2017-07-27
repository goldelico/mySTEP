//
//  NSURLTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>


@interface NSURLTest : XCTestCase {
	
}

@end


@implementation NSURLTest

- (void) test10
{
	NSURL *url;
	XCTAssertThrowsSpecificNamed([NSURL URLWithString:nil], NSException, NSInvalidArgumentException, nil);
	XCTAssertThrowsSpecificNamed([NSURL URLWithString:(NSString *) [NSArray array]], NSException, NSInvalidArgumentException, nil);
	XCTAssertNoThrow(url=[NSURL URLWithString:@"http://host/path" relativeToURL:(NSURL *) @"url"], nil);
	// this can't be correctly tested
	// XCTAssertThrows([url description], nil);
	/* conclusions
	 * passing nil is checked
	 * type of relativeURL is not checked and fails later
	 */
}

- (void) test11
{ // most complex initialization...
	NSURL *url=[NSURL URLWithString:@"file%20name.htm;param1;param2?something=other&andmore=more#fragments"
					  relativeToURL:[NSURL URLWithString:@"scheme://user:password@host.domain.org:888/path/absfile.htm"]];
	XCTAssertEqualObjects([url description], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments -- scheme://user:password@host.domain.org:888/path/absfile.htm", nil);
	XCTAssertEqualObjects([url absoluteString], @"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	XCTAssertEqualObjects([[url absoluteURL] description], @"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	XCTAssertEqualObjects([[url baseURL] description], @"scheme://user:password@host.domain.org:888/path/absfile.htm", nil);
	XCTAssertEqualObjects([url fragment], @"fragments", nil);
	XCTAssertEqualObjects([url host], @"host.domain.org", nil);
	XCTAssertFalse([url isFileURL], nil);
	XCTAssertEqualObjects([url parameterString], @"param1;param2", nil);
	XCTAssertEqualObjects([url password], @"password", nil);
	XCTAssertEqualObjects([url path], @"/path/file name.htm", nil);
	XCTAssertEqualObjects([url port], [NSNumber numberWithInt:888], nil);
	XCTAssertEqualObjects([url query], @"something=other&andmore=more", nil);
	XCTAssertEqualObjects([url relativePath], @"file name.htm", nil);
	XCTAssertEqualObjects([url relativeString], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	XCTAssertEqualObjects([url resourceSpecifier], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	XCTAssertEqualObjects([url scheme], @"scheme", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments -- scheme://user:password@host.domain.org:888/path/absfile.htm", nil);
	XCTAssertEqualObjects([url user], @"user", nil);
}

- (void) test12
{
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note"];
	XCTAssertEqualObjects([url scheme], @"data", nil);
	XCTAssertEqualObjects([url description], @"data:,A%20brief%20note", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
}

- (void) test13
{
	NSURL *url=[NSURL URLWithString:@"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"];
	XCTAssertEqualObjects([url scheme], @"data", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7", nil);
	XCTAssertEqualObjects([url path], nil, nil);
	XCTAssertEqualObjects([url parameterString], nil, nil);
	XCTAssertEqualObjects([url query], nil, nil);
	XCTAssertEqualObjects([url fragment], nil, nil);
	XCTAssertEqualObjects([url resourceSpecifier], @"image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7", nil);
	url=[NSURL URLWithString:@"html:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"];
	XCTAssertEqualObjects([url scheme], @"html", nil);
	XCTAssertEqualObjects([url absoluteString], @"html:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7", nil);
	XCTAssertEqualObjects([url path], nil, nil);
	XCTAssertEqualObjects([url parameterString], nil, nil);
	url=[NSURL URLWithString:@"html:image/gif"];
	XCTAssertEqualObjects([url scheme], @"html", nil);
	XCTAssertEqualObjects([url absoluteString], @"html:image/gif", nil);
	XCTAssertEqualObjects([url path], nil, nil);
	XCTAssertEqualObjects([url parameterString], nil, nil);
	/* conclusions
	 * this appears to have neither path nor a parameter string?
	 * a relative path with no base has a nil path
	 */
}

- (void) test14
{ // data: and file: URLs
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"data:other"]];
	XCTAssertEqualObjects([url scheme], @"data", nil);
	XCTAssertEqualObjects([url description], @"data:,A%20brief%20note", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
	/* conclusions
	 * base URL is ignored
	 */
}

- (void) test14b
{
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"file://localhost/"]];
	XCTAssertEqualObjects([url description], @"data:,A%20brief%20note", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
	/* conclusions
	 * base URL is ignored as well
	 */
}

- (void) test14c
{ // check influence of scheme in string and base
	NSURL *url=[NSURL URLWithString:@"data:data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	XCTAssertEqualObjects([url description], @"data:data", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:data", nil);
	XCTAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"data" relativeToURL:[NSURL URLWithString:@"data:file"]];
	XCTAssertEqualObjects([url description], @"data -- data:file", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:///data", nil);
	XCTAssertEqualObjects([url baseURL], [NSURL URLWithString:@"data:file"], nil);
	url=[NSURL URLWithString:@"data:data" relativeToURL:[NSURL URLWithString:@"data:file"]];
	XCTAssertEqualObjects([url description], @"data:data", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:data", nil);
	XCTAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"file:data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	XCTAssertEqualObjects([url description], @"file:data", nil);
	XCTAssertEqualObjects([url absoluteString], @"file:data", nil);
	XCTAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	XCTAssertEqualObjects([url description], @"data -- file:file", nil);
	XCTAssertEqualObjects([url absoluteString], @"file:///data", nil);
	XCTAssertEqualObjects([url baseURL], [NSURL URLWithString:@"file:file"], nil);
	url=[NSURL URLWithString:@"data:data" relativeToURL:[NSURL URLWithString:@"file"]];
	XCTAssertEqualObjects([url description], @"data:data", nil);
	XCTAssertEqualObjects([url absoluteString], @"data:data", nil);
	XCTAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"data" relativeToURL:[NSURL URLWithString:@"file"]];
	XCTAssertEqualObjects([url description], @"data -- file", nil);
	XCTAssertEqualObjects([url absoluteString], @"//data", nil);
	XCTAssertEqualObjects([url baseURL], [NSURL URLWithString:@"file"], nil);
	url=[NSURL URLWithString:@"html:data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	XCTAssertEqualObjects([url description], @"html:data", nil);
	XCTAssertEqualObjects([url absoluteString], @"html:data", nil);
	XCTAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"html:/data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	XCTAssertEqualObjects([url description], @"html:/data", nil);
	XCTAssertEqualObjects([url absoluteString], @"html:/data", nil);
	XCTAssertEqualObjects([url baseURL], nil, nil);
	/* conclusions
	 * relative URL is only stored if we have no scheme
	 * if both are relative, // is prefixed
	 * if only base has a scheme an additional / is prefixed (but see test23b!)
	 */
}

- (void) test15
{ // file: urls
	NSURL *url=[NSURL fileURLWithPath:@"/this#is a Path with % < > ?"];
	XCTAssertEqualObjects([url scheme], @"file", nil);
	XCTAssertEqualObjects([url host], @"localhost", nil);
	XCTAssertNil([url user], nil);
	XCTAssertNil([url password], nil);
	XCTAssertEqualObjects([url resourceSpecifier], @"//localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", nil);
	XCTAssertEqualObjects([url path], @"/this#is a Path with % < > ?", nil);
	XCTAssertNil([url query], nil);
	XCTAssertNil([url parameterString], nil);
	XCTAssertNil([url fragment], nil);
	XCTAssertEqualObjects([url absoluteString], @"file://localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", nil);
	XCTAssertEqualObjects([url relativePath], @"/this#is a Path with % < > ?", nil);
	XCTAssertEqualObjects([url description], @"file://localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", nil);
	/* conclusions
	 * if created by fileURLWithPath, the host == "localhost"
	 * characters not allowed in URLs are %-escaped
	 * only allowed are alphanum and "$-_.+!*'()," and reserved characters ":@/"
	 */
}

- (void) test15b
{
	NSURL *url=[NSURL URLWithString:@"file:///pathtofile;parameters?query#anchor"];
	XCTAssertTrue([url isFileURL], nil);
	XCTAssertEqualObjects([url scheme], @"file", nil);
	XCTAssertEqualObjects([url host], nil, nil);
	XCTAssertEqualObjects([url user], nil, nil);
	XCTAssertEqualObjects([url password], nil, nil);
	XCTAssertEqualObjects([url port], nil, nil);
	XCTAssertEqualObjects([url resourceSpecifier], @"/pathtofile;parameters?query#anchor", nil);
	XCTAssertEqualObjects([url path], @"/pathtofile",nil);
	XCTAssertEqualObjects([url query], @"query", nil);
	XCTAssertEqualObjects([url parameterString], @"parameters", nil);
	XCTAssertEqualObjects([url fragment], @"anchor", nil);
	XCTAssertEqualObjects([url absoluteString], @"file:///pathtofile;parameters?query#anchor", nil);
	XCTAssertEqualObjects([url relativePath], @"/pathtofile", nil);
	XCTAssertEqualObjects([url description], @"file:///pathtofile;parameters?query#anchor", nil);
	/* conclusions
	 * if created by fileURLWithPath, the host == "localhost"
	 * if created by URLWithString: it is as specified
	 */
}

- (void) test15c
{
	NSURL *url=[NSURL URLWithString:@"file:///pathtofile; parameters? query #anchor"];
	XCTAssertEqualObjects([url absoluteString], nil, nil);
	url=[NSURL URLWithString:@"file:///pathtofile;%20parameters?%20query%20#anchor"];
	XCTAssertEqualObjects([url absoluteString], @"file:///pathtofile;%20parameters?%20query%20#anchor", nil);
	url=[NSURL URLWithString:@"http:///this#is a Path with % < > ? # anything!§$%&/"];
	XCTAssertEqualObjects([url absoluteString], nil, nil);
	url=[NSURL URLWithString:@"http:///validpath#butanythingfragment!§$%&/"];
	XCTAssertEqualObjects([url absoluteString], nil, nil);
	/* conclusions
	 * can't have spaces or invalid characters in parameters or query part
	 * having %20 is ok
	 */
}

- (void) test15d
{
	NSURL *url=[NSURL URLWithString:@"file:///M%c3%bcller"];	// UTF8...
	XCTAssertEqualObjects([url absoluteString], @"file:///M%c3%bcller", nil);
	XCTAssertEqualObjects([url path], ([NSString stringWithFormat:@"/M%Cller", 0x00fc]), nil);
	/* conclusions
	 * UTF8 esacpes in file paths are resolved into Unicode NSStrings
	 */
}

- (void) test16
{
	NSURL *url=[NSURL URLWithString:@""];	// empty URL is allowed
	XCTAssertNotNil(url, nil);
	XCTAssertEqualObjects([url description], @"", nil);
}

- (void) test17
{
	NSURL *url=[NSURL URLWithString:@"http://host/confusing?order;of#fragment;and?query"];	// order of query, parameters, fragment mixed up
	XCTAssertEqualObjects([url path], @"/confusing", nil);
	XCTAssertEqualObjects([url query], @"order;of", nil);
	XCTAssertEqualObjects([url parameterString], nil, nil);
	XCTAssertEqualObjects([url fragment], @"fragment;and?query", nil);
}

- (void) test17b
{ // trailing / in paths
	NSURL *url=[NSURL URLWithString:@"http://host/file/"];
	XCTAssertEqualObjects([url absoluteString], @"http://host/file/", nil);
	XCTAssertEqualObjects([url path], @"/file", nil);
	XCTAssertEqualObjects([url relativePath], @"/file", nil);
	XCTAssertEqualObjects([url relativeString], @"http://host/file/", nil);
	url=[NSURL URLWithString:@"http://host/file"];
	XCTAssertEqualObjects([url absoluteString], @"http://host/file", nil);
	XCTAssertEqualObjects([url path], @"/file", nil);
	XCTAssertEqualObjects([url relativePath], @"/file", nil);
	XCTAssertEqualObjects([url relativeString], @"http://host/file", nil);
	url=[NSURL URLWithString:@"http:/file/"];
	XCTAssertEqualObjects([url absoluteString], @"http:/file/", nil);
	XCTAssertEqualObjects([url path], @"/file", nil);
	XCTAssertEqualObjects([url relativePath], @"/file", nil);
	XCTAssertEqualObjects([url relativeString], @"http:/file/", nil);
	url=[NSURL URLWithString:@"http:/file"];
	XCTAssertEqualObjects([url absoluteString], @"http:/file", nil);
	XCTAssertEqualObjects([url path], @"/file", nil);
	XCTAssertEqualObjects([url relativePath], @"/file", nil);
	XCTAssertEqualObjects([url relativeString], @"http:/file", nil);
	url=[NSURL URLWithString:@"http:file/"];
	XCTAssertEqualObjects([url absoluteString], @"http:file/", nil);
	XCTAssertEqualObjects([url path], nil, nil);
	XCTAssertEqualObjects([url relativePath], nil, nil);
	XCTAssertEqualObjects([url relativeString], @"http:file/", nil);
	url=[NSURL URLWithString:@"http:file"];
	XCTAssertEqualObjects([url absoluteString], @"http:file", nil);
	XCTAssertEqualObjects([url path], nil, nil);
	XCTAssertEqualObjects([url relativePath], nil, nil);
	XCTAssertEqualObjects([url relativeString], @"http:file", nil);
	/* conclusions
	 * a trailing / is stripped from path and relativePath
	 * relative paths return nil if there is no baseURL
	 * relativeString is not processed
	 */
}

- (void) test18
{ // %escapes embedded
	NSURL *url=[NSURL URLWithString:@"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33"];
	XCTAssertEqualObjects([url description], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([url absoluteString], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([[url absoluteURL] description], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([[url baseURL] description], nil, nil);
	XCTAssertEqualObjects([url fragment], @"fragment%33", nil);
	XCTAssertEqualObjects([url host], @"&host", nil);
	XCTAssertFalse([url isFileURL], nil);
	XCTAssertEqualObjects([url parameterString], @"parameter%31", nil);
	XCTAssertEqualObjects([url password], @"%28password", nil);
	XCTAssertEqualObjects([url path], @"//path0", nil);
	XCTAssertEqualObjects([url port], nil, nil);
	XCTAssertEqualObjects([url query], @"query%32", nil);
	XCTAssertEqualObjects([url relativePath], @"//path0", nil);
	XCTAssertEqualObjects([url relativeString], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([url resourceSpecifier], @"//%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([url scheme], @"http", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"http://%25user:%28password@%26host//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([url user], @"%user", nil);
	
	url=[NSURL URLWithString:@"ht%39tp://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33"];
	XCTAssertEqualObjects([url description], @"ht%39tp://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	XCTAssertEqualObjects([url scheme], nil, nil);
	XCTAssertEqualObjects([url path], @"ht9tp://%user:(password@&host:12//path0", nil);
	/* conclusions
	 * %escapes are possible/Users
	 * they are only resolved if we ask for -host, -path, -relativePath, -user
	 * but not for -fragment, -parameterString, -password, -port, -query
	 * % characters in the scheme invalidate it and make a relative URL
	 * standardizedURL removes the port number if it is not valid!
	 * invalid schemes (with % escape) are treated as relative path
	 */
}


- (void) test19
{ // what does standardizedURL do?
	NSURL *url=[NSURL URLWithString:@"directory/../other/file%31.html" relativeToURL:[NSURL URLWithString:@"file:/root/file.html"]];
	XCTAssertEqualObjects([url description], @"directory/../other/file%31.html -- file:/root/file.html", nil);
	XCTAssertEqualObjects([url path], @"/root/other/file1.html", nil);
	XCTAssertEqualObjects([[url absoluteURL] description], @"file:///root/other/file%31.html", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"other/file%31.html -- file:/root/file.html", nil);
	XCTAssertEqualObjects([[url standardizedURL] path], @"/root/other/file1.html", nil);
	XCTAssertEqualObjects([[[url standardizedURL] absoluteURL] description], @"file:///root/other/file%31.html", nil);
	
	url=[NSURL URLWithString:@"directory/../other/file%31.html" relativeToURL:[NSURL URLWithString:@"file:/root/../file.html"]];
	XCTAssertEqualObjects([url description], @"directory/../other/file%31.html -- file:/root/../file.html", nil);
	XCTAssertEqualObjects([[[url standardizedURL] absoluteURL] description], @"file:///other/file%31.html", nil);
	
	/* conclusions:
	 * works only on the path
	 * does not automatically resolve against the base URL
	 * does not resolve %escapes
	 * standardization is not applied to the base URL - until it is used
	 */
}

- (void) test20
{
	NSURL *url=[NSURL URLWithString:@"file:/somefile"];
	NSURL *url2;
	XCTAssertEqualObjects([url path], @"/somefile", nil);
	url2=[[NSURL alloc] initWithString:@"http://www.goldelico.com/otherpath" relativeToURL:url];	// try relative string with its own scheme!
	XCTAssertEqualObjects([url2 scheme], @"http", nil);
	XCTAssertEqualObjects([url2 host], @"www.goldelico.com", nil);
	XCTAssertEqualObjects([url2 path], @"/otherpath", nil);
	[url2 release];
	url2=[[NSURL alloc] initWithString:@"other" relativeToURL:url];	// try relative string with its own scheme!
	XCTAssertEqualObjects([url2 scheme], @"file", nil);
	XCTAssertNil([url2 host], nil);
	XCTAssertEqualObjects([url2 path], @"/other", nil);
	[url2 release];
	/* conclusions
	 * if the string is an URL of its own, that one is returned
	 * if it is no scheme, the scheme components are copied from the other
	 * there is no requirement to have the same schemes
	 */
}

- (void) test21
{ // inheritance from baseURL?
	NSURL *url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://file.html;parameters?query=q#fragment"]];
	XCTAssertEqualObjects([url description], @"pathonly -- http://user:password@host:1234://file.html;parameters?query=q#fragment", nil);
	XCTAssertEqualObjects([url absoluteString], @"http://user:password@host:1234://pathonly", nil);
	XCTAssertEqualObjects([[url absoluteURL] description], @"http://user:password@host:1234://pathonly", nil);
	XCTAssertEqualObjects([[url baseURL] description], @"http://user:password@host:1234://file.html;parameters?query=q#fragment", nil);
	XCTAssertEqualObjects([url fragment], nil, nil);
	XCTAssertEqualObjects([url host], @"host", nil);
	XCTAssertFalse([url isFileURL], nil);
	XCTAssertEqualObjects([url parameterString], nil, nil);
	XCTAssertEqualObjects([url password], @"password", nil);
	XCTAssertEqualObjects([url path], @"//pathonly", nil);
	XCTAssertEqualObjects([url port], nil, nil);
	XCTAssertEqualObjects([url query], nil, nil);
	XCTAssertEqualObjects([url relativePath], @"pathonly", nil);
	XCTAssertEqualObjects([url relativeString], @"pathonly", nil);
	XCTAssertEqualObjects([url resourceSpecifier], @"pathonly", nil);
	XCTAssertEqualObjects([url scheme], @"http", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"pathonly -- http://user:password@host:1234://file.html;parameters?query=q#fragment", nil);
	XCTAssertEqualObjects([url user], @"user", nil);
	
	url=[NSURL URLWithString:@"scheme:newuser@otherhost/mixed" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://file.html;parameters?query=q#fragment"]];
	XCTAssertEqualObjects([url description], @"scheme:newuser@otherhost/mixed", nil);
	XCTAssertEqualObjects([url absoluteString], @"scheme:newuser@otherhost/mixed", nil);
	
	url=[NSURL URLWithString:@"scheme:newuser@otherhost/mixed?newquery" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://file.html;parameters?query=q#fragment"]];
	XCTAssertEqualObjects([url description], @"scheme:newuser@otherhost/mixed?newquery", nil);
	XCTAssertEqualObjects([url absoluteString], @"scheme:newuser@otherhost/mixed?newquery", nil);
	
	url=[NSURL URLWithString:@"mixed?newquery" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://path/file.html;parameters?query=q#fragment"]];
	XCTAssertEqualObjects([url description], @"mixed?newquery -- http://user:password@host:1234://path/file.html;parameters?query=q#fragment", nil);
	XCTAssertEqualObjects([url absoluteString], @"http://user:password@host:1234://path/mixed?newquery", nil);
	
	url=[NSURL URLWithString:@"scheme:path/mixed.html" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://path/file.html;parameters?query=q#fragment"]];
	XCTAssertEqualObjects([url description], @"scheme:path/mixed.html", nil);
	XCTAssertEqualObjects([url absoluteString], @"scheme:path/mixed.html", nil);
	
	/* conclusions:
	 * scheme, user/password, host/port are inherited
	 * path is merged
	 * the base path is ignored as soon as we have scheme or host or user etc.
	 * query, fragment and parameters are not inherited, only the path is mixed
	 * note that we have a bug in the host:port syntax - there is an additional : at the end which is stored but ignored
	 * but it is not clear if that prevents standardization to work
	 * what it does is to make [url port] == nil (because it is defined nowhere)
	 * another observation: if string and baseURL define a different scheme, the base URL is ignored - sometimes
	 */
}

- (void) test23
{ // two relative URLS?
	NSURL *url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"path/file.html"]];
	XCTAssertEqualObjects([url description], @"pathonly -- path/file.html", nil);
	XCTAssertEqualObjects([url absoluteString], @"//path/pathonly", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"pathonly -- path/file.html", nil);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"path/file.html"]];
	XCTAssertEqualObjects([url description], @"/pathonly -- path/file.html", nil);
	XCTAssertEqualObjects([url absoluteString], @"///pathonly", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- path/file.html", nil);
	
	url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"/path/file.html"]];
	XCTAssertEqualObjects([url description], @"pathonly -- /path/file.html", nil);
	XCTAssertEqualObjects([url absoluteString], @"///path/pathonly", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"pathonly -- /path/file.html", nil);
	
	/* conclusions
	 * it is possible to have two relative URLs
	 * but we can't standardize them!
	 * unless in case 2 where the absolute string overwrites the base path
	 * if any of them is absolute, a / is prefixed
	 * since there is no scheme, a // is prefixed
	 */
}

- (void) test23b
{ // when is an empty host // added?
	NSURL *url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"path/file.html"]];
	XCTAssertEqualObjects([url description], @"pathonly -- path/file.html", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"//path/pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"pathonly -- path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"file:path/file.html"]];
	XCTAssertEqualObjects([url description], @"pathonly -- file:path/file.html", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"file:///pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"pathonly -- file:path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"path/file.html"]];
	XCTAssertEqualObjects([url description], @"/pathonly -- path/file.html", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"///pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"file:path/file.html"]];
	XCTAssertEqualObjects([url description], @"/pathonly -- file:path/file.html", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"file:///pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- file:path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"file:/path/file.html"]];
	XCTAssertEqualObjects([url description], @"/pathonly -- file:/path/file.html", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"file:///pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- file:/path/file.html", [url description]);
		
	url=[NSURL URLWithString:@"pathonly" relativeToURL:nil];
	XCTAssertEqualObjects([url description], @"pathonly", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"pathonly", [url description]);
	
	url=[NSURL URLWithString:@"file:pathonly" relativeToURL:nil];
	XCTAssertEqualObjects([url description], @"file:pathonly", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"file:pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:pathonly", [url description]);
	
	url=[NSURL URLWithString:@"file:/pathonly" relativeToURL:nil];
	XCTAssertEqualObjects([url description], @"file:/pathonly", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"file:/pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///pathonly", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:nil];
	XCTAssertEqualObjects([url description], @"/pathonly", [url description]);
	XCTAssertEqualObjects([url absoluteString], @"/pathonly", [url description]);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/pathonly", [url description]);
	
	/* conclusions
	 * // is added each time
	 * we have two relative paths or
	 * we have a baseURL or
	 * a scheme with on an absolute path
	 */
}

- (void) test24
{ // standardization test
	NSURL *url=[NSURL URLWithString:@"/somewhere/../here/./other/././more/."];
	XCTAssertEqualObjects([url description], @"/somewhere/../here/./other/././more/.", nil);
	XCTAssertEqualObjects([url absoluteString], @"/somewhere/../here/./other/././more/.", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/here/other/more/", nil);
	url=[NSURL URLWithString:@"/somewhere/../here/./other/././more/./"];
	XCTAssertEqualObjects([url description], @"/somewhere/../here/./other/././more/./", nil);
	XCTAssertEqualObjects([url absoluteString], @"/somewhere/../here/./other/././more/./", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"/here/other/more/", nil);
	/* conclusions
	 * something/../ are removed by standardization
	 * /./ are removed by standardization
	 * trailing /. removes the . only
	 */
}

- (void) test25
{ // another strange case
	NSURL *url=[NSURL URLWithString:@"//host/path"];
	XCTAssertEqualObjects([url description], @"//host/path", nil);
	XCTAssertEqualObjects([url host], @"host", nil);
	XCTAssertEqualObjects([url path], @"/path", nil);
	XCTAssertEqualObjects([url absoluteString], @"//host/path", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"host/path", nil);
	/* conclusions
	 * //host can be detected even if we have no scheme
	 */
}

- (void) test25b
{ // another strange case
	NSURL *url=[NSURL URLWithString:@"//host"];
	XCTAssertEqualObjects([url description], @"//host", nil);
	XCTAssertEqualObjects([url host], @"host", nil);
	XCTAssertEqualObjects([url path], @"", nil);
	XCTAssertEqualObjects([url absoluteString], @"//host", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"host", [url description]);
	/* conclusions
	 * //host can be detected even if we have no scheme
	 * standardization removes the // but absoluteString povides it (may be a bug in Cocoa!)
	 */
}

- (void) test26
{ // check if and where scheme and host name are converted to lower case
	NSURL *url=[NSURL URLWithString:@"HTTP://WWW.SOMEHOST.COM/PaTh"];
	XCTAssertEqualObjects([url description], @"HTTP://WWW.SOMEHOST.COM/PaTh", nil);
	XCTAssertEqualObjects([url host], @"WWW.SOMEHOST.COM", nil);
	XCTAssertEqualObjects([url path], @"/PaTh", nil);
	XCTAssertEqualObjects([url absoluteString], @"HTTP://WWW.SOMEHOST.COM/PaTh", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"HTTP://WWW.SOMEHOST.COM/PaTh", nil);
	/* conclusions
	 * there is no case conversion
	 */
}

- (void) test27
{ // normalization of . and ..
	NSURL *url;
	url=[NSURL URLWithString:@"file:/file/."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///file/", [url description]);
	url=[NSURL URLWithString:@"file:/file/./"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///file/", [url description]);
	url=[NSURL URLWithString:@"file:/file//./"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///file//", [url description]);
	url=[NSURL URLWithString:@"file:/file/.//"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///file//", [url description]);
	url=[NSURL URLWithString:@"file:/file/.//other"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///file//other", [url description]);
	url=[NSURL URLWithString:@"file:./"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:./", [url description]);
	url=[NSURL URLWithString:@"file:./file"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:./file", [url description]);
	url=[NSURL URLWithString:@"file:."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:.", [url description]);
	url=[NSURL URLWithString:@"file:../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:../", [url description]);
	url=[NSURL URLWithString:@"file:hello/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/../", [url description]);
	url=[NSURL URLWithString:@"file:hello/there/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/there/../", [url description]);
	url=[NSURL URLWithString:@"file:/hello/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///hello/", [url description]);
	XCTAssertEqualObjects([[url absoluteURL] description], @"file:/hello/there/../", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///hello", [url description]);
	XCTAssertEqualObjects([[url absoluteURL] description], @"file:/hello/there/..", [url description]);
	url=[NSURL URLWithString:@"file:"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/..file"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///hello/there/..file", [url description]);
	url=[NSURL URLWithString:@"data:/file/."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"data:///file/", [url description]);
	url=[NSURL URLWithString:@"http:/file/."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"http:///file/", [url description]);
	url=[NSURL URLWithString:@"http:file/."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"http:file/.", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/../file"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///hello/file", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/file/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///hello/there", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there/", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/", [url description]);
	url=[NSURL URLWithString:@"file://host/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/", [url description]);
	url=[NSURL URLWithString:@"file://host/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host", [url description]);
	url=[NSURL URLWithString:@"file:/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///", [url description]);
	url=[NSURL URLWithString:@"file:/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://", [url description]);
	url=[NSURL URLWithString:@"file:.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:..", [url description]);
	url=[NSURL URLWithString:@"file:../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:../", [url description]);
	url=[NSURL URLWithString:@"file://host/../hello"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello", [url description]);
	url=[NSURL URLWithString:@"file://host/../hello/"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/../" relativeToURL:[NSURL URLWithString:@"file://host/other"]];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there/", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/../" relativeToURL:[NSURL URLWithString:@"file://host/other/"]];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there/", [url description]);
	url=[NSURL URLWithString:@"file:hello/there/file/../"];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/there/file/../", [url description]);
	url=[NSURL URLWithString:@"file:hello/there/file/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/there/file/..", [url description]);
	url=[NSURL URLWithString:@"file:hello/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/..", [url description]);
	url=[NSURL URLWithString:@"file:hello/../.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/../..", [url description]);
	url=[NSURL URLWithString:@"file:hello/../../.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:hello/../../..", [url description]);
	url=[NSURL URLWithString:@"file:/.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///", [url description]);
	url=[NSURL URLWithString:@"file:/../.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///", [url description]);
	url=[NSURL URLWithString:@"file:/../../.."];
	XCTAssertEqualObjects([[url standardizedURL] description], @"file:///", [url description]);
	/* conclusions
	 * ./ are removed (or simple trailing .)
	 * /.. removes parent but only for absolute paths or if base is defined (!)
	 * /. and /.. must be followed by / or end of string
	 * standardization adds an empty host // for absolute paths
	 * for absolute paths, we can reduce /.. to /
	 */
}

- (void) test28
{ // is a well known port removed?
	NSURL *url=[NSURL URLWithString:@"http://localhost:80/"];
	XCTAssertEqualObjects([url description], @"http://localhost:80/", nil);
	XCTAssertEqualObjects([url absoluteString], @"http://localhost:80/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"http://localhost:80/", nil);
	url=[NSURL URLWithString:@"https://localhost:443/"];
	XCTAssertEqualObjects([url description], @"https://localhost:443/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:443/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost:443/", nil);
	url=[NSURL URLWithString:@"https://localhost:123/"];
	XCTAssertEqualObjects([url description], @"https://localhost:123/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:123/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost:123/", nil);
	/* conclusions
	 * no, never
	 */
}

- (void) test29
{ // are port numbers "standardized"?
	NSURL *url=[NSURL URLWithString:@"http://localhost:0080/"];
	XCTAssertEqualObjects([url description], @"http://localhost:0080/", nil);
	XCTAssertEqualObjects([url absoluteString], @"http://localhost:0080/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"http://localhost:80/", nil);
	url=[NSURL URLWithString:@"https://localhost:1234567890123456789/"];
	XCTAssertEqualObjects([url description], @"https://localhost:1234567890123456789/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:1234567890123456789/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost:2147483647/", nil);
	url=[NSURL URLWithString:@"https://localhost:1234567890123456788/"];
	XCTAssertEqualObjects([url description], @"https://localhost:1234567890123456788/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:1234567890123456788/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost:2147483647/", nil);
	url=[NSURL URLWithString:@"https://localhost:abc/"];
	XCTAssertEqualObjects([url description], @"https://localhost:abc/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:abc/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost/", nil);
	url=[NSURL URLWithString:@"https://localhost:01234abc/"];
	XCTAssertEqualObjects([url description], @"https://localhost:01234abc/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:01234abc/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost/", nil);
	url=[NSURL URLWithString:@"https://localhost:0000/"];
	XCTAssertEqualObjects([url description], @"https://localhost:0000/", nil);
	XCTAssertEqualObjects([url absoluteString], @"https://localhost:0000/", nil);
	XCTAssertEqualObjects([[url standardizedURL] description], @"https://localhost:0/", nil);
	/* conclusions
	 * yes, but only during standardization and not for absoluteString
	 * port humber is converted to integer (limited to 2^31-1) and converted back to a string
	 * this removes leading 0 and eliminates port numbers with non-digits
	 */
}

- (void) test30
{ // when are NURLs considered -isEqual? Before or after standardization?
	NSURL *url1=[NSURL URLWithString:@"http://localhost:80/"];
	NSURL *url2=[NSURL URLWithString:@"http://localhost:80/"];
	XCTAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost:80/"];
	url2=[NSURL URLWithString:@"http://localhost:0080/"];
	XCTAssertFalse([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost/dir/subdir/../file"];
	url2=[NSURL URLWithString:@"http://localhost/dir/subdir/../file"];
	XCTAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost/dir/subdir/../file"];
	url2=[NSURL URLWithString:@"http://localhost/dir/file"];
	XCTAssertFalse([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"file2" relativeToURL:[NSURL URLWithString:@"file:/root/file1"]];
	url2=[NSURL URLWithString:@"file2" relativeToURL:[NSURL URLWithString:@"file:/root/file1"]];
	XCTAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"file2" relativeToURL:[NSURL URLWithString:@"file:///root/file1"]];
	url2=[NSURL URLWithString:@"file:///root/file2"];
	XCTAssertEqualObjects([url1 absoluteString], @"file:///root/file2", nil);
	XCTAssertEqualObjects([url2 absoluteString], @"file:///root/file2", nil);
	XCTAssertFalse([url1 isEqual:url2], nil);
	/* conclusions
	 * is based on string compare of the initializing string
	 * not on the concept of standardizedURL
	 * and it is not sufficient to return the same absoluteURL!
	 */
}

- (void) test30a
{ // when are NURLs considered -isEqual? Before or after standardization?
	NSURL *url1=[NSURL URLWithString:@"http://localhost:80/file"];
	NSURL *url2=[NSURL URLWithString:@"http://localhost:80/file"];
	XCTAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost:80/file"];
	url2=[NSURL URLWithString:@"http://LOCALHOST:80/file"];
	XCTAssertFalse([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost:80/file"];
	url2=[NSURL URLWithString:@"HTTP://localhost:80/file"];
	XCTAssertFalse([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost:80/file"];
	url2=[NSURL URLWithString:@"http://localhost:80/FILE"];
	XCTAssertFalse([url1 isEqual:url2], nil);
	/* conclusions
	 * compare is case sensitive
	 */
}

- (void) test31
{ // handling unicode in URL string?
	XCTAssertNil(([NSURL URLWithString:[NSString stringWithFormat:@"http://M%Cller.de/Ueberweisung", 0x00FC]]), nil);
	XCTAssertNil(([NSURL URLWithString:[NSString stringWithFormat:@"http://M%Cller.de/%Cberweisung", 0x00FC, 0x00DC]]), nil);
	XCTAssertNil(([NSURL URLWithString:[NSString stringWithFormat:@"http://Mueller.de/%Cberweisung", 0x00DC]]), nil);
	/* conclusion
	 * unicode characters are rejected everywhere
	 * i.e. translation from a user typed URL (e.g. browser address text field) to % escapes and Punycode must be done outside this class
	 */
}

- (void) test3986
{ // normalization according to RFC
	// FIXME: completely test the examples of http://tools.ietf.org/html/rfc3986#section-5.4
	NSURL *url;
	NSURL *base=[NSURL URLWithString:@"http://a/b/c/d;p?q"];

#define RFC3986(REL, RESULT) url=[NSURL URLWithString:@REL relativeToURL:base]; XCTAssertEqualObjects([[url absoluteURL] description], @RESULT, [url description]);
	
	/* 5.4.1.  Normal Examples
	 */
	
	RFC3986("g:h", "g:h");
	RFC3986("g", "http://a/b/c/g");
	
	RFC3986("./g"           ,  "http://a/b/c/g");
	RFC3986("g/"            ,  "http://a/b/c/g/");
	RFC3986("/g"            ,  "http://a/g");
	RFC3986("//g"           ,  "http://g");
	RFC3986("?y"            ,  "http://a/b/c/d;p?y");
	RFC3986("g?y"           ,  "http://a/b/c/g?y");
	RFC3986("#s"            ,  "http://a/b/c/d;p?q#s");
	RFC3986("g#s"           ,  "http://a/b/c/g#s");
	RFC3986("g?y#s"         ,  "http://a/b/c/g?y#s");
#if 0	// what we should get
	RFC3986(";x"            ,  "http://a/b/c/;x");
#else	// Cocoa does not treat ";" as empty path component to replace d
	RFC3986(";x"            ,  "http://a/b/c/d;x");
#endif
	RFC3986("g;x"           ,  "http://a/b/c/g;x");
	RFC3986("g;x?y#s"       ,  "http://a/b/c/g;x?y#s");
	RFC3986(""              ,  "http://a/b/c/d;p?q");
	RFC3986("."             ,  "http://a/b/c/");
	RFC3986("./"            ,  "http://a/b/c/");
	RFC3986(".."            ,  "http://a/b/");
	RFC3986("../"           ,  "http://a/b/");
	RFC3986("../g"          ,  "http://a/b/g");
	RFC3986("../.."         ,  "http://a/");
	RFC3986("../../"        ,  "http://a/");
	RFC3986("../../g"       ,  "http://a/g");
	
	/*
	 5.4.2.  Abnormal Examples
	 
	 Although the following abnormal examples are unlikely to occur in
	 normal practice, all URI parsers should be capable of resolving them
	 consistently.  Each example uses the same base as that above.
	 
	 Parsers must be careful in handling cases where there are more ".."
	 segments in a relative-path reference than there are hierarchical
	 levels in the base URI's path.  Note that the ".." syntax cannot be
	 used to change the authority component of a URI.
	 */
	
#if 0	// what we should get
	RFC3986("../../../g"    ,  "http://a/g");
	RFC3986("../../../../g" ,  "http://a/g");
#else		// Cocoa keeps every second ../
	RFC3986("../../../g"    ,  "http://a/../g");
	RFC3986("../../../../g" ,  "http://a/../../g");
#endif
	
	/*
	 Similarly, parsers must remove the dot-segments "." and ".." when
	 they are complete components of a path, but not when they are only
	 part of a segment.
	 */
	
#if 0	// what we should get
	RFC3986("/./g"          ,  "http://a/g");
	RFC3986("/../g"         ,  "http://a/g");
#else		// Cocoa does not standardize if the path begins with ./ or ../, i.e. starts processing after the /
	RFC3986("/./g"          ,  "http://a/./g");
	RFC3986("/../g"         ,  "http://a/../g");
#endif
	RFC3986("g."            ,  "http://a/b/c/g.");
	RFC3986(".g"            ,  "http://a/b/c/.g");
	RFC3986("g.."           ,  "http://a/b/c/g..");
	RFC3986("..g"           ,  "http://a/b/c/..g");
	
	/*
	 Less likely are cases where the relative reference uses unnecessary
	 or nonsensical forms of the "." and ".." complete path segments.
	 */
	
	RFC3986("./../g"        ,  "http://a/b/g");
	RFC3986("./g/."         ,  "http://a/b/c/g/");
	RFC3986("g/./h"         ,  "http://a/b/c/g/h");
	RFC3986("g/../h"        ,  "http://a/b/c/h");
#if 0	// what we should get according to RFC3986 (which means that ./ and ../ should also be standardized in ;parameters!
	RFC3986("g;x=1/./y"     ,  "http://a/b/c/g;x=1/y");
	RFC3986("g;x=1/../y"    ,  "http://a/b/c/y");
#else		// Cocoa does not standardize in parameters
	RFC3986("g;x=1/./y"     ,  "http://a/b/c/g;x=1/./y");
	RFC3986("g;x=1/../y"    ,  "http://a/b/c/g;x=1/../y");
#endif

	/*
	 Some applications fail to separate the reference's query and/or
	 fragment components from the path component before merging it with
	 the base path and removing dot-segments.  This error is rarely
	 noticed, as typical usage of a fragment never includes the hierarchy
	 ("/") character and the query component is not normally used within
	 relative references.
	 */
	
	RFC3986("g?y/./x"       ,  "http://a/b/c/g?y/./x");
	RFC3986("g?y/../x"      ,  "http://a/b/c/g?y/../x");
	RFC3986("g#s/./x"       ,  "http://a/b/c/g#s/./x");
	RFC3986("g#s/../x"      ,  "http://a/b/c/g#s/../x");
	
	/*
	 Some parsers allow the scheme name to be present in a relative
	 reference if it is the same as the base URI scheme.  This is
	 considered to be a loophole in prior specifications of partial URI
	 [RFC1630].  Its use should be avoided but is allowed for backward
	 compatibility.
	 */
	
#if 1	// Cocoa is strict in this case
	RFC3986("http:g"        ,  "http:g"); // for strict parsers
#else
	RFC3986("http:g"        ,  "http://a/b/c/g"); // for backward compatibility
#endif
}


// add more such tests
// -isEqual case sensitive or insensitive?...

@end
