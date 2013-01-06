/*$Id: SenRandom.m,v 1.1 2004/03/03 16:08:42 william Exp $*/

// Copyright (c) 1997-2003, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

// This is a Mersenne Twister implementation. The original code and license can be found
// in this distribution in the mt19937int.c file. 
// More information at http://www.math.keio.ac.jp/~matumoto/emt.html

#import "SenRandom.h"

#define N SEN_RANDOM_N
#define M 397
#define MATRIX_A 0x9908b0df   /* constant vector a */
#define UPPER_MASK 0x80000000 /* most significant w-r bits */
#define LOWER_MASK 0x7fffffff /* least significant r bits */

/* Tempering parameters */   
#define TEMPERING_MASK_B 0x9d2c5680
#define TEMPERING_MASK_C 0xefc60000
#define TEMPERING_SHIFT_U(y)  (y >> 11)
#define TEMPERING_SHIFT_S(y)  (y << 7)
#define TEMPERING_SHIFT_T(y)  (y << 15)
#define TEMPERING_SHIFT_L(y)  (y >> 18)

#define DEFAULT_SEED 4357

#define DOUBLE_2_TO_32 (1.0 + (double) 0xffffffffU)

#define NEXT_UNSIGNED_LONG \
( \
    { \
        unsigned long y; \
        if (mti >= N) {\
            int kk;\
            for (kk=0;kk<N-M;kk++) {\
                y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);\
                mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];\
            }\
            for (;kk<N-1;kk++) {\
                y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);\
                mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];\
            }\
            y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);\
            mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];\
            mti = 0;\
        }\
    \
        y = mt[mti++];\
        y ^= TEMPERING_SHIFT_U(y);\
        y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;\
        y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;\
        y ^= TEMPERING_SHIFT_L(y);\
    \
        y; \
    }\
)


@implementation SenRandom
+ defaultGenerator
{
    static SenRandom *defaultGenerator = nil;
    if (defaultGenerator == nil) {
        defaultGenerator = [[self alloc] init];
    }
    return defaultGenerator;
}


- init
{
    return [self initWithSeed:DEFAULT_SEED];
}


- initWithSeed:(unsigned short) seed
{
    [super init];
    [self setSeed:seed];
    mag01[0] = 0x0;
    mag01[1] = MATRIX_A;
    return self;
}


- (void) setSeed:(unsigned short) seed
{
    mt[0] = seed & 0xffffffffU;
    for (mti = 1; mti < N; mti++) {
        mt[mti] = (69069 * mt[mti - 1]) & 0xffffffffU;
    }
}


- (unsigned long) nextUnsignedLong
{
    return NEXT_UNSIGNED_LONG; 
}


- (unsigned short) nextUnsignedShort
{
    return (short)(NEXT_UNSIGNED_LONG >> 16);
}


- (unsigned char) nextUnsignedChar
{
    return (char)(NEXT_UNSIGNED_LONG >> 24);
}


- (BOOL) nextBoolean
{
    return (NEXT_UNSIGNED_LONG >> 31) != 0;
}


- (BOOL) nextBooleanWithProbability:(float) probability
{
    if (probability < 0.0 || probability > 1.0) {
        [NSException raise:NSInvalidArgumentException format:@"%f should be between 0.0 and 1.0", probability];
        return NO;
    }
    else if (probability == 0.0) {
        return NO;
    }
    else if (probability == 1.0) {
        return YES;
    }
    else {
	return (NEXT_UNSIGNED_LONG >> 8) / ((float)(1 << 24)) < probability;
    }
}


- (double) nextDoubleFrom0To1
{
    return ((double)NEXT_UNSIGNED_LONG / 0xffffffffU);
}


- (unsigned int) nextIntegerLessThan:(unsigned int) upperBound
{
    
    return (unsigned int) floor (((double)NEXT_UNSIGNED_LONG / DOUBLE_2_TO_32 * upperBound));
}
@end
