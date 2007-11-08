/* 
   NSComboBoxCell.h

   Control which combines a textfield and a popup list.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	7. November 2007 - aligned with 10.5
 
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

- (void) addItemsWithObjectValues:(NSArray *) objects;
- (void) addItemWithObjectValue:(id) object;
- (NSString *) completedString:(NSString *) string;
- (BOOL) completes;
- (id) dataSource;
- (void) deselectItemAtIndex:(NSInteger) index;
- (void) encodeWithCoder:(NSCoder *) coder;
- (BOOL) hasVerticalScroller;
- (NSInteger) indexOfItemWithObjectValue:(id) object;
- (NSInteger) indexOfSelectedItem;
- (id) initWithCoder:(NSCoder *) coder;
- (void) insertItemWithObjectValue:(id) object atIndex:(NSInteger) index;
- (NSSize) intercellSpacing;
- (BOOL) isButtonBordered;
- (CGFloat) itemHeight;
- (id) itemObjectValueAtIndex:(NSInteger) index;
- (void) noteNumberOfItemsChanged;
- (NSInteger) numberOfItems;
- (NSInteger) numberOfVisibleItems;
- (id) objectValueOfSelectedItem;
- (NSArray *) objectValues;
- (void) reloadData;
- (void) removeAllItems;
- (void) removeItemAtIndex:(NSInteger) index;
- (void) removeItemWithObjectValue:(id) object;
- (void) scrollItemAtIndexToTop:(NSInteger) index;
- (void) scrollItemAtIndexToVisible:(NSInteger) index;
- (void) selectItemAtIndex:(NSInteger) index;
- (void) selectItemWithObjectValue:(id) object;
- (void) setButtonBordered:(BOOL) flag;
- (void) setCompletes:(BOOL) flag;
- (void) setDataSource:(id) aSource;
- (void) setHasVerticalScroller:(BOOL) flag;
- (void) setIntercellSpacing:(NSSize) aSize;
- (void) setItemHeight:(CGFloat) itemHeight;
- (void) setNumberOfVisibleItems:(NSInteger) visibleItems;
- (void) setUsesDataSource:(BOOL) flag;
- (BOOL) usesDataSource;

@end


@interface NSObject (NSComboBoxCellDataSource)

- (NSInteger) numberOfItemsInComboBoxCell:(NSComboBoxCell *) comboBoxCell;
- (id) comboBoxCell:(NSComboBoxCell *) aComboBoxCell objectValueForItemAtIndex:(NSInteger) index;
- (NSUInteger) comboBoxCell:(NSComboBoxCell *) aComboBoxCell indexOfItemWithStringValue:(NSString *) string;
- (NSString *) comboBoxCell:(NSComboBoxCell *) cell completedString:(NSString *) str;

@end

#endif /* _mySTEP_H_NSComboBoxCell */
