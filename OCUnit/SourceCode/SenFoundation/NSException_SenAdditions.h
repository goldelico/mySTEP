/*$Id: NSException_SenAdditions.h,v 1.4 2001/11/22 13:11:46 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>

@interface NSException (SenAdditions)

- (BOOL) isOfType:(NSString *) aName;
@end
