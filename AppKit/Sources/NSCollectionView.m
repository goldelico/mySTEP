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
	
	// hier sollte gar nichts gemalt werden
	
	// das Grid wird vermutlich in setContent: berechnet
	// alle Items sind Subviews und malen sich selbst
	// CollectionView steuert vermutlich nur das Layout und malt selber gar nichts
	
    int i;
	int j; //counter for the viewItems
	int k;
	for (i=0;i<_maxNumberOfRows;i++) {
		for (j=0;j<_maxNumberOfColumns;j++) {
			//draw j column
			k = i * _maxNumberOfColumns + j;
			NSCollectionViewItem *aktItem = [_content objectAtIndex:k];
			NSView *v = [aktItem view];
			NSRect m = [v frame];
			//draw view
			NSRect newOrigin = NSMakeRect((j*m.size.width)+5, (i*m.size.height)+5, m.size.width, m.size.height);
			// das hier ist nicht sinnvoll!
			// [v setBounds:newOrigin];
			// [self addSubview:v];
		}
	}
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
	[item performSelector:@selector(_setCollectionView:) withObject:self];
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
	[coder encodeInt:_maxNumberOfColumns forKey:@"maxNumberOfColumns"];
	[coder encodeInt:_maxNumberOfRows forKey:@"maxNumberOfRows"];
	[coder encodeSize:_minItemSize forKey:@"minItemSize"];
	[coder encodeBool:_selectable forKey:@"selectable"];
	[super encodeWithCoder:coder];
}

@end
