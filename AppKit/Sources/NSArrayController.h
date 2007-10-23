/*
  NSArrayController.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
  Copyright (c) 2005 DSITRI.

  Author: Fabian Spillner
  Date:	16. October 2007 
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

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
- (BOOL) alwaysUsesMultipleValuesMarker; 
- (id) arrangedObjects;
- (NSArray *) arrangeObjects:(NSArray *) obj;
- (BOOL) automaticallyPreparesContent; 
- (BOOL) avoidsEmptySelection;
- (BOOL) canInsert;
- (BOOL) canSelectNext;
- (BOOL) canSelectPrevious;
- (BOOL) clearsFilterPredicateOnInsertion; 
- (NSPredicate *) filterPredicate; 
- (void) insert:(id) sender;
- (void) insertObject:(id) obj atArrangedObjectIndex:(unsigned int) idx;
- (void) insertObjects:(NSArray *) obj atArrangedObjectIndexes:(NSIndexSet *) idx;
- (BOOL) preservesSelection;
- (void) rearrangeObjects;
- (void) remove:(id) sender;
- (void) removeObject:(id) obj;
- (void) removeObjectAtArrangedObjectIndex:(unsigned int) idx;
- (void) removeObjects:(NSArray *) obj;
- (void) removeObjectsAtArrangedObjectIndexes:(NSIndexSet *) idx;
- (BOOL) removeSelectedObjects:(NSArray *) obj;
- (BOOL) removeSelectionIndexes:(NSIndexSet *) idx;
- (NSArray *) selectedObjects;
- (unsigned int) selectionIndex;
- (NSIndexSet *) selectionIndexes;
- (void) selectNext:(id) sender;
- (void) selectPrevious:(id) sender;
- (BOOL) selectsInsertedObjects;
- (void) setAlwaysUsesMultipleValuesMarker:(BOOL) flag;
- (void) setAutomaticallyPreparesContent:(BOOL) flag; 
- (void) setAvoidsEmptySelection:(BOOL) flag;
- (void) setClearsFilterPredicateOnInsertion:(BOOL) flag; 
- (void) setFilterPredicate:(NSPredicate *) filter; 
- (void) setPreservesSelection:(BOOL) flag;
- (BOOL) setSelectedObjects:(NSArray *) obj;
- (BOOL) setSelectionIndex:(unsigned int) idx;
- (BOOL) setSelectionIndexes:(NSIndexSet *) idx;
- (void) setSelectsInsertedObjects:(BOOL) flag;
- (void) setSortDescriptors:(NSArray *) desc;
- (NSArray *) sortDescriptors;
@end

#endif /* _mySTEP_H_NSArrayController */
