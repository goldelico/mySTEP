//
//  NSCollectionView.m
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSCollectionView.h"
#import "NSCollectionViewItem.h"
#import "NSAppKitPrivate.h"


@implementation NSCollectionView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		if(!_itemPrototype) { //makeup one itemPrototype
			NSCollectionViewItem *item = [[NSCollectionViewItem alloc] init];
			[item setView:[[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease]];
			[self setItemPrototype:item];
		}
    }
    return self;
}

- (void) drawRect:(NSRect) rect {
	//Layout für die ViewItems
	[self _computeGridGeometry];
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
	[item _setCollectionView:self];
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
- (void)_computeTargetGridGeometry{
	//wie viele Zeilen und Spalten haben wir?
	NSView *protoView = [_itemPrototype view];
	NSRect protoRect = [protoView bounds];
	NSSize protoSize = protoRect.size;
	NSSize cvSize = [self frame].size;
	if (_maxNumberOfRows == 0) { //berechne maximale Zeilennummer aus den vorhandenen Items
		int numberOfRows =  cvSize.height /  protoSize.height;
		NSLog(@"Number of Rows: %d",numberOfRows);
	}
	if(_maxNumberOfColumns==0) { //das gleiche mit den Spalten...
		int numberofColums =  cvSize.width / protoSize.width;
		NSLog(@"Number of Columns: %d", numberofColums);
		
	} else {
		
	}
}
- (id) initWithCoder:(NSCoder *) coder;
{
	if ((self=[super initWithCoder:coder]))
	{
		[self setBackgroundColors:[coder decodeObjectForKey:@"backgroundColors"]];
		[self setItemPrototype:[coder decodeObjectForKey:@"itemPrototype"]];
		[self setSelectionIndexes:[coder decodeObjectForKey:@"selectionIndexes"]];
		[self setContent:[coder decodeObjectForKey:@"content"]];
		[self setAllowsMultipleSelection:[coder decodeBoolForKey:@"allowsMultipleSelection"]];
		[self setMaxItemSize:[coder decodeSizeForKey:@"maxItemSize"]];
		[self setMaxNumberOfColumns:[coder decodeIntForKey:@"maxNumberOfColumns"]];
		[self setMaxNumberOfRows:[coder decodeIntForKey:@"maxNumberOfRows"]];
		[self setMinItemSize:[coder decodeSizeForKey:@"minItemSize"]];
		[self setSelectable:[coder decodeBoolForKey:@"selectable"]];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	[coder encodeObject:_backgroundColors forKey:@"backgroundColors"];
	[coder encodeObject:_itemPrototype forKey:@"itemPrototype"];
	[coder encodeObject:_selectionIndexes forKey:@"selectionIndexes"];
	[coder encodeObject:_content forKey:@"content"];
	[coder encodeBool:_allowsMultipleSelection forKey:@"allowedMultipleSelection"];
	[coder encodeSize:_maxItemSize forKey:@"maxItemSize"];
	[coder encodeInteger:_maxNumberOfColumns forKey:@"maxNumberOfColumns"];
	[coder encodeInteger:_maxNumberOfRows forKey:@"maxNumberOfRows"];
	[coder encodeSize:_minItemSize forKey:@"minItemSize"];
	[coder encodeBool:_selectable forKey:@"selectable"];
	[super encodeWithCoder:coder];
}

@end
