/* 
   NSUserDefaults.h

   Interface for NSUserDefaults

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Author:  Georg Tuparev <Tuparev@EMBL-Heidelberg.de>
   Date:    1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSUserDefaults
#define _mySTEP_H_NSUserDefaults

#import <Foundation/NSObject.h>

@class NSString;
@class NSMutableString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSData;
@class NSTimer;

extern NSString *NSAMPMDesignation;
extern NSString *NSCurrencySymbol;
extern NSString *NSDateFormatString;
extern NSString *NSDateTimeOrdering;
extern NSString *NSDecimalDigits;
extern NSString *NSDecimalSeparator;
extern NSString *NSEarlierTimeDesignations;
extern NSString *NSHourNameDesignations;
extern NSString *NSInternationalCurrencyString;
extern NSString *NSLaterTimeDesignations;
extern NSString *NSMonthNameArray;
extern NSString *NSNegativeCurrencyFormatString;
extern NSString *NSNextDayDesignations;
extern NSString *NSNextNextDayDesignations;
extern NSString *NSPositiveCurrencyFormatString;
extern NSString *NSPriorDayDesignations;
extern NSString *NSShortDateFormatString;
extern NSString *NSShortMonthNameArray;
extern NSString *NSShortTimeDateFormatString;
extern NSString *NSShortWeekDayNameArray;
extern NSString *NSThisDayDesignations;
extern NSString *NSThousandsSeparator;
extern NSString *NSTimeDateFormatString;
extern NSString *NSTimeFormatString;
extern NSString *NSWeekDayNameArray;
extern NSString *NSYearMonthWeekDesignations;

extern NSString *NSArgumentDomain;						// Standard domains
extern NSString *NSGlobalDomain;
extern NSString *NSRegistrationDomain;


@interface NSUserDefaults : NSObject
{
	NSMutableArray *_searchList;					// Current search list;
	NSMutableDictionary *_persDomains;				// persistent defaults info
	NSMutableDictionary *_tempDomains;				// volatile defaults info
	NSMutableArray *_changedDomains;
	NSMutableString *_defaultsDatabase;
//	NSMutableString *_defaultsDBLockName;
//	NSDistributedLock *_defaultsDBLock;
	NSTimer *_timerActive;							// for synchronization
}

+ (void) resetStandardUserDefaults;
+ (NSUserDefaults *) standardUserDefaults;

- (void) addSuiteNamed:(NSString *)suiteName;
- (NSArray *) arrayForKey:(NSString *)defaultName;		// Get / Set Defaults
- (BOOL) boolForKey:(NSString *)defaultName;
- (NSData *) dataForKey:(NSString *)defaultName;
- (NSDictionary *) dictionaryForKey:(NSString *)defaultName;
- (NSDictionary *) dictionaryRepresentation;			// Advanced Use
- (float) floatForKey:(NSString *)defaultName;
- (id) init;
- (id) initWithUser:(NSString *)userName;
- (int) integerForKey:(NSString *)defaultName;
- (id) objectForKey:(NSString *)defaultName;
- (BOOL) objectIsForcedForKey:(NSString *)key;
- (BOOL) objectIsForcedForKey:(NSString *)key inDomain:(NSString *)domain;
- (NSDictionary *) persistentDomainForName:(NSString *)domainName;
- (NSArray *) persistentDomainNames;
- (void) registerDefaults:(NSDictionary *)dictionary;
- (void) removeObjectForKey:(NSString *)defaultName;
- (void) removePersistentDomainForName:(NSString *)domainName;
- (void) removeSuiteNamed:(NSString *)suiteName;
- (void) removeVolatileDomainForName:(NSString *)domainName;
- (NSMutableArray *) searchList;						// Search List
- (void) setBool:(BOOL)value forKey:(NSString *)defaultName;
- (void) setFloat:(float)value forKey:(NSString *)defaultName;
- (void) setInteger:(int)value forKey:(NSString *)defaultName;
- (void) setObject:(id)value forKey:(NSString *)defaultName;
- (void) setPersistentDomain:(NSDictionary *)domain 
					 forName:(NSString *)domainName;
- (void) setSearchList:(NSArray*)newList;
- (void) setVolatileDomain:(NSDictionary *)domain 
				   forName:(NSString *)domainName;
- (NSArray *) stringArrayForKey:(NSString *)defaultName;
- (NSString *) stringForKey:(NSString *)defaultName;
- (BOOL) synchronize;
- (NSDictionary *) volatileDomainForName:(NSString *)domainName;
- (NSArray *) volatileDomainNames;

@end

extern NSString *NSUserDefaultsDidChangeNotification;	// Notifications

#endif /* _mySTEP_H_NSUserDefaults */
