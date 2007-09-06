//
//  NSErrorRecoveryAttempting.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Dec 27 2005.
//  Copyright (c) 2005 DSITRI.
//
//	H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef mySTEP_NSERROR_H
#define mySTEP_NSERROR_H

#import "Foundation/NSObject.h"
#import "Foundation/NSError.h"

@interface NSObject (NSErrorRecoveryAttempting)

- (BOOL) attemptRecoveryFromError:(NSError *) error
					  optionIndex:(unsigned int) recoveryOptionIndex;

- (void) attemptRecoveryFromError:(NSError *) error
					  optionIndex:(unsigned int) recoveryOptionIndex
						 delegate:(id) delegate
			   didRecoverSelector:(SEL) didRecoverSelector
					  contextInfo:(void *) contextInfo;

- (void) didPresentErrorWithRecovery:(BOOL) didRecover
						 contextInfo:(void *) contextInfo;

@end

#endif // mySTEP_NSERROR_H
