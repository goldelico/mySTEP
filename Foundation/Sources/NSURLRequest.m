//
//  NSURLRequest.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSURLRequest.h>


@implementation NSURLRequest

+ (NSURLRequest *) requestWithURL:(NSURL *) url;	// create request
{
	return [[[self alloc] initWithURL:url] autorelease];
}

+ (id) requestWithURL:(NSURL *) url cachePolicy:(NSURLRequestCachePolicy) policy timeoutInterval:(NSTimeInterval) timeout;
{
	return [[[self alloc] initWithURL:url cachePolicy:policy timeoutInterval:timeout] autorelease];
}

- (NSDictionary *) allHTTPHeaderFields; { return _headerFields; }
- (NSURLRequestCachePolicy) cachePolicy; { return _policy; }
- (NSString *) HTTPMethod; { return _method; }
- (BOOL) HTTPShouldHandleCookies; { return _handleCookies; }
- (NSTimeInterval) interval; { return _timeout; }
- (NSURL *) URL; { return _url; }
- (NSString *) valueForHTTPHeaderField:(NSString *) field;
{
	return [_headerFields objectForKey:[field lowercaseString]];
}

- (NSData *) HTTPBody; { return nil; }
- (NSInputStream *) HTTPBodyStream; { return nil; }
- (NSURL *) mainDocumentURL; { return nil; }

- (id) initWithURL:(NSURL *) url;
{
	return [self initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
}

- (id) initWithURL:(NSURL *) url cachePolicy:(NSURLRequestCachePolicy) policy timeoutInterval:(NSTimeInterval) timeout;
{
	if((self=[super init]))
		{
		_url=[url retain];
		_policy=policy;
		_timeout=timeout;
		_method=@"GET";
		_headerFields=[[NSMutableDictionary alloc] initWithCapacity:10];
		}
	return self;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ URL=%@ POL=%d time=%f METH=%@ %@", NSStringFromClass(isa),
		_url,
		_policy,
		_timeout,
		_method,
		_headerFields];
}

- (void) dealloc;
{
	[_url release];
	[_headerFields release];
	[_method release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) z; { return [self retain]; }

- (id) mutableCopyWithZone:(NSZone *) z;
{ // make a mutable copy
	NSURLRequest *c=[NSMutableURLRequest allocWithZone:z];
#if 0
	NSLog(@"%@ mutableCopyWithZone -> %@", self, c);
#endif
	if(c)
		{
		c->_url=[_url copyWithZone:z];
		c->_policy=_policy;
		c->_timeout=_timeout;
		c->_method=[_method copyWithZone:z];
		c->_headerFields=[_headerFields mutableCopyWithZone:z];	// should this be a deep copy for addValue:toHeaderField:
#if 0
		NSLog(@"  copied -> %@", c);
#endif
		}
	return c;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

@end

@implementation NSMutableURLRequest

- (void) addValue:(NSString *) value forHTTPHeaderField:(NSString *) field;
{ // append string (comma separated)
	NSString *c=[self valueForHTTPHeaderField:field];	// already defined
	if(c)
		c=[c stringByAppendingFormat:@",%@", value];
	else
		c=value;
	[self setValue:c forHTTPHeaderField:field];	// add to header fields
}

- (void) setAllHTTPHeaderFields:(NSDictionary *) headers;
{
	[_headerFields autorelease];
	_headerFields=[headers mutableCopy];
	// FIXME: copy to lower case dictionary keys!
}

- (void) setCachePolicy:(NSURLRequestCachePolicy) policy; { _policy=policy; }
- (void) setHTTPBody:(NSData *) data; { NIMP; }
- (void) setHTTPBodyStream:(NSInputStream *) stream; { NIMP; }
- (void) setHTTPMethod:(NSString *) method; { ASSIGN(_method, method); }
- (void) setHTTPShouldHandleCookies:(BOOL) flag; { _handleCookies=flag; }
- (void) setMainDocumentURL:(NSURL *) url; { NIMP; }
- (void) setTimeoutInterval:(NSTimeInterval) interval; { _timeout=interval; }
- (void) setURL:(NSURL *) url; { ASSIGN(_url, url); }

- (void) setValue:(NSString *) value forHTTPHeaderField:(NSString *) field;
{
	// FIXME: trim \n characters
	[_headerFields setObject:value forKey:[field lowercaseString]];
}

- (id) copyWithZone:(NSZone *) z;
{ // make immutable copy
	NSURLRequest *c=[NSURLRequest allocWithZone:z];
	if(c)
		{
		c->_url=[_url retain];
		c->_policy=_policy;
		c->_timeout=_timeout;
		c->_method=[_method retain];
		c->_headerFields=[_headerFields copyWithZone:z];
		}
	return c;
}

@end
