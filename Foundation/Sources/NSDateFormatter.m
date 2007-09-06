/** Implementation of NSDateFormatter class
Copyright (C) 1998 Free Software Foundation, Inc.

Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
Created: December 1998

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

<title>NSDateFormatter class reference</title>
$Date: 2004/09/14 03:34:37 $ $Revision: 1.10 $

adapted for mySTEP

*/

#include "Foundation/NSDate.h"
#include "Foundation/NSCalendarDate.h"
#include "Foundation/NSTimeZone.h"
#include "Foundation/NSFormatter.h"
#include "Foundation/NSDateFormatter.h"
#include "Foundation/NSString.h"
#include "Foundation/NSValue.h"
#include "Foundation/NSCoder.h"
#include "Foundation/NSDictionary.h"

@implementation NSDateFormatter

static NSDateFormatterBehavior _defaultFormatterBehavior=NSDateFormatterBehaviorDefault;

+ (NSDateFormatterBehavior) defaultFormatterBehavior; { return _defaultFormatterBehavior; }
+ (void) setDefaultFormatterBehavior:(NSDateFormatterBehavior) behavior; { _defaultFormatterBehavior=behavior; }

#if 0	// not available - so don't override default implementation
- (NSAttributedString*) attributedStringForObjectValue: (id)anObject
								 withDefaultAttributes: (NSDictionary*)attr
{
	return NIMP;
}
#endif

- (id) copyWithZone: (NSZone*)zone
{
	NSDateFormatter	*other = [super copyWithZone:zone];
	other->_attributes=[_attributes mutableCopy];
	return other;
}

- (id) init;
{
	if((self=[super init]))
		{
		_attributes=[[NSMutableDictionary alloc] initWithCapacity:10];
		// should we set a default format???
		}
	return self;
}

- (void) dealloc
{
	[_attributes release];
	[super dealloc];
}

- (NSString*) editingStringForObjectValue: (id)anObject
{
	return [self stringForObjectValue: anObject];
}

- (NSDate *) dateFromString:(NSString *) string;
{
	return NIMP;
}

- (BOOL) getObjectValue:(id *)obj
			  forString:(NSString *) string
				  range:(inout NSRange *) rangep
				  error:(NSError **) error;
{
	NIMP;
	return NO;
}

- (BOOL) getObjectValue: (id*)anObject
			  forString: (NSString*)string
       errorDescription: (NSString**)error
{
	NSCalendarDate	*d;
	
	d = [NSCalendarDate dateWithString: string calendarFormat:[self dateFormat]];
	if (d == nil)
		{
		if (_allowsNaturalLanguage)
			{
			//			d = [NSCalendarDate dateWithNaturalLanguageString: string];
			// FIXME: read from LANGUAGE dictionary
			if([string isEqualToString:@"now"])
				d=[NSCalendarDate calendarDate];
			else if([string isEqualToString:@"today"])
				d=[NSCalendarDate calendarDate];
			else if([string isEqualToString:@"tomorrow"])
				d=[[NSCalendarDate calendarDate] dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
			else if([string isEqualToString:@"yesterday"])
				d=[[NSCalendarDate calendarDate] dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
			}
		if (d == nil)
			{
			if (error)
				{
				*error = @"Couldn't convert to date";
				}
			return NO;
			}
		}
	if (anObject)
		{
		*anObject = d;
		}
	return YES;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
//	[aCoder encodeValuesOfObjCTypes: "@C", &_dateFormat, &_allowsNaturalLanguage];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
	if([aCoder allowsKeyedCoding])
		{
		_attributes=[[aCoder decodeObjectForKey:@"NS.attributes"] retain];
		[self setDateFormat:[aCoder decodeObjectForKey:@"NS.format"]];
		_allowsNaturalLanguage=[aCoder decodeBoolForKey:@"NS.natural"];
#if 1
		NSLog(@"attributes=%@", _attributes);
		/* e.g.
			dateFormat_10_0 = "%b %d, %Y %H:%M:%S";
		formatterBehavior = 1000;
		lenient = 0;
			*/
#endif
		return self;
		}
//	[aCoder decodeValuesOfObjCTypes: "@C", &_dateFormat, &_allowsNaturalLanguage];
	return self;
}

- (id) initWithDateFormat: (NSString *)format
     allowNaturalLanguage: (BOOL)flag
{
	if((self=[self init]))
		{
		[self setDateFormat:format];
		_allowsNaturalLanguage = flag;
		}
	return self;
}

- (BOOL) isPartialStringValid: (NSString*)partialString
			 newEditingString: (NSString**)newString
			 errorDescription: (NSString**)error
{
	// FIXME!
	if(newString)
		*newString = nil;
	if(error)
		*error = nil;
	return YES;
}

- (NSString *) stringFromDate:(NSDate *) date;
{
	return NIMP;
}

- (NSString*) stringForObjectValue: (id)anObject
{
#if 0
	NSLog(@"stringForObjectValue: %@", anObject);
#endif
	if(![anObject isKindOfClass: [NSDate class]])
		return nil;
	if([anObject isKindOfClass: [NSCalendarDate class]])
		return [anObject descriptionWithCalendarFormat: [self dateFormat] locale: nil /*[self locale]*/];
	return [anObject descriptionWithCalendarFormat: [self dateFormat] timeZone: [NSTimeZone defaultTimeZone] locale: nil /*[self locale]*/];
}

- (BOOL) allowsNaturalLanguage { return _allowsNaturalLanguage; }
- (NSString *) AMSymbol; { return [_attributes objectForKey:@"AMSymbol"]; }
- (NSCalendar *) calendar; { return [_attributes objectForKey:@"calendar"]; }
- (NSString *) dateFormat; { return [_attributes objectForKey:@"dateFormat"]; }
- (NSDateFormatterStyle) dateStyle; { return [[_attributes objectForKey:@"dateStyle"] intValue]; }
- (NSDate *) defaultDate; { return [_attributes objectForKey:@"defaultDate"]; }
- (NSArray *) eraSymbols; { return [_attributes objectForKey:@"eraSymbols"]; }
- (NSDateFormatterBehavior) formatterBehavior; { return [[_attributes objectForKey:@"formatterBehavior"] intValue]; }
- (BOOL) generatesCalendarDates; { return [[_attributes objectForKey:@"generatesCalendarDates"] boolValue]; }
- (BOOL) isLenient; { return [[_attributes objectForKey:@"isLenient"] boolValue]; }
- (NSLocale *) locale; { return [_attributes objectForKey:@"locale"]; }
- (NSArray *) monthSymbols; { return [_attributes objectForKey:@"monthSymbols"]; }
- (NSString *) PMSymbol; { return [_attributes objectForKey:@"PMSymbol"]; }

- (void) setAMSymbol:(NSString *) string; { [_attributes setValue:string forKey:@"AMSymbol"]; }
- (void) setCalendar:(NSCalendar *) cal; { [_attributes setValue:cal forKey:@"calendar"]; }
- (void) setDateFormat:(NSString *) string; { [_attributes setValue:string forKey:@"dateFormat"]; }
- (void) setDateStyle:(NSDateFormatterStyle) style; { [_attributes setValue:[NSNumber numberWithInt:style] forKey:@"dateFormat"]; }
- (void) setDefaultDate:(NSDate *) date; { [_attributes setValue:date forKey:@"dateFormat"]; }
- (void) setEraSymbols:(NSArray *) array; { [_attributes setValue:array forKey:@"eraSymbols"]; }
- (void) setFormatterBehavior:(NSDateFormatterBehavior) behavior; { [_attributes setValue:[NSNumber numberWithInt:behavior] forKey:@"formatterBehavior"]; }
- (void) setGeneratesCalendarDates:(BOOL) flag; { [_attributes setValue:[NSNumber numberWithBool:flag] forKey:@"generatesCalendarDates"]; }
- (void) setLenient:(BOOL) flag; { [_attributes setValue:[NSNumber numberWithBool:flag] forKey:@"isLenient"]; }
- (void) setLocale:(NSLocale *) locale; { [_attributes setValue:locale forKey:@"locale"]; }
- (void) setMonthSymbols:(NSArray *) array; { [_attributes setValue:array forKey:@"monthSymbols"]; }
- (void) setPMSymbol:(NSString *) string; { [_attributes setValue:string forKey:@"PMSymbol"]; }
- (void) setShortMonthSymbols:(NSArray *) array; { [_attributes setValue:array forKey:@"shortMonthSymbols"]; }
- (void) setShortWeekdaySymbols:(NSArray *) array; { [_attributes setValue:array forKey:@"shortWeekdaySymbols"]; }
- (void) setTimeStyle:(NSDateFormatterStyle) style; { [_attributes setValue:[NSNumber numberWithInt:style] forKey:@"timeStyle"]; }
- (void) setTimeZone:(NSTimeZone *) tz; { [_attributes setValue:tz forKey:@"timeZone"]; }
- (void) setTwoDigitStartDate:(NSDate *) date; { [_attributes setValue:date forKey:@"twoDigitStartDate"]; }
- (void) setWeekdaySymbols:(NSArray *) array; { [_attributes setValue:array forKey:@"weekdaySymbols"]; }

- (NSArray *) shortMonthSymbols; { return [_attributes objectForKey:@"shortMonthSymbols"]; }
- (NSArray *) shortWeekdaySymbols; { return [_attributes objectForKey:@"shortWeekdaySymbols"]; }
- (NSDateFormatterStyle) timeStyle; { return [[_attributes objectForKey:@"timeStyle"] intValue]; }
- (NSTimeZone *) timeZone; { return [_attributes objectForKey:@"timeZone"]; }
- (NSDate *) twoDigitStartDate; { return [_attributes objectForKey:@"twoDigitStartDate"]; }
- (NSArray *) weekdaySymbols; { return [_attributes objectForKey:@"weekdaySymbols"]; }

@end

