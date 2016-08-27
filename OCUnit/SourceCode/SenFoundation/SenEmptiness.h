/*$Id: SenEmptiness.h,v 1.4 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import "SenFoundationDefines.h"

// These categories implements an important missing method of all Foundation
// containers: isEmpty.

@protocol SenEmptiness
- (BOOL) isEmpty;
- (BOOL) notEmpty;
@end

@interface NSString (SenEmptiness) <SenEmptiness>
@end

@interface NSData (SenEmptiness) <SenEmptiness>
@end

@interface NSArray (SenEmptiness) <SenEmptiness>
@end

@interface NSSet (SenEmptiness) <SenEmptiness>
@end

@interface NSDictionary (SenEmptiness) <SenEmptiness>
@end


SENFOUNDATION_EXTERN_INLINE BOOL isNilOrEmpty (id <SenEmptiness> object);
// Predicate returns YES if object is nil or else object isEmpty
// Runtime error if object does not respond to isEmpty.

SENFOUNDATION_EXTERN_INLINE BOOL isNotEmpty (id <SenEmptiness> object);
