/*
    NSLocale.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
    Copyright (c) 2005 DSITRI.
 
    Fabian Spillner, May 2008 - API revised to be compatible to 10.5 

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

extern NSString *NSLocaleIdentifier;
extern NSString *NSLocaleLanguageCode;
extern NSString *NSLocaleCountryCode;
extern NSString *NSLocaleScriptCode;
extern NSString *NSLocaleVariantCode;
extern NSString *NSLocaleExemplarCharacterSet;
extern NSString *NSLocaleCalendar;
extern NSString *NSLocaleCollationIdentifier;
extern NSString *NSLocaleUsesMetricSystem;
extern NSString *NSLocaleMeasurementSystem;
extern NSString *NSLocaleDecimalSeparator;
extern NSString *NSLocaleGroupingSeparator;
extern NSString *NSLocaleCurrencySymbol;
extern NSString *NSLocaleCurrencyCode;

extern NSString *NSGregorianCalendar;
extern NSString *NSBuddhistCalendar;
extern NSString *NSChineseCalendar;
extern NSString *NSHebrewCalendar;
extern NSString *NSIslamicCalendar;
extern NSString *NSIslamicCivilCalendar;
extern NSString *NSJapaneseCalendar;

extern NSString *NSCurrentLocaleDidChangeNotification;

@interface NSLocale : NSObject <NSCoding, NSCopying>
{
	NSString *_localeIdentifier;
}

+ (id) autoupdatingCurrentLocale;
+ (NSArray *) availableLocaleIdentifiers;
+ (NSString *) canonicalLocaleIdentifierFromString:(NSString *) string;
+ (NSArray *) commonISOCurrencyCodes;
+ (NSDictionary *) componentsFromLocaleIdentifier:(NSString *) string;
+ (id) currentLocale;
+ (NSArray *) ISOCountryCodes;
+ (NSArray *) ISOCurrencyCodes;
+ (NSArray *) ISOLanguageCodes;
+ (NSString *) localeIdentifierFromComponents:(NSDictionary *) dict;
+ (NSArray *) preferredLanguages;
+ (id) systemLocale;

- (NSString *) displayNameForKey:(id) key value:(id) val;
- (id) initWithLocaleIdentifier:(NSString *) ident;
- (NSString *) localeIdentifier;
- (id) objectForKey:(id) key;

@end
