/*
	NSToolbar.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	20. December 2007 - aligned with 10.5 

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSToolbar
#define _mySTEP_H_NSToolbar

#import "AppKit/NSView.h"

@class NSString;
@class NSToolbarItem; 

typedef enum {
	NSToolbarDisplayModeDefault,
	NSToolbarDisplayModeIconAndLabel,
	NSToolbarDisplayModeIconOnly,
	NSToolbarDisplayModeLabelOnly,
} NSToolbarDisplayMode;

typedef enum {
	NSToolbarSizeModeDefault,
	NSToolbarSizeModeRegular,
	NSToolbarSizeModeSmall
} NSToolbarSizeMode;

@class NSToolbarView;
@class NSPanel;

@interface NSToolbar : NSView
{
	NSString *_identifier; 
	NSMutableArray *_items;									// all items we have defined
	NSMutableArray *_visibleItems;					// thereof visible
	NSString *_selectedItemIdentifier;
	NSPanel *_customizationPalette;
	NSToolbarView *_toolbarView;
	id _delegate; 
	NSToolbarDisplayMode _displayMode; 
	NSToolbarSizeMode _sizeMode; 
	BOOL _allowsUserCustomization; 
	BOOL _autosavesConfiguration; 
	BOOL _customizationPaletteIsRunning; 
	BOOL _isVisible; 
	BOOL _showsBaselineSeparator; 
}

- (BOOL) allowsUserCustomization; 
- (BOOL) autosavesConfiguration; 
- (NSDictionary *) configurationDictionary; 
- (BOOL) customizationPaletteIsRunning; 
- (id) delegate; 
- (NSToolbarDisplayMode) displayMode; 
- (NSString *) identifier; 
- (id) initWithIdentifier:(NSString *) str; 
- (void) insertItemWithItemIdentifier:(NSString *) itemId atIndex:(NSInteger) idx; 
- (BOOL) isVisible; 
- (NSArray *) items; 
- (void) removeItemAtIndex:(NSInteger) idx; 
- (void) runCustomizationPalette:(id) sender; 
- (NSString *) selectedItemIdentifier; 
- (void) setAllowsUserCustomization:(BOOL) flag; 
- (void) setAutosavesConfiguration:(BOOL) autosaveConfig; 
- (void) setConfigurationFromDictionary:(NSDictionary *) dict; 
- (void) setDelegate:(id) delegate; 
- (void) setDisplayMode:(NSToolbarDisplayMode) mode; 
- (void) setSelectedItemIdentifier:(NSString *) itemId; 
- (void) setShowsBaselineSeparator:(BOOL) flag; 
- (void) setSizeMode:(NSToolbarSizeMode) mode; 
- (void) setVisible:(BOOL) flag; 
- (BOOL) showsBaselineSeparator; 
- (NSToolbarSizeMode) sizeMode; 
- (void) validateVisibleItems; 
- (NSArray *) visibleItems; 

@end


@interface NSObject (NSToolbarDelegate)

- (NSToolbarItem *) toolbar:(NSToolbar *) toolbar itemForItemIdentifier:(NSString *) itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag; 
- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar; 
- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *) toolbar; 
- (void) toolbarDidRemoveItem:(NSNotification *) notification; 
- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *) toolbar; 
- (void) toolbarWillAddItem:(NSNotification *) notification; 

@end

extern NSString * NSToolbarDidRemoveItemNotification; 
extern NSString * NSToolbarWillAddItemNotification; 


#endif /* _mySTEP_H_NSNSToolbar */
