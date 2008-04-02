//
//  NSToolbarItemGroup.h
//  AppKit
//
//  Created by Fabian Spillner on 20.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSToolbarItem.h>

@class NSArray; 

@interface NSToolbarItemGroup : NSToolbarItem {

}

- (void) setSubitems:(NSArray *) items; 
- (NSArray *) subitems; 

@end
