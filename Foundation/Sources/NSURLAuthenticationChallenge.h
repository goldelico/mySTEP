//
//  NSURLAuthenticationChallenge.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSObject.h>

@class NSError;
@class NSURLAuthenticationChallenge;
@class NSURLCredential;
@class NSURLProtectionSpace;
@class NSURLResponse;

@protocol NSURLAuthenticationChallengeSender

- (void) cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;
- (void) useCredential:(NSURLCredential *) credential forAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge;

@end

@interface NSURLAuthenticationChallenge : NSObject
{
	NSError *_error;
	NSURLResponse *_failureResponse;
	NSURLCredential *_proposedCredential;
	NSURLProtectionSpace *_protectionSpace;
	id <NSURLAuthenticationChallengeSender> _sender;
	unsigned _previousFailureCount;
}

- (NSError *) error;
- (NSURLResponse *) failureResponse;
- (id) initWithAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge
								sender:(id <NSURLAuthenticationChallengeSender>) sender;
- (id) initWithProtectionSpace:(NSURLProtectionSpace *) space
			proposedCredential:(NSURLCredential *) credential
		  previousFailureCount:(int) count
			   failureResponse:(NSURLResponse *) response
						 error:(NSError *) error
						sender:(id <NSURLAuthenticationChallengeSender>) sender;
- (unsigned) previousFailureCount;
- (NSURLCredential *) proposedCredential;
- (NSURLProtectionSpace *) protectionSpace;
- (id <NSURLAuthenticationChallengeSender>) sender;

@end