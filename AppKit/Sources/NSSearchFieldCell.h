/* 
 NSSearchFieldCell.h
 
 Secure Text field control class for data entry
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author: H. Nikolaus Schaller <hns@computer.org>
 Date: Dec 2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_NSSearchFieldCell
#define _mySTEP_H_NSSearchFieldCell

#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSMenu.h>

enum
{
	NSSearchFieldRecentsTitleMenuItemTag,
	NSSearchFieldRecentsMenuItemTag,
	NSSearchFieldClearRecentsMenuItemTag,
	NSSearchFieldNoRecentsMenuItemTag
};

@interface NSSearchFieldCell : NSTextFieldCell
{
	NSArray *recentSearches;
	NSString *recentsAutosaveName;
	NSButtonCell *_searchButtonCell;
	NSButtonCell *_cancelButtonCell;
	NSMenu *_menuTemplate;
	BOOL sendsWholeSearchString;
	unsigned char maxRecents;
}

- (NSArray *) recentSearches;
- (NSString *) recentsAutosaveName;
- (void) setRecentSearches:(NSArray *) searches;
- (void) setRecentsAutosaveName:(NSString *) name;

- (BOOL) sendsWholeSearchString;
- (void) setSendsWholeSearchString:(BOOL) flag;

- (int) maximumRecents;
- (void) setMaximumRecents:(int) max;

- (NSMenu *) searchMenuTemplate;
- (void) setSearchMenuTemplate:(NSMenu *) menu;

- (NSButtonCell *) cancelButtonCell;
- (void) setCancelButtonCell:(NSButtonCell *) cell;
- (void) resetCancelButtonCell;
- (NSButtonCell *) searchButtonCell;
- (void) setSearchButtonCell:(NSButtonCell *) cell;
- (void) resetSearchButtonCell;

- (NSRect) cancelButtonRectForBounds:(NSRect) rect;
- (NSRect) searchButtonRectForBounds:(NSRect) rect;
- (NSRect) searchTextRectForBounds:(NSRect) rect;

@end

#endif /* _mySTEP_H_NSSearchFieldCell */
