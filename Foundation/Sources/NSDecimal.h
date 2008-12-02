/* NSDecimal types and functions
   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Created: November 1998

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

   */

#ifndef __NSDecimal_h_GNUSTEP_BASE_INCLUDE
#define __NSDecimal_h_GNUSTEP_BASE_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>

typedef	enum _NSRoundingMode
{
	NSRoundDown,
	NSRoundUp,
	NSRoundPlain,		/* Round .5 up		*/
	NSRoundBankers	/* Make last digit even	*/
} NSRoundingMode;

typedef enum _NSCalculationError
{
	NSCalculationNoError = 0,
	NSCalculationUnderflow,	/* result became zero */
	NSCalculationOverflow,
	NSCalculationLossOfPrecision,
	NSCalculationDivideByZero
} NSCalculationError;

/*
 *	Give a precision of at least 38 decimal digits
 *	requires 128 bits.
 */

#define NSDecimalMaxSize (16/sizeof(mp_limb_t))

#define NSDecimalMaxDigit 38
#define NSDecimalNoScale 128

// FIXME: this is NOT compatible to 10.4!

typedef struct
{
	signed char		exponent;		// Signed exponent - -128 to 127
	BOOL			isNegative;		// Is this negative?
	BOOL			validNumber;	// Is this a valid number?
	unsigned char	length;			// digits in mantissa
	unsigned char	cMantissa[NSDecimalMaxDigit];
} NSDecimal;

static inline BOOL NSDecimalIsNotANumber(const NSDecimal *decimal) { return (decimal->validNumber == NO); }

void NSDecimalCopy(NSDecimal *destination, const NSDecimal *source);
void NSDecimalCompact(NSDecimal *number);
NSComparisonResult NSDecimalCompare(const NSDecimal *leftOperand, const NSDecimal *rightOperand);
void NSDecimalRound(NSDecimal *result, const NSDecimal *number, int scale, NSRoundingMode mode);
NSCalculationError NSDecimalNormalize(NSDecimal *n1, NSDecimal *n2, NSRoundingMode mode);
NSCalculationError NSDecimalAdd(NSDecimal *result, const NSDecimal *left, const NSDecimal *right, NSRoundingMode mode);
NSCalculationError NSDecimalSubtract(NSDecimal *result, const NSDecimal *left, const NSDecimal *right, NSRoundingMode mode);
NSCalculationError NSDecimalMultiply(NSDecimal *result, const NSDecimal *l, const NSDecimal *r, NSRoundingMode mode);
NSCalculationError NSDecimalDivide(NSDecimal *result, const NSDecimal *l, const NSDecimal *rr, NSRoundingMode mode);
NSCalculationError NSDecimalPower(NSDecimal *result, const NSDecimal *n, unsigned power, NSRoundingMode mode);
NSCalculationError NSDecimalMultiplyByPowerOf10(NSDecimal *result, const NSDecimal *n, short power, NSRoundingMode mode);
NSString *NSDecimalString(const NSDecimal *decimal, NSDictionary *locale);

#endif // __NSDecimal_h_GNUSTEP_BASE_INCLUDE
