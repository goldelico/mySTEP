/* 
   NSForm.h

   Form class, a text field with a label

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSForm
#define _mySTEP_H_NSForm

#import <AppKit/NSMatrix.h>

@class NSFormCell;
@class NSFont;

@interface NSForm : NSMatrix  <NSCoding>

- (NSFormCell *) addEntry:(NSString*) title;				// Layout the Form
- (id) cellAtIndex:(NSInteger) index;
- (void) drawCellAtIndex:(NSInteger) index;					// Drawing
- (NSInteger) indexOfCellWithTag:(NSInteger) aTag;					// Access cells
- (NSInteger) indexOfSelectedItem;
- (NSFormCell *) insertEntry:(NSString *) title atIndex:(NSInteger) index;
- (void) removeEntryAtIndex:(NSInteger) index;
- (void) selectTextAtIndex:(NSInteger) index;					// Editing
- (void) setBezeled:(BOOL) flag;							// Graphic Attributes
- (void) setBordered:(BOOL) flag;
- (void) setEntryWidth:(CGFloat) width;
- (void) setFrameSize:(NSSize) size;
- (void) setInterlineSpacing:(CGFloat) spacing;
- (void) setTextAlignment:(NSInteger) mode;
- (void) setTextBaseWritingDirection:(NSWritingDirection) direction;
- (void) setTextFont:(NSFont *) fontObject;
- (void) setTitleAlignment:(NSTextAlignment) mode;
- (void) setTitleBaseWritingDirection:(NSWritingDirection) direction;
- (void) setTitleFont:(NSFont *) fontObject;

@end

#endif /* _mySTEP_H_NSForm */
