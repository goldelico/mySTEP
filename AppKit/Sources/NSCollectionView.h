//
//  NSCollectionView.h
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <AppKit/NSView.h>

@class NSCollectionViewItem; 

@interface NSCollectionView : NSView <NSCoding> {

}

- (BOOL) allowsMultipleSelection; 
- (NSArray *) backgroundColors; 
- (NSArray *) content; 
- (BOOL) isFirstResponder; 
- (BOOL) isSelectable; 
- (NSCollectionViewItem *) itemPrototype; 
- (NSSize) maxItemSize; 
- (NSUInteger) maxNumberOfColumns; 
- (NSUInteger) maxNumberOfRows; 
- (NSSize) minItemSize; 
- (NSCollectionViewItem *) newItemForRepresentedObject:(id) obj; 
- (NSIndexSet *) selectionIndexes; 
- (void) setAllowsMultipleSelection:(BOOL) flag; 
- (void) setBackgroundColors:(NSArray *) bgColors; 
- (void) setContent:(NSArray *) newContent; 
- (void) setItemPrototype:(NSCollectionViewItem *) itemPrototype; 
- (void) setMaxItemSize:(NSSize) size; 
- (void) setMaxNumberOfColumns:(NSUInteger) num; 
- (void) setMaxNumberOfRows:(NSUInteger) num; 
- (void) setMinItemSize:(NSSize) size; 
- (void) setSelectable:(BOOL) flag; 
- (void) setSelectionIndexes:(NSIndexSet *) ids; 

@end
