//
//  NSTextList.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import "AppKit/NSTextList.h"
#import <Foundation/Foundation.h>

@implementation NSTextList

- (id) initWithMarkerFormat:(NSString *) format options:(unsigned) mask;
{
	if((self=[super init]))
		{
		_markerFormat=[format retain];
		_listOptions=mask;
		}
	return self;
}

- (void) dealloc;
{
	[_markerFormat release];
	[super dealloc];
}

- (unsigned) listOptions; { return _listOptions; }
- (NSString *) markerFormat; { return _markerFormat; }

// NOTE: this function is not intended to automatically handle the NSTextListPrependEnclosingMarker option!

- (NSString *) markerForItemNumber:(int) item;
{ // decode marker format string e.g. {decimal} according to CSS3 spec
	NSMutableString *s=[_markerFormat mutableCopy];
	[s replaceOccurrencesOfString:@"{box}" withString:[NSString stringWithFormat:@"%C", 0x2022] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{check}" withString:[NSString stringWithFormat:@"%C", 0x2022] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{circle}" withString:[NSString stringWithFormat:@"%C", 0x25E6] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{diamond}" withString:[NSString stringWithFormat:@"%C", 0x2023] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{disc}" withString:[NSString stringWithFormat:@"%C", 0x2022] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{hyphen}" withString:[NSString stringWithFormat:@"%C", 0x2010] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{square}" withString:[NSString stringWithFormat:@"%C", 0x2022] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{decimal}" withString:[NSString stringWithFormat:@"%d", item] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{lower-alpha}" withString:[NSString stringWithFormat:@"%c", item+'a'] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{lower-latin}" withString:[NSString stringWithFormat:@"%c", item+'a'] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{upper-alpha}" withString:[NSString stringWithFormat:@"%c", item+'A'] options:0 range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"{upper-latin}" withString:[NSString stringWithFormat:@"%c", item+'A'] options:0 range:NSMakeRange(0, [s length])];
	// others
	return [s autorelease];
}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
//	[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding])
		{
		}
	else
		{
		}
	NIMP;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		_markerFormat=[[aDecoder decodeObjectForKey:@"NSListMarkerFormat???"] retain];
		_listOptions=[aDecoder decodeIntForKey:@"NSListOptions???"];
		}
	else
		{
		}
	return NIMP;
}

@end
