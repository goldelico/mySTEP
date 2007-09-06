//
//  NSTreeController.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Nov 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSTreeController
#define _mySTEP_H_NSTreeController

#import "AppKit/NSObjectController.h"

@class NSString;
@class NSCoder;
@class NSArray;
@class NSIndexSet;
@class NSIndexPath;

@interface NSTreeController : NSObjectController <NSCoding>
{
	NSString *_childrenKeyPath;
	NSString *_countKeyPath;
	NSString *_leafKeyPath;
	NSArray *_sortDescriptors;
	BOOL _alwaysUsesMultipleValuesMarker;
	BOOL _avoidsEmptySelection;
	BOOL _preservesSelection;
}

- (void) add:(id) Sender;
- (void) addChild:(id) Sender;
- (BOOL) addSelectionIndexPaths:(NSArray *) paths;
- (BOOL) alwaysUsesMultipleValuesMarker;
- (id) arrangedObjects;
- (BOOL) avoidsEmptySelection;
- (BOOL) canAddChild;
- (BOOL) canInsert;
- (BOOL) canInsertChild;
- (NSString *) childrenKeyPath;
- (NSString *) countKeyPath;
- (void) insert:(id) Sender;
- (void) insertChild:(id) Sender;
- (void) insertObject:(id) obj atArrangedObjectIndexPath:(NSIndexPath *) idx;
- (void) insertObjects:(NSArray *) obj atArrangedObjectIndexPaths:(NSArray *) idx;
- (NSString *) leafKeyPath;
- (BOOL) preservesSelection;
- (void) rearrangeObjects;
- (void) remove:(id) Sender;
- (void) removeObject:(id) obj;
- (void) removeObjectAtArrangedObjectIndexPath:(NSIndexPath *) idx;
- (void) removeObjectsAtArrangedObjectIndexPaths:(NSArray *) idx;
- (BOOL) removeSelectionIndexPaths:(NSArray *) obj;
- (NSArray *) selectedObjects;
- (NSIndexPath *) selectionIndexPath;
- (NSIndexPath *) selectionIndexPaths;
- (BOOL) selectsInsertedObjects;
- (void) setAlwaysUsesMultipleValuesMarker:(BOOL) flag;
- (void) setAvoidsEmptySelection:(BOOL) flag;
- (void) setChildrenKeyPath:(NSString *) key;
- (void) setCountKeyPath:(NSString *) key;
- (void) setLeafKeyPath:(NSString *) key;
- (void) setPreservesSelection:(BOOL) flag;
- (BOOL) setSelectionIndexPath:(NSIndexPath *) path;
- (BOOL) setSelectionIndexPaths:(NSArray *) paths;
- (void) setSelectsInsertedObjects:(BOOL) flag;
- (void) setSortDescriptors:(NSArray *) desc;
- (NSArray *) sortDescriptors;
@end

#endif /* _mySTEP_H_NSArrayController */
