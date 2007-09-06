/*
   NSTabViewItem.h
   
   Copyright (C) 1996 Free Software Foundation, Inc.
  
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999
  
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTabViewItem
#define _mySTEP_H_NSTabViewItem

#import <AppKit/NSTabView.h>

typedef enum {
	NSSelectedTab = 0,
	NSBackgroundTab,
	NSPressedTab
} NSTabState;

@class NSColor;
@class NSImage;

@interface NSTabViewItem : NSObject  <NSCoding>
{
	id item_ident;
	NSString *item_label;
	NSView *item_view;
	NSColor *item_color;
	NSTabView *item_tabview;
	NSView *item_initialFirstResponder;
	NSRect item_rect;			// cached
	NSTabState item_state;
}

- (NSColor *)color;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)tabRect;
- (id)identifier;
- (id)initialFirstResponder;
- (id) initWithIdentifier:(id)identifier;
- (NSString *)label;
- (void)setColor:(NSColor *)color;	// deprecated, i.e. not used
- (void)setIdentifier:(id)identifier;
- (void)setInitialFirstResponder:(NSView *)view;
- (void)setLabel:(NSString *)label;
- (void)setView:(NSView *)view;
- (NSSize)sizeOfLabel:(BOOL)shouldTruncateLabel;
- (NSTabState)tabState;
- (NSTabView *)tabView;
- (NSView *)view;

@end

#endif /* _mySTEP_H_NSTabViewItem */
