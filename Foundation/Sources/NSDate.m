/* 
   NSDate.m

   Implementations of NSDate and NSCalendarDate.

   Copyright (C) 1996, 1998 Free Software Foundation, Inc.

   Author:  Jeremy Bettis <jeremy@hksys.com>
   Date:	March 1995
   mySTEP:	Felipe A. Rodriguez <far@pcmagic.net>
   Date:	April 1999
   mySTEP:	H. Nikolaus Schaller <hns@computer.org>
   Date:	Sept 2005 - added %F

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef __WIN32__
#include <time.h>
#include <sys/time.h>
#endif /* !__WIN32__ */

#import <Foundation/NSDate.h>
#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>

#import "NSPrivate.h"

// Absolute Gregorian date for NSDate reference date Jan 01 2001
//
//  N = 1;                 // day of month
//  N = N + 0;             // days in prior months for year
//  N = N +                // days this year
//    + 365 * (year - 1)   // days in previous years ignoring leap days
//    + (year - 1)/4       // Julian leap days before this year...
//    - (year - 1)/100     // ...minus prior century years...
//    + (year - 1)/400     // ...plus prior years divisible by 400

#define GREGORIAN_REFERENCE		730486

//  The number of seconds between 1/1/2001 and 1/1/1970 = -978307200.
//  This number comes from: 
//        -(((31 years * 365 days) + 8 days for leap years) = 
//        <total number of days> * 24 hours * 60 minutes * 60 seconds)
//  This ignores leap-seconds. 

#define UNIX_REFERENCE_INTERVAL -978307200.0
#define DISTANT_YEARS			100000.0
#define DISTANT_FUTURE			(DISTANT_YEARS * 365.0 * 24 * 60 * 60)
#define DISTANT_PAST			(-DISTANT_FUTURE)

// Class variables
static NSString *__format = @"%Y-%m-%d %H:%M:%S %z";
static id _distantFuture = nil;
static id _distantPast = nil;

//
// Month names    FIX ME should be localized
//
static id _monthAbbrev[12] = { @"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", 
							   @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"};
static id _month[12] = { @"January", @"February", @"March", @"April",
						 @"May", @"June", @"July", @"August", @"September", 
						 @"October", @"November", @"December" };
static id _dayAbbrev[7] = { @"Sun",@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat" };
static id _day[7] =	{ @"Sunday", @"Monday", @"Tuesday", @"Wednesday",
					  @"Thursday", @"Friday", @"Saturday" };

NSTimeInterval NSTimeIntervalSince1970=0.0;

//*****************************************************************************
//
// 		NSDate 
//
//*****************************************************************************

@implementation NSDate

+ (void) initialize
{
	if (self == [NSDate class])
		{
		_distantFuture = [[self alloc] initWithTimeIntervalSinceReferenceDate:DISTANT_FUTURE];
		_distantPast = [[self alloc] initWithTimeIntervalSinceReferenceDate:DISTANT_PAST];
#if 1
		NSTimeIntervalSince1970=[[NSDate dateWithString:@"2001/01/01 00:00:00 +00:00"] timeIntervalSince1970];
#endif
		}
}

+ (NSTimeInterval) timeIntervalSinceReferenceDate
{ // return current time
	NSTimeInterval interval = UNIX_REFERENCE_INTERVAL;
	struct timeval tp;
#if 0	// !!! don't use NSLog here since it leads to recursion
	printf("UNIX_REFERENCE_INTERVAL=%lf\n", interval);
#endif
	gettimeofday (&tp, NULL);
#if 0
	printf("tv_sec=%ld\n", tp.tv_sec);
	printf("tv_usec=%ld\n", (long) tp.tv_usec);
#endif
	interval += tp.tv_sec;
	interval += (double)((long)tp.tv_usec) / 1000000.0;	// suseconds_t tv_usec; - "su" stands for signed (!) microseconds
#if 0
	printf("interval=%lf\n", interval);
#endif
	NSAssert(interval > UNIX_REFERENCE_INTERVAL, NSInternalInconsistencyException);	// we should be well beyond UNIX_REFERENCE_INTERVAL
	return interval;
}

+ (id) date									{ return [[self new] autorelease];}
+ (id) distantFuture						{ return _distantFuture; }
+ (id) distantPast							{ return _distantPast; }

+ (id) dateWithNaturalLanguageString:(NSString *)string;
{
	return [self dateWithNaturalLanguageString:string locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

+ (id) dateWithNaturalLanguageString:(NSString *)string locale:(NSDictionary *)locale;
{
	if(!locale)
		locale=nil;	// use system defaults
	// should we call NSDateFormatter?
	return NIMP;
}

+ (id) dateWithString:(NSString*)description
{
	return [[[self alloc] initWithString:description] autorelease];
}

+ (id) dateWithTimeIntervalSinceNow:(NSTimeInterval)seconds
{
	return [[[self alloc] initWithTimeIntervalSinceNow: seconds] autorelease];
}

+ (id) dateWithTimeIntervalSince1970:(NSTimeInterval)seconds
{
	return [[[self alloc] initWithTimeIntervalSinceReferenceDate: 
						  UNIX_REFERENCE_INTERVAL + seconds] autorelease];
}

+ (id) dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)seconds
{
	return [[[self alloc] initWithTimeIntervalSinceReferenceDate: seconds]
						  autorelease];
}

- (id) copyWithZone:(NSZone *) zone					{ return [self retain]; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder
{ // default is to encode by copy
	if(![coder isByref])
		return self;
	return [super replacementObjectForPortCoder:coder];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&_secondsSinceRef];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	if([coder allowsKeyedCoding])
		_secondsSinceRef=[[coder decodeObjectForKey:@"NS.time"] doubleValue];
	else
		[coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&_secondsSinceRef];
	return self;
}

- (id) init
{
	return [self initWithTimeIntervalSinceReferenceDate:[isa timeIntervalSinceReferenceDate]];
}

- (id) initWithString:(NSString*)description
{ // Easiest to just have NSCalendarDate do the work for us
	NSCalendarDate *d = [[NSCalendarDate alloc] initWithString: description];
	self=[self initWithTimeIntervalSinceReferenceDate:[d timeIntervalSinceReferenceDate]];
	[d release];
	return self;
}

- (id) initWithTimeInterval:(NSTimeInterval)secsToBeAdded
				  sinceDate:(NSDate*)anotherDate;
{					// Get the other date's time, add the secs and init thyself
	return [self initWithTimeIntervalSinceReferenceDate:
				 [anotherDate timeIntervalSinceReferenceDate] + secsToBeAdded];
}

- (id) initWithTimeIntervalSinceNow:(NSTimeInterval)secsToBeAdded;
{						// Get the current time, add the secs and init thyself
	return [self initWithTimeIntervalSinceReferenceDate:
				[isa timeIntervalSinceReferenceDate] + secsToBeAdded];
}

- (id) initWithTimeIntervalSince1970:(NSTimeInterval)seconds
{
	return [self initWithTimeIntervalSinceReferenceDate:
				 UNIX_REFERENCE_INTERVAL + seconds];
}

- (id) initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)secs
{
	if((self=[super init]))
		{
		_secondsSinceRef = secs;
		}
	return self;
}

- (NSCalendarDate *) dateWithCalendarFormat:(NSString*)formatString
								   timeZone:(NSTimeZone*)timeZone
{													
	NSCalendarDate *d = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate: _secondsSinceRef];	// Convert to NSCalendarDate
	[d setCalendarFormat: formatString];
	[d setTimeZone: timeZone];
	return [d autorelease];
}

- (NSString*) description
{
	return [self descriptionWithLocale:nil];
}

- (NSString*) descriptionWithCalendarFormat:(NSString*)format
								   timeZone:(NSTimeZone*)aTimeZone
									 locale:(NSDictionary *)locale;
{
	if(_secondsSinceRef <= DISTANT_PAST)
		return @"distantPast";
	if(_secondsSinceRef >= DISTANT_FUTURE)
		return @"distantFuture";
	return [[self dateWithCalendarFormat:format timeZone:aTimeZone] descriptionWithLocale:locale];
}

- (NSString *) descriptionWithLocale:(id)locale
{
	return [self descriptionWithCalendarFormat:nil timeZone:nil locale:locale];
}

- (id) addTimeInterval:(NSTimeInterval)seconds
{									
	NSTimeInterval total = _secondsSinceRef + seconds;
	return [isa dateWithTimeIntervalSinceReferenceDate:total];
}

- (NSTimeInterval) timeIntervalSince1970
{
	return _secondsSinceRef - UNIX_REFERENCE_INTERVAL;
}

- (NSTimeInterval) timeIntervalSinceDate:(NSDate*)otherDate
{
	return _secondsSinceRef - [otherDate timeIntervalSinceReferenceDate];
}

- (NSTimeInterval) timeIntervalSinceNow
{
	NSTimeInterval now = [isa timeIntervalSinceReferenceDate];
	return _secondsSinceRef - now;
}

- (NSTimeInterval) timeIntervalSinceReferenceDate
{
	return _secondsSinceRef;
}

- (NSComparisonResult) compare:(NSDate*)otherDate			// Comparing dates
{
	if (_secondsSinceRef > otherDate->_secondsSinceRef)
		return NSOrderedDescending;
	if (_secondsSinceRef < otherDate->_secondsSinceRef)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (NSDate *) earlierDate:(NSDate *)otherDate
{ // nil date is taken as equivalent for distantPast
#if 0
	NSLog(@"earlier date (%@, %@)", self, otherDate);
#endif
	if (!otherDate || _secondsSinceRef > otherDate->_secondsSinceRef)
		{
#if 0
			NSLog(@"-> %@", otherDate);
#endif
		return otherDate;
		}
#if 0
	NSLog(@"-> %@", self);
#endif
	return self;
}

- (BOOL) isEqual:(id)other
{ // within 1 second precision (!)
	if ([other isKindOfClass: [NSDate class]] && ABS(_secondsSinceRef - ((NSDate *)other)->_secondsSinceRef) < 1.0)
		return YES;
	return NO;
}		

- (BOOL) isEqualToDate:(NSDate *) other
{ // within 1 second precision
	return other && ABS(_secondsSinceRef - (other->_secondsSinceRef)) < 1.0;
}		

- (NSDate*) laterDate:(NSDate*)otherDate
{
	if (_secondsSinceRef < otherDate->_secondsSinceRef)
		return otherDate;
	return self;
}

@end /* NSDate */

//*****************************************************************************
//
// 		NSCalendarDate 
//
//*****************************************************************************

@interface NSCalendarDate (Private)

// Internal methods

- (int) _lastDayOfGregorianMonth:(int)month year:(int)year;
- (int) _absoluteGregorianDay:(int)day month:(int)month year:(int)year;
- (void) _gregorianDateFromAbsolute:(int)d 
								day:(int *)day
							  month:(int *)month
							   year:(int *)year;
- (void) _getYear:(int *)year 
			month:(int *)month 
			day:(int *)day
			hour:(int *)hour 
			minute:(int *)minute 
			second:(int *)second;

@end

@implementation NSCalendarDate

+ (id) calendarDate				{ return [[self new] autorelease]; }

+ (id) dateWithString:(NSString *)description 
	   calendarFormat:(NSString *)format
{
	return [[[NSCalendarDate alloc] initWithString: description
									calendarFormat: format] autorelease];
}

+ (id) dateWithString:(NSString *)description
	   calendarFormat:(NSString *)format
	   locale:(NSDictionary *)dictionary
{
	return [[[NSCalendarDate alloc] initWithString: description
									calendarFormat: format
									locale: dictionary] autorelease];
}

+ (id) dateWithYear:(int)year
			  month:(unsigned int)month
			  day:(unsigned int)day
			  hour:(unsigned int)hour
			  minute:(unsigned int)minute
			  second:(unsigned int)second
			  timeZone:(NSTimeZone *)aTimeZone
{
	return [[[NSCalendarDate alloc] initWithYear: year
									month: month
									day: day
									hour: hour
									minute: minute
									second: second
									timeZone: aTimeZone] autorelease];
}

- (void) encodeWithCoder:(NSCoder*)aCoder
{
	[super encodeWithCoder: aCoder];
    [aCoder encodeObject: calendar_format];
    [aCoder encodeObject: time_zone];
}

- (id) initWithCoder:(NSCoder*)aCoder
{
	self = [super initWithCoder:aCoder];
	if([aCoder allowsKeyedCoding])
		{
		calendar_format=[[aCoder decodeObjectForKey:@"NS.format"] retain];
		time_zone=[[aCoder decodeObjectForKey:@"NS.timezone"] retain];
		}
	else
		{
		[aCoder decodeValueOfObjCType: @encode(id) at: &calendar_format];
		[aCoder decodeValueOfObjCType: @encode(id) at: &time_zone];
		}
    return self;
}

- (void) dealloc
{
    [calendar_format release];
    [super dealloc];
}
												// Init an NSCalendar Date
- (id) initWithString:(NSString *)description
{												// FIX ME What is the locale?
	return [self initWithString:description 
				 calendarFormat:__format 
				 locale:nil];
}

- (id) initWithString:(NSString *)description calendarFormat:(NSString *)format
{												// FIX ME What is the locale?
	return [self initWithString: description
				 calendarFormat: format
				 locale: nil];
}

- (id) initWithString:(NSString *)description			// This function could
	   calendarFormat:(NSString *)format				// possibly be written
	   locale:(NSDictionary *)dictionary				// better but it works
{														// ok; currently
const char *d = [description UTF8String];					// ignores locale info
const char *f = [format UTF8String];						// and some specifiers.
char *newf;
int lf = strlen(f);
BOOL mtag = NO, dtag = NO, ycent = NO;
BOOL fullm = NO;
// FIXME: risk of buffer oferflow!
char ms[80] = "", ds[80] = "", timez[80] = "", ampm[80] = "";
int yd = 0, md = 0, dd = 0, hd = 0, mnd = 0, sd = 0, msec = 0;
// FIXME: is this save against buffer overflow if too many and duplicate specifiers are found?
void *pntr[11] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int yord = 0, mord = 0, dord = 0, hord = 0, mnord = 0, sord = 0, tzord = 0, msord = 0;
int tznum = 0;
int ampmord = 0;
int i, order;
NSTimeZone *tz;
BOOL zoneByAbbreviation = YES;
										// If either the string or format 
	if (!description)					// is nil then raise exception
		[NSException raise: NSInvalidArgumentException
					 format: @"NSCalendar date description is nil"];
	if (!format)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSCalendar date format is nil"];
										// Find the order of date elements and 
										// translate format string into scanf 
	order = 1;							// ready string
	newf = objc_malloc(lf+1);
	for (i = 0;i < lf; ++i)				// see description method for a list of
		{								// the strftime format specifiers
		newf[i] = f[i];

		if (f[i] == '%')				// Only care about a format specifier
			{
			switch (f[i+1])				// check the character that comes after
				{	
				case '%':								// skip literal %
					++i;
					newf[i] = f[i];
					break;

				case 'Y':								// is it the year
					ycent = YES;
				case 'y':
					yord = order;
					++order;
					++i;
					newf[i] = 'd';
					pntr[yord] = (void *)&yd;
					break;

				case 'B':								// is it the month
					fullm = YES;						// Full month name
				case 'b':
					mtag = YES;							// Month is char string
				case 'm':
					mord = order;
					++order;
					++i;
					if (mtag)
						{
						newf[i] = 's';
						pntr[mord] = (void *)ms;
						}
					else
						{
						newf[i] = 'd';
						pntr[mord] = (void *)&md;
						}
					break;

				case 'a':							// is it the day
				case 'A':
					dtag = YES;						// Day is character string
				case 'd':
				case 'j':
				case 'w':
					dord = order;
					++order;
					++i;
					if (dtag)
						{
						newf[i] = 's';
						pntr[dord] = (void *)ds;
						}
					else
						{
						newf[i] = 'd';
						pntr[dord] = (void *)&dd;
						}
					break;

				case 'H':									// is it the hour
				case 'I':
					hord = order;
					++order;
					++i;
					newf[i] = 'd';
					pntr[hord] = (void *)&hd;
					break;

				case 'M':									// is it the minute
					mnord = order;
					++order;
					++i;
					newf[i] = 'd';
					pntr[mnord] = (void *)&mnd;
					break;

				case 'S':									// is it the second
					sord = order;
					++order;
					++i;
					newf[i] = 'd';
					pntr[sord] = (void *)&sd;
					break;

				case 'Z':									// time zone abbrev
					tzord = order;
					++order;
					++i;
					newf[i] = 's';
					pntr[tzord] = (void *)timez;
					break;

				case 'z':									// time zone in 
					tzord = order;							// numeric format
					++order;
					++i;
					newf[i] = 'd';
					pntr[tzord] = (void *)&tznum;
					zoneByAbbreviation = NO;
					break;

				case 'p':									// AM PM indicator
					ampmord = order;
					++order;
					++i;
					newf[i] = 's';
					pntr[ampmord] = (void *)ampm;
					break;

				case 'F':	// milliseconds
					msord = order;
					++order;
					++i;
					newf[i] = 'd';
					pntr[msord] = (void *)&msec;
					break;
					
				default:									// Anything else is 
					objc_free(newf);								// invalid format
					[NSException raise: NSInvalidArgumentException
								 format: @"Invalid NSCalendar date, specifier \
								%c not recognized in format %s", f[i+1], f];
		}	}	}
	newf[lf] = '\0';
		
			// Have sscanf parse and retrieve the values for us
	
	// !!!!
	// FIXME: this has a fatal flaw: %d means 2 digits in date format, but any number of digits in sscanf
	// so, we can't parse 090705 properly

	if (order != 1)
		sscanf(d, newf, pntr[1], pntr[2], pntr[3], pntr[4], pntr[5], pntr[6],
				pntr[7], pntr[8], pntr[9]);
	else
			// nothing in the string?
			;
		
			// Put century on year if need be
			// +++ How do we be year 2000 compliant?
	if (!ycent)
		yd += 1900;
		
			// Possibly convert month from string to decimal number
			// +++ how do we take locale into account?
	if (mtag)
		{
		int i;
		NSString *m = [NSString stringWithCString: ms];
		
		if (fullm)
			{
			for (i = 0;i < 12; ++i)
				if ([_month[i] isEqual: m] == YES)
					break;
			}
		else
			{
			for (i = 0;i < 12; ++i)
				if ([_monthAbbrev[i] isEqual: m] == YES)
					break;
			}
		md = i + 1;
		}
		
	if (dtag)			// Possibly convert day from string to decimal number
		{						// +++ how do we take locale into account?
		}
						// +++ We need to take 'am' and 'pm' into account
	if (ampmord)
		{									// If its PM then we shift
		if ((ampm[0] == 'p') || (ampm[0] == 'P'))
			{								// 12pm is 12pm not 24pm
			if (hd != 12)
				hd += 12;
		}	}
											// +++ then there is the time zone
	if (tzord)
		{
		if (zoneByAbbreviation)
			{
			NSString *abbrev = [NSString stringWithCString: timez];

			if (!(tz = [NSTimeZone timeZoneWithAbbreviation: abbrev]))
				tz = [NSTimeZone localTimeZone];
			}
		else
			{
			int tzm, tzh, sign;
		
			if (tznum < 0)
				{
				sign = -1;
				tznum = -tznum;
				}
			else
				sign = 1;
			tzm = tznum % 100;
			tzh = tznum / 100;
			tz = [NSTimeZone timeZoneForSecondsFromGMT:(tzh*60 + tzm)*60*sign];
			if (!tz)
				tz = [NSTimeZone localTimeZone];
		}	}
	else
		tz = [NSTimeZone localTimeZone];
		
	objc_free(newf);

	self=[self initWithYear: yd 
				 month: md 
				 day: dd 
				 hour: hd
				 minute: mnd 
				 second: sd 
					 timeZone: tz];
	if(self)
		_secondsSinceRef+=msec*0.001;	// adjust for milliseconds (%F)
	return self;
}

- (id) initWithYear:(int)year
			  month:(unsigned int)month
			  day:(unsigned int)day
			  hour:(unsigned int)hour
			  minute:(unsigned int)minute
			  second:(unsigned int)second
			  timeZone:(NSTimeZone *)aTimeZone
{
int	c, a = [self _absoluteGregorianDay: day month: month year: year];
NSTimeInterval s;

	a -= GREGORIAN_REFERENCE;						// Calculate date as GMT
	s = (double)a * 86400;
	s += hour * 3600;
	s += minute * 60;
	s += second;
													// Assign time zone detail
	time_zone = [aTimeZone _timeZoneDetailForDate:
					[NSDate dateWithTimeIntervalSinceReferenceDate: s]];
	
								// Adjust date so it is correct for time zone.
	s -= [time_zone secondsFromGMT];
	self = [self initWithTimeIntervalSinceReferenceDate: s];
	
			// Now permit up to five cycles of adjustment to allow for daylight 
			// savings. NB. this depends on it being OK to call the
			// [-initWithTimeIntervalSinceReferenceDate:] method repeatedly!
	for (c = 0; c < 5 && self != nil; c++)
		{
		int	y, m, d, h, mm, ss;
		NSTimeZone *z;
		NSDate *dt;
	
		[self _getYear:&y month:&m day:&d hour:&h minute:&mm second:&ss];
		if(y==year && m==month && d==day && h==hour && mm==minute && 
				ss==second)
			return self;
	
				// Has the time-zone detail changed?  If so - adjust time for 
				// it, other wise -  try to adjust to the correct time.
		dt = [NSDate dateWithTimeIntervalSinceReferenceDate: s];
		if ((z = [aTimeZone _timeZoneDetailForDate: dt]) != time_zone)
			{
			NSTimeInterval oldOffset = [time_zone secondsFromGMT];
			NSTimeInterval newOffset = [z secondsFromGMT];

			time_zone = z;
			s += newOffset - oldOffset;
			}
		else
			{
			NSTimeInterval move;		// Do we need to go back or forwards in 
										// time?  Shift at most two hours - we 
			if (y > year)				// know of no daylight savings time
				move = -7200.0;			// which is an offset of more than two
			else if (y < year)			// hours
				move = +7200.0;
			else if (m > month)
				move = -7200.0;
			else if (m < month)
				move = +7200.0;
			else if (d > day)
				move = -7200.0;
			else if (d < day)
				move = +7200.0;
			else if (h > hour || h < hour)
				move = (hour - h)*3600.0;
			else if (mm > minute || mm < minute)
				move = (minute - mm)*60.0;
			else
				move = (second - ss);
		
			s += move;
			}
		self = [self initWithTimeIntervalSinceReferenceDate: s];
		}

	return self;
}

- (id) initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)seconds
{															// Designated init
	if((self=[super initWithTimeIntervalSinceReferenceDate: seconds]))
		{
		if (!calendar_format)
			calendar_format = __format;
		if (!time_zone)
			time_zone = [[NSTimeZone localTimeZone] _timeZoneDetailForDate: self];
		}
	return self;
}

- (int) dayOfCommonEra
{										// Get reference date in terms of days
double a = (_secondsSinceRef+[time_zone secondsFromGMT]) / 86400.0;
int r;
										// Offset by Gregorian reference
	a += GREGORIAN_REFERENCE;
	r = (int)a;

	return r;
}

- (int) dayOfMonth
{
int m, d, y, a = [self dayOfCommonEra];

	[self _gregorianDateFromAbsolute:a day: &d month: &m year: &y];

	return d;
}

- (int) dayOfWeek
{												// The era started on a sunday.
int d = [self dayOfCommonEra];					// Did we always have a seven 
												// day week? Did we lose week 
	d = d % 7;									// days changing from Julian to 
	if (d < 0)									// Gregorian? AFAIK seven days 
		d += 7;									// per week is ok for all 
												// reasonable dates. 
	return d;
}

- (int) dayOfYear
{
int m, d, y, days, i, a = [self dayOfCommonEra];

	[self _gregorianDateFromAbsolute: a day: &d month: &m year: &y];
	days = d;
	for (i = m - 1;  i > 0; i--) 			// days in prior months this year
		days = days + [self _lastDayOfGregorianMonth: i year: y];

	return days;
}

- (int) hourOfDay
{
int h;
double a, d = [self dayOfCommonEra];

	d -= GREGORIAN_REFERENCE;
	d *= 86400;
	a = abs(d - (_secondsSinceRef+[time_zone secondsFromGMT]));
	a = a / 3600;
	h = (int)a;
										// There is a small chance of getting
	if (h == 24)						// it right at the stroke of midnight
		h = 0;

	return h;
}

- (int) minuteOfHour
{
int h, m;
double a, b, d = [self dayOfCommonEra];

	d -= GREGORIAN_REFERENCE;
	d *= 86400;
	a = abs(d - (_secondsSinceRef+[time_zone secondsFromGMT]));
	b = a / 3600;
	h = (int)b;
	h = h * 3600;
	b = a - h;
	b = b / 60;
	m = (int)b;

	return m;
}

- (int) monthOfYear
{
int m, d, y, a = [self dayOfCommonEra];

	[self _gregorianDateFromAbsolute:a day:&d month:&m year:&y];

	return m;
}

- (int) secondOfMinute
{
int h, m, s;
double a, b, c, d = [self dayOfCommonEra];

	d -= GREGORIAN_REFERENCE;
	d *= 86400;
	a = abs(d - (_secondsSinceRef+[time_zone secondsFromGMT]));
	b = a / 3600;
	h = (int)b;
	h = h * 3600;
	b = a - h;
	b = b / 60;
	m = (int)b;
	m = m * 60;
	c = a - h - m;
	s = (int)c;

	return s;
}

- (int) yearOfCommonEra
{										// Get reference date in terms of days
int a = (_secondsSinceRef+[time_zone secondsFromGMT]) / 86400;
int m, d, y;
											// Offset by Gregorian reference
	a += GREGORIAN_REFERENCE;
	[self _gregorianDateFromAbsolute: a day: &d month: &m year: &y];

	return y;
}

- (NSCalendarDate*) addYear:(int)year					// return adjusted date
					  month:(unsigned int)month
					  day:(unsigned int)day
					  hour:(unsigned int)hour
					  minute:(unsigned int)minute
					  second:(unsigned int)second
{
	return [self dateByAddingYears: year
				 months: month
				 days: day
				 hours: hour
		         minutes: minute
		         seconds: second];
}

- (NSString *) description								// String Description 
{
	return [self descriptionWithLocale: nil];
}

- (NSString *) descriptionWithCalendarFormat:(NSString *)format
{
	return [self descriptionWithCalendarFormat: format locale: nil];
}

- (NSString *) descriptionWithCalendarFormat:(NSString *)format
									  locale:(NSDictionary *)locale
{
	const char *f = (format) ? [format UTF8String] : "%Y%m%dT%H%M%SZ%z";
	int lf = strlen(f);
	char buf[1024];	// should estimate required size from lf to prevent buffer overflow!
	BOOL mtag = NO, dtag = NO, ycent = NO;
	BOOL mname = NO, dname = NO;
	double s;
	int yd = 0, md = 0, mnd = 0, sd = 0, dom = -1, dow = -1, doy = -1;
	int hd = 0, nhd;
	int i, j, k, z;

	[self _getYear:&yd month:&md day:&dom hour:&hd minute:&mnd second:&sd];
	nhd = hd;

//	The strftime format specifiers
//	%a   abbreviated weekday name according to locale
//	%A   full weekday name according to locale
//	%b   abbreviated month name according to locale
//	%B   full month name according to locale
	// %c	shorthand for "%X %x"
//	%d   day of month as decimal number (leading zero)
//	%e   day of month as decimal number (leading space) **
//	%F   milliseconds (000 to 999) **
//	%H   hour as a decimal number using 24-hour clock
//	%I   hour as a decimal number using 12-hour clock
//	%j   day of year as a decimal number
//	%m   month as decimal number
//	%M   minute as decimal number
//	%p   'am' or 'pm'
//	%S   second as decimal number
//	%U   week of the current year as decimal number (Sunday first day)
//	%W   week of the current year as decimal number (Monday first day)
//	%w   day of the week as decimal number (Sunday = 0)
//	%y   year as a decimal number without century
//	%Y   year as a decimal number with century
//	%z   time zone offset (HHMM) **
//	%Z   time zone
//	%%   literal % character
//
//	** Note -- may not be supported in init method
//
										// Find the order of date elements and 
										// translate format string into printf 
	j = 0;								// ready string
	for (i = 0;i < lf; ++i)
		{								// Only care about a format specifier
		if (f[i] == '%')
			{							// check the character that comes after
			switch (f[i+1])
				{											// literal %
				case '%':
					++i;
					buf[j] = f[i];
					++j;
					break;

				case 'Y':									// is it the year
					ycent = YES;
				case 'y':
					++i;
					if (ycent)
						k = sprintf(&(buf[j]), "%04d", yd);
					else
						k = sprintf(&(buf[j]), "%02d", yd%100);
					j += k;
					break;

				case 'b':									// is it the month
					mname = YES;
				case 'B':
					mtag = YES;					// Month is character string
				case 'm':
					++i;
					if (mtag)
						{			// +++ Translate to locale character string
						if (mname)
							k = sprintf(&(buf[j]), "%s",
										[_monthAbbrev[md-1] cString]);
						else
							k = sprintf(&(buf[j]), "%s", 
										[_month[md-1] cString]);
						}
					else
						k = sprintf(&(buf[j]), "%02d", md);
					j += k;
					break;
		
				case 'd':									// day of month
					++i;
					k = sprintf(&(buf[j]), "%02d", dom);
					j += k;
					break;
		
				case 'e':									// day of month
					++i;
					k = sprintf(&(buf[j]), "%2d", dom);
					j += k;
					break;
		
				case 'F':									// milliseconds
					s = ([self dayOfCommonEra] -GREGORIAN_REFERENCE) * 86400.0;
					s -= (_secondsSinceRef+[time_zone secondsFromGMT]);
					s = fabs(s);
					s -= floor(s);
					++i;
					k = sprintf(&(buf[j]), "%03d",(int)(s*1000.0));
					j += k;
					break;
		
				case 'j':									// day of year
					if (doy < 0) 
						doy = [self dayOfYear];
					++i;
					k = sprintf(&(buf[j]), "%02d", doy);
					j += k;
					break;

				case 'a':									// is it week-day
					dname = YES;
				case 'A':
					dtag = YES;						// Day is character string
				case 'w':
					++i;
					if (dow < 0) 
						dow = [self dayOfWeek];
					if (dtag)
						{			// +++ Translate to locale character string
						if (dname)
							k = sprintf(&(buf[j]),"%s",
										[_dayAbbrev[dow] cString]);
						else
							k = sprintf(&(buf[j]), "%s", 
										[_day[dow] cString]);
						}
					else
						k = sprintf(&(buf[j]), "%02d", dow);
					j += k;
					break;

				case 'I':									// is it the hour
					nhd = hd % 12;			// 12 hour clock
					if (hd == 12)
						nhd = 12;			// 12pm not 0pm
				case 'H':
					++i;
					k = sprintf(&(buf[j]), "%02d", nhd);
					j += k;
					break;

				case 'M':									// is it the minute
					++i;
					k = sprintf(&(buf[j]), "%02d", mnd);
					j += k;
					break;

				case 'S':									// is it the second
					++i;
					k = sprintf(&(buf[j]), "%02d", sd);
					j += k;
					break;

				case 'p':							// Is it am/pm indicator
					++i;
					if (hd >= 12)
						k = sprintf(&(buf[j]), "PM");
					else
						k = sprintf(&(buf[j]), "AM");
					j += k;
					break;

				case 'Z':									// is it zone name
					++i;
					k = sprintf(&(buf[j]), "%s",
								[[time_zone abbreviation] cString]);
					j += k;
					break;
		
				case 'z':
					++i;
					z = [time_zone secondsFromGMT];
					if (z < 0) 
						{
						z = -z;
						z /= 60;
						k = sprintf(&(buf[j]), "-%02d%02d",z/60,z%60);
						}
					else 
						{
						z /= 60;
						k = sprintf(&(buf[j]), "+%02d%02d",z/60,z%60);
						}
					j += k;
					break;

				default:			// Anything else is unknown so just copy
					buf[j] = f[i];
					++i;
					++j;
					buf[j] = f[i];
					++i;
					++j;
					break;
			}	}
		else
			{
			buf[j] = f[i];
			++j;
		}	}
	buf[j] = '\0';

	return [NSString stringWithCString: buf];
}

- (NSString *) descriptionWithLocale:(id)locale
{
	return [self descriptionWithCalendarFormat:calendar_format locale:locale];
}

- (void) setCalendarFormat:(NSString *)format
{
	[calendar_format release];
	calendar_format = [format copy];
}

- (NSString *) calendarFormat				{ return calendar_format; }
- (id) copyWithZone:(NSZone *) zone			{ return [self retain]; }

- (NSTimeZone *) timeZone; { return time_zone; }

- (void) setTimeZone:(NSTimeZone *)aTimeZone
{
	if(!aTimeZone)
		aTimeZone=[NSTimeZone localTimeZone];	// default
	time_zone = [aTimeZone _timeZoneDetailForDate: self];
}

- (NSCalendarDate *) dateByAddingYears:(int)years
								months:(int)months
								  days:(int)days
								 hours:(int)hours
							   minutes:(int)minutes
							   seconds:(int)seconds
{
	int i, year, month, day, hour, minute, second;
	
	[self _getYear: &year
			 month: &month
			   day: &day
			  hour: &hour
			minute: &minute
			second: &second];
	
	second += seconds;
	minute += second/60;
	second %= 60;
	if (second < 0)
		{
		minute--;
		second += 60;
		}
	
	minute += minutes;
	hour += minute/60;
	minute %= 60;
	if (minute < 0)
		{
		hour--;
		minute += 60;
		}
	
	hour += hours;
	day += hour/24;
	hour %= 24;
	if (hour < 0)
		{
		day--;
		hour += 24;
		}
	
	day += days;
	if (day > 28)
		{
		i = [self _lastDayOfGregorianMonth: month year: year];
		while (day > i)
			{
			day -= i;
			if (month < 12)
				month++;
			else
				{
				month = 1;
				year++;
				}
			i = [self _lastDayOfGregorianMonth: month year: year];
			}
		}
	else
		while (day <= 0)
			{
			if (month == 1)
				{
				year--;
				month = 12;
				}
			else
				month--;
			day += [self _lastDayOfGregorianMonth: month year: year];
			}
			
			month += months;      
	while (month > 12)
		{
		year++;
		month -= 12;
		}
	while (month < 1)
		{
		year--;
		month += 12;
		}
	
	year += years;
	
	return [NSCalendarDate dateWithYear:year
								  month:month
									day:day
								   hour:hour
								 minute:minute
								 second:second
							   timeZone:nil];
}

- (void) years:(NSInteger*)years
		months:(NSInteger*)months
		  days:(NSInteger*)days
		 hours:(NSInteger*)hours
	   minutes:(NSInteger*)minutes
	   seconds:(NSInteger*)seconds
	 sinceDate:(NSCalendarDate*)date
{
	NSCalendarDate *start;
	NSCalendarDate *end;
	NSCalendarDate *tmp;
	int diff;
	int extra;
	int sign;
	int syear, smonth, sday, shour, sminute, ssecond;
	int eyear, emonth, eday, ehour, eminute, esecond;
	
	// FIXME What if the two dates are in different time zones?
	// How about daylight savings time?
	if ([date isKindOfClass: [NSCalendarDate class]])
		tmp = (NSCalendarDate*)[date retain];
	else
		tmp = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate:
			[date timeIntervalSinceReferenceDate]];
	
	end = (NSCalendarDate*)[self laterDate: tmp];
	if (end == self)
		{
		start = tmp;
		sign = 1;
		}
	else
		{
		start = self;
		sign = -1;
		}
	
	[start _getYear: &syear
			  month: &smonth
				day: &sday
			   hour: &shour
			 minute: &sminute
			 second: &ssecond];
	[end _getYear: &eyear
			month: &emonth
			  day: &eday
			 hour: &ehour
		   minute: &eminute
		   second: &esecond];
	
	// Calculate year difference and leave any remaining months in 'extra'
	diff = eyear - syear;
	extra = 0;
	if (emonth < smonth)
		{
		diff--;
		extra += 12;
		}
	if (years)
		*years = sign*diff;
	else
		extra += diff*12;
	
	// Calculate month difference and leave any remaining days in 'extra'
	diff = emonth - smonth + extra;
	extra = 0;
	if (eday < sday)
		{
		diff--;
		extra = [end _lastDayOfGregorianMonth: smonth year: syear];
		}
	if (months)
		*months = sign*diff;
	else
		{
		while (diff--) 
			{
			int tmpmonth = emonth - diff;
			int tmpyear = eyear;
			
			tmpmonth--;
			while (tmpmonth < 1) 
				{
				tmpmonth += 12;
				tmpyear--;
				}
			extra += [end _lastDayOfGregorianMonth: tmpmonth year: tmpyear];
			}	}
	
	// Calculate day difference and leave any remaining hours in 'extra'
	diff = eday - sday + extra;
	extra = 0;
	if (ehour < shour)
		{
		diff--;
		extra = 24;
		}
	if (days)
		*days = sign * diff;
	else
		extra += diff * 24;
	
	// Calculate hour difference and leave any remaining minutes in 'extra'
	diff = ehour - shour + extra;
	extra = 0;
	if (eminute < sminute)
		{
		diff--;
		extra = 60;
		}
	if (hours)
		*hours = sign * diff;
	else
		extra += diff * 60;
	
	// Calc minute difference and leave any remaining seconds in 'extra'
	diff = eminute - sminute + extra;
	extra = 0;
	if (esecond < ssecond)
		{
		diff--;
		extra = 60;
		}
	if (minutes)
		*minutes = sign * diff;
	else
		extra += diff * 60;
	
	diff = esecond - ssecond + extra;
	if (seconds)
		*seconds = sign * diff;
	
	[tmp release];
}

- (void) _getYear:(int *)year						// Retreiving Date Elements
			month:(int *)month 
			  day:(int *)day
			 hour:(int *)hour 
		   minute:(int *)minute 
		   second:(int *)second
{
	int h, m;
	double a, b, c, d = [self dayOfCommonEra];
	// Calc year, month, and day
	[self _gregorianDateFromAbsolute: d day: day month: month year: year];
	
	d -= GREGORIAN_REFERENCE;				// Calc hour, minute, and seconds
	d *= 86400;
	a = abs(d - (_secondsSinceRef+[time_zone secondsFromGMT]));
	b = a / 3600;
	*hour = (int)b;
	h = *hour;
	h = h * 3600;
	b = a - h;
	b = b / 60;
	*minute = (int)b;
	m = *minute;
	m = m * 60;
	c = a - h - m;
	*second = (int)c;
}

// Manipulate Gregorian dates

- (int) _lastDayOfGregorianMonth:(int)month year:(int)year
{
	switch (month) 
		{
		case 2:
			if((((year % 4) ==0) && ((year % 100) !=0)) || ((year % 400) == 0))
				return 29;
			else
				return 28;
		case 4:
		case 6:
		case 9:
		case 11: return 30;
		default: return 31;
		}
}

- (int) _absoluteGregorianDay:(int)day month:(int)month year:(int)year
{
int m, N = day;

	for (m = month - 1;  m > 0; m--)		// days in prior months this year
		N = N + [self _lastDayOfGregorianMonth: m year: year];

	return (N					// days this year
     		+ 365 * (year - 1)	// days in previous years ignoring leap days
     		+ (year - 1)/4		// Julian leap days before this year...
     		- (year - 1)/100	// ...minus prior century years...
     		+ (year - 1)/400);	// ...plus prior years divisible by 400
}

- (void) _gregorianDateFromAbsolute:(int)d
							   day:(int *)day
							   month:(int *)month
							   year:(int *)year
{						// Search forward year by year from approximate year
	*year = d/366;
	while (d >= [self _absoluteGregorianDay:1 month:1 year:(*year)+1])
		(*year)++;
						// Search forward month by month from January
	(*month) = 1;
	while (d > [self _absoluteGregorianDay: 
			[self _lastDayOfGregorianMonth: *month year: *year]
			month: *month year: *year])
	(*month)++;
	*day = d - [self _absoluteGregorianDay: 1 month: *month year: *year] + 1;
}

@end  /* NSCalendarDate (GregorianDate) */
