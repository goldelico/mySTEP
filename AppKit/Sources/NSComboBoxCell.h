/* 
   NSComboBoxCell.h

   Control which combines a textfield and a popup list.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSComboBoxCell
#define _mySTEP_H_NSComboBoxCell

#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSTextField.h>

@class NSNotification;
@class NSButtonCell;
@class NSTableView;
@class NSScrollView;
@class NSPanel;

@interface NSComboBoxCell : NSTextFieldCell
{
    id _dataSource;
    NSButtonCell *_buttonCell;
	NSTableView *_tableView;
    NSMutableArray *_popUpList;
    NSSize _intercellSpacing;
	float _itemHeight;
	int _visibleItems;

    struct __comboBoxCellFlags {
		unsigned int usesDataSource:1;
		unsigned int hasVerticalScroller:1;
		unsigned int buttonBordered:1;
		unsigned int completes:1;
		unsigned int reserved:4;
		} _cbc;
}

- (void) addItemsWithObjectValues:(NSArray *)objects;
- (void) addItemWithObjectValue:(id)object;
- (NSString *) completedString:(NSString *) string;
- (BOOL) completes;
- (id) dataSource;
- (void) deselectItemAtIndex:(int)index;
- (BOOL) hasVerticalScroller;
- (int) indexOfItemWithObjectValue:(id)object;
- (int) indexOfSelectedItem;
- (void) insertItemWithObjectValue:(id)object atIndex:(int)index;
- (NSSize) intercellSpacing;
- (BOOL) isButtonBordered;
- (float) itemHeight;
- (id) itemObjectValueAtIndex:(int)index;
- (void) noteNumberOfItemsChanged;
- (int) numberOfItems;
- (int) numberOfVisibleItems;
- (id) objectValueOfSelectedItem;
- (NSArray *) objectValues;
- (void) reloadData;
- (void) removeAllItems;
- (void) removeItemAtIndex:(int)index;
- (void) removeItemWithObjectValue:(id)object;
- (void) scrollItemAtIndexToTop:(int)index;
- (void) scrollItemAtIndexToVisible:(int)index;
- (void) selectItemAtIndex:(int)index;
- (void) selectItemWithObjectValue:(id)object;
- (void) setButtonBordered:(BOOL)flag;
- (void) setCompletes:(BOOL)flag;
- (void) setDataSource:(id)aSource;
- (void) setHasVerticalScroller:(BOOL)flag;
- (void) setIntercellSpacing:(NSSize)aSize;
- (void) setItemHeight:(float)itemHeight;
- (void) setNumberOfVisibleItems:(int)visibleItems;
- (void) setUsesDataSource:(BOOL)flag;
- (BOOL) usesDataSource;

@end


@interface NSObject (NSComboBoxCellDataSource)

- (int) numberOfItemsInComboBoxCell:(NSComboBoxCell *)comboBoxCell;
- (id) comboBoxCell:(NSComboBoxCell *)aComboBoxCell
	   objectValueForItemAtIndex:(int)index;
- (unsigned int) comboBoxCell:(NSComboBoxCell *)aComboBoxCell
				 indexOfItemWithStringValue:(NSString *)string;
- (NSString *) comboBoxCell:(NSComboBoxCell *)cell completedString:(NSString *) str;
@end

#endif /* _mySTEP_H_NSComboBoxCell */
