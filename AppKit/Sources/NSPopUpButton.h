/* 
   NSPopUpButton.h

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
   Date:   June 1999
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPopUpButton
#define _mySTEP_H_NSPopUpButton

#import <AppKit/NSButton.h>
#import <AppKit/NSPopUpButtonCell.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSFont;
@class NSPopUpButton;

extern NSString *NSPopUpButtonWillPopUpNotification;

@interface NSPopUpButton : NSButton  <NSCoding>
{
}

- (id) initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag;

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
- (void) setMenu:(NSMenu *) menu;
- (NSMenu *) menu;
- (int) numberOfItems;
- (NSArray *) itemArray;
- (NSString *) itemTitleAtIndex:(int)index;
- (NSArray *) itemTitles;
- (id <NSMenuItem>) itemAtIndex:(int)index;
- (id <NSMenuItem>) itemWithTitle:(NSString *)title;
- (id <NSMenuItem>) lastItem;
- (id <NSMenuItem>) selectedItem;
- (NSString*) titleOfSelectedItem;

	// - (NSFont *) font;		// Graphic Attributes
- (NSPopUpArrowPosition) arrowPosition;
- (NSRectEdge) preferredEdge;
- (BOOL) pullsDown;
- (void) selectItem:(id <NSMenuItem>) item;
- (void) selectItemAtIndex:(int)index;
- (void) selectItemWithTitle:(NSString *)title;
- (void) setObjectValue:(id) obj;	// selectItemAtIndex:[obj intValue]
- (void) setArrowPosition:(NSPopUpArrowPosition) position;
	  // - (void) setFont:(NSFont *)fontObject;
- (void) setPreferredEdge:(NSRectEdge) edge;
- (void) setPullsDown:(BOOL)flag;
- (void) setTitle:(NSString *)aString;
- (void) synchronizeTitleAndSelectedItem;

- (void) setImage:(NSImage *) image;	// has no effect

@end

#endif /* _mySTEP_H_NSPopUpButton */
