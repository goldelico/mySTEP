/*$Id: SenEmptiness.m,v 1.4 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenEmptiness.h"
#import "SenFoundationDefines.h"

@implementation NSObject (SenEmptinessExtension)
- (BOOL) notEmpty
{
    return ![(id <SenEmptiness>) self isEmpty];
}
@end


@implementation NSString (SenEmptinessPrimitive)
- (BOOL) isEmpty
// This is the correct implementation: Testing for a null length with
// ([self length] == 0) does not work with Unicode.
{
    return ([self isEqualToString:@""]);
}
@end


@implementation NSData (SenEmptinessPrimitive)
- (BOOL) isEmpty
{
    return ([self length] == 0);
}
@end


@implementation NSArray (SenEmptinessPrimitive)
- (BOOL) isEmpty
{
    return ([self count] == 0);
}
@end


@implementation NSDictionary (SenEmptinessPrimitive)
- (BOOL) isEmpty
{
    return ([self count] == 0);
}
@end


@implementation NSSet (SenEmptinessPrimitive)
- (BOOL) isEmpty
{
    return ([self count] == 0);
}
@end


inline BOOL isNilOrEmpty (id <SenEmptiness> object)
{
    return (object == nil) || [object isEmpty];
}

inline BOOL isNotEmpty (id <SenEmptiness> object)
{
    return !isNilOrEmpty(object);
}
