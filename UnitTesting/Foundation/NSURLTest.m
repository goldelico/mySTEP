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
	/*
	 * conclusions - this appears to have neither path nor a parameter string?
	 */
}

- (void) test14
{ // data: and file: URLs
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"data:other"]];
	STAssertEqualObjects([url scheme], @"data", nil);
	STAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
}

- (void) test14b
{
	NSURL *url=[NSURL URLWithString:@"data:,A%20brief%20note" relativeToURL:[NSURL URLWithString:@"file://localhost/"]];
	STAssertEqualObjects([url absoluteString], @"data:,A%20brief%20note", nil);
	/* conclusions
	 * does not copy localhost
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
	 * .. areremoved
	 * /. are removed
	 * trailing /. removes the . only
	 */
}

// add many more such tests
// like Unicode hostnames, user names, paths...


@end
