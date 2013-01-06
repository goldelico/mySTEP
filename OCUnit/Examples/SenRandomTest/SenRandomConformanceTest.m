// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenRandomConformanceTest.h"

#define SEQUENCE_LENGTH 100L * 1000L

@implementation SenRandomConformanceTest
- (void) testSenRandomUnsignedLong
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        STAssertTrue (([generator nextUnsignedLong] == igenrand()),
                      @"The method -nextUnsignedLong should equal the function igenrand().");
    }
}


- (void) testSenRandomDouble
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        double generated = [generator nextDoubleFrom0To1];
        STAssertTrue ((generated == genrand()),
                      @"The method -nextDoubleFrom0To1 should equal the function genrand().");
        STAssertTrue (((generated >= 0.0) && (generated <= 1.0)),
                      @"The method -nextDoubleFrom0To1 should return a value between zero and one.");
    }
}


- (void) testCokus
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        STAssertTrue ((randomMT() == igenrand()),
                      @"The functions randomMT() and igenrand() should return the same value.");
    }
}


- (void) testOptimizedSenRandom
{
    unsigned long count = SEQUENCE_LENGTH;
    SEL nextUnsignedLongSelector = @selector(nextUnsignedLong);
    unsigned long (*nextUnsignedLongFunction) (id, SEL);
    nextUnsignedLongFunction  = (unsigned long (*)(id, SEL)) [generator methodForSelector:nextUnsignedLongSelector];
    while (count--) {
        STAssertTrue ((nextUnsignedLongFunction (generator, nextUnsignedLongSelector) == igenrand()),
                      @"");
    }
}


- (void) testDice
{
    unsigned long count = SEQUENCE_LENGTH;
    while (count--) {
        unsigned int sideCount = 2 + [generator nextIntegerLessThan:99];
        STAssertTrue ((sideCount <= 100), @"");
        STAssertTrue (([generator nextIntegerLessThan:sideCount] < sideCount), @"");
    }
}

@end
