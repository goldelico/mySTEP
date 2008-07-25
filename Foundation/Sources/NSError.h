/*
    NSError.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
    Copyright (c) 2004 DSITRI.

  	H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5

    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	9. May 2008 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSERROR_H
#define mySTEP_NSERROR_H

#import "Foundation/NSObject.h"

@class NSArray;
@class NSCoder;
@class NSDictionary;
@class NSString;

extern NSString *CFStreamErrorDomain;	// FIXME: is enum on real CF?
extern NSString *NSCocoaErrorDomain;
extern NSString *NSMachErrorDomain;
extern NSString *NSOSStatusErrorDomain;
extern NSString *NSPOSIXErrorDomain;

extern NSString *NSFilePathErrorKey;
extern NSString *NSLocalizedDescriptionKey;
extern NSString *NSStringEncodingErrorKey;
extern NSString *NSUnderlyingErrorKey;

extern NSString *NSLocalizedFailureReasonErrorKey;
extern NSString *NSLocalizedRecoverySuggestionErrorKey;
extern NSString *NSLocalizedRecoveryOptionsErrorKey;
extern NSString *NSRecoveryAttempterErrorKey;


@interface NSError : NSObject <NSCoding, NSCopying>
{
	NSString *_domain;
	NSDictionary *_dict;
	int _code;
}

+ (id) errorWithDomain:(NSString *) domain code:(NSInteger) code userInfo:(NSDictionary *) dict;

- (NSInteger) code;
- (NSString *) domain;
- (id) initWithDomain:(NSString *) domain code:(NSInteger) code userInfo:(NSDictionary *) dict;
- (NSString *) localizedDescription;
- (NSString *) localizedFailureReason;
- (NSArray *) localizedRecoveryOptions;
- (NSString *) localizedRecoverySuggestion;
- (id) recoveryAttempter;
- (NSDictionary *) userInfo;

@end

@interface NSObject (NSErrorRecoveryAttempting)

- (BOOL) attemptRecoveryFromError:(NSError *) err optionIndex:(NSUInteger) idx;
- (void) attemptRecoveryFromError:(NSError *) err 
					  optionIndex:(NSUInteger) idx 
						 delegate:(id) del 
			   didRecoverSelector:(SEL) sel 
					  contextInfo:(void *) context;

@end

#endif // mySTEP_NSERROR_H
