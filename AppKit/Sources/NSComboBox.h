/* 
   NSComboBox.h

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

#ifndef _mySTEP_H_NSComboBox
#define _mySTEP_H_NSComboBox

#import <AppKit/NSComboBoxCell.h>

@class NSNotification;

@interface NSComboBox : NSTextField
{
    id _dataSource;
}

- (void) addItemsWithObjectValues:(NSArray *) objects;
- (void) addItemWithObjectValue:(id) object;
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


@interface NSObject (NSComboBoxDataSource)

- (NSString *) comboBox:(NSComboBox *) aComboBox completedString:(NSString *) str;
- (NSUInteger) comboBox:(NSComboBox *) aComboBox indexOfItemWithStringValue:(NSString *) string;
- (id) comboBox:(NSComboBox *) aComboBox objectValueForItemAtIndex:(NSInteger) index;
- (NSInteger) numberOfItemsInComboBox:(NSComboBox *) aComboBox;

@end


@interface NSObject (NSComboBoxDelegateNotifications)

- (void) comboBoxSelectionDidChange:(NSNotification *) notification;
- (void) comboBoxSelectionIsChanging:(NSNotification *) notification;
- (void) comboBoxWillDismiss:(NSNotification *) notification;
- (void) comboBoxWillPopUp:(NSNotification *) notification;

@end

extern NSString *NSComboBoxSelectionDidChangeNotification;
extern NSString *NSComboBoxSelectionIsChangingNotification;
extern NSString *NSComboBoxWillDismissNotification;
extern NSString *NSComboBoxWillPopUpNotification;

#endif /* _mySTEP_H_NSComboBox */
