/* Interface for NSDateFormatter for GNUStep
   Copyright (C) 1998 Free Software Foundation, Inc.

   Header Written by:  Camille Troillard <tuscland@wanadoo.fr>
   Created: November 1998
   Modified by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

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

#ifndef __NSDateFormatter_h_GNUSTEP_BASE_INCLUDE
#define __NSDateFormatter_h_GNUSTEP_BASE_INCLUDE

#import <Foundation/NSFormatter.h>
#import <Foundation/NSError.h>
#import <Foundation/NSRange.h>

typedef enum
{
	NSDateFormatterNoStyle,
	NSDateFormatterShortStyle,
	NSDateFormatterMediumStyle,
	NSDateFormatterLongStyle,
	NSDateFormatterFullStyle
} NSDateFormatterStyle;

typedef enum _NSDateFormatterBehavior
{
	NSDateFormatterBehaviorDefault,
	NSDateFormatterBehavior10_0 = 1000,
	NSDateFormatterBehavior10_4 = 1040
} NSDateFormatterBehavior;

@class NSMutableDictionary;
@class NSCalendar;
@class NSLocale;

@interface NSDateFormatter : NSFormatter <NSCoding, NSCopying>
{
//	NSString				*_dateFormat;
//	NSDateFormatterBehavior	_formatterBehavior;
//	NSDateFormatterStyle	_dateStyle;
//	NSDate 					*_defaultDate;
//	NSLocale				*_locale;
	NSMutableDictionary		*_attributes;
	BOOL					_allowsNaturalLanguage;
//	BOOL					_generatesCalendarDates;
//	BOOL					_isLenient;
}

+ (NSDateFormatterBehavior) defaultFormatterBehavior;
+ (void) setDefaultFormatterBehavior:(NSDateFormatterBehavior) behavior;

- (BOOL) allowsNaturalLanguage;
- (NSString *) AMSymbol;
- (NSCalendar *) calendar;
- (NSString *) dateFormat;
- (NSDate *) dateFromString:(NSString *) string;
- (NSDateFormatterStyle) dateStyle;
- (NSDate *) defaultDate;
- (NSArray *) eraSymbols;
- (NSDateFormatterBehavior) formatterBehavior;
- (BOOL) generatesCalendarDates;
- (BOOL) getObjectValue:(id *)obj
			  forString:(NSString *) string
				  range:(inout NSRange *) rangep
				  error:(NSError **) error;
- (NSDate *) gregorianStartDate;
- (id) init;
- (id) initWithDateFormat:(NSString *) format allowNaturalLanguage:(BOOL) flag;
- (BOOL) isLenient;
- (NSLocale *) locale;
- (NSArray *) longEraSymbols;
- (NSArray *) monthSymbols;
- (NSString *) PMSymbol;
- (NSArray *) quarterSymbols;
- (void) setAMSymbol:(NSString *) string;
- (void) setCalendar:(NSCalendar *) calendar;
- (void) setDateFormat:(NSString *) string;
- (void) setDateStyle:(NSDateFormatterStyle) style;
- (void) setDefaultDate:(NSDate *) date;
- (void) setEraSymbols:(NSArray *) array;
- (void) setFormatterBehavior:(NSDateFormatterBehavior) behavior;
- (void) setGeneratesCalendarDates:(BOOL) flag;
- (void) setGregorianStartDate:(NSDate *) date;
- (void) setLenient:(BOOL) flag;
- (void) setLocale:(NSLocale *) locale;
- (void) setLongEraSymbols:(NSArray *) array;
- (void) setMonthSymbols:(NSArray *) array;
- (void) setPMSymbol:(NSString *) string;
- (void) setQuarterSymbols:(NSArray *) array;
- (void) setShortMonthSymbols:(NSArray *) array;
- (void) setShortQuarterSymbols:(NSArray *) array;
- (void) setShortStandaloneMonthSymbols:(NSArray *) array;
- (void) setShortStandaloneQuarterSymbols:(NSArray *) array;
- (void) setShortStandaloneWeekdaySymbols:(NSArray *) array;
- (void) setShortWeekdaySymbols:(NSArray *) array;
- (void) setStandaloneMonthSymbols:(NSArray *) array;
- (void) setStandaloneQuarterSymbols:(NSArray *) array;
- (void) setStandaloneWeekdaySymbols:(NSArray *) array;
- (void) setTimeStyle:(NSDateFormatterStyle) style;
- (void) setTimeZone:(NSTimeZone *) tz;
- (void) setTwoDigitStartDate:(NSDate *) date;
- (void) setWeekdaySymbols:(NSArray *) array;
- (void) setVeryShortMonthSymbols:(NSArray *) array;
- (void) setVeryShortStandaloneMonthSymbols:(NSArray *) array;
- (void) setVeryShortStandaloneWeekdaySymbols:(NSArray *) array;
- (void) setVeryShortWeekdaySymbols:(NSArray *) array;
- (NSArray *) shortMonthSymbols;
- (NSArray *) shortQuarterSymbols;
- (NSArray *) shortStandaloneMonthSymbols;
- (NSArray *) shortStandaloneQuarterSymbols;
- (NSArray *) shortStandaloneWeekdaySymbols;
- (NSArray *) shortWeekdaySymbols;
- (NSArray *) standaloneMonthSymbols;
- (NSArray *) standaloneQuarterSymbols;
- (NSArray *) standaloneWeekdaySymbols;
- (NSString *) stringFromDate:(NSDate *) date;
- (NSDateFormatterStyle) timeStyle;
- (NSTimeZone *) timeZone;
- (NSDate *) twoDigitStartDate;
- (NSArray *) veryShortMonthSymbols;
- (NSArray *) veryShortStandaloneMonthSymbols;
- (NSArray *) veryShortStandaloneWeekdaySymbols;
- (NSArray *) veryShortWeekdaySymbols;
- (NSArray *) weekdaySymbols;

@end

#endif /* _NSDateFormatter_h_GNUSTEP_BASE_INCLUDE */
