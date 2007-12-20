/*
	NSToolbarItem.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	20. December 2007 - aligned with 10.5  

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSToolbarItem
#define _mySTEP_H_NSToolbarItem

#import "AppKit/NSMenuItem.h"

enum {
	NSToolbarItemVisibilityPriorityStandard = 0,
	NSToolbarItemVisibilityPriorityLow  = -1000,
	NSToolbarItemVisibilityPriorityHigh  = 1000,
	NSToolbarItemVisibilityPriorityUser  = 2000
};

@interface NSToolbarItem : NSMenuItem
{
}

- (SEL) action; 
- (BOOL) allowsDuplicatesInToolbar; 
- (BOOL) autovalidates; 
- (NSImage *) image; 
- (id) initWithItemIdentifier:(NSString *) itemId; 
- (BOOL) isEnabled; 
- (NSString *) itemIdentifier; 
- (NSString *) label; 
- (NSSize) maxSize; 
- (NSMenuItem *) menuFormRepresentation; 
- (NSSize) minSize; 
- (NSString *) paletteLabel; 
- (void) setAction:(SEL) sel; 
- (void) setAutovalidates:(BOOL) flag; 
- (void) setEnabled:(BOOL) flag; 
- (void) setImage:(NSImage *) img; 
- (void) setLabel:(NSString *) str; 
- (void) setMaxSize:(NSSize) size; 
- (void) setMenuFormRepresentation:(NSMenuItem *) item; 
- (void) setMinSize:(NSSize) size; 
- (void) setPaletteLabel:(NSString *) label; 
- (void) setTag:(NSInteger) tag; 
- (void) setTarget:(id) target; 
- (void) setToolTip:(NSString *) toolTip; 
- (void) setView:(NSView *) view; 
- (void) setVisibilityPriority:(NSInteger) priority; 
- (NSInteger) tag; 
- (id) target; 
- (NSToolbar *) toolbar; 
- (NSString *) toolTip; 
- (void) validate; 
- (NSView *) view; 
- (NSInteger) visibilityPriority; 

@end

extern NSString *NSToolbarSeparatorItemIdentifier;
extern NSString *NSToolbarSpaceItemIdentifier;
extern NSString *NSToolbarFlexibleSpaceItemIdentifier;
extern NSString *NSToolbarShowColorsItemIdentifier;
extern NSString *NSToolbarShowFontsItemIdentifier;
extern NSString *NSToolbarCustomizeToolbarItemIdentifier;
extern NSString *NSToolbarPrintItemIdentifier;

@interface NSObject (NSToolbarItemValidation)

- (BOOL) validateToolbarItem:(NSToolbarItem *) item;

@end

#endif /* _mySTEP_H_NSToolbarItem */
