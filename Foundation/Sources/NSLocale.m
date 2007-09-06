//
//  NSLocale.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

// CODE NOT TESTED

#import <Foundation/NSLocale.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

NSString *NSLocaleIdentifier;
NSString *NSLocaleLanguageCode;
NSString *NSLocaleCountryCode;
NSString *NSLocaleScriptCode;
NSString *NSLocaleVariantCode;
NSString *NSLocaleExemplarCharacterSet;
NSString *NSLocaleCalendar;
NSString *NSLocaleCollationIdentifier;
NSString *NSLocaleUsesMetricSystem;
NSString *NSLocaleMeasurementSystem;
NSString *NSLocaleDecimalSeparator;
NSString *NSLocaleGroupingSeparator;
NSString *NSLocaleCurrencySymbol;
NSString *NSLocaleCurrencyCode;

@implementation NSLocale

+ (NSArray *) availableLocaleIdentifiers;
{
	// or should we get that from the Foundation Info.plist???

	NSArray *langs = [[NSUserDefaults standardUserDefaults] stringArrayForKey:@"Languages"];
	const char *env_list;
	if(langs)
		return langs;   // have been defined in sharedDefaults
	// Try to build it from the env 
	env_list = getenv("LANGUAGES");
	if (env_list)
		{
		NSString *env = [NSString stringWithCString:env_list];
		langs = [[env componentsSeparatedByString:@";"] retain];
		}
	if (!langs || ![langs containsObject:@"English"])
		{
		int s = [langs count] + 2;
		NSMutableArray *u = [NSMutableArray arrayWithCapacity:s];
		
		if(langs)
			[u addObjectsFromArray:langs];
		[u addObject:@"English"];
		ASSIGN(langs, (NSArray *)u);
		}
#if 0
	NSLog(@"languages = %@", langs);
#endif
	return langs;
}

+ (NSString *) canonicalLocaleIdentifierFromString:(NSString *) string;
{
	return NIMP;
}

+ (NSDictionary *) componentsFromLocaleIdentifier:(NSString *) string;
{
	return NIMP;
}

+ (id) currentLocale;
{
	return NIMP;
}

+ (NSArray *) ISOCountryCodes;
{
	return NIMP;
}

+ (NSArray *) ISOCurrencyCodes;
{
	return NIMP;
}

+ (NSArray *) ISOLanguageCodes;
{
	return NIMP;
}

+ (NSString *) localeIdentifierFromComponents:(NSDictionary *) dict;
{
	return NIMP;
}

+ (id) systemLocale;
{
	return NIMP;
}


- (NSString *) displayNameForKey:(id) key value:(id) val;
{
	return NIMP;
}

- (id) initWithLocaleIdentifier:(NSString *) ident;
{
	return NIMP;
}

- (id) copyWithZone:(NSZone *) z;
{
	return NIMP;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

- (void) dealloc;
{
	[super dealloc];
}

- (NSString *) localeIdentifier;
{
	return NIMP;
}

- (id) objectForKey:(id) key;
{
	return NIMP;
}

@end