/*
    NSURLResponse.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
    Copyright (c) 2004 DSITRI. All rights reserved.

    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSURL.h>

@class NSDictionary, NSString, NSURL;

#define NSURLResponseUnknownLength ((long long)-1)

@interface NSURLResponse : NSObject <NSCopying, NSCoding>
{
	long long _expectedContentLength;
	NSString *_MIMEType;
	NSString *_textEncodingName;
	NSURL *_URL;
}

- (long long) expectedContentLength;
- (id) initWithURL:(NSURL *) URL
		  MIMEType:(NSString *) MIMEType
expectedContentLength:(NSInteger) length 
  textEncodingName:(NSString *) name;
- (NSString *) MIMEType;
- (NSString *) suggestedFilename;
- (NSString *) textEncodingName;
- (NSURL *) URL;

@end

@interface NSHTTPURLResponse : NSURLResponse
{
	NSDictionary *_headerFields;
	int _statusCode;
}

+ (NSString *) localizedStringForStatusCode:(NSInteger) code;

- (NSDictionary *) allHeaderFields;
- (NSInteger) statusCode;

@end
