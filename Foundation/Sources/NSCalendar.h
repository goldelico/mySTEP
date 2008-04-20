/*
    NSCalendar.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
    Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	20. April 2008 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

typedef NSUInteger NSCalendarUnit;

enum {
	NSEraCalendarUnit = kCFCalendarUnitEra,
	NSYearCalendarUnit = kCFCalendarUnitYear,
	NSMonthCalendarUnit = kCFCalendarUnitMonth,
	NSDayCalendarUnit = kCFCalendarUnitDay,
	NSHourCalendarUnit = kCFCalendarUnitHour,
	NSMinuteCalendarUnit = kCFCalendarUnitMinute,
	NSSecondCalendarUnit = kCFCalendarUnitSecond,
	NSWeekCalendarUnit = kCFCalendarUnitWeek,
	NSWeekdayCalendarUnit = kCFCalendarUnitWeekday,
	NSWeekdayOrdinalCalendarUnit = kCFCalendarUnitWeekdayOrdinal
};

enum
{
	NSWrapCalendarComponents = kCFCalendarComponentsWrap,
};

@interface NSCalendar : NSObject

+ (id) autoupdatingCurrentCalendar;
+ (id) currentCalendar;

- (NSString *) calendarIdentifier;
- (NSDateComponents *) components:(NSUInteger) flags fromDate:(NSDate *) date;
- (NSDateComponents *) components:(NSUInteger) flags 
						 fromDate:(NSDate *) fromDate 
						   toDate:(NSDate *) toDate 
						  options:(NSUInteger) options;
- (NSDate *) dateByAddingComponents:(NSDateComponents *) components 
							 toDate:(NSDate *) toDate 
							options:(NSUInteger) options;
- (NSDate *) dateFromComponents:(NSDateComponents *) components;
- (NSUInteger) firstWeekday;
- (id) initWithCalendarIdentifier:(NSString *) str;
- (NSLocale *) locale;
- (NSRange) maximumRangeOfUnit:(NSCalendarUnit) calendarUnit;
- (NSUInteger) minimumDaysInFirstWeek;
- (NSRange) minimumRangeOfUnit:(NSCalendarUnit) unit;
- (NSUInteger) ordinalityOfUnit:(NSCalendarUnit) smaller 
						 inUnit:(NSCalendarUnit) larger 
						forDate:(NSDate *) date;
- (NSRange) rangeOfUnit:(NSCalendarUnit) smaller inUnit:(NSCalendarUnit) larger forDate:(NSDate *) date;
- (BOOL) rangeOfUnit:(NSCalendarUnit) unit startDate:(NSDate **) datep interval:(NSTimeInterval *) tip forDate:(NSDate *) date;
- (void) setFirstWeekday:(NSUInteger) weekday;
- (void) setLocale:(NSLocale *) locale;
- (void) setMinimumDaysInFirstWeek:(NSUInteger) minDayInFirstWeek;
- (void) setTimeZone:(NSTimeZone *) timezone;
- (NSTimeZone *) timeZone;

@end