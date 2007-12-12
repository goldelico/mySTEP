/* 
   NSTextField.h

   Text field control class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSTextField
#define _mySTEP_H_NSTextField

#import <AppKit/NSControl.h>
#import <AppKit/NSTextFieldCell.h>

@class NSNotification;
@class NSColor;
@class NSText;

@interface NSTextField : NSControl  <NSCoding>
{
//	id _delegate;	// inherit from NSControl
}

- (BOOL) acceptsFirstResponder;							// Event handling
- (BOOL) allowsEditingTextAttributes; 
- (NSColor *) backgroundColor;							// Graphic Attributes
- (NSTextFieldBezelStyle) bezelStyle; 
- (id) delegate;
- (BOOL) drawsBackground;
- (BOOL) importsGraphics;
- (BOOL) isBezeled;
- (BOOL) isBordered;
- (BOOL) isEditable;									// Access to Text
- (BOOL) isSelectable;
- (void) selectText:(id)sender;							// Editing Text
- (void) setAllowsEditingTextAttributes:(BOOL) flag;
- (void) setBackgroundColor:(NSColor*)aColor;
- (void) setBezeled:(BOOL)flag;
- (void) setBezelStyle:(NSTextFieldBezelStyle) style; 
- (void) setBordered:(BOOL) flag;
- (void) setDelegate:(id) anObject;						// Delegate
- (void) setDrawsBackground:(BOOL) flag;
- (void) setEditable:(BOOL) flag;
- (void) setImportsGraphics:(BOOL) flag; 
- (void) setSelectable:(BOOL) flag;
- (void) setTextColor:(NSColor*) aColor;
- (void) setTitleWithMnemonic:(NSString *) string; 
- (NSColor *) textColor;
- (void) textDidBeginEditing:(NSNotification *) aNotification;
- (void) textDidChange:(NSNotification *) aNotification;
- (void) textDidEndEditing:(NSNotification *) aNotification;
- (BOOL) textShouldBeginEditing:(NSText *) textObject;
- (BOOL) textShouldEndEditing:(NSText *) textObject;

@end

#endif /* _mySTEP_H_NSTextField */
