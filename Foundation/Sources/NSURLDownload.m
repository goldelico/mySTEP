//
//  NSURLDownload.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSURLDownload.h>
#import <Foundation/NSString.h>

// code is similar to what we do for NSURLConnection

@implementation NSURLDownload

+ (BOOL) canResumeDownloadDecodedWithEncodingMIMEType:(NSString *) MIMEType;
{
	NIMP;
	return NO;
}

- (void) cancel;
{
	NIMP;
}

- (BOOL) deletesFileUponFailure; { return _deletesFileUponFailure; }
- (NSString *) destination;	{ return _destination; } // missing in documentation?

- (id) initWithRequest:(NSURLRequest *) request delegate:(id) delegate;
{
	return NIMP;
}

- (id) initWithResumeData:(NSData *) resumeData delegate:(id) delegate path:(NSString *) path;
{
	return NIMP;
}

- (void) dealloc;
{
	[super dealloc];
}

- (NSURLRequest *) request; { return _request; }
- (NSData *) resumeData; { return _resumeData; }
- (void) setDeletesFileUponFailure:(BOOL) flag; { _deletesFileUponFailure=flag; }

- (void) setDestination:(NSString *) path allowOverwrite:(BOOL) flag;
{
	if(!flag && NO /* file exists */)
		; // raise exception or ignore?
	ASSIGN(_destination, path);
}


@end

/*
- (void) download:(NSURLDownload *) download decideDestinationWithSuggestedFilename:(NSString *) filename;
- (void) download:(NSURLDownload *) download didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) download:(NSURLDownload *) download didCreateDestination:(NSString *) path;
- (void) download:(NSURLDownload *) download didFailWithError:(NSError *) error;
- (void) download:(NSURLDownload *) download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) download:(NSURLDownload *) download didReceiveDataOfLength:(unsigned) len;
- (void) download:(NSURLDownload *) download didReceiveResponse:(NSURLResponse *) response;
- (BOOL) download:(NSURLDownload *) download shouldDecodeSourceDataOfMIMEType:(NSString *) MIMEType;
- (void) download:(NSURLDownload *) download willResumeWithResponse:(NSURLResponse *) response fromByte:(long long) startingByte;
- (NSURLRequest *) download:(NSURLDownload *) download willSendRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
- (void) downloadDidBegin:(NSURLDownload *) download;
- (void) downloadDidFinish:(NSURLDownload *) download;
*/
