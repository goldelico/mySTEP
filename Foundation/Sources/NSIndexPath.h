//
//  NSIndexPath.h
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

#ifndef mySTEP_NSIndexPath_H
#define mySTEP_NSIndexPath_H

#import "Foundation/Foundation.h"

@interface NSIndexPath : NSObject <NSCopying, NSCoding>
{
	NSIndexPath *_parent;			// parent object (not retained)
	// FIXME: should be a NSMapTable where children are stored with their index value
	NSMutableArray *_children;		// children
	unsigned _length;				// our depth level
	unsigned _index;				// our value
}

+ (NSIndexPath *) indexPathWithIndex:(unsigned) idx;
+ (NSIndexPath *) indexPathWithIndexes:(unsigned *) idx
								length:(unsigned) len;
- (NSComparisonResult) compare:(NSIndexPath *) obj;
- (void) getIndexes:(unsigned *) idx;
- (unsigned) indexAtPosition:(unsigned) pos;
- (NSIndexPath *) indexPathByAddingIndex:(unsigned) idx;
- (NSIndexPath *) indexPathByRemovingLastIndex;
- (id) initWithIndex:(unsigned) index;
- (id) initWithIndexes:(unsigned *) idx length:(unsigned) len;
- (unsigned) length;

@end

#endif mySTEP_NSIndexPath_H
