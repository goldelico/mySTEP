/*$Id: SenDateInterval.h,v 1.3 2001/11/22 13:48:19 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
#import "SenFoundationDefines.h"


@class NSCalendarDate;
@class NSString;


/*
 *	SenDateInterval: represents a date interval, in days, with a start date.
 *	Interval is closed. Precision is the day, from 0h00 to 23h59.59.999...
 *	This class instantiates immutable objects.
 *	The -description... methods return a nice output, removing unnecessary
 *	duplicate month/year indication, and allowing localization.
 */

SENFOUNDATION_EXPORT NSDictionary *SenLocaleForLanguage(NSString *language);

@interface SenDateInterval : NSObject <NSCopying, NSCoding>
{
    NSCalendarDate	*startDate;
    NSCalendarDate	*endDate;
}

+ (id) intervalWithStartDate:(NSCalendarDate *)startDate endDate:(NSCalendarDate *)endDate;
// If endDate < startDate, startDate and endDate are swapped.
+ (id) intervalWithStartDate:(NSCalendarDate *)startDate durationInDays:(unsigned)days;

- (id) initWithStartDate:(NSCalendarDate *)startDate endDate:(NSCalendarDate *)endDate;
// Designated initializer

- (NSCalendarDate *) startDate;
- (NSCalendarDate *) endDate;
// Hours, minutes and seconds are aleays 0; timezone is GMT

- (double) durationInDays;
// Always return a positive integer number; double is used for its precision

- (NSString *) description;
// Calls -descriptionForLanguage: with nil language, meaning user's default language

- (NSString *) descriptionForLanguage:(NSString *)language;
// Returns a localized description of the interval: From ... to ..., and checks
// if year and/or month needs to be displayed twice.
// Calls -descriptionWithPrefix:separator:dateFormat:language:
// Date format is NSDateFormatString localized format.

- (NSString *) descriptionWithPrefix:(NSString *)prefix separator:(NSString *)separator dateFormat:(NSString *)dateFormat language:(NSString *)language;
// Returns a localized description of the interval, using localized versions of the prefix, separator and dateFormat
// Known localized prefixes and separators:
//   "From " " to "
//   "from "
//   "FROM " " TO "
//   "From the "
//   "from the "
//   "FROM THE "

- (BOOL) isEqualToInterval:(SenDateInterval *)interval;
- (BOOL) containsDate:(NSCalendarDate *)date;
- (BOOL) intersectsInterval:(SenDateInterval *)interval;
- (SenDateInterval *) intervalByIntersectingInterval:(SenDateInterval *)interval;
// May return nil;
- (SenDateInterval *) intervalByUnioningInterval:(SenDateInterval *)interval;


@end
