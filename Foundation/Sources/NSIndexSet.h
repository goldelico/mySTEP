//
//  NSIndexSet.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Nov 22 2005.
//  Copyright (c) 2005 DSITRI.
//
//  H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

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
+ (id) indexSetWithIndex:(unsigned int) value;
+ (id) indexSetWithIndexesInRange:(NSRange) range;

- (BOOL) containsIndex:(unsigned int) value;
- (BOOL) containsIndexes:(NSIndexSet *) indexSet;
- (BOOL) containsIndexesInRange:(NSRange) range;
- (unsigned int) count;
- (unsigned int) firstIndex;
- (unsigned int) getIndexes:(unsigned int *) indexBuffer
				   maxCount:(unsigned int) bufferSize
			   inIndexRange:(NSRangePointer) range;
- (unsigned int) indexGreaterThanIndex:(unsigned int) value;
- (unsigned int) indexGreaterThanOrEqualToIndex:(unsigned int) value;
- (unsigned int) indexLessThanIndex:(unsigned int) value;
- (unsigned int) indexLessThanOrEqualToIndex:(unsigned int) value;
- (id) init;
- (id) initWithIndex:(unsigned int) value;
- (id) initWithIndexesInRange:(NSRange) range;
- (id) initWithIndexSet:(NSIndexSet *) indexSet;
- (BOOL) intersectsIndexesInRange:(NSRange) range;
- (BOOL) isEqualToIndexSet:(NSIndexSet *) indexSet;
- (unsigned int) lastIndex;

@end


@interface NSMutableIndexSet : NSIndexSet
{
	unsigned	_capacity;	// how much ranges are malloc'd/realloc'd
}

- (void) addIndex:(unsigned int) value;
- (void) addIndexes:(NSIndexSet *) indexSet;
- (void) addIndexesInRange:(NSRange) range;
- (void) removeAllIndexes;
- (void) removeIndex:(unsigned int) value;
- (void) removeIndexes:(NSIndexSet *) indexSet;
- (void) removeIndexesInRange:(NSRange) range;
- (void) shiftIndexesStartingAtIndex:(unsigned int) index by:(int) delta;

@end

#endif mySTEP_NSIndexSet_H
