//
//  NSURLDownload.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSURLDownload.h>
#import <Foundation/NSURLProtocol.h>
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
	[_protocol stopLoading];
}

- (BOOL) deletesFileUponFailure; { return _deletesFileUponFailure; }
- (NSString *) destination;	{ return _destination; } // missing in documentation?

- (id) initWithRequest:(NSURLRequest *) request delegate:(id) delegate;
{
	self=[super init];
#if 0
	NSLog(@"%@ initWithRequest:%@ delegate:%@", self, request, delegate);
#endif
	if(self)
			{
				_delegate=delegate;
				_protocol=[[NSURLProtocol alloc] initWithRequest:request cachedResponse:[[NSURLCache sharedURLCache] cachedResponseForRequest:request] client:(id <NSURLProtocolClient>) self];
#if 1
				NSLog(@"  -> protocol %@", _protocol);
#endif
				[_protocol startLoading];
				[_delegate downloadDidBegin:self];
			}
	return self;
}

- (id) initWithResumeData:(NSData *) resumeData delegate:(id) delegate path:(NSString *) path;
{
	// resumeData is minimal state information
	// i.e. should encode the URL
	// and the file position
	return NIMP;
}

- (void) dealloc;
{
	[_protocol release];
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

// notification handlers just forward those our client wants to know

- (void) URLProtocol:(NSURLProtocol *) proto cachedResponseIsValid:(NSCachedURLResponse *) resp;
{
	return;
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	[_delegate download:self didReceiveAuthenticationChallenge:chall];
}

- (void) URLProtocol:(NSURLProtocol *) proto didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) chall;
{
	[_delegate download:self didCancelAuthenticationChallenge:chall];
}

- (void) URLProtocol:(NSURLProtocol *) proto wasRedirectedToRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
{
	NSURLRequest *r=[_delegate download:self willSendRequest:request redirectResponse:redirectResponse];
	if(!r)
		[proto stopLoading];
	NSLog(@"wasRedirectedToRequest:%@", request);
	// send new request for r
}

- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
{
	[_delegate download:self didFailWithError:error];
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
{
	[_delegate download:self didReceiveResponse:response];
}

- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;
{
	[_delegate downloadDidFinish:self];
}

- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
{
	// append to file
	[_delegate download:self didReceiveDataOfLength:[data length]];
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
