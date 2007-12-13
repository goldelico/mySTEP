/* 
 NSSearchFieldCell.h
 
 Secure Text field control class for data entry
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author: H. Nikolaus Schaller <hns@computer.org>
 Date: Dec 2004
 
 Author:	Fabian Spillner <fabian.spillner@gmail.com>
 Date:		05. December 2007 - aligned with 10.5   

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_NSSearchFieldCell
#define _mySTEP_H_NSSearchFieldCell

#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSMenu.h>

#define NSSearchFieldRecentsTitleMenuItemTag 1000
#define NSSearchFieldRecentsMenuItemTag 1001
#define NSSearchFieldClearRecentsMenuItemTag 1002
#define NSSearchFieldNoRecentsMenuItemTag 1003

@interface NSSearchFieldCell : NSTextFieldCell
{
	NSArray *recentSearches;
	NSString *recentsAutosaveName;
	NSButtonCell *_searchButtonCell;
	NSButtonCell *_cancelButtonCell;
	NSMenu *_menuTemplate;
	unsigned char maxRecents;
	BOOL sendsWholeSearchString;
	BOOL sendsSearchStringImmediately;
}

- (NSButtonCell *) cancelButtonCell;
- (NSRect) cancelButtonRectForBounds:(NSRect) rect;
- (NSInteger) maximumRecents;
- (NSString *) recentsAutosaveName;
- (NSArray *) recentSearches;
- (void) resetCancelButtonCell;
- (void) resetSearchButtonCell;
- (NSButtonCell *) searchButtonCell;
- (NSRect) searchButtonRectForBounds:(NSRect) rect;
- (NSMenu *) searchMenuTemplate;
- (NSRect) searchTextRectForBounds:(NSRect) rect;
- (BOOL) sendsSearchStringImmediately; 
- (BOOL) sendsWholeSearchString;
- (void) setCancelButtonCell:(NSButtonCell *) cell;
- (void) setMaximumRecents:(NSInteger) max;
- (void) setRecentsAutosaveName:(NSString *) name;
- (void) setRecentSearches:(NSArray *) searches;
- (void) setSearchButtonCell:(NSButtonCell *) cell;
- (void) setSearchMenuTemplate:(NSMenu *) menu;
- (void) setSendsSearchStringImmediately:(BOOL) flag; 
- (void) setSendsWholeSearchString:(BOOL) flag;

@end

#endif /* _mySTEP_H_NSSearchFieldCell */
