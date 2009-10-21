/* 
   NSMenu.h

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    July 1998
 
   Modified:  H. Nikolaus Schaller <hns@computer.org>
   Date:    2003-2006
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	13. November 2007 - aligned with 10.5    
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSMenu
#define _mySTEP_H_NSMenu

// #import <AppKit/NSMenuItem.h>
#import <AppKit/NSControl.h>

@class NSString;
@class NSEvent;
@class NSMenu;		// forward declaration for NSMenuItem protocol
@class NSMenuItem; 

#if 1	// DEPRECATED but we still need to keep it to remain compatible to older source codes

// according to the documentation, this protocol is defined in NSMenuItem.h
// but we need it here anyway.
// if you want to import this protocol (only), please use NSMenuItem.h!

@protocol NSMenuItem  <NSCopying, NSCoding>

+ (NSMenuItem *) separatorItem;
+ (void) setUsesUserKeyEquivalents:(BOOL) flag;
+ (BOOL) usesUserKeyEquivalents;

- (SEL) action;
- (NSAttributedString *) attributedTitle;	// OS X 10.3
- (BOOL) hasSubmenu;
- (NSImage *) image;
- (id) initWithTitle:(NSString *) title action:(SEL) action keyEquivalent:(NSString *) key;
- (BOOL) isAlternate;   // alternate to previous item
- (BOOL) isEnabled;
- (BOOL) isSeparatorItem;
- (NSString *) keyEquivalent;
- (unsigned int) keyEquivalentModifierMask;
- (NSMenu *) menu;
- (NSImage *) mixedStateImage;
- (NSString *) mnemonic;
- (NSString *) mnemonicLocation;
- (NSImage *) offStateImage;
- (NSImage *) onStateImage;
- (id) representedObject;
- (void) setAction:(SEL) action;
- (void) setAlternate:(BOOL) flag;  // OS X 10.3
- (void) setAttributedTitle:(NSAttributedString *) string;  // OS X 10.3
- (void) setEnabled:(BOOL) flag;
- (void) setImage:(NSImage *) image;
- (void) setKeyEquivalent:(NSString *) key;
- (void) setKeyEquivalentModifierMask:(unsigned int) mask;
- (void) setMenu:(NSMenu *) menu;
- (void) setMixedStateImage:(NSImage *) image;
- (void) setMnemonicLocation:(unsigned) location;
- (void) setOffStateImage:(NSImage *) image;
- (void) setOnStateImage:(NSImage *) image;
- (void) setRepresentedObject:(id) anObject;
- (void) setState:(int) itemState;
- (void) setSubmenu:(NSMenu *) menu;
- (void) setTag:(int) tag;
- (void) setTarget:(id) object;
- (void) setTitle:(NSString *) title;
- (void) setTitleWithMnemonic:(NSString *) title;	// use &x to define the mnemonic
- (void) setToolTip:(NSString *) toolTip;
- (int) state;
- (NSMenu *) submenu;
- (int) tag;
- (id) target;
- (NSString *) title;
- (NSString *) toolTip;
- (NSString*) userKeyEquivalent;
- (NSString*) userKeyEquivalentModifier;

@end

#endif

@interface NSMenu : NSObject  <NSCoding, NSCopying>
{
	struct __MenuFlags {
		unsigned int autoenablesItems:1;
		unsigned int menuChangedMessagesEnabled:1;
		unsigned int menuHasChanged:1;
		unsigned int isTornOff:1;
		unsigned int hasTornOffMenu:1;
		unsigned int reserved:3;
		} _mn;

	NSString *_title;
	NSMutableArray *_menuItems;
	NSMenu *_supermenu;	// not retained
	NSMenu *_attachedMenu;
	NSMenu *tornOffMenu;
	id _delegate;
	id _contextMenuRepresentation;  // link to NSMenuView
	id _menuRepresentation;			// link to NSMenuView
	id _tearOffMenuRepresentation;
}

+ (BOOL) menuBarVisible;
+ (NSZone *) menuZone;
+ (void) popUpContextMenu:(NSMenu *) menu withEvent:(NSEvent *) event forView:(NSView *) view;
+ (void) popUpContextMenu:(NSMenu *) menu withEvent:(NSEvent *) event forView:(NSView *) view withFont:(NSFont *) font;
+ (void) setMenuBarVisible:(BOOL) flag;
+ (void) setMenuZone:(NSZone *) zone;

- (void) addItem:(NSMenuItem *) item;
- (NSMenuItem *) addItemWithTitle:(NSString *) aString
						   action:(SEL) aSelector
				    keyEquivalent:(NSString *) charCode;
- (NSMenu *) attachedMenu;
- (BOOL) autoenablesItems;
- (void) cancelTracking; 
- (id) contextMenuRepresentation;		// deprecated but implemented
- (id) delegate;
- (void) helpRequested:(NSEvent *) event;
- (NSMenuItem *) highlightedItem; 
- (NSInteger) indexOfItem:(NSMenuItem *) item;
- (NSInteger) indexOfItemWithRepresentedObject:(id) object;
- (NSInteger) indexOfItemWithSubmenu:(NSMenu *) submenu;
- (NSInteger) indexOfItemWithTag:(int) tag;
- (NSInteger) indexOfItemWithTarget:(id) target andAction:(SEL) action;
- (NSInteger) indexOfItemWithTitle:(NSString *) title;
- (id) initWithTitle:(NSString *) aTitle;
- (void) insertItem:(NSMenuItem *) item atIndex:(NSInteger) index;
- (NSMenuItem *) insertItemWithTitle:(NSString *) aString
								 action:(SEL) aSelector
						  keyEquivalent:(NSString *) charCode
							    atIndex:(NSInteger) index;
- (BOOL) isAttached;
- (BOOL) isTornOff;
- (NSArray *) itemArray;
- (NSMenuItem *) itemAtIndex:(NSInteger) index;
- (void) itemChanged:(NSMenuItem *) item;
- (NSMenuItem *) itemWithTag:(NSInteger) aTag;				// Find menu items
- (NSMenuItem *) itemWithTitle:(NSString *) aString;
- (NSPoint) locationForSubmenu:(NSMenu *) aSubmenu;
- (CGFloat) menuBarHeight; 
- (BOOL) menuChangedMessagesEnabled;
- (id) menuRepresentation;		// deprecated - used for connecting to NSMenuView
- (NSInteger) numberOfItems;
- (void) performActionForItemAtIndex:(NSInteger) index;
- (BOOL) performKeyEquivalent:(NSEvent *) event;			// keyboard equivalents
- (void) removeItem:(NSMenuItem *) anItem;
- (void) removeItemAtIndex:(NSInteger) index;
- (void) setAutoenablesItems:(BOOL) flag;				// Enabling menu items
- (void) setContextMenuRepresentation:(id) representation;		// used internally /*Deprecated*/
- (void) setDelegate:(id) delegate;
- (void) setMenuChangedMessagesEnabled:(BOOL) flag;		// Menu layout
- (void) setMenuRepresentation:(id) representation;		// deprecated - used for connecting to NSMenuView
- (void) setShowsStateColumn:(BOOL) flag; 
- (void) setSubmenu:(NSMenu *) aMenu forItem:(NSMenuItem *) anItem;
- (void) setSupermenu:(NSMenu *) menu;
- (void) setTearOffMenuRepresentation:(id) representation;  // deprecated
- (void) setTitle:(NSString *) aTitle;						// Menu title
- (BOOL) showsStateColumn;
- (void) sizeToFit;		// calls sizeToFit for all installed representations
- (void) submenuAction:(id) sender;						// Managing submenus
- (NSMenu *) supermenu;
- (id) tearOffMenuRepresentation;						// deprecated
- (NSString *) title;
- (void) update;	// do menu item validation protocol

@end

@interface NSObject (NSMenuValidation)

- (BOOL) validateMenuItem:(NSMenuItem *) menuItem;

@end

@interface NSObject (NSMenuDelegate)

- (BOOL) menu:(NSMenu *) menu updateItem:(NSMenuItem *) updateItem atIndex:(NSInteger) idx shouldCancel:(BOOL) flag;
- (void) menu:(NSMenu *) menu willHighlightItem:(NSMenuItem *) highlightItem;
- (void) menuDidClose:(NSMenu *) menu; 
- (BOOL) menuHasKeyEquivalent:(NSMenu *) menu forEvent:(NSEvent *) evt target:(id *) target action:(SEL *) actionSelector; 
- (void) menuNeedsUpdate:(NSMenu *) menu;	// give delegate a chance to update the menu just before it is popped up
- (void) menuWillOpen:(NSMenu *) menu; 
- (NSInteger) numberOfItemsInMenu:(NSMenu *) menu; 

@end

extern NSString *NSMenuLocationsKey;	// what is this ????

extern NSString *NSMenuDidAddItemNotification;
extern NSString *NSMenuDidChangeItemNotification;
extern NSString *NSMenuDidBeginTrackingNotification; 
extern NSString *NSMenuDidEndTrackingNotification; 
extern NSString *NSMenuDidRemoveItemNotification;
extern NSString *NSMenuDidSendActionNotification;
extern NSString *NSMenuWillSendActionNotification;

#endif /* _mySTEP_H_NSMenu */
