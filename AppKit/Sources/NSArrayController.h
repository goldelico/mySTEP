//
//  NSArrayController.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSArrayController
#define _mySTEP_H_NSArrayController

#import "AppKit/NSObjectController.h"

@class NSString;
@class NSCoder;
@class NSArray;
@class NSIndexSet;

@interface NSArrayController : NSObjectController <NSCoding>
{
	NSArray *_sortDescriptors;
	NSIndexSet *_selectionIndexes;
	BOOL _avoidsEmptySelection;
	BOOL _preservesSelection;
}

- (void) addObject:(id) obj;
- (void) addObjects:(NSArray *) obj;
- (BOOL) addSelectedObjects:(NSArray *) obj;
- (BOOL) addSelectionIndexes:(NSIndexSet *) idx;
- (NSArray *) arrangeObjects:(NSArray *) obj;
- (id) arrangedObjects;
- (BOOL) avoidsEmptySelection;
- (BOOL) canInsert;
- (BOOL) canSelectNext;
- (BOOL) canSelectPrevious;
- (void) insert:(id) Sender;
- (void) insertObject:(id) obj atArrangedObjectIndex:(unsigned int) idx;
- (void) insertObjects:(NSArray *) obj atArrangedObjectIndexes:(NSIndexSet *) idx;
- (BOOL) preservesSelection;
- (void) rearrangeObjects;
- (void) remove:(id) Sender;
- (void) removeObject:(id) obj;
- (void) removeObjectAtArrangedObjectIndex:(unsigned int) idx;
- (void) removeObjects:(NSArray *) obj;
- (void) removeObjectsAtArrangedObjectIndexes:(NSIndexSet *) idx;
- (BOOL) removeSelectedObjects:(NSArray *) obj;
- (BOOL) removeSelectionIndexes:(NSIndexSet *) idx;
- (void) selectNext:(id) Sender;
- (void) selectPrevious:(id) Sender;
- (NSArray *) selectedObjects;
- (unsigned int) selectionIndex;
- (NSIndexSet *) selectionIndexes;
- (BOOL) selectsInsertedObjects;
- (void) setAvoidsEmptySelection:(BOOL) flag;
- (void) setPreservesSelection:(BOOL) flag;
- (BOOL) setSelectedObjects:(NSArray *) obj;
- (BOOL) setSelectionIndex:(unsigned int) idx;
- (BOOL) setSelectionIndexes:(NSIndexSet *) idx;
- (void) setSelectsInsertedObjects:(BOOL) flag;
- (void) setSortDescriptors:(NSArray *) desc;
- (NSArray *) sortDescriptors;
@end

#endif /* _mySTEP_H_NSArrayController */
