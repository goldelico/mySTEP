/* 
NSCalendarDate.h
 
 Interface to NSCalendarDate
 
 H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
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
+ (id) dateWithString:(NSString *)description 
	   calendarFormat:(NSString *)format;
+ (id) dateWithString:(NSString *)description
	   calendarFormat:(NSString *)format
			   locale:(NSDictionary *)dictionary;
+ (id) dateWithYear:(int)year
			  month:(unsigned int)month
				day:(unsigned int)day
			   hour:(unsigned int)hour
			 minute:(unsigned int)minute
			 second:(unsigned int)second
		   timeZone:(NSTimeZone *)aTimeZone;

- (NSString *) calendarFormat;
- (NSCalendarDate *) dateByAddingYears:(int)years
								months:(int)months
								  days:(int)days
								 hours:(int)hours
							   minutes:(int)minutes
							   seconds:(int)seconds;
- (int) dayOfCommonEra;										// Date Elements
- (int) dayOfMonth;
- (int) dayOfWeek;
- (int) dayOfYear;
- (NSString*) description;
- (NSString *) descriptionWithCalendarFormat:(NSString *)format;
- (NSString *) descriptionWithCalendarFormat:(NSString *)format
									  locale:(NSDictionary *)locale;
- (NSString*) descriptionWithLocale:(NSDictionary *)locale;
- (int) hourOfDay;
- (id) initWithString:(NSString *)description;
- (id) initWithString:(NSString *)description 
	   calendarFormat:(NSString *)format;
- (id) initWithString:(NSString *)description
	   calendarFormat:(NSString *)format
			   locale:(NSDictionary *)dictionary;
- (id) initWithYear:(int)year
			  month:(unsigned int)month
				day:(unsigned int)day
			   hour:(unsigned int)hour
			 minute:(unsigned int)minute
			 second:(unsigned int)second
		   timeZone:(NSTimeZone *)aTimeZone;
- (int) minuteOfHour;
- (int) monthOfYear;
- (int) secondOfMinute;
- (void) setCalendarFormat:(NSString *)format;
- (void) setTimeZone:(NSTimeZone *)aTimeZone;
- (NSTimeZone *) timeZone;
- (int) yearOfCommonEra;
- (void) years:(int*)years
		months:(int*)months
		  days:(int*)days
		 hours:(int*)hours
	   minutes:(int*)minutes
	   seconds:(int*)seconds
	 sinceDate:(NSDate*)date;

@end

#endif /* _mySTEP_H_NSCalendarDate */
