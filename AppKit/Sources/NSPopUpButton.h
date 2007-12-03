/* 
   NSPopUpButton.h

   Popup list class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
   Date:   June 1999
   
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	29. November 2007 - aligned with 10.5
 
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

- (void) addItemsWithTitles:(NSArray *) itemTitles;
- (void) addItemWithTitle:(NSString *) title;
- (BOOL) autoenablesItems; 
- (NSInteger) indexOfItem:(id < NSMenuItem >) obj; 
- (NSInteger) indexOfItemWithRepresentedObject:(id) obj;
- (NSInteger) indexOfItemWithTag:(NSInteger) tag;
- (NSInteger) indexOfItemWithTarget:(id) target andAction:(SEL) action;
- (NSInteger) indexOfItemWithTitle:(NSString *) title;
- (NSInteger) indexOfSelectedItem;
- (id) initWithFrame:(NSRect) frameRect pullsDown:(BOOL) flag;
- (void) insertItemWithTitle:(NSString *) title atIndex:(NSInteger) index;
- (NSArray *) itemArray;
- (id <NSMenuItem>) itemAtIndex:(NSInteger) index;
- (NSString *) itemTitleAtIndex:(NSInteger) index;
- (NSArray *) itemTitles;
- (id <NSMenuItem>) itemWithTitle:(NSString *) title;
- (id <NSMenuItem>) lastItem;
- (NSMenu *) menu;
- (NSInteger) numberOfItems;
- (id) objectValue;
- (NSRectEdge) preferredEdge;
- (BOOL) pullsDown;
- (void) removeAllItems;	
- (void) removeItemAtIndex:(NSInteger) index;
- (void) removeItemWithTitle:(NSString *) title;
- (id <NSMenuItem>) selectedItem;
- (void) selectItem:(id <NSMenuItem>) item;
- (void) selectItemAtIndex:(NSInteger) index;
- (BOOL) selectItemWithTag:(NSInteger) tag; 
- (void) selectItemWithTitle:(NSString *) title;
- (void) setAutoenablesItems:(BOOL) flag; 
- (void) setImage:(NSImage *) image;	// has no effect
- (void) setMenu:(NSMenu *) menu;
- (void) setObjectValue:(id) obj;
- (void) setPreferredEdge:(NSRectEdge) edge;
- (void) setPullsDown:(BOOL) flag;
- (void) setTitle:(NSString *) aString;
- (void) synchronizeTitleAndSelectedItem;
- (NSString *) titleOfSelectedItem;

- (NSPopUpArrowPosition) arrowPosition; // not in API
- (void) setArrowPosition:(NSPopUpArrowPosition) position; // not in API

@end

#endif /* _mySTEP_H_NSPopUpButton */
