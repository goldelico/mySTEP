/*
    NSURLDownload.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
    Copyright (c) 2006 DSITRI. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSObject.h>

@class NSData;
@class NSError;
@class NSString;
@class NSURLAuthenticationChallenge;
@class NSURLResponse;
@class NSURLRequest;
@class NSURLProtocol;

@interface NSURLDownload : NSObject
{
	id _delegate;
	NSString *_destination;
	NSURLRequest *_request;
	NSData *_resumeData;
	NSURLProtocol *_protocol;
	BOOL _done;
	BOOL _deletesFileUponFailure;
}

+ (BOOL) canResumeDownloadDecodedWithEncodingMIMEType:(NSString *) MIMEType;

- (void) cancel;
- (BOOL) deletesFileUponFailure;
- (NSString *) destination;	// missing in documentation?
- (id) initWithRequest:(NSURLRequest *) request delegate:(id) delegate;
- (id) initWithResumeData:(NSData *) resumeData delegate:(id) delegate path:(NSString *) path;
- (NSURLRequest *) request;
- (NSData *) resumeData;
- (void) setDeletesFileUponFailure:(BOOL) flag;
- (void) setDestination:(NSString *) path allowOverwrite:(BOOL) flag;

@end

@interface NSObject (NSURLDownloadDelegate)

- (void) download:(NSURLDownload *) download decideDestinationWithSuggestedFilename:(NSString *) filename;
- (void) download:(NSURLDownload *) download didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) download:(NSURLDownload *) download didCreateDestination:(NSString *) path;
- (void) download:(NSURLDownload *) download didFailWithError:(NSError *) error;
- (void) download:(NSURLDownload *) download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) download:(NSURLDownload *) download didReceiveDataOfLength:(NSUInteger) len;
- (void) download:(NSURLDownload *) download didReceiveResponse:(NSURLResponse *) response;
- (BOOL) download:(NSURLDownload *) download shouldDecodeSourceDataOfMIMEType:(NSString *) MIMEType;
- (void) download:(NSURLDownload *) download willResumeWithResponse:(NSURLResponse *) response fromByte:(long long) startingByte;
- (NSURLRequest *) download:(NSURLDownload *) download willSendRequest:(NSURLRequest *) request redirectResponse:(NSURLResponse *) redirectResponse;
- (void) downloadDidBegin:(NSURLDownload *) download;
- (void) downloadDidFinish:(NSURLDownload *) download;

@end
