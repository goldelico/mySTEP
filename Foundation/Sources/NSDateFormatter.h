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
- (id) init;
- (id) initWithDateFormat:(NSString *) format
     allowNaturalLanguage:(BOOL) flag;
- (BOOL) isLenient;
- (NSLocale *) locale;
- (NSArray *) monthSymbols;
- (NSString *) PMSymbol;
- (void) setAMSymbol:(NSString *) string;
- (void) setCalendar:(NSCalendar *) calendar;
- (void) setDateFormat:(NSString *) string;
- (void) setDateStyle:(NSDateFormatterStyle) style;
- (void) setDefaultDate:(NSDate *) date;
- (void) setEraSymbols:(NSArray *) array;
- (void) setFormatterBehavior:(NSDateFormatterBehavior) behavior;
- (void) setGeneratesCalendarDates:(BOOL) flag;
- (void) setLenient:(BOOL) flag;
- (void) setLocale:(NSLocale *) locale;
- (void) setMonthSymbols:(NSArray *) array;
- (void) setPMSymbol:(NSString *) string;
- (void) setShortMonthSymbols:(NSArray *) array;
- (void) setShortWeekdaySymbols:(NSArray *) array;
- (void) setTimeStyle:(NSDateFormatterStyle) style;
- (void) setTimeZone:(NSTimeZone *) tz;
- (void) setTwoDigitStartDate:(NSDate *) date;
- (void) setWeekdaySymbols:(NSArray *) array;
- (NSArray *) shortMonthSymbols;
- (NSArray *) shortWeekdaySymbols;
- (NSString *) stringFromDate:(NSDate *) date;
- (NSDateFormatterStyle) timeStyle;
- (NSTimeZone *) timeZone;
- (NSDate *) twoDigitStartDate;
- (NSArray *) weekdaySymbols;

@end

#endif /* _NSDateFormatter_h_GNUSTEP_BASE_INCLUDE */
