// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenRandom.h"
#import <SenTestingKit/SenTestingKit.h>

extern void isgenrand(unsigned long seed);
extern unsigned long igenrand(void);

extern void sgenrand(unsigned long seed);
extern double genrand(void);

extern inline unsigned long seedMT (unsigned long seed);
extern inline unsigned long randomMT(void);

@interface SenRandomTest : SenTestCase
{
    SenRandom * generator;
}

@end
