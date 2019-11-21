/* 
   NSRange.h

   Interface to NSRange

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@boulder.colorado.edu>
   Date:	1995
   mySTEP:	Felipe A. Rodriguez <farz@mindspring.com>
   Date:	Mar 1999
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSRange
#define _mySTEP_H_NSRange

#import <Foundation/NSObject.h>
#import <Foundation/NSObject.h>

#define LIMITED_NSMaxRange 1

@class NSString;

typedef struct _NSRange
{
	NSUInteger location;
	NSUInteger length;
} NSRange, *NSRangePointer;

static inline NSUInteger
NSMaxRange(NSRange range)
{
	NSUInteger r=range.location + range.length;
#if LIMITED_NSMaxRange
	if(r < range.location || r < range.length)
		return UINT_MAX;	// range overflow
#endif
	return r;
}

static inline NSRange
NSMakeRange(NSUInteger location, NSUInteger length)
{
	return (NSRange){location, length};
}

static inline BOOL
NSEqualRanges(NSRange range1, NSRange range2)
{
 return (range1.location == range2.location && range1.length == range2.length);
}

static inline BOOL
NSLocationInRange(NSUInteger location, NSRange range)
{
	return (location >= range.location) && (location < NSMaxRange(range));
}

extern NSRange
NSUnionRange(NSRange range1, NSRange range2);

extern NSRange
NSIntersectionRange(NSRange range1, NSRange range2);

extern NSString *
NSStringFromRange(NSRange range);

extern NSRange
NSRangeFromString(NSString *str);

#endif /* _mySTEP_H_NSRange */
