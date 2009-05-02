//
//  NSCollectionViewItem.m
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSCollectionViewItem.h"


@implementation NSCollectionViewItem
- (id) init
{
	self = [super init];
	if (self != nil) {
		_selected = NO;
		
	}
	return self;
}


- (NSCollectionView *) collectionView {
	return _collectionView;
}

- (BOOL) isSelected {
	return _selected;
}
- (id) representedObject{
	return _representedObject;
}
- (void) setRepresentedObject:(id) obj {
	ASSIGN(_representedObject,obj);
}
- (void) setSelected:(BOOL) flag {
	_selected = flag;
}
- (void) setView:(NSView *) view {
	ASSIGN(_view,view);
}
- (NSView *) view {
	return _view;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	
}
- (id) copyWithZone:(NSZone *) zone
{
	NSCollectionViewItem *c = [isa allocWithZone:zone];	// makes a real copy
	
	c->_view = _view;
	c->_representedObject = [_representedObject retain];
	c->_collectionView = _collectionView;
	
	return c;
}
@end
