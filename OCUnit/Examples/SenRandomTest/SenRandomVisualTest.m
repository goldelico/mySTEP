// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenRandomVisualTest.h"


@implementation SenRandomVisualTest
- (void) testLogSomeNumbers
{
    unsigned long count = 10;
    while (count--) {
        NSLog (@"%u", [generator nextUnsignedLong]);
    }
}
@end
