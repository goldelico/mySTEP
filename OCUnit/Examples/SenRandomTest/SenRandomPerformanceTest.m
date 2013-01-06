// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.


#import "SenRandomPerformanceTest.h"

#define SEQUENCE_LENGTH (10L * 1000L * 1000L)


@implementation SenRandomPerformanceTest
- (void) testSenRandom
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        (void) [generator nextUnsignedLong];
    }
}


- (void) testOptimizedSenRandom
{
    unsigned long count = SEQUENCE_LENGTH;
    SEL nextUnsignedLongSelector = @selector(nextUnsignedLong);
    unsigned long (*nextUnsignedLongFunction) (id, SEL);
    nextUnsignedLongFunction  = (unsigned long (*)(id, SEL)) [generator methodForSelector:nextUnsignedLongSelector];
    while (count--) {
        (void) nextUnsignedLongFunction (generator, nextUnsignedLongSelector);
    }
}


- (void) testMersenne
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        (void) igenrand();
    }
}


- (void) testSystemRand
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        (void) rand();
    }
}


- (void) testSystemRandom
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        (void) random();
    }
}


- (void) testCokus
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        (void) randomMT();
    }
}
@end
