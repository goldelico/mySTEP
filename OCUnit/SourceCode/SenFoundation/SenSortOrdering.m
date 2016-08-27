/*$Id: SenSortOrdering.m,v 1.2 2002/06/06 10:14:52 phink Exp $*/

// This is Goban, a Go program for Mac OS X.  Contact goban@sente.ch,
// or see http://www.sente.ch/software/goban for more information.
//
// Copyright (c) 1997-2002, Sen:te (Sente SA).  All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation - version 2.
//
// This program is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU General Public License in file COPYING
// for more details.
//
// You should have received a copy of the GNU General Public
// License along with this program; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111, USA.

#import "SenSortOrdering.h"
#import <SenFoundation/SenFoundation.h>

@implementation SenSortOrdering : NSObject
{
    SEL selector;
    NSString *key;
}


+ (id) sortOrderingWithKey:(NSString *) aKey selector:(SEL) aSelector
{
	return [[[self alloc] initWithKey:aKey selector:aSelector] autorelease];
}


- (id) initWithKey:(NSString *) aKey selector:(SEL) aSelector
{
	[super init];
	key = [aKey copy];
	selector = aSelector;
	return self;
}


- (void) dealloc
{
	RELEASE (key);
	[super dealloc];
}


- (NSString *) key
{
	return key;
}


- (SEL) selector
{
	return selector;
}
@end


int compareUsingKeyOrderingArray (id left, id right, void *context)
{
	NSEnumerator *orderingEnumerator = [(NSArray *) context objectEnumerator];
	id each;

	while (each = [orderingEnumerator nextObject]) {
		NSString *eachKey = [each key];
		id leftValue = [left valueForKey:eachKey];
		id rightValue = [right valueForKey:eachKey];
		NSComparisonResult result;
		
		if ((leftValue == nil) && (rightValue == nil)) {
			result = NSOrderedSame;
		}
		else if (leftValue == nil) {
			result = ([each selector] == SenCompareAscending) ? NSOrderedAscending : NSOrderedDescending;
		}
		else if (rightValue == nil) {
			result = ([each selector] == SenCompareAscending) ? NSOrderedDescending : NSOrderedAscending;
		}
		else {
			 result = (NSComparisonResult) [leftValue performSelector:[each selector] withObject:rightValue];
		}
		if (result != NSOrderedSame) {
			return result;
		}		
	}
	return NSOrderedSame;
}


@implementation NSArray (SenKeyBasedSorting)
- (NSArray *) arrayBySortingOnKeyOrderArray:(NSArray *) orderArray
{
	return [self sortedArrayUsingFunction:compareUsingKeyOrderingArray context:orderArray];
}
@end


@implementation NSMutableArray (SenKeyBasedSorting)
- (void) sortOnKeyOrderArray:(NSArray *) orderArray
{
	[self sortUsingFunction:compareUsingKeyOrderingArray context:orderArray];
}
@end


@protocol Comparable
- (NSComparisonResult) compare:other;
@end


@implementation NSObject (SenSortOrderingComparison)
- (NSComparisonResult) compareAscending:(id) other
{
	if (![self respondsToSelector:@selector (compare:)]) {
		[NSException raise:NSInvalidArgumentException format:@"%@ does not respond to compare:", self];
	}
	return [(id <Comparable>) self compare:other];
}


- (NSComparisonResult) compareDescending:(id) other
{
	if (![other respondsToSelector:@selector (compare:)]) {
		[NSException raise:NSInvalidArgumentException format:@"%@ does not respond to compare:", other];
	}
	return [(id <Comparable>) other compare:self];
}
@end
