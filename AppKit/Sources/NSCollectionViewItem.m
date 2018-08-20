//
//  NSCollectionViewItem.m
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSCollectionViewItem.h"
#import "NSAppKitPrivate.h"


@implementation NSCollectionViewItem

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self setSelected:NO];
		_collectionView = nil;
		_representedObject = nil;
		_view = [[NSView alloc] init];
		
	}
	return self;
}

- (NSCollectionView *) collectionView {
	return _collectionView;
}

- (void) _setCollectionView:(NSCollectionView *)newView {
	ASSIGN(_collectionView,newView);
}



- (BOOL) isSelected {
	return _isSelected;
}
- (id) representedObject{
	return _representedObject;
}
- (void) setRepresentedObject:(id) obj {
	ASSIGN(_representedObject,obj);
}
- (void) setSelected:(BOOL) flag {
	_isSelected = flag;
}
- (void) toggleSelected:(BOOL) flag {
	if (_isSelected == NO) {
		_isSelected = YES;
	} else {
		_isSelected = NO;
	}
}

- (void) setView:(NSView *) view {
	ASSIGN(_view,view);
}
- (NSView *) view {
	return _view;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if ((self=[super initWithCoder:coder]))
	{
		[self setView:[coder decodeObjectForKey:@"view"]];
		[self setRepresentedObject:[coder decodeObjectForKey:@"representedObject"]];
		[self setSelected:[coder decodeBoolForKey:@"selected"]];
	}
	return self;
}



- (void) encodeWithCoder:(NSCoder *) coder
{
	[coder encodeObject:_view forKey:@"view"];
	[coder encodeObject:_representedObject forKey:@"representedObject"];
	[coder encodeBool:_isSelected forKey:@"selected"];
	
}
- (id) copyWithZone:(NSZone *) zone
{
	NSCollectionViewItem *c = [[self class] allocWithZone:zone];	// makes a real copy
	
	c->_view = _view;
	c->_representedObject = [_representedObject retain];
	c->_collectionView = _collectionView;
	
	return c;
}
@end
