/* 
   NSPopUpButtonCell.h

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: H. Nikolaus Schaller <hns@computer.org>
   Date:   May 2004
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	29. November 2007 - aligned with 10.5 
   
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

- (void) addItemsWithTitles:(NSArray *) itemTitles;
- (void) addItemWithTitle:(NSString *) title;
- (BOOL) altersStateOfSelectedItem;
- (NSPopUpArrowPosition) arrowPosition;
- (void) attachPopUpWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
- (BOOL) autoenablesItems;
- (void) dismissPopUp;
- (NSInteger) indexOfItem:(id < NSMenuItem >) item; 
- (NSInteger) indexOfItemWithRepresentedObject:(id) obj;
- (NSInteger) indexOfItemWithTag:(NSInteger) tag;
- (NSInteger) indexOfItemWithTarget:(id) target andAction:(SEL) action;
- (NSInteger) indexOfItemWithTitle:(NSString *) title;
- (NSInteger) indexOfSelectedItem;
- (id) initTextCell:(NSString *) value pullsDown:(BOOL) flag;
- (void) insertItemWithTitle:(NSString *) title atIndex:(NSInteger) index;
- (NSArray *) itemArray;
- (id <NSMenuItem>) itemAtIndex:(NSInteger) index;
- (NSString *) itemTitleAtIndex:(int) index;
- (NSArray *) itemTitles;
- (id <NSMenuItem>) itemWithTitle:(NSString *) title;
- (id <NSMenuItem>) lastItem;
- (NSMenu *) menu; 
- (NSInteger) numberOfItems;
- (id) objectValue;
- (void) performClickWithFrame:(NSRect) frame inView:(NSView *) controlView;
- (NSRectEdge) preferredEdge;
- (BOOL) pullsDown;
- (void) removeAllItems;
- (void) removeItemAtIndex:(NSInteger) index;
- (void) removeItemWithTitle:(NSString *) title;
- (id <NSMenuItem>) selectedItem;
- (void) selectItem:(NSMenuItem *) item;
- (void) selectItemAtIndex:(NSInteger) index;
- (BOOL) selectItemWithTag:(NSInteger) tag; 
- (void) selectItemWithTitle:(NSString *) title;
- (void) setAltersStateOfSelectedItem:(BOOL) flag;
- (void) setArrowPosition:(NSPopUpArrowPosition) position;
- (void) setAutoenablesItems:(BOOL) flag;
- (void) setImage:(NSImage *) image; // has no effect
- (void) setMenu:(NSMenu *) menu; 
- (void) setObjectValue:(id) obj;
- (void) setPreferredEdge:(NSRectEdge) edge;
- (void) setPullsDown:(BOOL) flag;
- (void) setTitle:(NSString *) aString;
- (void) setUsesItemFromMenu:(BOOL) flag;
- (void) synchronizeTitleAndSelectedItem;
- (NSString *) titleOfSelectedItem;
- (BOOL) usesItemFromMenu;

@end

#endif /* _mySTEP_H_NSPopUpButtonCell */
