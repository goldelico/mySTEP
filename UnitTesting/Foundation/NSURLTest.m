//
//  NSURLTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURLTest.h"


@implementation NSURLTest

- (void) test10
{
	NSURL *url;
	STAssertThrowsSpecificNamed([NSURL URLWithString:nil], NSException, NSInvalidArgumentException, nil);
	STAssertThrowsSpecificNamed([NSURL URLWithString:(NSString *) [NSArray array]], NSException, NSInvalidArgumentException, nil);
	STAssertNoThrow(url=[NSURL URLWithString:@"http://host/path" relativeToURL:(NSURL *) @"url"], nil);
	// this can't be correctly tested
	// STAssertThrows([url description], nil);
	/* conclusions
	 * passing nil is checked
	 * type of relativeURL is not checked and fails later
	 */
}

- (void) test11
{ // most complex initialization...
	NSURL *url=[NSURL URLWithString:@"file%20name.htm;param1;param2?something=other&andmore=more#fragments"
					  relativeToURL:[NSURL URLWithString:@"scheme://user:password@host.domain.org:888/path/absfile.htm"]];
	STAssertEqualObjects([url description], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments -- scheme://user:password@host.domain.org:888/path/absfile.htm", nil);
	STAssertEqualObjects([url absoluteString], @"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	STAssertEqualObjects([[url absoluteURL] description], @"scheme://user:password@host.domain.org:888/path/file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	STAssertEqualObjects([[url baseURL] description], @"scheme://user:password@host.domain.org:888/path/absfile.htm", nil);
	STAssertEqualObjects([url fragment], @"fragments", nil);
	STAssertEqualObjects([url host], @"host.domain.org", nil);
	STAssertFalse([url isFileURL], nil);
	STAssertEqualObjects([url parameterString], @"param1;param2", nil);
	STAssertEqualObjects([url password], @"password", nil);
	STAssertEqualObjects([url path], @"/path/file name.htm", nil);
	STAssertEqualObjects([url port], [NSNumber numberWithInt:888], nil);
	STAssertEqualObjects([url query], @"something=other&andmore=more", nil);
	STAssertEqualObjects([url relativePath], @"file name.htm", nil);
	STAssertEqualObjects([url relativeString], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	STAssertEqualObjects([url resourceSpecifier], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments", nil);
	STAssertEqualObjects([url scheme], @"scheme", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"file%20name.htm;param1;param2?something=other&andmore=more#fragments -- scheme://user:password@host.domain.org:888/path/absfile.htm", nil);
	STAssertEqualObjects([url user], @"user", nil);
}

- (void) test12
{
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note"];
	STAssertEqualObjects([url scheme], @"data", nil);
	STAssertEqualObjects([url description], @"data:,A%20brief%20note", nil);
	STAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
}

- (void) test13
{
	NSURL *url=[NSURL URLWithString:@"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"];
	STAssertEqualObjects([url scheme], @"data", nil);
	STAssertEqualObjects([url absoluteString], @"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7", nil);
	STAssertEqualObjects([url path], nil, nil);
	STAssertEqualObjects([url parameterString], nil, nil);
	STAssertEqualObjects([url query], nil, nil);
	STAssertEqualObjects([url fragment], nil, nil);
	STAssertEqualObjects([url resourceSpecifier], @"image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7", nil);
	url=[NSURL URLWithString:@"html:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"];
	STAssertEqualObjects([url scheme], @"html", nil);
	STAssertEqualObjects([url absoluteString], @"html:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7", nil);
	STAssertEqualObjects([url path], nil, nil);
	STAssertEqualObjects([url parameterString], nil, nil);
	url=[NSURL URLWithString:@"html:image/gif"];
	STAssertEqualObjects([url scheme], @"html", nil);
	STAssertEqualObjects([url absoluteString], @"html:image/gif", nil);
	STAssertEqualObjects([url path], nil, nil);
	STAssertEqualObjects([url parameterString], nil, nil);
	/* conclusions
	 * this appears to have neither path nor a parameter string?
	 * a relative path with no base has a nil path
	 */
}

- (void) test14
{ // data: and file: URLs
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"data:other"]];
	STAssertEqualObjects([url scheme], @"data", nil);
	STAssertEqualObjects([url description], @"data:,A%20brief%20note", nil);
	STAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
	/* conclusions
	 * base URL is ignored
	 */
}

- (void) test14b
{
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"file://localhost/"]];
	STAssertEqualObjects([url description], @"data:,A%20brief%20note", nil);
	STAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
	/* conclusions
	 * base URL is ignored as well
	 */
}

- (void) test14c
{ // check influence of scheme in string and base
	NSURL *url=[NSURL URLWithString:@"data:data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	STAssertEqualObjects([url description], @"data:data", nil);
	STAssertEqualObjects([url absoluteString], @"data:data", nil);
	STAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"data" relativeToURL:[NSURL URLWithString:@"data:file"]];
	STAssertEqualObjects([url description], @"data -- data:file", nil);
	STAssertEqualObjects([url absoluteString], @"data:///data", nil);
	STAssertEqualObjects([url baseURL], [NSURL URLWithString:@"data:file"], nil);
	url=[NSURL URLWithString:@"data:data" relativeToURL:[NSURL URLWithString:@"data:file"]];
	STAssertEqualObjects([url description], @"data:data", nil);
	STAssertEqualObjects([url absoluteString], @"data:data", nil);
	STAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"file:data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	STAssertEqualObjects([url description], @"file:data", nil);
	STAssertEqualObjects([url absoluteString], @"file:data", nil);
	STAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	STAssertEqualObjects([url description], @"data -- file:file", nil);
	STAssertEqualObjects([url absoluteString], @"file:///data", nil);
	STAssertEqualObjects([url baseURL], [NSURL URLWithString:@"file:file"], nil);
	url=[NSURL URLWithString:@"data:data" relativeToURL:[NSURL URLWithString:@"file"]];
	STAssertEqualObjects([url description], @"data:data", nil);
	STAssertEqualObjects([url absoluteString], @"data:data", nil);
	STAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"data" relativeToURL:[NSURL URLWithString:@"file"]];
	STAssertEqualObjects([url description], @"data -- file", nil);
	STAssertEqualObjects([url absoluteString], @"//data", nil);
	STAssertEqualObjects([url baseURL], [NSURL URLWithString:@"file"], nil);
	url=[NSURL URLWithString:@"html:data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	STAssertEqualObjects([url description], @"html:data", nil);
	STAssertEqualObjects([url absoluteString], @"html:data", nil);
	STAssertEqualObjects([url baseURL], nil, nil);
	url=[NSURL URLWithString:@"html:/data" relativeToURL:[NSURL URLWithString:@"file:file"]];
	STAssertEqualObjects([url description], @"html:/data", nil);
	STAssertEqualObjects([url absoluteString], @"html:/data", nil);
	STAssertEqualObjects([url baseURL], nil, nil);
	/* conclusions
	 * relative URL is only stored if we have no scheme
	 * if both are relative, // is prefixed
	 * if only base has a scheme an additional / is prefixed (but see test23b!)
	 */
}

- (void) test15
{ // file: urls
	NSURL *url=[NSURL fileURLWithPath:@"/this#is a Path with % < > ?"];
	STAssertEqualObjects([url scheme], @"file", nil);
	STAssertEqualObjects([url host], @"localhost", nil);
	STAssertNil([url user], nil);
	STAssertNil([url password], nil);
	STAssertEqualObjects([url resourceSpecifier], @"//localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", nil);
	STAssertEqualObjects([url path], @"/this#is a Path with % < > ?", nil);
	STAssertNil([url query], nil);
	STAssertNil([url parameterString], nil);
	STAssertNil([url fragment], nil);
	STAssertEqualObjects([url absoluteString], @"file://localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", nil);
	STAssertEqualObjects([url relativePath], @"/this#is a Path with % < > ?", nil);
	STAssertEqualObjects([url description], @"file://localhost/this%23is%20a%20Path%20with%20%25%20%3C%20%3E%20%3F", nil);
	/* conclusions
	 * if created by fileURLWithPath, the host == "localhost"
	 * characters not allowed in URLs are %-escaped
	 * only allowed are alphanum and "$-_.+!*'()," and reserved characters ":@/"
	 */
}

- (void) test15b
{
	NSURL *url=[NSURL URLWithString:@"file:///pathtofile;parameters?query#anchor"];
	STAssertTrue([url isFileURL], nil);
	STAssertEqualObjects([url scheme], @"file", nil);
	STAssertEqualObjects([url host], nil, nil);
	STAssertEqualObjects([url user], nil, nil);
	STAssertEqualObjects([url password], nil, nil);
	STAssertEqualObjects([url port], nil, nil);
	STAssertEqualObjects([url resourceSpecifier], @"/pathtofile;parameters?query#anchor", nil);
	STAssertEqualObjects([url path], @"/pathtofile",nil);
	STAssertEqualObjects([url query], @"query", nil);
	STAssertEqualObjects([url parameterString], @"parameters", nil);
	STAssertEqualObjects([url fragment], @"anchor", nil);
	STAssertEqualObjects([url absoluteString], @"file:///pathtofile;parameters?query#anchor", nil);
	STAssertEqualObjects([url relativePath], @"/pathtofile", nil);
	STAssertEqualObjects([url description], @"file:///pathtofile;parameters?query#anchor", nil);
	/* conclusions
	 * if created by fileURLWithPath, the host == "localhost"
	 * if created by URLWithString: it is as specified
	 */
}

- (void) test15c
{
	NSURL *url=[NSURL URLWithString:@"file:///pathtofile; parameters? query #anchor"];
	STAssertEqualObjects([url absoluteString], nil, nil);
	url=[NSURL URLWithString:@"file:///pathtofile;%20parameters?%20query%20#anchor"];
	STAssertEqualObjects([url absoluteString], @"file:///pathtofile;%20parameters?%20query%20#anchor", nil);
	url=[NSURL URLWithString:@"http:///this#is a Path with % < > ? # anything!§$%&/"];
	STAssertEqualObjects([url absoluteString], nil, nil);
	url=[NSURL URLWithString:@"http:///validpath#butanythingfragment!§$%&/"];
	STAssertEqualObjects([url absoluteString], nil, nil);
	/* conclusions
	 * can't have spaces or invalid characters in parameters or query part
	 * having %20 is ok
	 */
}

- (void) test16
{
	NSURL *url=[NSURL URLWithString:@""];	// empty URL is allowed
	STAssertNotNil(url, nil);
	STAssertEqualObjects([url description], @"", nil);
}

- (void) test17
{
	NSURL *url=[NSURL URLWithString:@"http://host/confusing?order;of#fragment;and?query"];	// order of query, parameters, fragment mixed up
	STAssertEqualObjects([url path], @"/confusing", nil);
	STAssertEqualObjects([url query], @"order;of", nil);
	STAssertEqualObjects([url parameterString], nil, nil);
	STAssertEqualObjects([url fragment], @"fragment;and?query", nil);
}

- (void) test17b
{ // trailing / in paths
	NSURL *url=[NSURL URLWithString:@"http://host/file/"];
	STAssertEqualObjects([url absoluteString], @"http://host/file/", nil);
	STAssertEqualObjects([url path], @"/file", nil);
	STAssertEqualObjects([url relativePath], @"/file", nil);
	STAssertEqualObjects([url relativeString], @"http://host/file/", nil);
	url=[NSURL URLWithString:@"http://host/file"];
	STAssertEqualObjects([url absoluteString], @"http://host/file", nil);
	STAssertEqualObjects([url path], @"/file", nil);
	STAssertEqualObjects([url relativePath], @"/file", nil);
	STAssertEqualObjects([url relativeString], @"http://host/file", nil);
	url=[NSURL URLWithString:@"http:/file/"];
	STAssertEqualObjects([url absoluteString], @"http:/file/", nil);
	STAssertEqualObjects([url path], @"/file", nil);
	STAssertEqualObjects([url relativePath], @"/file", nil);
	STAssertEqualObjects([url relativeString], @"http:/file/", nil);
	url=[NSURL URLWithString:@"http:/file"];
	STAssertEqualObjects([url absoluteString], @"http:/file", nil);
	STAssertEqualObjects([url path], @"/file", nil);
	STAssertEqualObjects([url relativePath], @"/file", nil);
	STAssertEqualObjects([url relativeString], @"http:/file", nil);
	url=[NSURL URLWithString:@"http:file/"];
	STAssertEqualObjects([url absoluteString], @"http:file/", nil);
	STAssertEqualObjects([url path], nil, nil);
	STAssertEqualObjects([url relativePath], nil, nil);
	STAssertEqualObjects([url relativeString], @"http:file/", nil);
	url=[NSURL URLWithString:@"http:file"];
	STAssertEqualObjects([url absoluteString], @"http:file", nil);
	STAssertEqualObjects([url path], nil, nil);
	STAssertEqualObjects([url relativePath], nil, nil);
	STAssertEqualObjects([url relativeString], @"http:file", nil);
	/* conclusions
	 * a trailing / is stripped from path and relativePath
	 * relative paths return nil if there is no baseURL
	 * relativeString is not processed
	 */
}

- (void) test18
{ // %escapes embedded
	NSURL *url=[NSURL URLWithString:@"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33"];
	STAssertEqualObjects([url description], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([url absoluteString], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([[url absoluteURL] description], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([[url baseURL] description], nil, nil);
	STAssertEqualObjects([url fragment], @"fragment%33", nil);
	STAssertEqualObjects([url host], @"&host", nil);
	STAssertFalse([url isFileURL], nil);
	STAssertEqualObjects([url parameterString], @"parameter%31", nil);
	STAssertEqualObjects([url password], @"%28password", nil);
	STAssertEqualObjects([url path], @"//path0", nil);
	STAssertEqualObjects([url port], nil, nil);
	STAssertEqualObjects([url query], @"query%32", nil);
	STAssertEqualObjects([url relativePath], @"//path0", nil);
	STAssertEqualObjects([url relativeString], @"http://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([url resourceSpecifier], @"//%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([url scheme], @"http", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"http://%25user:%28password@%26host//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([url user], @"%user", nil);
	
	url=[NSURL URLWithString:@"ht%39tp://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33"];
	STAssertEqualObjects([url description], @"ht%39tp://%25user:%28password@%26host:%31%32//path%30;parameter%31?query%32#fragment%33", nil);
	STAssertEqualObjects([url scheme], nil, nil);
	STAssertEqualObjects([url path], @"ht9tp://%user:(password@&host:12//path0", nil);
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
	STAssertEqualObjects([url description], @"directory/../other/file%31.html -- file:/root/file.html", nil);
	STAssertEqualObjects([url path], @"/root/other/file1.html", nil);
	STAssertEqualObjects([[url absoluteURL] description], @"file:///root/other/file%31.html", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"other/file%31.html -- file:/root/file.html", nil);
	STAssertEqualObjects([[url standardizedURL] path], @"/root/other/file1.html", nil);
	STAssertEqualObjects([[[url standardizedURL] absoluteURL] description], @"file:///root/other/file%31.html", nil);
	
	url=[NSURL URLWithString:@"directory/../other/file%31.html" relativeToURL:[NSURL URLWithString:@"file:/root/../file.html"]];
	STAssertEqualObjects([url description], @"directory/../other/file%31.html -- file:/root/../file.html", nil);
	STAssertEqualObjects([[[url standardizedURL] absoluteURL] description], @"file:///other/file%31.html", nil);
	
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
	STAssertEqualObjects([url path], @"/somefile", nil);
	url2=[[NSURL alloc] initWithString:@"http://www.goldelico.com/otherpath" relativeToURL:url];	// try relative string with its own scheme!
	STAssertEqualObjects([url2 scheme], @"http", nil);
	STAssertEqualObjects([url2 host], @"www.goldelico.com", nil);
	STAssertEqualObjects([url2 path], @"/otherpath", nil);
	[url2 release];
	url2=[[NSURL alloc] initWithString:@"other" relativeToURL:url];	// try relative string with its own scheme!
	STAssertEqualObjects([url2 scheme], @"file", nil);
	STAssertNil([url2 host], nil);
	STAssertEqualObjects([url2 path], @"/other", nil);
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
	STAssertEqualObjects([url description], @"pathonly -- http://user:password@host:1234://file.html;parameters?query=q#fragment", nil);
	STAssertEqualObjects([url absoluteString], @"http://user:password@host:1234://pathonly", nil);
	STAssertEqualObjects([[url absoluteURL] description], @"http://user:password@host:1234://pathonly", nil);
	STAssertEqualObjects([[url baseURL] description], @"http://user:password@host:1234://file.html;parameters?query=q#fragment", nil);
	STAssertEqualObjects([url fragment], nil, nil);
	STAssertEqualObjects([url host], @"host", nil);
	STAssertFalse([url isFileURL], nil);
	STAssertEqualObjects([url parameterString], nil, nil);
	STAssertEqualObjects([url password], @"password", nil);
	STAssertEqualObjects([url path], @"//pathonly", nil);
	STAssertEqualObjects([url port], nil, nil);
	STAssertEqualObjects([url query], nil, nil);
	STAssertEqualObjects([url relativePath], @"pathonly", nil);
	STAssertEqualObjects([url relativeString], @"pathonly", nil);
	STAssertEqualObjects([url resourceSpecifier], @"pathonly", nil);
	STAssertEqualObjects([url scheme], @"http", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"pathonly -- http://user:password@host:1234://file.html;parameters?query=q#fragment", nil);
	STAssertEqualObjects([url user], @"user", nil);
	
	url=[NSURL URLWithString:@"scheme:newuser@otherhost/mixed" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://file.html;parameters?query=q#fragment"]];
	STAssertEqualObjects([url description], @"scheme:newuser@otherhost/mixed", nil);
	STAssertEqualObjects([url absoluteString], @"scheme:newuser@otherhost/mixed", nil);
	
	url=[NSURL URLWithString:@"scheme:newuser@otherhost/mixed?newquery" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://file.html;parameters?query=q#fragment"]];
	STAssertEqualObjects([url description], @"scheme:newuser@otherhost/mixed?newquery", nil);
	STAssertEqualObjects([url absoluteString], @"scheme:newuser@otherhost/mixed?newquery", nil);
	
	url=[NSURL URLWithString:@"mixed?newquery" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://path/file.html;parameters?query=q#fragment"]];
	STAssertEqualObjects([url description], @"mixed?newquery -- http://user:password@host:1234://path/file.html;parameters?query=q#fragment", nil);
	STAssertEqualObjects([url absoluteString], @"http://user:password@host:1234://path/mixed?newquery", nil);
	
	url=[NSURL URLWithString:@"scheme:path/mixed.html" relativeToURL:[NSURL URLWithString:@"http://user:password@host:1234://path/file.html;parameters?query=q#fragment"]];
	STAssertEqualObjects([url description], @"scheme:path/mixed.html", nil);
	STAssertEqualObjects([url absoluteString], @"scheme:path/mixed.html", nil);
	
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
	STAssertEqualObjects([url description], @"pathonly -- path/file.html", nil);
	STAssertEqualObjects([url absoluteString], @"//path/pathonly", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"pathonly -- path/file.html", nil);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"path/file.html"]];
	STAssertEqualObjects([url description], @"/pathonly -- path/file.html", nil);
	STAssertEqualObjects([url absoluteString], @"///pathonly", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- path/file.html", nil);
	
	url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"/path/file.html"]];
	STAssertEqualObjects([url description], @"pathonly -- /path/file.html", nil);
	STAssertEqualObjects([url absoluteString], @"///path/pathonly", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"pathonly -- /path/file.html", nil);
	
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
	STAssertEqualObjects([url description], @"pathonly -- path/file.html", [url description]);
	STAssertEqualObjects([url absoluteString], @"//path/pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"pathonly -- path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"pathonly" relativeToURL:[NSURL URLWithString:@"file:path/file.html"]];
	STAssertEqualObjects([url description], @"pathonly -- file:path/file.html", [url description]);
	STAssertEqualObjects([url absoluteString], @"file:///pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"pathonly -- file:path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"path/file.html"]];
	STAssertEqualObjects([url description], @"/pathonly -- path/file.html", [url description]);
	STAssertEqualObjects([url absoluteString], @"///pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"file:path/file.html"]];
	STAssertEqualObjects([url description], @"/pathonly -- file:path/file.html", [url description]);
	STAssertEqualObjects([url absoluteString], @"file:///pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- file:path/file.html", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:[NSURL URLWithString:@"file:/path/file.html"]];
	STAssertEqualObjects([url description], @"/pathonly -- file:/path/file.html", [url description]);
	STAssertEqualObjects([url absoluteString], @"file:///pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"/pathonly -- file:/path/file.html", [url description]);
		
	url=[NSURL URLWithString:@"pathonly" relativeToURL:nil];
	STAssertEqualObjects([url description], @"pathonly", [url description]);
	STAssertEqualObjects([url absoluteString], @"pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"pathonly", [url description]);
	
	url=[NSURL URLWithString:@"file:pathonly" relativeToURL:nil];
	STAssertEqualObjects([url description], @"file:pathonly", [url description]);
	STAssertEqualObjects([url absoluteString], @"file:pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"file:pathonly", [url description]);
	
	url=[NSURL URLWithString:@"file:/pathonly" relativeToURL:nil];
	STAssertEqualObjects([url description], @"file:/pathonly", [url description]);
	STAssertEqualObjects([url absoluteString], @"file:/pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"file:///pathonly", [url description]);
	
	url=[NSURL URLWithString:@"/pathonly" relativeToURL:nil];
	STAssertEqualObjects([url description], @"/pathonly", [url description]);
	STAssertEqualObjects([url absoluteString], @"/pathonly", [url description]);
	STAssertEqualObjects([[url standardizedURL] description], @"/pathonly", [url description]);
	
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
	STAssertEqualObjects([url description], @"/somewhere/../here/./other/././more/.", nil);
	STAssertEqualObjects([url absoluteString], @"/somewhere/../here/./other/././more/.", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"/here/other/more/", nil);
	url=[NSURL URLWithString:@"/somewhere/../here/./other/././more/./"];
	STAssertEqualObjects([url description], @"/somewhere/../here/./other/././more/./", nil);
	STAssertEqualObjects([url absoluteString], @"/somewhere/../here/./other/././more/./", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"/here/other/more/", nil);
	/* conclusions
	 * something/../ are removed by standardization
	 * /./ are removed by standardization
	 * trailing /. removes the . only
	 */
}

- (void) test25
{ // another strange case
	NSURL *url=[NSURL URLWithString:@"//host/path"];
	STAssertEqualObjects([url description], @"//host/path", nil);
	STAssertEqualObjects([url host], @"host", nil);
	STAssertEqualObjects([url path], @"/path", nil);
	STAssertEqualObjects([url absoluteString], @"//host/path", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"host/path", nil);
	/* conclusions
	 * //host can be detected even if we have no scheme
	 */
}

- (void) test25b
{ // another strange case
	NSURL *url=[NSURL URLWithString:@"//host"];
	STAssertEqualObjects([url description], @"//host", nil);
	STAssertEqualObjects([url host], @"host", nil);
	STAssertEqualObjects([url path], @"", nil);
	STAssertEqualObjects([url absoluteString], @"//host", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"host", [url description]);
	/* conclusions
	 * //host can be detected even if we have no scheme
	 * standardization removes the // but absoluteString povides it (may be a bug in Cocoa!)
	 */
}

- (void) test26
{ // check if and where scheme and host name are converted to lower case
	NSURL *url=[NSURL URLWithString:@"HTTP://WWW.SOMEHOST.COM/PaTh"];
	STAssertEqualObjects([url description], @"HTTP://WWW.SOMEHOST.COM/PaTh", nil);
	STAssertEqualObjects([url host], @"WWW.SOMEHOST.COM", nil);
	STAssertEqualObjects([url path], @"/PaTh", nil);
	STAssertEqualObjects([url absoluteString], @"HTTP://WWW.SOMEHOST.COM/PaTh", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"HTTP://WWW.SOMEHOST.COM/PaTh", nil);
	/* conclusions
	 * there is no case conversion
	 */
}

- (void) test27
{ // normalization of . and ..
	NSURL *url;
	url=[NSURL URLWithString:@"file:/file/."];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///file/", [url description]);
	url=[NSURL URLWithString:@"file:/file/./"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///file/", [url description]);
	url=[NSURL URLWithString:@"file:/file//./"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///file//", [url description]);
	url=[NSURL URLWithString:@"file:/file/.//"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///file//", [url description]);
	url=[NSURL URLWithString:@"file:./"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:./", [url description]);
	url=[NSURL URLWithString:@"file:../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:../", [url description]);
	url=[NSURL URLWithString:@"file:hello/../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:hello/../", [url description]);
	url=[NSURL URLWithString:@"file:hello/there/../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:hello/there/../", [url description]);
	url=[NSURL URLWithString:@"file:/hello/../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///hello/", [url description]);
	STAssertEqualObjects([[url absoluteURL] description], @"file:/hello/there/../", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/.."];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///hello", [url description]);
	STAssertEqualObjects([[url absoluteURL] description], @"file:/hello/there/..", [url description]);
	url=[NSURL URLWithString:@"file:"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/..file"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///hello/there/..file", [url description]);
	url=[NSURL URLWithString:@"data:/file/."];
	STAssertEqualObjects([[url standardizedURL] description], @"data:///file/", [url description]);
	url=[NSURL URLWithString:@"http:/file/."];
	STAssertEqualObjects([[url standardizedURL] description], @"http:///file/", [url description]);
	url=[NSURL URLWithString:@"http:file/."];
	STAssertEqualObjects([[url standardizedURL] description], @"http:file/.", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/../file"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///hello/file", [url description]);
	url=[NSURL URLWithString:@"file:/hello/there/file/.."];
	STAssertEqualObjects([[url standardizedURL] description], @"file:///hello/there", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/.."];
	STAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there/", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/../" relativeToURL:[NSURL URLWithString:@"file://host/other"]];
	STAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there/", [url description]);
	url=[NSURL URLWithString:@"file://host/hello/there/file/../" relativeToURL:[NSURL URLWithString:@"file://host/other/"]];
	STAssertEqualObjects([[url standardizedURL] description], @"file://host/hello/there/", [url description]);
	url=[NSURL URLWithString:@"file:hello/there/file/../"];
	STAssertEqualObjects([[url standardizedURL] description], @"file:hello/there/../", [url description]);
	url=[NSURL URLWithString:@"file:hello/there/file/.."];
	STAssertEqualObjects([[url standardizedURL] description], @"file:hello/there/..", [url description]);
	/* conclusions
	 * ./ are removed (or simple trailing .)
	 * /.. removes parent but only for absolute paths or if base is defined (!)
	 * /. and /.. must be followed by / or end of string
	 * standardization adds an empty host // for absolute paths
	 */
}

- (void) test28
{ // is a well known port removed?
	NSURL *url=[NSURL URLWithString:@"http://localhost:80/"];
	STAssertEqualObjects([url description], @"http://localhost:80/", nil);
	STAssertEqualObjects([url absoluteString], @"http://localhost:80/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"http://localhost:80/", nil);
	url=[NSURL URLWithString:@"https://localhost:443/"];
	STAssertEqualObjects([url description], @"https://localhost:443/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:443/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost:443/", nil);
	url=[NSURL URLWithString:@"https://localhost:123/"];
	STAssertEqualObjects([url description], @"https://localhost:123/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:123/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost:123/", nil);
	/* conclusions
	 * no, never
	 */
}

- (void) test29
{ // are port numbers "standardized"?
	NSURL *url=[NSURL URLWithString:@"http://localhost:0080/"];
	STAssertEqualObjects([url description], @"http://localhost:0080/", nil);
	STAssertEqualObjects([url absoluteString], @"http://localhost:0080/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"http://localhost:80/", nil);
	url=[NSURL URLWithString:@"https://localhost:1234567890123456789/"];
	STAssertEqualObjects([url description], @"https://localhost:1234567890123456789/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:1234567890123456789/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost:2147483647/", nil);
	url=[NSURL URLWithString:@"https://localhost:1234567890123456788/"];
	STAssertEqualObjects([url description], @"https://localhost:1234567890123456788/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:1234567890123456788/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost:2147483647/", nil);
	url=[NSURL URLWithString:@"https://localhost:abc/"];
	STAssertEqualObjects([url description], @"https://localhost:abc/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:abc/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost/", nil);
	url=[NSURL URLWithString:@"https://localhost:01234abc/"];
	STAssertEqualObjects([url description], @"https://localhost:01234abc/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:01234abc/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost/", nil);
	url=[NSURL URLWithString:@"https://localhost:0000/"];
	STAssertEqualObjects([url description], @"https://localhost:0000/", nil);
	STAssertEqualObjects([url absoluteString], @"https://localhost:0000/", nil);
	STAssertEqualObjects([[url standardizedURL] description], @"https://localhost:0/", nil);
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
	STAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost:80/"];
	url2=[NSURL URLWithString:@"http://localhost:0080/"];
	STAssertFalse([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost/dir/subdir/../file"];
	url2=[NSURL URLWithString:@"http://localhost/dir/subdir/../file"];
	STAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"http://localhost/dir/subdir/../file"];
	url2=[NSURL URLWithString:@"http://localhost/dir/file"];
	STAssertFalse([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"file2" relativeToURL:[NSURL URLWithString:@"file:/root/file1"]];
	url2=[NSURL URLWithString:@"file2" relativeToURL:[NSURL URLWithString:@"file:/root/file1"]];
	STAssertTrue([url1 isEqual:url2], nil);
	url1=[NSURL URLWithString:@"file2" relativeToURL:[NSURL URLWithString:@"file:///root/file1"]];
	url2=[NSURL URLWithString:@"file:///root/file2"];
	STAssertEqualObjects([url1 absoluteString], @"file:///root/file2", nil);
	STAssertEqualObjects([url2 absoluteString], @"file:///root/file2", nil);
	STAssertFalse([url1 isEqual:url2], nil);
	/* conclusions
	 * is based on string compares
	 * not on the concept of standardizedURL
	 * and it is not sufficient to return the same absoluteURL!
	 */
}

- (void) test31
{ // handling unicode in URL string?
	STAssertNil(([NSURL URLWithString:[NSString stringWithFormat:@"http://M%Cller.de/Ueberweisung", 0x00FC]]), nil);
	STAssertNil(([NSURL URLWithString:[NSString stringWithFormat:@"http://M%Cller.de/%Cberweisung", 0x00FC, 0x00DC]]), nil);
	STAssertNil(([NSURL URLWithString:[NSString stringWithFormat:@"http://Mueller.de/%Cberweisung", 0x00DC]]), nil);
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

#define RFC3986(REL, RESULT) url=[NSURL URLWithString:@REL relativeToURL:base]; STAssertEqualObjects([[url absoluteURL] description], @RESULT, [url description]);
	
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
// like Unicode hostnames and strings passed to the initWithString: method
// -isEqual case sensitive or insensitive?...


@end
