/* 
   NSForm.h

   Form class, a text field with a label

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSForm
#define _mySTEP_H_NSForm

#import <AppKit/NSMatrix.h>

@class NSFormCell;
@class NSFont;

@interface NSForm : NSMatrix  <NSCoding>

- (NSFormCell*) addEntry:(NSString*)title;				// Layout the Form
- (NSFormCell*) insertEntry:(NSString*)title atIndex:(int)index;
- (void) removeEntryAtIndex:(int)index;
- (void) setInterlineSpacing:(float)spacing;
- (void) setEntryWidth:(float)width;

- (int) indexOfCellWithTag:(int)aTag;					// Access cells
- (int) indexOfSelectedItem;
- (id) cellAtIndex:(int)index;

- (void) setBezeled:(BOOL)flag;							// Graphic Attributes
- (void) setBordered:(BOOL)flag;
- (void) setTextAlignment:(int)mode;
- (void) setTextFont:(NSFont*)fontObject;
- (void) setTitleAlignment:(NSTextAlignment)mode;
- (void) setTitleFont:(NSFont*)fontObject;

- (void) drawCellAtIndex:(int)index;					// Drawing

- (void) selectTextAtIndex:(int)index;					// Editing

@end

#endif /* _mySTEP_H_NSForm */
