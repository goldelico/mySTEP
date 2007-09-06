/* 
   NSTimeZone.h

   Interface to Time Zone class

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	April 2005

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTimeZone
#define _mySTEP_H_NSTimeZone

#import <Foundation/NSObject.h>

@class NSArray;
@class NSData;
@class NSDate;
@class NSDictionary;
@class NSString;

@interface NSTimeZone : NSObject  <NSCopying, NSCoding>

+ (NSDictionary *) abbreviationDictionary;
+ (NSTimeZone *) defaultTimeZone;
+ (NSArray *) knownTimeZoneNames;
+ (NSTimeZone *) localTimeZone;
+ (void) resetSystemTimeZone;
+ (void) setDefaultTimeZone:(NSTimeZone *)timeZone;
+ (NSTimeZone *) systemTimeZone;
+ (NSTimeZone *) timeZoneForSecondsFromGMT:(int)seconds;
+ (NSTimeZone *) timeZoneWithAbbreviation:(NSString *)abbreviation;  
+ (NSTimeZone *) timeZoneWithName:(NSString *)timeZone;
+ (NSTimeZone *) timeZoneWithName:(NSString *)timeZone data:(NSData *) data;

- (NSString *) abbreviation;
- (NSString *) abbreviationForDate:(NSDate *) date;
- (NSData *) data;
- (NSString *) description;
- (id) initWithName:(NSString *)name;
- (id) initWithName:(NSString *)timeZoneName data:(NSData *)data;
- (BOOL) isDaylightSavingTime;
- (BOOL) isDaylightSavingTimeForDate:(NSDate *) date;
- (BOOL) isEqualToTimeZone:(NSTimeZone *)timeZone;
- (NSString *) name;
- (int) secondsFromGMT;
- (int) secondsFromGMTForDate:(NSDate *) date;

@end

#endif /* _mySTEP_H_NSTimeZone */
