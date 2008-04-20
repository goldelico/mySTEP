/* 
    NSCalendarDate.h
 
    Interface to NSCalendarDate
 
    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	20. April 2008 - aligned with 10.5
 
    Copyright (C) 1994, 1996 Free Software Foundation, Inc.
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSCalendarDate
#define _mySTEP_H_NSCalendarDate

#import <Foundation/NSDate.h>


@interface NSCalendarDate : NSDate
{
	NSString *calendar_format;
	NSTimeZone *time_zone;
}

+ (id) calendarDate;
+ (id) dateWithString:(NSString *) description 
	   calendarFormat:(NSString *) format;
+ (id) dateWithString:(NSString *) description
	   calendarFormat:(NSString *) format
			   locale:(NSDictionary *) dictionary;
+ (id) dateWithYear:(NSInteger) year
			  month:(NSUInteger) month
				day:(NSUInteger) day
			   hour:(NSUInteger) hour
			 minute:(NSUInteger) minute
			 second:(NSUInteger) second
		   timeZone:(NSTimeZone *) aTimeZone;

- (NSString *) calendarFormat;
- (NSCalendarDate *) dateByAddingYears:(NSInteger) years
								months:(NSInteger) months
								  days:(NSInteger) days
								 hours:(NSInteger) hours
							   minutes:(NSInteger) minutes
							   seconds:(NSInteger) seconds;
- (NSInteger) dayOfCommonEra;
- (NSInteger) dayOfMonth;
- (NSInteger) dayOfWeek;
- (NSInteger) dayOfYear;
- (NSString *) description;
- (NSString *) descriptionWithCalendarFormat:(NSString *) format;
- (NSString *) descriptionWithCalendarFormat:(NSString *) format
									  locale:(NSDictionary *) locale;
- (NSString *) descriptionWithLocale:(id) locale;
- (NSInteger) hourOfDay;
- (id) initWithString:(NSString *) description;
- (id) initWithString:(NSString *) description 
	   calendarFormat:(NSString *) format;
- (id) initWithString:(NSString *) description
	   calendarFormat:(NSString *) format
			   locale:(NSDictionary *) dictionary;
- (id) initWithYear:(NSInteger) year
			  month:(NSUInteger) month
				day:(NSUInteger) day
			   hour:(NSUInteger) hour
			 minute:(NSUInteger) minute
			 second:(NSUInteger) second
		   timeZone:(NSTimeZone *) aTimeZone;
- (NSInteger) minuteOfHour;
- (NSInteger) monthOfYear;
- (NSInteger) secondOfMinute;
- (void) setCalendarFormat:(NSString *) format;
- (void) setTimeZone:(NSTimeZone *) aTimeZone;
- (NSTimeZone *) timeZone;
- (NSInteger) yearOfCommonEra;
- (void) years:(NSInteger *) years
		months:(NSInteger *) months
		  days:(NSInteger *) days
		 hours:(NSInteger *) hours
	   minutes:(NSInteger *) minutes
	   seconds:(NSInteger *) seconds
	 sinceDate:(NSCalendarDate *) date;

@end

#endif /* _mySTEP_H_NSCalendarDate */
