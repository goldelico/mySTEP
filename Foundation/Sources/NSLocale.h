//
//  NSLocale.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

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

@interface NSLocale : NSObject <NSCoding, NSCopying>
{
}

+ (NSArray *) availableLocaleIdentifiers;
+ (NSString *) canonicalLocaleIdentifierFromString:(NSString *) string;
+ (NSDictionary *) componentsFromLocaleIdentifier:(NSString *) string;
+ (id) currentLocale;
+ (NSArray *) ISOCountryCodes;
+ (NSArray *) ISOCurrencyCodes;
+ (NSArray *) ISOLanguageCodes;
+ (NSString *) localeIdentifierFromComponents:(NSDictionary *) dict;
+ (id) systemLocale;

- (NSString *) displayNameForKey:(id) key value:(id) val;
- (id) initWithLocaleIdentifier:(NSString *) ident;
- (NSString *) localeIdentifier;
- (id) objectForKey:(id) key;

@end