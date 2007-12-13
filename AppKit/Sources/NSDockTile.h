//
//  NSDockTile.h
//  AppKit
//
//  Created by Fabian Spillner on 07.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSView;

@interface NSDockTile : NSObject {

}

- (NSString *) badgeLabel; 
- (NSView *) contentView; 
- (void) display; 
- (id) owner; 
- (void) setBadgeLabel:(NSString *) label; 
- (void) setContentView:(NSView *) view; 
- (void) setShowsApplicationBadge:(BOOL) flag; 
- (BOOL) showsApplicationBadge; 
- (NSSize) size; 


@end
