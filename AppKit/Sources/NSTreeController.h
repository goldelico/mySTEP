/*
	NSTreeController.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Mon Nov 21 2005.
	Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. December 2007 - aligned with 10.5 

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTreeController
#define _mySTEP_H_NSTreeController

#import "AppKit/NSObjectController.h"

@class NSString;
@class NSCoder;
@class NSArray;
@class NSIndexSet;
@class NSIndexPath;
@class NSTreeNode; 

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

- (void) add:(id) sender;
- (void) addChild:(id) sender;
- (BOOL) addSelectionIndexPaths:(NSArray *) paths;
- (BOOL) alwaysUsesMultipleValuesMarker;
- (id) arrangedObjects;
- (BOOL) avoidsEmptySelection;
- (BOOL) canAddChild;
- (BOOL) canInsert;
- (BOOL) canInsertChild;
- (NSString *) childrenKeyPath;
- (NSString *) childrenKeyPathForNode:(NSTreeNode *) treeNode; 
- (id) content; 
- (NSString *) countKeyPath;
- (NSString *) countKeyPathForNode:(NSTreeNode *)treeNode; 
- (void) insert:(id) sender;
- (void) insertChild:(id) sender;
- (void) insertObject:(id) obj atArrangedObjectIndexPath:(NSIndexPath *) idx;
- (void) insertObjects:(NSArray *) obj atArrangedObjectIndexPaths:(NSArray *) idx;
- (NSString *) leafKeyPath;
- (NSString *) leafKeyPathForNode:(NSTreeNode *) treeNode; 
- (void) moveNode:(NSTreeNode *) treeNode toIndexPath:(NSIndexPath *) path; 
- (void) moveNodes:(NSArray *) treeNodes toIndexPath:(NSIndexPath *) path;
- (BOOL) preservesSelection;
- (void) rearrangeObjects;
- (void) remove:(id) sender;
- (void) removeObject:(id) obj; /* NOT IN API */
- (void) removeObjectAtArrangedObjectIndexPath:(NSIndexPath *) idx;
- (void) removeObjectsAtArrangedObjectIndexPaths:(NSArray *) idx;
- (BOOL) removeSelectionIndexPaths:(NSArray *) obj;
- (NSArray *) selectedNodes; 
- (NSArray *) selectedObjects;
- (NSIndexPath *) selectionIndexPath;
- (NSIndexPath *) selectionIndexPaths;
- (BOOL) selectsInsertedObjects;
- (void) setAlwaysUsesMultipleValuesMarker:(BOOL) flag;
- (void) setAvoidsEmptySelection:(BOOL) flag;
- (void) setChildrenKeyPath:(NSString *) key;
- (void) setContent:(id) obj;
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
