//
//  NSURLResponse.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSURLResponse.h>
#import "NSPrivate.h"

@implementation NSURLResponse

static NSDictionary *_mimeExtensions;

+ (void) initialize;
{ // read from "mime.types" resource?
	_mimeExtensions=[[NSDictionary alloc] initWithObjectsAndKeys:	// map some common file extensions to mime types (default is text/html)
		@"image/jpeg", @"jpeg",
		@"image/jpeg", @"jpg",
		@"image/tiff", @"tiff",
		@"image/png", @"png",
		@"image/gif", @"gif",
		@"text/pdf", @"pdf",
		@"text/xml", @"xml",
		nil];
}

- (long long) expectedContentLength; { return _expectedContentLength; }
- (NSString *) MIMEType; { return _MIMEType; }
- (NSString *) suggestedFilename; { return @"filename"; }	// FIXME - make it based on MIMEType
- (NSString *) textEncodingName; { return _textEncodingName; }
- (NSURL *) URL; { return _URL; }

- (id) initWithURL:(NSURL *) URL
		  MIMEType:(NSString *) MIMEType
	expectedContentLength:(int) length 
  textEncodingName:(NSString *) name;
{
#if 0
	NSLog(@"initWithURL=%@ mime=%@ encoding=%@ len=%d", URL, MIMEType, name, length);
#endif
	if((self=[super init]))
		{
		_URL=[URL retain];
		if(!MIMEType)
			{
			MIMEType=[_mimeExtensions objectForKey:[[URL path] pathExtension]];	// get from extension
			if(!MIMEType)
				MIMEType=@"text/html";
			}
		_MIMEType=[MIMEType retain];
		_textEncodingName=[name retain];
		if(length < -1) length=-1;	// ignore heavily negative values
		_expectedContentLength=length;
		}
	return self;
}

- (void) dealloc;
{
	[_URL release];
	[_MIMEType release];
	[_textEncodingName release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ URL=%@ MIME=%@ ENC=%@ LEN=%ld", NSStringFromClass(isa),
		_URL,
		_MIMEType,
		_textEncodingName,
		(long) _expectedContentLength];
}

- (id) copyWithZone:(NSZone *) z;
{
	NSURLResponse *c=[isa allocWithZone:z];
	if(c)
		{
		c->_URL=[_URL retain];
		c->_MIMEType=[_MIMEType retain];
		c->_textEncodingName=[_textEncodingName retain];
		c->_expectedContentLength=_expectedContentLength;
		}
	return c;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return self;
}

@end

@implementation NSHTTPURLResponse

+ (NSString *) localizedStringForStatusCode:(int) code;
{
	return [NSString stringWithFormat:@"Status code %d", code];
}

- (id) _initWithURL:(NSURL *) url headerFields:(NSDictionary *) headers andStatusCode:(int) code;
{
	NSString *len=[headers objectForKey:@"content-length"];
	NSString *content=[headers objectForKey:@"content-type"];
	// FIXME: make more robust to missing components and whitespace
	NSArray *a=[content componentsSeparatedByString:@"; charset="];
	NSString *mime=nil;
	NSString *encoding=nil;
	if([a count] >= 1)
		mime=[a objectAtIndex:0];
	if([a count] >= 2)
		encoding=[a objectAtIndex:1];
#if 1
	NSLog(@"content-length=%@", len);
	NSLog(@"content-type=%@", content);
	NSLog(@"content-type array=%@", a);
	NSLog(@"mime=%@", mime);
	NSLog(@"encoding=%@", encoding);
#endif
	if((self=[super initWithURL:url
					   MIMEType:mime
		  expectedContentLength:0
			   textEncodingName:encoding]))
		{
		_expectedContentLength=[len length] > 0?[len longLongValue]:-1;
		_headerFields=[headers retain];
		_statusCode=code;
		}
	return self;
}

- (void) dealloc;
{
	[_headerFields release];
	[super dealloc];
}

- (NSString *) description;
{
#if 0
	NSLog(@"super descr=%@", [super description]);
	NSLog(@"headers=%@", _headerFields);
#endif
	return [NSString stringWithFormat:@"%@ HDR=%@ STAT=%d", [super description],
		_headerFields,
		_statusCode];
}

- (NSString *) suggestedFilename; { return @"filename"; }	// FIXME - make it based on MIMEType

- (NSDictionary *) allHeaderFields;
{
	return _headerFields;
}

- (int) statusCode;
{
	return _statusCode;
}

@end
