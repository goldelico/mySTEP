//
//  NSCollectionView.m
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSCollectionView.h"
#import "NSCollectionViewItem.h"


@implementation NSCollectionView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    
}

- (BOOL) allowsMultipleSelection {return _allowsMultipleSelection;} 
- (NSArray *) backgroundColors {return _backgroundColors;} 
- (NSArray *) content {return _content;} 
- (BOOL) isFirstResponder {return _firstResponder;} 
- (BOOL) isSelectable {
	return _selectable;
}
- (NSCollectionViewItem *) itemPrototype{
	return _itemPrototype;
}
- (NSSize) maxItemSize {
	return _maxItemSize;
}
- (NSUInteger) maxNumberOfColumns{
	return _maxNumberOfColumns;
}
- (NSUInteger) maxNumberOfRows{
	return _maxNumberOfRows;
}
- (NSSize) minItemSize{
	return _minItemSize;
}
- (NSCollectionViewItem *) newItemForRepresentedObject:(id) obj{
	NSCollectionViewItem *item = [_itemPrototype copy];
	[item setRepresentedObject:obj];
	return item;
}
- (NSIndexSet *) selectionIndexes {
	return _selectionIndexes;
}
- (void) setAllowsMultipleSelection:(BOOL) flag {
	_allowsMultipleSelection = flag;
}
- (void) setBackgroundColors:(NSArray *) bgColors{
	if(bgColors) {
		ASSIGN(_backgroundColors,bgColors);
	}
}
- (void) setContent:(NSArray *) newContent{
	ASSIGN(_content, newContent);
}
- (void) setItemPrototype:(NSCollectionViewItem *) itemPrototype{
	ASSIGN(_itemPrototype,itemPrototype);
}
- (void) setMaxItemSize:(NSSize) size{
	_maxItemSize = size;
}
- (void) setMaxNumberOfColumns:(NSUInteger) num{
	_maxNumberOfColumns = num;
}
- (void) setMaxNumberOfRows:(NSUInteger) num{
	_maxNumberOfRows = num;
}
- (void) setMinItemSize:(NSSize) size{
	_minItemSize = size;
}
- (void) setSelectable:(BOOL) flag{
	_selectable = flag;
}
- (void) setSelectionIndexes:(NSIndexSet *) ids{
	ASSIGN(_selectionIndexes, ids);
}
- (id) initWithCoder:(NSCoder *) coder;
{
	if ((self=[super initWithCoder:coder]))
	{
		
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	
}

@end
