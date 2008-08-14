//
//  NSURLAuthenticationChallenge.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSURLAuthenticationChallenge.h>
#import <Foundation/NSURLCredential.h>
#import <Foundation/NSURLResponse.h>
#import <Foundation/NSURLProtectionSpace.h>
#import <Foundation/NSError.h>


@implementation NSURLAuthenticationChallenge

- (NSError *) error; { return _error; }
- (NSURLResponse *) failureResponse; { return _failureResponse; }

- (id) initWithAuthenticationChallenge:(NSURLAuthenticationChallenge *) challenge
								sender:(id <NSURLAuthenticationChallengeSender>) sender;
{
	return [self initWithProtectionSpace:challenge->_protectionSpace
					  proposedCredential:challenge->_proposedCredential
					previousFailureCount:challenge->_previousFailureCount
						 failureResponse:challenge->_failureResponse
								   error:challenge->_error
								  sender:sender];
}

- (id) initWithProtectionSpace:(NSURLProtectionSpace *) space
			proposedCredential:(NSURLCredential *) credential
		  previousFailureCount:(int) count
			   failureResponse:(NSURLResponse *) response
						 error:(NSError *) error
						sender:(id <NSURLAuthenticationChallengeSender>) sender;
{
	if((self=[super init]))
		{
		_error=[error retain];
		_failureResponse=[response retain];
		_proposedCredential=[credential retain];
		_protectionSpace=[space retain];
//		_sender=[sender retain];
		_sender=sender;	// can't assume that it responds to the NSObject protocol
		_previousFailureCount=count;
		}
	return self;
}

- (void) dealloc;
{
	[_error release];
	[_failureResponse release];
	[_proposedCredential release];
	[_protectionSpace release];
//	[_sender release];
	[super dealloc];
}

- (int) previousFailureCount; { return _previousFailureCount; }
- (NSURLCredential *) proposedCredential; { return _proposedCredential; }
- (NSURLProtectionSpace *) protectionSpace; { return _protectionSpace; }
- (id <NSURLAuthenticationChallengeSender>) sender; { return _sender; }

@end
