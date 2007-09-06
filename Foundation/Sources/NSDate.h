/* 
   NSDate.h

   Interface to NSDate

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Copyright (C) 1994, 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDate
#define _mySTEP_H_NSDate

#import <Foundation/NSObject.h>

typedef double NSTimeInterval;				// Time interval difference between 
											// two dates, in seconds.
@class NSArray;
@class NSCalendarDate;
@class NSDictionary;
@class NSString;
@class NSTimeZone;

extern NSTimeInterval NSTimeIntervalSince1970;

@interface NSDate : NSObject  <NSCoding, NSCopying>
{
	NSTimeInterval _secondsSinceRef;
}

+ (id) date;
+ (id) dateWithNaturalLanguageString:(NSString *)string;
+ (id) dateWithNaturalLanguageString:(NSString *)string locale:(NSDictionary *)locale;
+ (id) dateWithString:(NSString*)description;
+ (id) dateWithTimeIntervalSince1970:(NSTimeInterval)seconds;
+ (id) dateWithTimeIntervalSinceNow:(NSTimeInterval)seconds;
+ (id) dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)seconds;
+ (id) distantFuture;
+ (id) distantPast;
+ (NSTimeInterval) timeIntervalSinceReferenceDate;

- (id) addTimeInterval:(NSTimeInterval)seconds;				// Time Intervals
- (NSComparisonResult) compare:(NSDate*)otherDate;			// Compare dates
- (NSCalendarDate *) dateWithCalendarFormat:(NSString*)formatString
								   timeZone:(NSTimeZone*)timeZone;
- (NSString*) description;
- (NSString*) descriptionWithCalendarFormat:(NSString *)formatString
								   timeZone:(NSTimeZone *)timeZone
									 locale:(NSDictionary *)locale;
- (NSString*) descriptionWithLocale:(NSDictionary *)locale;
- (NSDate*) earlierDate:(NSDate*)otherDate;
- (id) init;
- (id) initWithString:(NSString*)description;
- (id) initWithTimeInterval:(NSTimeInterval)secsToBeAdded
				  sinceDate:(NSDate*)anotherDate;
- (id) initWithTimeIntervalSinceNow:(NSTimeInterval)secsToBeAdded;
// - (id) initWithTimeIntervalSince1970:(NSTimeInterval)seconds;
- (id) initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)secs;
- (BOOL) isEqual:(id)other;
- (BOOL) isEqualToDate:(NSDate *)other;
- (NSDate*) laterDate:(NSDate*)otherDate;
- (NSTimeInterval) timeIntervalSince1970;
- (NSTimeInterval) timeIntervalSinceDate:(NSDate*)otherDate;
- (NSTimeInterval) timeIntervalSinceNow;
- (NSTimeInterval) timeIntervalSinceReferenceDate;

@end

#endif /* _mySTEP_H_NSDate */
