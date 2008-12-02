/*
    NSIndexSet.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Tue Nov 22 2005.
    Copyright (c) 2005 DSITRI.

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

    Fabian Spillner, May 2008 - API revised to be compatible to 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSIndexSet_H
#define mySTEP_NSIndexSet_H

#import "Foundation/Foundation.h"

@interface NSIndexSet : NSObject <NSCopying, NSMutableCopying, NSCoding>
{
	@public
	NSRange *_indexRanges;		// non-overlapping subranges
	unsigned _nranges;			// number of ranges in use
	unsigned _count1;
}

+ (id) indexSet;
+ (id) indexSetWithIndex:(NSUInteger) value;
+ (id) indexSetWithIndexesInRange:(NSRange) range;

- (BOOL) containsIndex:(NSUInteger) value;
- (BOOL) containsIndexes:(NSIndexSet *) indexSet;
- (BOOL) containsIndexesInRange:(NSRange) range;
- (NSUInteger) count;
- (NSUInteger) countOfIndexesInRange:(NSRange) range;
- (NSUInteger) firstIndex;
- (NSUInteger) getIndexes:(NSUInteger *) indexBuffer
				 maxCount:(NSUInteger) bufferSize
			   inIndexRange:(NSRangePointer) range;
- (NSUInteger) indexGreaterThanIndex:(NSUInteger) value;
- (NSUInteger) indexGreaterThanOrEqualToIndex:(NSUInteger) value;
- (NSUInteger) indexLessThanIndex:(NSUInteger) value;
- (NSUInteger) indexLessThanOrEqualToIndex:(NSUInteger) value;
- (id) init;
- (id) initWithIndex:(NSUInteger) value;
- (id) initWithIndexesInRange:(NSRange) range;
- (id) initWithIndexSet:(NSIndexSet *) indexSet;
- (BOOL) intersectsIndexesInRange:(NSRange) range;
- (BOOL) isEqualToIndexSet:(NSIndexSet *) indexSet;
- (NSUInteger) lastIndex;

@end


@interface NSMutableIndexSet : NSIndexSet
{
	unsigned	_capacity;	// how much ranges are malloc'd/realloc'd
}

- (void) addIndex:(NSUInteger) value;
- (void) addIndexes:(NSIndexSet *) indexSet;
- (void) addIndexesInRange:(NSRange) range;
- (void) removeAllIndexes;
- (void) removeIndex:(NSUInteger) value;
- (void) removeIndexes:(NSIndexSet *) indexSet;
- (void) removeIndexesInRange:(NSRange) range;
- (void) shiftIndexesStartingAtIndex:(NSUInteger) index by:(NSInteger) delta;

@end

#endif // mySTEP_NSIndexSet_H
