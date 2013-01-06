// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenRandomTest.h"

#define DEFAULT_SEED 4357

@implementation SenRandomTest
- (void) setUp
{
    generator = [[SenRandom alloc] initWithSeed:DEFAULT_SEED];
    isgenrand(DEFAULT_SEED);
    sgenrand (DEFAULT_SEED);
    seedMT(DEFAULT_SEED);
}


- (void) tearDown
{
    [generator release];
}
@end
