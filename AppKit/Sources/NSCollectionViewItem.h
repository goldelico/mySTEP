//
//  NSCollectionViewItem.h
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSView.h>

@class NSCollectionView;

@interface NSCollectionViewItem : NSObject <NSCoding, NSCopying>
{
	NSCollectionView *_collectionView;
	id _representedObject;
	NSView *_view;
	BOOL _isSelected;
}

- (NSCollectionView *) collectionView;
- (BOOL) isSelected;
- (id) representedObject;
- (void) setRepresentedObject:(id) obj;
- (void) setSelected:(BOOL) flag;
- (void) toggleSelected:(BOOL) flag;
- (void) setView:(NSView *) view;
- (NSView *) view;

@end
