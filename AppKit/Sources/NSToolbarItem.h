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

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSString; 
@class NSMenuItem; 
@class NSToolbar; 
@class NSImage; 
@class NSView; 

enum {
	NSToolbarItemVisibilityPriorityStandard = 0,
	NSToolbarItemVisibilityPriorityLow  = -1000,
	NSToolbarItemVisibilityPriorityHigh  = 1000,
	NSToolbarItemVisibilityPriorityUser  = 2000
};

@interface NSToolbarItem : NSObject
{
	NSString *_itemIdentifier;
	NSString *_label;
	NSString *_paletteLabel;
	NSImage *_image;
	NSMenuItem *_menuFormRepresentation;
	NSString *_toolTip;
	NSToolbar *_toolbar;
	NSView *_view;
	NSSize _maxSize;
	NSSize _minSize;
	NSInteger _tag;
	NSInteger _visibilityPriority;
	id _target;
	SEL _action;
	BOOL _autovalidates;;
	BOOL _allowsDuplicatesInToolbar;	
	BOOL _isEnabled;
	BOOL _selectable;
	BOOL _builtin;
	BOOL _canKeepVisible;
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


@interface NSObject (NSToolbarItemValidation)

- (BOOL) validateToolbarItem:(NSToolbarItem *) item;

@end

extern NSString *NSToolbarSeparatorItemIdentifier;
extern NSString *NSToolbarSpaceItemIdentifier;
extern NSString *NSToolbarFlexibleSpaceItemIdentifier;
extern NSString *NSToolbarShowColorsItemIdentifier;
extern NSString *NSToolbarShowFontsItemIdentifier;
extern NSString *NSToolbarCustomizeToolbarItemIdentifier;
extern NSString *NSToolbarPrintItemIdentifier;

#endif /* _mySTEP_H_NSToolbarItem */
