/*$Id: SenRandom.h,v 1.1 2001/11/22 13:11:08 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>

#define SEN_RANDOM_N 624

@interface SenRandom : NSObject 
{
    unsigned long mag01[2];
    int mti;
    unsigned long mt[SEN_RANDOM_N];
}

+ defaultGenerator;

- initWithSeed:(unsigned short) seed;
- (void) setSeed:(unsigned short) seed;

- (unsigned long) nextUnsignedLong;
- (unsigned short) nextUnsignedShort;
- (unsigned char) nextUnsignedChar;

- (unsigned int) nextIntegerLessThan:(unsigned int) upperBound;

- (BOOL) nextBoolean;
- (BOOL) nextBooleanWithProbability:(float) probability;

- (double) nextDoubleFrom0To1;

@end
