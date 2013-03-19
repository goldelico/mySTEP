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

#import <Foundation/NSLocale.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSCoder.h>

NSString *NSLocaleIdentifier=@"NSLocaleIdentifier";
NSString *NSLocaleLanguageCode=@"NSLocaleLanguageCode";
NSString *NSLocaleCountryCode=@"NSLocaleCountryCode";
NSString *NSLocaleScriptCode=@"NSLocaleScriptCode";
NSString *NSLocaleVariantCode=@"NSLocaleVariantCode";
NSString *NSLocaleExemplarCharacterSet=@"NSLocaleExemplarCharacterSet";
NSString *NSLocaleCalendar=@"NSLocaleCalendar";
NSString *NSLocaleCollationIdentifier=@"NSLocaleCollationIdentifier";
NSString *NSLocaleUsesMetricSystem=@"NSLocaleUsesMetricSystem";
NSString *NSLocaleMeasurementSystem=@"NSLocaleMeasurementSystem";
NSString *NSLocaleDecimalSeparator=@"NSLocaleDecimalSeparator";
NSString *NSLocaleGroupingSeparator=@"NSLocaleGroupingSeparator";
NSString *NSLocaleCurrencySymbol=@"NSLocaleCurrencySymbol";
NSString *NSLocaleCurrencyCode=@"NSLocaleCurrencyCode";

@implementation NSLocale

+ (id) autoupdatingCurrentLocale;
{
	return [[[self alloc] init] autorelease];
}

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
		langs = [env componentsSeparatedByString:@";"];
		}
	if (!langs || ![langs containsObject:@"English"])
		{
		int s = [langs count] + 1;
		NSMutableArray *u = [NSMutableArray arrayWithCapacity:s];
		
		if(langs)
			[u addObjectsFromArray:langs];
		[u addObject:@"English"];
		langs=u;
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

+ (NSArray *) commonISOCurrencyCodes;
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

+ (NSArray *) preferredLanguages;
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
	if((self=[self init]))
		{
		_localeIdentifier=[ident retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z;
{
	NSLocale *l=[super copyWithZone:z];
	l->_localeIdentifier=[_localeIdentifier copyWithZone:z];
	return l;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	_localeIdentifier=[[coder decodeObjectForKey:@"NS.identifier"] retain];
	return self;
}

- (void) dealloc;
{
	[_localeIdentifier release];
	[super dealloc];
}

- (NSString *) localeIdentifier;
{
	return _localeIdentifier;
}

- (id) objectForKey:(id) key;
{
	return NIMP;
}

@end
