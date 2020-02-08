/**
 NSDecimalNumber class
 Copyright (C) 2000 Free Software Foundation, Inc.

 Written by: Fred Kiefer <FredKiefer@gmx.de>
 Created: July 2000

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

 <title>NSDecimalNumber class reference</title>
 $Date: 2004/06/22 22:40:37 $ $Revision: 1.11 $
 */

#import <Foundation/NSException.h>
#import <Foundation/NSDecimal.h>
#import <Foundation/NSDecimalNumber.h>

#import "NSPrivate.h"

// shared default behavior for NSDecimalNumber class
static NSDecimalNumberHandler *handler;

@implementation NSDecimalNumberHandler

+ (id) defaultDecimalNumberHandler
{
	if (handler == nil)
		handler = [[self alloc] initWithRoundingMode: NSRoundPlain
											   scale: 38
									raiseOnExactness: NO
									 raiseOnOverflow: YES
									raiseOnUnderflow: YES
								 raiseOnDivideByZero: YES];

	return handler;
}

+ (id) decimalNumberHandlerWithRoundingMode: (NSRoundingMode)roundingMode
									  scale: (short)scale
						   raiseOnExactness: (BOOL)raiseOnExactness
							raiseOnOverflow: (BOOL)raiseOnOverflow
						   raiseOnUnderflow: (BOOL)raiseOnUnderflow
						raiseOnDivideByZero: (BOOL)raiseOnDivideByZero
{
	return AUTORELEASE([[self alloc] initWithRoundingMode: roundingMode
													scale: scale
										 raiseOnExactness: raiseOnExactness
										  raiseOnOverflow: raiseOnOverflow
										 raiseOnUnderflow: raiseOnUnderflow
									  raiseOnDivideByZero: raiseOnDivideByZero]);
}

- (id) initWithRoundingMode: (NSRoundingMode)roundingMode
					  scale: (short)scale
		   raiseOnExactness: (BOOL)raiseOnExactness
			raiseOnOverflow: (BOOL)raiseOnOverflow
		   raiseOnUnderflow: (BOOL)raiseOnUnderflow
		raiseOnDivideByZero: (BOOL)raiseOnDivideByZero
{
	_roundingMode = roundingMode;
	_scale = scale;
	_raiseOnExactness = raiseOnExactness;
	_raiseOnOverflow = raiseOnOverflow;
	_raiseOnUnderflow = raiseOnUnderflow;
	_raiseOnDivideByZero = raiseOnDivideByZero;

	return self;
}

- (NSDecimalNumber*) exceptionDuringOperation: (SEL)method
										error: (NSCalculationError)error
								  leftOperand: (NSDecimalNumber*)leftOperand
								 rightOperand: (NSDecimalNumber*)rightOperand
{
	switch (error)
	{
		case NSCalculationNoError: return nil;
		case NSCalculationUnderflow:
		if (_raiseOnUnderflow)
			// FIXME: What exception to raise?
			[NSException raise: @"NSDecimalNumberException"
						format: @"Underflow"];
		else
			return [NSDecimalNumber minimumDecimalNumber];
		break;
		case NSCalculationOverflow:
		if (_raiseOnOverflow)
			[NSException raise: @"NSDecimalNumberException"
						format: @"Overflow"];
		else
			return [NSDecimalNumber maximumDecimalNumber];
		break;
		case NSCalculationLossOfPrecision:
		if (_raiseOnExactness)
			[NSException raise: @"NSDecimalNumberException"
						format: @"Loss of precision"];
		else
			return nil;
		break;
		case NSCalculationDivideByZero:
		if (_raiseOnDivideByZero)
			[NSException raise: @"NSDecimalNumberException"
						format: @"Divide by zero"];
		else
			return [NSDecimalNumber notANumber];
		break;
	}

	return nil;
}

- (NSRoundingMode) roundingMode
{
	return _roundingMode;
}

- (short) scale
{
	return _scale;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	_roundingMode=[coder decodeIntForKey:@"NS.roundingmode"];
	_raiseOnDivideByZero=[coder decodeIntForKey:@"NS.raise.dividebyzero"];
	_raiseOnUnderflow=[coder decodeIntForKey:@"NS.raise.underflow"];
	_raiseOnOverflow=[coder decodeIntForKey:@"NS.raise.overflow"];
	_raiseOnExactness=[coder decodeIntForKey:@"NS.raise.exactness"];
	// _scale=?
	return self;
}

@end


@implementation NSDecimalNumber

static NSDecimalNumber *maxNumber;
static NSDecimalNumber *minNumber;
static NSDecimalNumber *notANumber;
static NSDecimalNumber *zero;
static NSDecimalNumber *one;

+ (void) initialize
{
	NSDecimal d;

	d.validNumber = NO;
	notANumber = [[self alloc] initWithDecimal: d];
	NSDecimalMax(&d);
	maxNumber = [[self alloc] initWithDecimal: d];
	NSDecimalMin(&d);
	minNumber = [[self alloc] initWithDecimal: d];
	zero = [[self alloc] initWithMantissa: 0
								 exponent: 0
							   isNegative: NO];
	one = [[self alloc] initWithMantissa: 1
								exponent: 0
							  isNegative: NO];
}

+ (id) allocWithZone: (NSZone*)z
{ // we need a private allocator to override NSNumber singleton initialization
	return (NSDecimalNumber *) NSAllocateObject(self, 0, z);
}

+ (id) alloc;
{
	return (NSDecimalNumber *) NSAllocateObject(self, 0, NSDefaultMallocZone());
}

+ (id <NSDecimalNumberBehaviors>) defaultBehavior
{
	// Reuse the handler from the class NSDecimalNumberHandler
	return [NSDecimalNumberHandler defaultDecimalNumberHandler];
}

+ (void) setDefaultBehavior: (id <NSDecimalNumberBehaviors>)behavior
{
	// Reuse the handler from the class NSDecimalNumberHandler
	// Might give interessting result on this class as behavior may came
	// from a different class
	ASSIGN(handler, behavior);
}

+ (NSDecimalNumber*) maximumDecimalNumber
{
	return maxNumber;
}
+ (NSDecimalNumber*) minimumDecimalNumber
{
	return minNumber;
}

+ (NSDecimalNumber*) notANumber
{
	return notANumber;
}

+ (NSDecimalNumber*) zero
{
	return zero;
}

+ (NSDecimalNumber*) one
{
	return one;
}

+ (NSDecimalNumber*) decimalNumberWithDecimal: (NSDecimal)decimal
{
	return AUTORELEASE([[self alloc] initWithDecimal: decimal]);
}

+ (NSDecimalNumber*) decimalNumberWithMantissa: (unsigned long long)mantissa
									  exponent: (short)exponent
									isNegative: (BOOL)isNegative
{
	return AUTORELEASE([[self alloc] initWithMantissa: mantissa
											 exponent: exponent
										   isNegative: isNegative]);
}

+ (NSDecimalNumber*) decimalNumberWithString: (NSString*)numericString
{
	return AUTORELEASE([[self alloc] initWithString: numericString]);
}

+ (NSDecimalNumber*) decimalNumberWithString: (NSString*)numericString
									  locale: (NSDictionary*)locale
{
	return AUTORELEASE([[self alloc] initWithString: numericString
											 locale: locale]);
}

/**
 * Inefficient ... quick hack by converting double value to string,
 * then initialising from string.
 */
- (id) initWithBytes: (const void*)value objCType: (const char*)type
{
	double	tmp;
	NSString	*s;

	memcpy(&tmp, value, sizeof(tmp));
	s = [[NSString alloc] initWithFormat: @"%g", tmp];
	self = [self initWithString: s];
	RELEASE(s);
	return self;
}

- (id) initWithDecimal: (NSDecimal)decimal
{
	NSDecimalCopy(&data, &decimal);
	return self;
}

- (id) initWithMantissa: (unsigned long long)mantissa
			   exponent: (short)exponent
			 isNegative: (BOOL)flag
{
	NSDecimal decimal;

	NSDecimalFromComponents(&decimal, mantissa, exponent, flag);
	return [self initWithDecimal: decimal];
}

- (id) initWithString: (NSString*)numberValue
{
	return [self initWithString: numberValue
						 locale: nil];
}

- (id) initWithString: (NSString*)numberValue
			   locale: (NSDictionary*)locale
{
	NSDecimal decimal;

	NSDecimalFromString(&decimal, numberValue, locale);
	return [self initWithDecimal: decimal];
}

- (id) initWithBool: (BOOL)value
{
	return [self initWithMantissa: (value == YES) ? 1 : 0
						 exponent: 0
					   isNegative: NO];
}

- (id) initWithChar:(char) value
{
	int ival=value;
	if(ival < 0)
		{
		return [self initWithMantissa: -ival
							 exponent: 0
						   isNegative: YES];
		}
	else
		{
		return [self initWithMantissa: ival
							 exponent: 0
						   isNegative: NO];
		}
}

- (id) initWithDouble: (double)value
{
	return [self initWithBytes: &value objCType: "d"];
}

- (id) initWithFloat: (float)value
{
	double	d = (double)value;

	return [self initWithBytes: &d objCType: "d"];
}

- (id) initWithInt: (signed int)value
{
	if (value < 0)
		{
		return [self initWithMantissa: -value
							 exponent: 0
						   isNegative: YES];
		}
	else
		{
		return [self initWithMantissa: value
							 exponent: 0
						   isNegative: NO];
		}
}

- (id) initWithLong: (signed long)value
{
	if (value < 0)
		{
		return [self initWithMantissa: -value
							 exponent: 0
						   isNegative: YES];
		}
	else
		{
		return [self initWithMantissa: value
							 exponent: 0
						   isNegative: NO];
		}
}

- (id) initWithLongLong: (signed long long)value
{
	if (value < 0)
		{
		return [self initWithMantissa: -value
							 exponent: 0
						   isNegative: YES];
		}
	else
		{
		return [self initWithMantissa: value
							 exponent: 0
						   isNegative: NO];
		}
}

- (id) initWithShort: (signed short)value
{
	if (value < 0)
		{
		return [self initWithMantissa: -value
							 exponent: 0
						   isNegative: YES];
		}
	else
		{
		return [self initWithMantissa: value
							 exponent: 0
						   isNegative: NO];
		}
}

- (id) initWithUnsignedChar: (unsigned char)value
{
	return [self initWithMantissa: value
						 exponent: 0
					   isNegative: NO];
}

- (id) initWithUnsignedInt: (unsigned int)value
{
	return [self initWithMantissa: value
						 exponent: 0
					   isNegative: NO];
}

- (id) initWithUnsignedLong: (unsigned long)value
{
	return [self initWithMantissa: value
						 exponent: 0
					   isNegative: NO];
}

- (id) initWithUnsignedLongLong: (unsigned long long)value
{
	return [self initWithMantissa: value
						 exponent: 0
					   isNegative: NO];
}

- (id) initWithUnsignedShort: (unsigned short)value
{
	return [self initWithMantissa: value
						 exponent: 0
					   isNegative: NO];
}

- (NSString*) descriptionWithLocale:(id) locale
{
	return NSDecimalString(&data, locale);
}

- (const char*) objCType
{
	return "d";
}

- (NSDecimal) decimalValue
{
	NSDecimal decimal;

	NSDecimalCopy(&decimal, &data);
	return decimal;
}

- (int) intValue
{
	return NSDecimalDouble(&data);
}

- (float) floatValue
{
	return NSDecimalDouble(&data);
}

- (double) doubleValue
{
	return NSDecimalDouble(&data);
}

/**
 * Get the approximate value of the decimal number into a buffer
 * as a double.
 */
- (void) getValue: (void*)buffer
{
	double	tmp = NSDecimalDouble(&data);

	memcpy(buffer, &tmp, sizeof(tmp));
}

- (NSComparisonResult) compare: (NSNumber*)decimalNumber
{
	// well, we should compare with the lower precision of both?
	//	if ([decimalNumber isMemberOfClass: [self class]])
	//	{
	NSDecimal d1 = [self decimalValue];
	NSDecimal d2 = [(NSDecimalNumber*)decimalNumber decimalValue];

	return NSDecimalCompare(&d1, &d2);
	//		}
	//	else
	//		return [super compare: decimalNumber];
}

- (NSDecimalNumber*) decimalNumberByAdding: (NSDecimalNumber*)decimalNumber
{
	return [self decimalNumberByAdding: decimalNumber
						  withBehavior: [[self class] defaultBehavior]];
}

- (NSDecimalNumber*) decimalNumberByAdding: (NSDecimalNumber*)decimalNumber
							  withBehavior: (id<NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];
	NSDecimal d2 = [decimalNumber decimalValue];
	NSCalculationError error;
	NSDecimalNumber *res;

	error = NSDecimalAdd(&result, &d1, &d2, [behavior roundingMode]);
	if (error)
		{
		res = [behavior exceptionDuringOperation: _cmd
										   error: error
									 leftOperand: self
									rightOperand: decimalNumber];
		if (res != nil)
			return res;
		}

	return [NSDecimalNumber decimalNumberWithDecimal: result];
}

- (NSDecimalNumber*) decimalNumberBySubtracting: (NSDecimalNumber*)decimalNumber
{
	return [self decimalNumberBySubtracting: decimalNumber
							   withBehavior: [[self class] defaultBehavior]];
}

- (NSDecimalNumber*) decimalNumberBySubtracting: (NSDecimalNumber*)decimalNumber
								   withBehavior: (id <NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];
	NSDecimal d2 = [decimalNumber decimalValue];
	NSCalculationError error;
	NSDecimalNumber *res;

	error = NSDecimalSubtract(&result, &d1, &d2, [behavior roundingMode]);
	if (error)
		{
		res = [behavior exceptionDuringOperation: _cmd
										   error: error
									 leftOperand: self
									rightOperand: decimalNumber];
		if (res != nil)
			return res;
		}

	return [NSDecimalNumber decimalNumberWithDecimal: result];
}

- (NSDecimalNumber*) decimalNumberByMultiplyingBy:
(NSDecimalNumber*)decimalNumber
{
	return [self decimalNumberByMultiplyingBy: decimalNumber
								 withBehavior: [[self class] defaultBehavior]];
}

- (NSDecimalNumber*) decimalNumberByMultiplyingBy:
(NSDecimalNumber*)decimalNumber
									 withBehavior: (id <NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];
	NSDecimal d2 = [decimalNumber decimalValue];
	NSCalculationError error;
	NSDecimalNumber *res;

	error = NSDecimalMultiply(&result, &d1, &d2, [behavior roundingMode]);
	if (error)
		{
		res = [behavior exceptionDuringOperation: _cmd
										   error: error
									 leftOperand: self
									rightOperand: decimalNumber];
		if (res != nil)
			return res;
		}

	return [NSDecimalNumber decimalNumberWithDecimal: result];
}

- (NSDecimalNumber*) decimalNumberByDividingBy: (NSDecimalNumber*)decimalNumber
{
	return [self decimalNumberByDividingBy: decimalNumber
							  withBehavior: [[self class] defaultBehavior]];
}

- (NSDecimalNumber*) decimalNumberByDividingBy: (NSDecimalNumber*)decimalNumber
								  withBehavior: (id <NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];
	NSDecimal d2 = [decimalNumber decimalValue];
	NSCalculationError error;
	NSDecimalNumber *res;

	error = NSDecimalDivide(&result, &d1, &d2, [behavior roundingMode]);
	if (error)
		{
		res = [behavior exceptionDuringOperation: _cmd
										   error: error
									 leftOperand: self
									rightOperand: decimalNumber];
		if (res != nil)
			return res;
		}

	return [NSDecimalNumber decimalNumberWithDecimal: result];
}

- (NSDecimalNumber*) decimalNumberByMultiplyingByPowerOf10: (short)power
{
	return [self decimalNumberByMultiplyingByPowerOf10: power
										  withBehavior: [[self class] defaultBehavior]];
}

- (NSDecimalNumber*) decimalNumberByMultiplyingByPowerOf10: (short)power
											  withBehavior: (id <NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];
	NSCalculationError error;
	NSDecimalNumber *res;

	error = NSDecimalMultiplyByPowerOf10(&result, &d1,
										 power, [behavior roundingMode]);
	if (error)
		{
		res = [behavior exceptionDuringOperation: _cmd
										   error: error
									 leftOperand: self
									rightOperand: nil];
		if (res != nil)
			return res;
		}

	return [NSDecimalNumber decimalNumberWithDecimal: result];
}

- (NSDecimalNumber*) decimalNumberByRaisingToPower: (NSUInteger)power
{
	return [self decimalNumberByRaisingToPower: power
								  withBehavior: [[self class] defaultBehavior]];
}

- (NSDecimalNumber*) decimalNumberByRaisingToPower: (NSUInteger)power
									  withBehavior: (id <NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];
	NSCalculationError error;
	NSDecimalNumber *res;

	error = NSDecimalPower(&result, &d1,
						   (NSInteger) power, [behavior roundingMode]);
	if (error)
		{
		res = [behavior exceptionDuringOperation: _cmd
										   error: error
									 leftOperand: self
									rightOperand: nil];
		if (res != nil)
			return res;
		}

	return [NSDecimalNumber decimalNumberWithDecimal: result];
}

- (NSDecimalNumber*) decimalNumberByRoundingAccordingToBehavior:
(id <NSDecimalNumberBehaviors>)behavior
{
	NSDecimal result;
	NSDecimal d1 = [self decimalValue];

	NSDecimalRound(&result, &d1, [behavior scale], [behavior roundingMode]);
	return [NSDecimalNumber decimalNumberWithDecimal: result];
}


// Methods for NSDecimalNumberBehaviors
- (NSDecimalNumber*) exceptionDuringOperation: (SEL)method
										error: (NSCalculationError)error
								  leftOperand: (NSDecimalNumber*)leftOperand
								 rightOperand: (NSDecimalNumber*)rightOperand
{
	return [[[self class] defaultBehavior] exceptionDuringOperation: method
															  error: error
											   leftOperand: leftOperand
													   rightOperand: rightOperand];
}

- (NSRoundingMode) roundingMode
{
	return [[[self class] defaultBehavior] roundingMode];
}

- (short) scale
{
	return [[[self class] defaultBehavior] scale];
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

- (int) _nextOrder						{ return 13; }
- (int) _typeOrder						{ return 13; }

@end

@interface NSDecimalNumberPlaceholder : NSObject	// directly derived from NSObject!

@end

@implementation NSDecimalNumberPlaceholder

- (id) initWithCoder:(NSCoder *) coder;
{
	if([coder allowsKeyedCoding])
		{
		NSDecimal decimal;	// currently NOT compatible to 10.4!
		NSData *mantissa=[coder decodeObjectForKey:@"NS.mantissa"];
		BOOL byteorder=[coder decodeBoolForKey:@"NS.mantissa.bo"];
		if(byteorder)
			{
			// ?
			}
		else
			{
			// ?
			}
		decimal.exponent=[coder decodeIntForKey:@"NS.exponent"];
		decimal.isNegative=[coder decodeBoolForKey:@"NS.negative"];
		decimal.validNumber=YES;
		decimal.length=[coder decodeIntForKey:@"NS.length"];
		if(![coder decodeBoolForKey:@"NS.compact"])
			{
			int i=0;
			const char *bytes=[mantissa bytes];
			if(decimal.length == 0)
				decimal.length=2*[mantissa length];	// 2 digits per byte
													// CHECKME and handle different endian values
			while(i<decimal.length)
				{
				decimal.cMantissa[i++]=(*bytes>>4)&0x0f;
				decimal.cMantissa[i++]=(*bytes>>0)&0x0f;
				bytes++;
				}
			}
		else
			{ // compact
			  // FIXME!!!
				decimal.validNumber=NO;
			}
		[self release];
		return (id) [[NSDecimalNumber alloc] initWithDecimal:decimal];
		}
	return NIMP;
}

@end

@implementation NSNumber (NSDecimalNumber)
/** Returns an NSDecimal representation of the number. Float and double
 values may not be converted exactly */
- (NSDecimal) decimalValue
{
	double num;
	NSDecimalNumber *dnum;
	num = [self doubleValue];
	dnum = [[NSDecimalNumber alloc] initWithBytes: &num objCType: "d"];
	AUTORELEASE(dnum);
	return [dnum decimalValue];
}
@end

