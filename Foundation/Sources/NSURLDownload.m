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
	_resumeData=[resumeData retain];
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
	if(r)
			{
				[proto autorelease];
				_protocol=[[NSURLProtocol alloc] initWithRequest:r cachedResponse:[[NSURLCache sharedURLCache] cachedResponseForRequest:r] client:(id <NSURLProtocolClient>) self];
#if 1
				NSLog(@"redirected to protocol %@", _protocol);
#endif
				// check redirect response if we should wait some time ("retry-after")
				[_protocol startLoading];
			}
}

- (void) URLProtocol:(NSURLProtocol *) proto didFailWithError:(NSError *) error;
{
	[_delegate download:self didFailWithError:error];
	if(_deletesFileUponFailure)
		; // delete file
}

- (void) URLProtocol:(NSURLProtocol *) proto didReceiveResponse:(NSURLResponse *) response cacheStoragePolicy:(NSURLCacheStoragePolicy) policy;
{
#if 0	// FIXME
	if(policy != NSURLCacheStorageNotAllowed)
			{ // create a cached response and try to store
				NSData *data=nil;	// where do we get that from unless we collect all data???
				NSCachedURLResponse *cachedResponse=[[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:policy];
				[[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:[_protocol request]];
				[cachedResponse release];
			}
#endif
	[_delegate download:self didReceiveResponse:response];
	// if no destination yet: - (void) download:(NSURLDownload *) download decideDestinationWithSuggestedFilename:(NSString *) filename;
	// if first data: - (void) download:(NSURLDownload *) download didCreateDestination:(NSString *) path;
}

- (void) URLProtocolDidFinishLoading:(NSURLProtocol *) proto;
{
	[_delegate downloadDidFinish:self];
	// check for response mime type
	// MacBinary ("application/macbinary"), Binhex ("application/mac-binhex40") and gzip ("application/gzip").
	// ask download:(NSURLDownload *) download shouldDecodeSourceDataOfMIMEType:
}

- (void) URLProtocol:(NSURLProtocol *) proto didLoadData:(NSData *) data;
{
	// append to file
	//	[_destination appendData:data];
	[_delegate download:self didReceiveDataOfLength:[data length]];
}

/* delegate methods not yet called
 - (void) download:(NSURLDownload *) download decideDestinationWithSuggestedFilename:(NSString *) filename;
 - (BOOL) download:(NSURLDownload *) download shouldDecodeSourceDataOfMIMEType:(NSString *) MIMEType;
 - (void) download:(NSURLDownload *) download willResumeWithResponse:(NSURLResponse *) response fromByte:(long long) startingByte;
 */

@end

@implementation NSObject (NSURLDownloadDelegate)

- (void) download:(NSURLDownload *) download decideDestinationWithSuggestedFilename:(NSString *) filename; { return; }
- (void) download:(NSURLDownload *) download didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge; { return; }
- (void) download:(NSURLDownload *) download didCreateDestination:(NSString *) path; { return; }
- (void) download:(NSURLDownload *) download didFailWithError:(NSError *) error; { return; }
- (void) download:(NSURLDownload *) download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge; { return; }
- (void) download:(NSURLDownload *) download didReceiveDataOfLength:(NSUInteger) len; { return; }
- (void) download:(NSURLDownload *) download didReceiveResponse:(NSURLResponse *) response; { return; }
- (BOOL) download:(NSURLDownload *) download shouldDecodeSourceDataOfMIMEType:(NSString *) MIMEType; { return NO; }
- (void) download:(NSURLDownload *) download willResumeWithResponse:(NSURLResponse *) response fromByte:(long long) startingByte;  { return; }
- (NSURLRequest *) download:(NSURLDownload *) download willSendRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse; { return request; }
- (void) downloadDidBegin:(NSURLDownload *) download; { return; }
- (void) downloadDidFinish:(NSURLDownload *) download; { return; }

@end
