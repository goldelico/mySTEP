/*$Id: SenDateInterval.m,v 1.4 2001/11/22 13:48:19 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenDateInterval.h"
#import <Foundation/Foundation.h>


#define FRENCH_BUG
// In /System/Library/Frameworks/Foundation.framework/Resources/Languages/French,
// day and month names begin with a capital letter, what we consider as a bug!


@implementation SenDateInterval

static NSCalendarDate *_dayDate(NSCalendarDate *date)
{
    int year = [date yearOfCommonEra];
    unsigned month = [date monthOfYear];
    unsigned day = [date dayOfMonth];

    return [NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
}

static NSCalendarDate *_nextDayDate(NSCalendarDate *date)
{
    return [_dayDate(date) dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
}

static NSArray *_languages(void)
{
    NSArray	*languages = [[NSUserDefaults standardUserDefaults] arrayForKey:@"NSLanguages"];

    if(languages == nil || [languages count] == 0)
        languages = [NSArray arrayWithObject:@"English"];

    return languages;
}

static NSString *_languageForLanguage(NSString *language)
{
    if(language == nil)
        language = [_languages() objectAtIndex:0];

    return language;
}

static NSDictionary *_localeForLanguage(NSString *language)
{
    NSBundle	*aBundle = [NSBundle bundleForClass:[NSString class]]; // Search in Foundation.framework
    NSString	*aPath;

    language = _languageForLanguage(language);
    aPath = [aBundle pathForResource:language ofType:@"" inDirectory:@"Languages"];
    if(aPath == nil){
        NSEnumerator	*langEnum = [_languages() objectEnumerator];
        NSString		*aLanguage;

        while(aLanguage = [langEnum nextObject]){
            aPath = [aBundle pathForResource:aLanguage ofType:@"" inDirectory:@"Languages"];
            if(aPath != nil)
                break;
        }
        if(aPath == nil){
            aPath = [aBundle pathForResource:@"Default" ofType:@"" inDirectory:@"Languages"];
            NSCAssert(aPath != nil, @"Unable to find definitions of formats.");
        }
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:aPath];
}

NSDictionary *SenLocaleForLanguage(NSString *language)
{
    return _localeForLanguage(language);
}


static NSString *_description(NSCalendarDate *startDate, NSCalendarDate *endDate, NSString *prefix, NSString *separator, NSString *dateFormat, NSString *language)
{
    NSMutableString	*description = [NSMutableString string];
    NSBundle		*aBundle = [NSBundle bundleForClass:[SenDateInterval class]];
    NSDictionary	*stringTable;
    NSString		*aPath;
    NSDictionary	*locale;

    locale = _localeForLanguage(_languageForLanguage(language));

    aPath = [aBundle pathForResource:@"SenDateInterval" ofType:@"strings" inDirectory:[language stringByAppendingPathExtension:@"lproj"]];
    if(aPath == nil){
        aPath = [aBundle pathForResource:@"SenDateInterval" ofType:@"strings"];
        NSCAssert(aPath != nil, @"Unable to find SenDateInterval.strings");
    }
    stringTable = [[NSString stringWithContentsOfFile:aPath] propertyListFromStringsFileFormat];
    NSCAssert2(stringTable != nil, @"Invalid string table %@.\n%@", aPath, stringTable);
    
    if(prefix != nil){
        NSString	*aString = [stringTable objectForKey:prefix];

        if(aString)
            [description appendString:aString];
    }

    if(separator != nil){
        NSString	*aString = [stringTable objectForKey:separator];

        if(aString)
            separator = aString;
    }
    else
        separator = @" - ";

    if(dateFormat != nil){
        NSString	*aString = [stringTable objectForKey:dateFormat];

        if(aString)
            dateFormat = aString;
    }
    else{
        dateFormat = [locale objectForKey:NSDateFormatString]; // NSShortDateFormatString
        NSCAssert(dateFormat != nil, @"Unable to find NSDateFormatString");
    }

    {
        BOOL	skipsYear, skipsMonth = NO;

        skipsYear = ([startDate yearOfCommonEra] == [endDate yearOfCommonEra]);
        if(skipsYear)
            skipsMonth = ([startDate monthOfYear] == [endDate monthOfYear]);

        if(skipsYear || skipsMonth){
            int				i, length = [dateFormat length];
            BOOL			isFormat = NO, skipsChar = NO, skippedAtLeastOne = NO;
            NSMutableString	*modifiedDateFormat = [NSMutableString stringWithCapacity:length];
            NSMutableString	*accumulatedSeparators = [NSMutableString stringWithCapacity:length];

            for(i = 0; i < length; i++){
                unichar	aChar = [dateFormat characterAtIndex:i];

                if(aChar == '%' && !isFormat)
                    isFormat = YES;
                else if(isFormat){
                    switch(aChar){
#ifdef FRENCH_BUG
                        case 'a':
                        case 'A':
                            if([language isEqualToString:@"French"])
                                [accumulatedSeparators appendString:[[startDate descriptionWithCalendarFormat:[@"%" stringByAppendingString:[NSString stringWithCharacters:&aChar length:1]] locale:locale] lowercaseString]];
                            else{
                                [accumulatedSeparators appendString:@"%"];
                                [accumulatedSeparators appendString:[NSString stringWithCharacters:&aChar length:1]];
                            }
                            [modifiedDateFormat appendString:accumulatedSeparators];
                            [accumulatedSeparators setString:@""];
                            skipsChar = NO;
                            break;
#endif
                        case 'b':
                        case 'B':
                        case 'm':
                            if(!skipsMonth){
#ifdef FRENCH_BUG
                                if([language isEqualToString:@"French"])
                                    [accumulatedSeparators appendString:[[startDate descriptionWithCalendarFormat:[@"%" stringByAppendingString:[NSString stringWithCharacters:&aChar length:1]] locale:locale] lowercaseString]];
                                else{
                                    [accumulatedSeparators appendString:@"%"];
                                    [accumulatedSeparators appendString:[NSString stringWithCharacters:&aChar length:1]];
                                }
#else
                                [accumulatedSeparators appendString:@"%"];
                                [accumulatedSeparators appendString:[NSString stringWithCharacters:&aChar length:1]];
#endif
                                [modifiedDateFormat appendString:accumulatedSeparators];
                                [accumulatedSeparators setString:@""];
                                skipsChar = NO;
                            }
                            else{
                                skippedAtLeastOne = YES;
                                skipsChar = YES;
                            }
                            break;
                        case 'y':
                        case 'Y':
                            if(!skipsYear){
                                [accumulatedSeparators appendString:@"%"];
                                [accumulatedSeparators appendString:[NSString stringWithCharacters:&aChar length:1]];
                                [modifiedDateFormat appendString:accumulatedSeparators];
                                [accumulatedSeparators setString:@""];
                                skipsChar = NO;
                            }
                            else{
                                skipsChar = YES;
                                skippedAtLeastOne = YES;
                            }
                            break;
                        default:
                            [accumulatedSeparators appendString:@"%"];
                            [accumulatedSeparators appendString:[NSString stringWithCharacters:&aChar length:1]];
                            [modifiedDateFormat appendString:accumulatedSeparators];
                            [accumulatedSeparators setString:@""];
                            skipsChar = NO;
                    }
                    isFormat = NO;
                }
                else{
                    if(!skipsChar)
                        [accumulatedSeparators appendString:[NSString stringWithCharacters:&aChar length:1]];
                }
            }

            if(!skipsChar)
                [modifiedDateFormat appendString:accumulatedSeparators];
            [description appendString:[startDate descriptionWithCalendarFormat:modifiedDateFormat locale:locale]];
        }
        else{
#ifdef FRENCH_BUG
        if([language isEqualToString:@"French"]){
            int				i, length = [dateFormat length];
            BOOL			isFormat = NO;
            NSMutableString	*modifiedDateFormat = [NSMutableString stringWithCapacity:length];

            for(i = 0; i < length; i++){
                unichar	aChar = [dateFormat characterAtIndex:i];

                if(aChar == '%' && !isFormat)
                    isFormat = YES;
                else if(isFormat){
                    switch(aChar){
                        case 'a':
                        case 'A':
                        case 'b':
                        case 'B':
                        case 'm':
                            [modifiedDateFormat appendString:[[startDate descriptionWithCalendarFormat:[@"%" stringByAppendingString:[NSString stringWithCharacters:&aChar length:1]] locale:locale] lowercaseString]];
                            break;
                        default:
                            [modifiedDateFormat appendString:@"%"];
                            [modifiedDateFormat appendString:[NSString stringWithCharacters:&aChar length:1]];
                    }
                    isFormat = NO;
                }
                else{
                    [modifiedDateFormat appendString:[NSString stringWithCharacters:&aChar length:1]];
                }
            }
           [description appendString:[startDate descriptionWithCalendarFormat:modifiedDateFormat locale:locale]];
        }
        else
#endif
            [description appendString:[startDate descriptionWithCalendarFormat:dateFormat locale:locale]];
        }
        [description appendString:separator];
#ifdef FRENCH_BUG
        if([language isEqualToString:@"French"]){
            int				i, length = [dateFormat length];
            BOOL			isFormat = NO;
            NSMutableString	*modifiedDateFormat = [NSMutableString stringWithCapacity:length];

            for(i = 0; i < length; i++){
                unichar	aChar = [dateFormat characterAtIndex:i];

                if(aChar == '%' && !isFormat)
                    isFormat = YES;
                else if(isFormat){
                    switch(aChar){
                        case 'a':
                        case 'A':
                        case 'b':
                        case 'B':
                        case 'm':
                            [modifiedDateFormat appendString:[[endDate descriptionWithCalendarFormat:[@"%" stringByAppendingString:[NSString stringWithCharacters:&aChar length:1]] locale:locale] lowercaseString]];
                            break;
                        default:
                            [modifiedDateFormat appendString:@"%"];
                            [modifiedDateFormat appendString:[NSString stringWithCharacters:&aChar length:1]];
                    }
                    isFormat = NO;
                }
                else{
                    [modifiedDateFormat appendString:[NSString stringWithCharacters:&aChar length:1]];
                }
            }
            [description appendString:[endDate descriptionWithCalendarFormat:modifiedDateFormat locale:locale]];
        }
        else
#endif
        [description appendString:[endDate descriptionWithCalendarFormat:dateFormat locale:locale]];
    }
    
    return description;
}

+ (void) initialize
{
    [super initialize];
    if(self == [SenDateInterval class])
        [self setVersion:1];
}

+ (id) intervalWithStartDate:(NSCalendarDate *)aStartDate endDate:(NSCalendarDate *)anEndDate
{
    return [[[self alloc] initWithStartDate:aStartDate endDate:anEndDate] autorelease];
}

+ (id) intervalWithStartDate:(NSCalendarDate *)aStartDate durationInDays:(unsigned)days
{
    return [[[self alloc] initWithStartDate:aStartDate endDate:[_dayDate(aStartDate) dateByAddingYears:0 months:0 days:days hours:0 minutes:0 seconds:0]] autorelease];
}

- (id) init
{
    if(self = [super init]){
        NSZone	*aZone = [self zone];

        startDate = [_dayDate([NSCalendarDate calendarDate]) copyWithZone:aZone];
        endDate = [startDate copyWithZone:aZone];
    }

    return self;
}

- (id) initWithStartDate:(NSCalendarDate *)aStartDate endDate:(NSCalendarDate *)anEndDate
// Designated initializer
{
    NSParameterAssert(aStartDate != nil && anEndDate != nil);
    
    if(self = [super init]){
        NSZone	*aZone = [self zone];

        startDate = [_dayDate(aStartDate) copyWithZone:aZone];
        endDate = [_dayDate(anEndDate) copyWithZone:aZone];
        if([startDate compare:endDate] == NSOrderedDescending){
            NSCalendarDate	*tempDate = startDate;

            startDate = endDate;
            endDate = tempDate;
        }
    }

    return self;
}

- (void) dealloc
{
    [startDate release];
    [endDate release];
    
    [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
    if(zone != NULL){
        if(zone != [self zone])
            return [[[self class] allocWithZone:zone] initWithStartDate:[self startDate] endDate:[self endDate]];
    }
    else if([self zone] != NSDefaultMallocZone())
        return [[[self class] allocWithZone:zone] initWithStartDate:[self startDate] endDate:[self endDate]];

    return self;
}

- (id) initWithCoder:(NSCoder *)decoder
{
    NSCalendarDate	*aStartDate = [decoder decodeObject];
    NSCalendarDate	*anEndDate = [decoder decodeObject];

    return [self initWithStartDate:aStartDate endDate:anEndDate];
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:startDate];
    [coder encodeObject:endDate];
}

- (NSCalendarDate *) startDate
{
    return startDate;
}

- (NSCalendarDate *) endDate
{
    return endDate;
}

- (double) durationInDays
{
    return [[self startDate] timeIntervalSinceDate:[self endDate]] / (24 * 60 * 60);
}

- (BOOL) isEqualToInterval:(SenDateInterval *)interval
{
    return [[self startDate] isEqualToDate:[interval startDate]] && [[self endDate] isEqualToDate:[interval endDate]];
}

- (NSString *) description
// Returns a localized description of the interval: From ... to ...
{
    return [self descriptionWithPrefix:@"From the " separator:@" to the " dateFormat:nil language:nil];
}

- (NSString *) descriptionForLanguage:(NSString *)language
{
    return [self descriptionWithPrefix:@"From the " separator:@" to the " dateFormat:nil language:language];
}

- (NSString *) descriptionWithPrefix:(NSString *)prefix separator:(NSString *)separator dateFormat:(NSString *)dateFormat language:(NSString *)language
{
    return _description([self startDate], [self endDate], prefix, separator, dateFormat, language);
}

- (BOOL) containsDate:(NSCalendarDate *)date
{
    // There is no need to set date's timezone to GMT; comparisons are OK.
    return [[self startDate] compare:date] != NSOrderedDescending && [_nextDayDate([self endDate]) compare:date] == NSOrderedDescending;
}

- (BOOL) intersectsInterval:(SenDateInterval *)interval
{
    return [[self endDate] compare:[interval startDate]] != NSOrderedAscending && [[self startDate] compare:[interval endDate]] != NSOrderedDescending;
}

- (SenDateInterval *) intervalByIntersectingInterval:(SenDateInterval *)interval
{
    NSCalendarDate	*aStartDate = ([[self startDate] compare:[interval startDate]] == NSOrderedDescending ? [self startDate]:[interval startDate]);
    NSCalendarDate	*anEndDate = ([[self endDate] compare:[interval endDate]] == NSOrderedAscending ? [self endDate]:[interval endDate]);

    if([aStartDate compare:anEndDate] == NSOrderedDescending)
        return nil;
    else
        return [[self class] intervalWithStartDate:aStartDate endDate:anEndDate];
}

- (SenDateInterval *) intervalByUnioningInterval:(SenDateInterval *)interval
{
    NSCalendarDate	*aStartDate = ([[self startDate] compare:[interval startDate]] == NSOrderedAscending ? [self startDate]:[interval startDate]);
    NSCalendarDate	*anEndDate = ([[self endDate] compare:[interval endDate]] == NSOrderedDescending ? [self endDate]:[interval endDate]);

    return [[self class] intervalWithStartDate:aStartDate endDate:anEndDate];
}

@end
