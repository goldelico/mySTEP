/*
   NSTimeZone.m

   Time zone management.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Yoo C. Chung <wacko@laplace.snu.ac.kr>
   Date:	June 1997
   mySTEP:  Felipe A. Rodriguez <far@pcmagic.net>
   Date: 	April 2005

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.


   The local time zone can be specified with the TZ environment
   variable, the file LOCAL_TIME_FILE or the fallback time zone
   (which is UTC) with precedence in that order.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSString.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSAutoreleasePool.h>

#import "NSPrivate.h"

#include "tzfile.h"

#define HOUR_SECS (60*60)
#define DAY_SECS  (HOUR_SECS*24)

// System file that defines local time zone

#define LOCAL_TIME_FILE  @"localtime"
#define POSIX_TZONES     @""

								// Temporary structure for holding 
struct ttinfo					// time zone details
{
	int offset; 				// Seconds east of UTC
	BOOL isdst; 				// Daylight savings time?
	char abbr_idx; 				// Index into time zone abbreviations string
};

static NSTimeZone *__localTimeZone;		// Local time zone
static NSTimeZone *__defaultTimeZone;	// App defined default time zone
static NSLock *__zone_mutex;	// Lock for creating time zones.

								// Dictionary for time zones.  Each time 
								// zone must have a unique name.
static NSMutableDictionary *__zoneDictionary = nil;
static NSMutableDictionary *__abbreviationDictionary = nil;
static NSArray *__knownTimeZoneNames = nil;

// Search for time zone files in these dirs
// NOTE: this requires some symbolic links
//       since these names are relative to the virtual root so that -initWithContentsOfFile: can read them

NSString *__zonedirs[] = {
						   @"/etc/",	// skipped for knownTimeZoneNames
						   @"/usr/share/zoneinfo/", 
						   @"/usr/lib/zoneinfo/",
						   @"/usr/local/share/zoneinfo/",
						   @"/usr/local/lib/zoneinfo/", 
						   @"/etc/zoneinfo/",
						   @"/usr/local/etc/zoneinfo/",
						};

static NSString *_getTimeZoneFile(NSString *name)
{
	int i;
	NSFileManager *fm = [NSFileManager defaultManager];
	if([name hasPrefix:@"/"])
		return name;	// absolute name
	if([name length] == 0)
		return @"";	// empty name
	if([[name pathExtension] length] != 0)
		return @"";	// contains a dot
	for(i = 0; i<sizeof(__zonedirs)/sizeof(__zonedirs[0]); i++) 
		{ // try all zone directories
		NSString *filename = [__zonedirs[i] stringByAppendingString:name];
	    BOOL isDir;
		if([fm fileExistsAtPath:filename isDirectory:&isDir] && !isDir)
			return filename;
		}
	return @"";
}

static NSData *_openTimeZoneFile(NSString *name)
{
	NSData *data;
	NSString *filename = _getTimeZoneFile(name);	// relative file name

	if (!(data = [[NSData alloc] initWithContentsOfFile: filename]))
			{
			NSLog(@"Unable to obtain time zone `%@'.", name);	// this will try to print the current date...
			}
	return data;	// warning! not autoreleased
}

									// Decode the four bytes at PTR as a signed 
static inline int					// integer in network byte order.  Based on
decode (const void *ptr)			// code included in the GNU C Library 2.0.3
{
#if defined(WORDS_BIGENDIAN) && INT_MAX == 2147483647	// 32 bit machine
	return *(const int *) ptr;
#else

	const unsigned char *p = ptr;
#if INT_MAX == 2147483647	// 32 bit machine
	int result=*p++;
#else
#warning compiling for 64 bit int LITTLEENDIAN
	int result = *p & (1 << (CHAR_BIT - 1)) ? ~0 : 0;	// properly initialize signed 64 bit integer
	result = (result << 8) | *p++;
#endif
	result = (result << 8) | *p++;
	result = (result << 8) | *p++;
	result = (result << 8) | *p/*++*/;

	return result;
#endif
}


@interface GSTimeTransition : NSObject
{
	int trans_time; 			// When the transition occurs
	char detail_index; 			// Index of time zone detail
}
  
- (id) initWithTime:(int)aTime withIndex:(char)anIndex;
- (int) transTime;
- (char) detailIndex;

@end

@implementation GSTimeTransition

- (NSString*) description
{
	return [NSString stringWithFormat: @"%@(%d, %d)", [self class], 
										trans_time, (int)detail_index];
}

- (id) initWithTime:(int)aTime withIndex:(char)anIndex
{
	trans_time = aTime;
	detail_index = anIndex;
	
	return self;
}

- (int) transTime					{ return trans_time; }
- (char) detailIndex				{ return detail_index; }

@end /* GSTimeTransition */


@interface GSTimeZoneDetail : NSTimeZone
{
	NSTimeZone *timeZone; 		// Time zone which created this object.
	NSString *abbrev; 			// Abbreviation for time zone detail.
	int offset; 				// Offset from UTC in seconds.
	BOOL is_dst; 				// Is it daylight savings time?
}

- (id) initWithTimeZone:(NSTimeZone*)aZone 
			 withAbbrev:(NSString*)anAbbrev
			 withOffset:(int)anOffset 
			 withDST:(BOOL)isDST;
- (GSTimeZoneDetail*) _timeZoneDetailForDate:(NSDate*)date;

@end 


@implementation GSTimeZoneDetail
  
- (id) initWithTimeZone:(NSTimeZone*)aZone 
			 withAbbrev:(NSString*)anAbbrev
			 withOffset:(int)anOffset 
			 withDST:(BOOL)isDST
{
	if((self=[super init]))
		{
		timeZone = [aZone retain];
		abbrev = [anAbbrev retain];
		offset = anOffset;
		is_dst = isDST;
#if 0
		NSLog(@"GSTimeZoneDetail %@ off=%d isdst=%d", abbrev, offset, is_dst);
#endif
		}
	return self;
}
  
- (void) dealloc
{
	[timeZone release];
	[abbrev release];
	[super dealloc];
}

- (GSTimeZoneDetail*) _timeZoneDetailForDate:(NSDate*)date
{
	return [timeZone _timeZoneDetailForDate: date];
}

- (NSString*) name						{ return [timeZone name]; }
- (NSString*) abbreviation				{ return abbrev; }
- (BOOL) isDaylightSavingTime			{ return is_dst; }
- (int) secondsFromGMT					{ return offset; }
  
- (NSString*) description
{
	return [NSString stringWithFormat:@"%@(%@, %s%d)",
						[self name], [self abbreviation],
						([self isDaylightSavingTime]? "IS_DST, ": ""),
						[self secondsFromGMT]];
}

@end /* GSTimeZoneDetail */


@interface NSTimeZone (TimeZoneDetail)

- (NSArray *) _timeZoneDetailArray;

@end


@interface GSConcreteTimeZone : NSTimeZone
{
	NSData *_data;
	NSString *_name;
	NSArray *_transitions; 		// Transition times and rules
	NSArray *_details; 			// Time zone details
}

@end
  
@implementation GSConcreteTimeZone
  
- (id) initWithName:(NSString *)timeZoneName data:(NSData *)data
{
	struct tzhead header;
	unsigned int len=0;
	const char *bytes;
	if (!data)
		[NSException raise:NSInvalidArgumentException format:@"nil data"];
	if (!(bytes = [data bytes]) || (len=[data length]) < sizeof(struct tzhead))
		[NSException raise:NSGenericException format:@"timezone header invalid"];
	if((self=[super init]))
		{
			int n_trans;
			int n_types;
			int names_size;
			int i; 
			int offset;
			_name=[timeZoneName copy];	// remember
			_data=[data retain];		// remember
			memcpy(&header, bytes, sizeof(struct tzhead));	// copy to proper byte/word/long alignment
			n_trans = decode(header.tzh_timecnt);
			n_types = decode(header.tzh_typecnt);	// shouldn't we limit that to a reasonable amount i.e. 255???
			offset = ((4 * n_trans) + n_trans) + sizeof(struct tzhead);	// 5 bytes each n_trans
			names_size = decode(header.tzh_charcnt);
#if 0
			NSLog(@"n_trans=%d n_types=%d names_size=%d", n_trans, n_types, names_size);
#endif
			if(n_trans > 350 || n_types > 20)
				{
				NSLog(@"Time Zone %@ has probably bad data %@", timeZoneName, data);
				return nil;
				}
			_details = [[NSMutableArray alloc] initWithCapacity:n_types];
			for (i = 0; i < n_types; i++)			// Read time zone details
				{
				time_t off;
				char isdst;
				unsigned char abbr_idx;
				if(offset+6 >= len)
					[NSException raise:NSGenericException format:@"range error scanning timezone details"];
				off = decode(bytes+offset);	// 4 bytes GMT offset in seconds
				isdst = ((char *) bytes)[offset+4];	// is DST flag
				abbr_idx = ((char *) bytes)[offset+5];	// abbreviation index
				if(abbr_idx < names_size)
					[(NSMutableArray *) _details addObject:[[[GSTimeZoneDetail alloc]
											initWithTimeZone: self
												  withAbbrev: [NSString stringWithCString:
													  &bytes[sizeof(struct tzhead) +
													  (5*n_trans) +
													  (6*n_types) +
													  (unsigned char) abbr_idx]]
												  withOffset:off
													 withDST:(isdst > 0)] autorelease]];
				else
					NSLog(@"invalid abbr_idx %d", abbr_idx);
				offset += 6;
				}
		[__zoneDictionary setObject:self forKey:timeZoneName];	// (replace any conflicting definition!)
		}
	return self;
}

- (void) dealloc
{
	[_data release];
	[_name release];
	[_transitions release];
	[_details release];
	[super dealloc];
}

- (NSString*) name										{ return _name; }
- (NSData*) data										{ return _data; }
- (NSArray*) _timeZoneDetailArray						{ return _details; }

- (NSArray*) _determineTransitions
{
	id transitions = nil;
	struct tzhead header;
	const char *bytes;
	unsigned int len;
	NSData *data;
	
	if ((data = _openTimeZoneFile(_name)) && (bytes = [data bytes])
			&& (len = [data length]) > sizeof(struct tzhead)
			&& memcpy(&header, bytes, sizeof(struct tzhead)))
			{
				unsigned int n_trans = decode(header.tzh_timecnt);
				char *trans;
				char *type_idxs;
				int i, offset = sizeof(struct tzhead);
				
				fprintf(stderr, "ntrans=%d\n", n_trans);
				
				if (bytes+offset+((4*n_trans)+n_trans) > bytes+len)
						[NSException raise:NSGenericException format:@"range error in timezone transitions"];
				transitions = [[NSMutableArray alloc] initWithCapacity: n_trans];
				trans = objc_malloc(4 * n_trans);
				type_idxs = objc_malloc(n_trans);
				memcpy(trans, bytes+offset, (i = (4*n_trans)));	// copy to adapt alignment (bytes+offset may be unaligned)
				memcpy(type_idxs, bytes+offset+i, (n_trans));
				for (i = 0; i < n_trans; i++)
					[transitions addObject: [[GSTimeTransition alloc]
																	 initWithTime: decode(trans+(i*4))
																	 withIndex: type_idxs[i]]];
				objc_free(trans);
				objc_free(type_idxs);
			}
	[data release];
	
	return transitions;
}

- (GSTimeZoneDetail*) _timeZoneDetailForDate:(NSDate*)date
{
	unsigned index, count;
	int the_time = (int)[date timeIntervalSince1970];
	
	if (!_transitions && !(_transitions = [self _determineTransitions]))
		return nil;
	
	count = [_transitions count];
	if (count == 0 || the_time < [[_transitions objectAtIndex: 0] transTime])
		{										// Either DATE is before any 
		unsigned detail_count;					// transitions or there is no 
												// transition. Return the first
		detail_count = [_details count];		// non-DST type, or the first 
		index = 0;								// one if they are all DST.
		while (index < detail_count
			   && [[_details objectAtIndex: index] isDaylightSavingTime])
			index++;
		if (index == detail_count)
			index = 0;
		}										// Find the first transition 
	else										// after DATE, and then pick 				
		{										// the type of the transition 
		for (index = 1; index < count; index++)	// before it.
			if (the_time < [[_transitions objectAtIndex: index] transTime])
				break;
		index = [[_transitions objectAtIndex: index-1] detailIndex];
		}
	
	return [_details objectAtIndex: index];
}

@end /* GSConcreteTimeZone */


@interface GSConcreteAbsoluteTimeZone : NSTimeZone
{
	NSString *_name;
	id _detail;
	int _offset; 				// Offset from UTC in seconds.
}

- (id) _initWithOffset:(int)anOffset;

@end

@implementation GSConcreteAbsoluteTimeZone

- (id) _initWithOffset:(int)anOffset
{
	if((self=[super init]))
		{
		_name = [[NSString stringWithFormat:@"GMT%+d", anOffset] retain];
		_offset = anOffset;
		_detail = [[GSTimeZoneDetail alloc] initWithTimeZone:self 
												  withAbbrev:_name
												  withOffset:_offset 
													 withDST:NO];
		}
	return self;
}

- (void) dealloc
{
	[_name release];
	[_detail release];
	[super dealloc];
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		NSLog(@"data=%@", [aDecoder decodeObjectForKey:@"NS.data"]);
		}
	else
		{
		[aDecoder decodeValueOfObjCType: @encode(id) at: &_name];
		}
	return [self _initWithOffset:[_name intValue]];
}

- (NSString*) name											{ return _name; }
- (NSData*) data											{ return nil; }	// we don't know...

- (GSTimeZoneDetail*) _timeZoneDetailForDate:(NSDate*)date	{ return _detail; }

@end /* GSConcreteAbsoluteTimeZone */


@implementation NSTimeZone

+ (void) initialize
{
	if (!__zoneDictionary)
		{
			// should read zone directory paths from Info.plist
		__zoneDictionary = [[NSMutableDictionary alloc] init];
		__zone_mutex = [NSLock new];
		[self systemTimeZone];
		}
}

+ (NSTimeZone*) localTimeZone		{ return __localTimeZone; }

+ (NSTimeZone*) defaultTimeZone
{
	return __defaultTimeZone ? __defaultTimeZone : [self systemTimeZone];
}

+ (NSTimeZone*) systemTimeZone
{
	if (!__localTimeZone)
		{
		NSProcessInfo *pi = [NSProcessInfo processInfo];
		id localZoneString = [[pi environment] objectForKey: @"TZ"];

		if ([localZoneString length] > 0)
			__localTimeZone = [NSTimeZone timeZoneWithName: localZoneString];
		if (__localTimeZone == nil)
			__localTimeZone = [NSTimeZone timeZoneWithName: LOCAL_TIME_FILE];
	
		if (__localTimeZone == nil)
			{ // Worst case alloc something sure to succeed 
			NSLog(@"Using time zone with absolute offset 0.");
			__localTimeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
			}
		}
	if (__defaultTimeZone == nil)
		__defaultTimeZone = [__localTimeZone retain];

	return __localTimeZone;
}

+ (NSTimeZone*) timeZoneForSecondsFromGMT:(int)seconds
{				// We simply return the following because an existing time zone 
				// with the given offset might not always have the same offset 
				// (daylight savings time, change in standard time, etc.).
	return [[[GSConcreteAbsoluteTimeZone alloc] _initWithOffset:seconds] autorelease];
}

+ (NSTimeZone*) timeZoneWithAbbreviation:(NSString*)abbreviation
{
	return [self timeZoneWithName:[[self abbreviationDictionary] objectForKey: abbreviation]];
}

+ (NSTimeZone*) timeZoneWithName:(NSString*)name
{
	return [[[self alloc] initWithName:name] autorelease];
}

+ (NSTimeZone*) timeZoneWithName:(NSString*)name data:(NSData *) data
{
	return [[[self alloc] initWithName:name data:data] autorelease];
}

+ (id) allocWithZone:(NSZone *) z
{
	return NSAllocateObject(self == [NSTimeZone class]?[GSConcreteTimeZone class]:(Class) self, 0, z);
}

- (void) dealloc;
{
	[super dealloc];
}

- (id) initWithName:(NSString *)name
{
	NSTimeZone *zone;
	NSData *data;
#if 0
	NSLog(@"NSTimeZone: __zone_mutex lock");
#endif
	[__zone_mutex lock];
	if([name isEqual:LOCAL_TIME_FILE])
		{ // try to substitute real timezone name
			NSString *f=[[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath:@"/etc/localtime"];
//			fprintf(stderr, "link to %s\n", f?[f cString]:"<nil>");
			if([f hasPrefix:@"/usr/share/zoneinfo/"])
				name=[f substringFromIndex:20];
//			fprintf(stderr, "   name=%s\n", [name cString]);
		}
	if(!(zone = [__zoneDictionary objectForKey:name]))
		{
		if((data = _openTimeZoneFile(name)))	// is just allocated & initialized - not autoreleased!
			zone = [self initWithName:name data:data];
		[data release];
		}
	[__zone_mutex unlock];

	return zone;
}

- (id) initWithName:(NSString *)name data:(NSData *) data;	{ return SUBCLASS; }

- (NSString*) name	{ return SUBCLASS; }
- (NSData*) data	{ return SUBCLASS; }

+ (void) setDefaultTimeZone:(NSTimeZone*)aTimeZone
{
	if (aTimeZone == nil)
		[NSException raise: NSInvalidArgumentException
					 format: @"Can't set nil time zone."];
	ASSIGN(__defaultTimeZone, aTimeZone);
}

+ (void) resetSystemTimeZone
{
	if (__defaultTimeZone == __localTimeZone)
		ASSIGN(__defaultTimeZone, nil);
	ASSIGN(__localTimeZone, nil);
}

+ (NSDictionary*) abbreviationDictionary
{
	if (__abbreviationDictionary == nil)	// inefficient but rarely used
		{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
		NSArray *timeZoneNames = [NSTimeZone knownTimeZoneNames];
		id e, name;
		int i;

		for (i = 0; i < 24; i++)
			{
			e = [[timeZoneNames objectAtIndex: i] objectEnumerator];
			while ((name = [e nextObject]))
				{
				NSTimeZone *zone;

				if ((zone = [NSTimeZone timeZoneWithName: name]))
					{
					id de = [[zone _timeZoneDetailArray] objectEnumerator];
					id detail;
	
					while ((detail = [de nextObject]) != nil)
						[d setObject:name forKey:[detail abbreviation]];
			}	}	}
		if (__abbreviationDictionary == nil)	// FIX ME use CAS primitive?
			__abbreviationDictionary = d;
		[pool release];
		if (__abbreviationDictionary != d)
			[d release];
		}

	return __abbreviationDictionary;
}

+ (NSArray*) knownTimeZoneNames
{
	if (__knownTimeZoneNames == nil)
		{
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *zonedir = nil;
		int i;

		for(i = 1; i<sizeof(__zonedirs)/sizeof(__zonedirs[0]) && !zonedir; i++)
			{ // get location of default time zone
			NSString *p = [__zonedirs[i] stringByAppendingString:POSIX_TZONES];
			BOOL isDir;
#if 0
			NSLog(@"try zone directory %@", p);
#endif
			if ([fm fileExistsAtPath:p isDirectory:&isDir] && isDir)
				{
				zonedir = p;
				break;	// use first one
				}
			}
		if(!zonedir)
			NSLog(@"no zone directory found!");
#if 0
		NSLog(@"NSTimeZone: __zone_mutex lock");
#endif
		[__zone_mutex lock];
		if (__knownTimeZoneNames == nil && zonedir)
			{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:zonedir];
			NSString *file;
			id a[24];		// Latitudinal regions every 15 degrees (360/15)

			for (i = 0; i < 24; i++)
				a[i] = [[NSMutableArray alloc] init];
			while ((file = [enumerator nextObject]))
				{
				NSString *name = [zonedir stringByAppendingString: file];
				NSTimeZone *zone = nil;
				NSData *data = nil;
				BOOL isDir;

				// FIXMEL: check if we are really a timezone file!
				
				if ([fm fileExistsAtPath:name isDirectory:&isDir] && !isDir)
					if (!(zone = [__zoneDictionary objectForKey: file]))
						if ((data = _openTimeZoneFile(name)))
							zone = [[self alloc] initWithName:file data:data];

				if (zone != nil)
					{
					int offset, j;
					id details = [zone _timeZoneDetailArray];
					id detail, e = [details objectEnumerator];
	
					while ((detail = [e nextObject]) != nil)
						if (![detail isDaylightSavingTime])
							break;					// Get a standard time

					if (detail == nil)				// If no standard time
						detail = [details objectAtIndex: 0];

					offset = [detail secondsFromGMT];
										// Get index from normalized offset
					if ((j = ((offset+DAY_SECS) %DAY_SECS)/HOUR_SECS) < 24)
						[a[j] addObject: file];
				}	}

			__knownTimeZoneNames =[[NSArray alloc] initWithObjects:a count:24];
			[pool release];
			}
		[__zone_mutex unlock];
		}
	{
		NSMutableArray *all=[NSMutableArray arrayWithCapacity:300];
		NSEnumerator *e=[__knownTimeZoneNames objectEnumerator];
		NSArray *zone;
		while((zone=[e nextObject]))
			[all addObjectsFromArray:zone];	// merge
		return all;
	}
}

- (NSString*) description						{ return [self name]; }

- (NSString*) abbreviation
{
	return [[self _timeZoneDetailForDate:[NSDate date]] abbreviation];
}

- (NSString*) abbreviationForDate:(NSDate *) date
{
	return [[self _timeZoneDetailForDate:date] abbreviation];
}

- (BOOL) isDaylightSavingTime
{
	return [[self _timeZoneDetailForDate:[NSDate date]] isDaylightSavingTime];
}

- (BOOL) isDaylightSavingTimeForDate:(NSDate *) date
{
	return [[self _timeZoneDetailForDate:date] isDaylightSavingTime];
}

- (int) secondsFromGMT
{
	return [[self _timeZoneDetailForDate: [NSDate date]] secondsFromGMT];
}

- (int) secondsFromGMTForDate:(NSDate *) date
{
	return [[self _timeZoneDetailForDate:date] secondsFromGMT];
}

- (BOOL) isEqualToTimeZone:(NSTimeZone *)timeZone	// FIX ME concrete classes
{
	return (self == timeZone) || [[self name] isEqualToString:[timeZone name]];
}

- (id) copyWithZone:(NSZone *) zone			{ return [self retain]; }

- (void) encodeWithCoder:(NSCoder*)aCoder
{
	if (self == __localTimeZone)
		[aCoder encodeObject: @"NSLocalTimeZone"];
	else
		[aCoder encodeObject: [self name]];
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
	NSString *name;
	NSData *data=nil;
	NSTimeZone *zone;
	if([aDecoder allowsKeyedCoding])
		{
#if 0
		NSLog(@"NSTimeZone -initWithCoder:%@", aDecoder);
		NSLog(@"name=%@", [aDecoder decodeObjectForKey:@"NS.name"]);
		NSLog(@"data=%@", [aDecoder decodeObjectForKey:@"NS.data"]);
#endif
		name=[aDecoder decodeObjectForKey:@"NS.name"];
		data=[aDecoder decodeObjectForKey:@"NS.data"];
		}
	else
		{
		name = [aDecoder decodeObject];
		}
	if([name isEqual: @"NSLocalTimeZone"])
		{
		[self release];
		return __localTimeZone;
		}
	if ((zone = [self initWithName:name data:data]))
		return zone;	// ok
	[self release];
		// FIX ME need to test this
	return [[GSConcreteAbsoluteTimeZone alloc] initWithCoder:aDecoder];
}

@end  /* NSTimeZone */
