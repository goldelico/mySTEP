/* 
   NSPopUpButtonCell.h

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: H. Nikolaus Schaller <hns@computer.org>
   Date:   May 2004
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPopUpButtonCell
#define _mySTEP_H_NSPopUpButtonCell

#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSMenu.h>

typedef enum
{
	NSPopUpArrowAtBottom,
	NSPopUpNoArrow,
	NSPopUpArrowAtCenter
} NSPopUpArrowPosition;

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSFont;
@class NSPopUpButton;

extern NSString *NSPopUpButtonCellWillPopUpNotification;

@interface NSPopUpButtonCell : NSMenuItemCell
{
	NSPanel *_menuWindow;
	int _selectedItem;
	NSPopUpArrowPosition _arrowPosition;
	NSRectEdge _preferredEdge;
	BOOL _altersStateOfSelectedItem;
	BOOL _autoenablesItems;
	BOOL _usesItemFromMenu;
	BOOL _pullsDown;
}

//- (id) initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag;
- (id) initTextCell:(NSString *)value pullsDown:(BOOL)flag;

- (void) addItemWithTitle:(NSString *)title;			// Adding Items
- (void) addItemsWithTitles:(NSArray *)itemTitles;
- (void) insertItemWithTitle:(NSString *)title atIndex:(unsigned int)index;

- (void) removeAllItems;								// Removing Items
- (void) removeItemWithTitle:(NSString *)title;
- (void) removeItemAtIndex:(int)index;

- (int) indexOfItemWithTitle:(NSString *)title;			// Access Items
- (int) indexOfItemWithTag:(int)tag;
- (int) indexOfItemWithRepresentedObject:(id)obj;
- (int) indexOfItemWithTarget:(id)target andAction:(SEL)action;
- (int) indexOfSelectedItem;
- (id <NSCopying>) objectValue;	// NSNumber with indexOfSelectedItem
//- (void) setMenu:(NSMenu *) menu;
//- (NSMenu *) menu;
- (int) numberOfItems;
- (NSArray *) itemArray;
- (NSString *) itemTitleAtIndex:(int)index;
- (NSArray *) itemTitles;
- (NSMenuItem *) itemAtIndex:(int)index;
- (NSMenuItem *) itemWithTitle:(NSString *)title;
- (NSMenuItem *) lastItem;
- (NSMenuItem *) selectedItem;
- (NSString*) titleOfSelectedItem;

// - (NSFont *) font;		// Graphic Attributes
- (NSPopUpArrowPosition) arrowPosition;
- (NSRectEdge) preferredEdge;
- (BOOL) pullsDown;
- (BOOL) usesItemFromMenu;
- (void) selectItem:(NSMenuItem *) item;
- (void) selectItemAtIndex:(int)index;
- (void) selectItemWithTitle:(NSString *)title;
- (void) setObjectValue:(id <NSCopying>) obj;	// selectItemAtIndex:[obj intValue]
- (void) setArrowPosition:(NSPopUpArrowPosition) position;
// - (void) setFont:(NSFont *)fontObject;
- (void) setPreferredEdge:(NSRectEdge) edge;
- (void) setPullsDown:(BOOL)flag;
- (void) setUsesItemFromMenu:(BOOL)flag;
- (void) setTitle:(NSString *)aString;
- (void) synchronizeTitleAndSelectedItem;

// - (NSString *) stringValue;	// ???
- (void) setImage:(NSImage *) image;	// has no effect

- (BOOL) autoenablesItems;								// Display management
- (void) setAutoenablesItems:(BOOL)flag;
- (BOOL) altersStateOfSelectedItem;
- (void) setAltersStateOfSelectedItem:(BOOL)flag;

- (void) attachPopUpWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
- (void) dismissPopUp;
- (void) performClickWithFrame:(NSRect)frame inView:(NSView *) controlView;

@end

#endif /* _mySTEP_H_NSPopUpButtonCell */
