//
//  NSCollectionViewItem.h
//  AppKit
//
//  Created by Fabian Spillner on 06.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSCollectionView; 

@interface NSCollectionViewItem : NSObject <NSCoding, NSCopying> 
{

}

- (NSCollectionView *) collectionView; 
- (BOOL) isSelected; 
- (id) representedObject; 
- (void) setRepresentedObject:(id) obj; 
- (void) setSelected:(BOOL) flag; 
- (void) setView:(NSView *) view; 
- (NSView *) view; 

@end
