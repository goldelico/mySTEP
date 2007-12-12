/*
   NSTabView.h

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999
  
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Apr 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTabView
#define _mySTEP_H_NSTabView
 
#import <AppKit/NSView.h>
#import <AppKit/NSCell.h>	// NSControlSize, NSControlTint
#import <AppKit/NSSegmentedCell.h>

typedef enum {
	NSTopTabsBezelBorder, 
	NSLeftTabsBezelBorder,
	NSBottomTabsBezelBorder,
	NSRightTabsBezelBorder,
	NSNoTabsBezelBorder,
	NSNoTabsLineBorder,
	NSNoTabsNoBorder
} NSTabViewType;

@class NSFont;
@class NSTabViewItem;

@interface NSTabView : NSView  <NSCoding>
{
	NSMutableArray *tab_items;
	NSFont *tab_font;
	NSTabViewType tab_type;
	NSTabViewItem *tab_selected;
	BOOL tab_draws_background;
	BOOL tab_truncated_label;
	id tab_delegate;
	int tab_selected_item;
	NSControlSize _controlSize;
	NSControlTint _controlTint;
}

- (void) addTabViewItem:(NSTabViewItem *) tabViewItem;
- (BOOL) allowsTruncatedLabels;
- (NSRect) contentRect;
- (NSControlSize) controlSize;
- (NSControlTint) controlTint;
- (id) delegate;
- (BOOL) drawsBackground;
- (NSFont *) font;
- (NSInteger) indexOfTabViewItem:(NSTabViewItem *) tabViewItem;
- (NSInteger) indexOfTabViewItemWithIdentifier:(id) identifier;
- (void) insertTabViewItem:(NSTabViewItem *) tabViewItem atIndex:(NSInteger) index;
- (NSSize) minimumSize;
- (NSInteger) numberOfTabViewItems;
- (void) removeTabViewItem:(NSTabViewItem *) tabViewItem;
- (NSTabViewItem *) selectedTabViewItem;
- (void) selectFirstTabViewItem:(id) sender;
- (void) selectLastTabViewItem:(id) sender;
- (void) selectNextTabViewItem:(id) sender;
- (void) selectPreviousTabViewItem:(id) sender;
- (void) selectTabViewItem:(NSTabViewItem *) tabViewItem;
- (void) selectTabViewItemAtIndex:(NSInteger) index;
- (void) selectTabViewItemWithIdentifier:(id) identifier;
- (void) setAllowsTruncatedLabels:(BOOL) allowTruncatedLabels;
- (void) setControlSize:(NSControlSize) size;
- (void) setControlTint:(NSControlTint) tint;
- (void) setDelegate:(id) anObject;
- (void) setDrawsBackground:(BOOL) flag;
- (void) setFont:(NSFont *) font;
- (void) setTabViewType:(NSTabViewType) tabViewType;
- (NSTabViewItem *) tabViewItemAtIndex:(NSInteger) index;
- (NSTabViewItem *) tabViewItemAtPoint:(NSPoint) point;
- (NSArray *) tabViewItems;
- (NSTabViewType) tabViewType;
- (void) takeSelectedTabViewItemFromSender:(id) sender;
- (NSWindow *) window;

@end

@interface NSObject (NSTabViewDelegate)

- (void) tabView:(NSTabView *) tabView 
		 didSelectTabViewItem:(NSTabViewItem *) tabViewItem;
- (BOOL) tabView:(NSTabView *) tabView 
		 shouldSelectTabViewItem:(NSTabViewItem *) tabViewItem;
- (void) tabView:(NSTabView *) tabView 
		 willSelectTabViewItem:(NSTabViewItem *) tabViewItem;
- (void) tabViewDidChangeNumberOfTabViewItems:(NSTabView *) tabView;

@end

#endif /* _mySTEP_H_NSTabView */
