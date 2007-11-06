/* Definition of class NSNumberFormatter
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by: 	Fred Kiefer <FredKiefer@gmx.de>
   Date: 	July 2000
   Updated by: Richard Frith-Macdonald <rfm@gnu.org> Sept 2001
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   This file is part of the GNUstep Library.
   
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

#ifndef _NSNumberFormatter_h__
#define _NSNumberFormatter_h__

#import <Foundation/NSObject.h>
#import <Foundation/NSFormatter.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSLocale.h>

@class	NSString, NSAttributedString, NSDictionary;

typedef enum _NSNumberFormatterStyle
{
	NSNumberFormatterNoStyle = 0,
	NSNumberFormatterDecimalStyle,
	NSNumberFormatterCurrencyStyle,
	NSNumberFormatterPercentStyle,
	NSNumberFormatterScientificStyle,
	NSNumberFormatterSpellOutStyle
} NSNumberFormatterStyle;

typedef enum _NSNumberFormatterBehavior
{
	NSNumberFormatterBehaviorDefault = 0,
	NSNumberFormatterBehavior10_0,
	NSNumberFormatterBehavior10_4
} NSNumberFormatterBehavior;

typedef enum _NSNumberFormatterPadPosition
{
	NSNumberFormatterPadBeforePrefix = 0,
	NSNumberFormatterPadAfterPrefix,
	NSNumberFormatterPadBeforeSuffix,
	NSNumberFormatterPadAfterSuffix
} NSNumberFormatterPadPosition;

typedef enum _NSNumberFormatterRoundingMode
{
	NSNumberFormatterRoundCeiling = 0,
	NSNumberFormatterRoundFloor,
	NSNumberFormatterRoundDown,
	NSNumberFormatterRoundHalfEven,
	NSNumberFormatterRoundUp,
	NSNumberFormatterRoundHalfDown,
	NSNumberFormatterRoundHalfUp
} NSNumberFormatterRoundingMode;

@interface NSNumberFormatter : NSFormatter
{
	// FIXME: store everything in a dictionary and not in iVars
	NSMutableDictionary *_attributes;
	// 
	NSDecimalNumberHandler *_roundingBehavior;
	NSDecimalNumber *_maximum;
	NSDecimalNumber *_minimum;
	NSAttributedString *_attributedStringForNil;
	NSAttributedString *_attributedStringForNotANumber;
	NSAttributedString *_attributedStringForZero;
	NSString *_negativeFormat;
	NSString *_positiveFormat;
	NSDictionary *_attributesForPositiveValues;
	NSDictionary *_attributesForNegativeValues;
	NSNumberFormatterStyle _numberStyle;
	unichar _thousandSeparator;
	unichar _decimalSeparator;
	BOOL _hasThousandSeparators;
	BOOL _allowsFloats;
	BOOL _localizesFormat;
}

+ (NSNumberFormatterBehavior) defaultFormatterBehavior;
+ (void) setDefaultFormatterBehavior:(NSNumberFormatterBehavior) behavior;

- (BOOL) allowsFloats;
- (BOOL) alwaysShowsDecimalSeparator;
- (NSAttributedString*) attributedStringForNil;
- (NSAttributedString*) attributedStringForNotANumber;
- (NSAttributedString*) attributedStringForZero;
- (NSString*) currencyCode;
- (NSString*) currencyDecimalSeparator;
- (NSString *) currencyGroupingSeparator;
- (NSString*) currencySymbol;
- (NSString*) decimalSeparator;
- (NSString*) exponentSymbol;
- (NSString*) format;
- (NSNumberFormatterBehavior) formatterBehavior;
- (unsigned int) formatWidth;
- (BOOL) generatesDecimalNumbers;
- (BOOL) getObjectValue:(out id *)anObject
			  forString:(NSString *)aString
				  range:(inout NSRange *)rangep
				  error:(out NSError **)error;
- (NSString *) groupingSeparator;
- (unsigned int) groupingSize;
- (BOOL) hasThousandSeparators;
- (NSString *) internationalCurrencySymbol;
- (BOOL) isLenient;
- (BOOL) isPartialStringValidationEnabled;
- (NSLocale *) locale;
- (BOOL) localizesFormat;
- (NSNumber*) maximum;	// may return NSDecimalNumber
- (unsigned int) maximumFractionDigits;
- (unsigned int) maximumIntegerDigits;
- (NSUInteger) maximumSignificantDigits;
- (NSNumber*) minimum;	// may return NSDecimalNumber
- (unsigned int) minimumFractionDigits;
- (unsigned int) minimumIntegerDigits;
- (NSUInteger) minimumSignificantDigits;
- (NSString *) minusSign;
- (NSNumber *) multiplier;
- (NSString *) negativeFormat;
- (NSString *) negativeInfinitySymbol;
- (NSString *) negativePrefix;
- (NSString *) negativeSuffix;
- (NSString *) nilSymbol;
- (NSString *) notANumberSymbol;
- (NSNumber *) numberFromString:(NSString *) string;
- (NSNumberFormatterStyle) numberStyle;
- (NSString *) paddingCharacter;
- (NSNumberFormatterPadPosition) paddingPosition;
- (NSString *) percentSymbol;
- (NSString *) perMillSymbol;
- (NSString *) plusSign;
- (NSString *) positiveFormat;
- (NSString *) positiveInfinitySymbol;
- (NSString *) positivePrefix;
- (NSString *) positiveSuffix;
- (NSDecimalNumberHandler*) roundingBehavior;
- (NSNumber *) roundingIncrement;
- (NSNumberFormatterRoundingMode) roundingMode;
- (unsigned int) secondaryGroupingSize;
- (void) setAllowsFloats: (BOOL)flag;
- (void) setAlwaysShowsDecimalSeparator:(BOOL)flag;
- (void) setAttributedStringForNil: (NSAttributedString*)newAttributedString;
- (void) setAttributedStringForNotANumber: (NSAttributedString*)newAttributedString;
- (void) setAttributedStringForZero: (NSAttributedString*)newAttributedString;
- (void) setCurrencyCode:(NSString *)string;
- (void) setCurrencyDecimalSeparator:(NSString *)string;
- (void) setCurrencyGroupingSeparator:(NSString *)string;
- (void) setCurrencySymbol:(NSString *)string;
- (void) setDecimalSeparator: (NSString*)newSeparator;
- (void) setExponentSymbol:(NSString *)string;
- (void) setFormat:(NSString*)aFormat;
- (void) setFormatterBehavior:(NSNumberFormatterBehavior)behavior;
- (void) setFormatWidth:(unsigned int)number;
- (void) setGeneratesDecimalNumbers:(BOOL)flag;
- (void) setGroupingSeparator:(NSString *)string;
- (void) setGroupingSize:(unsigned int)size;
- (void) setHasThousandSeparators: (BOOL)flag;
- (void) setInternationalCurrencySymbol:(NSString *)string;
- (void) setLenient:(BOOL) flag;
- (void) setLocale:(NSLocale *)locale;
- (void) setLocalizesFormat: (BOOL)flag;
- (void) setMaximum: (NSNumber*)aMaximum;
- (void) setMaximumFractionDigits:(unsigned int)number;
- (void) setMaximumIntegerDigits:(unsigned int)number;
- (void) setMaximumSignificantDigits:(NSUInteger) number;
- (void) setMinimum: (NSNumber*)aMinimum;
- (void) setMinimumFractionDigits:(unsigned int)number;
- (void) setMinimumIntegerDigits:(unsigned int)number;
- (void) setMinimumSignificantDigits:(NSUInteger) number;
- (void) setMinusSign:(NSString *)string;
- (void) setMultiplier:(NSNumber *)number;
- (void) setNegativeFormat: (NSString*)aFormat;
- (void) setNegativeInfinitySymbol:(NSString *)string;
- (void) setNegativePrefix:(NSString *)string;
- (void) setNegativeSuffix:(NSString *)string;
- (void) setNilSymbol:(NSString *)string;
- (void) setNotANumberSymbol:(NSString *)string;
- (void) setNumberStyle:(NSNumberFormatterStyle)style;
- (void) setPaddingCharacter:(NSString *)string;
- (void) setPaddingPosition:(NSNumberFormatterPadPosition)position;
- (void) setPartialStringValidationEnabled:(BOOL) flag;
- (void) setPercentSymbol:(NSString *)string;
- (void) setPerMillSymbol:(NSString *)string;
- (void) setPlusSign:(NSString *)string;
- (void) setPositiveFormat: (NSString*)aFormat;
- (void) setPositiveInfinitySymbol:(NSString *)string;
- (void) setPositivePrefix:(NSString *)string;
- (void) setPositiveSuffix:(NSString *)string;
- (void) setRoundingBehavior: (NSDecimalNumberHandler*)newRoundingBehavior;
- (void) setRoundingIncrement:(NSNumber *)number;
- (void) setRoundingMode:(NSNumberFormatterRoundingMode)mode;
- (void) setSecondaryGroupingSize:(unsigned int)number;
- (void) setTextAttributesForNegativeInfinity:(NSDictionary *)newAttributes;
- (void) setTextAttributesForNegativeValues: (NSDictionary*)newAttributes;
- (void) setTextAttributesForNil:(NSDictionary *)newAttributes;
- (void) setTextAttributesForNotANumber:(NSDictionary *)newAttributes;
- (void) setTextAttributesForPositiveInfinity:(NSDictionary *)newAttributes;
- (void) setTextAttributesForPositiveValues: (NSDictionary*)newAttributes;
- (void) setTextAttributesForZero:(NSDictionary *)newAttributes;
- (void) setThousandSeparator: (NSString*)newSeparator;
- (void) setUsesGroupingSeparator:(BOOL) flag;
- (void) setUsesSignificantDigits:(BOOL) flag;
- (void) setZeroSymbol:(NSString *)string;
- (NSString *) stringFromNumber:(NSNumber *)number;
- (NSDictionary *) textAttributesForNegativeInfinity;
- (NSDictionary*) textAttributesForNegativeValues;
- (NSDictionary *) textAttributesForNil;
- (NSDictionary *) textAttributesForNotANumber;
- (NSDictionary *) textAttributesForPositiveInfinity;
- (NSDictionary*) textAttributesForPositiveValues;
- (NSDictionary *) textAttributesForZero;
- (NSString*) thousandSeparator;
- (BOOL) usesGroupingSeparator;
- (BOOL) usesSignificantDigits;
- (NSString *) zeroSymbol;

@end

#endif
