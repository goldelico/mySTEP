/* 
   NSControl.h

   Abstract control class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSControl
#define _mySTEP_H_NSControl

#import <AppKit/NSText.h>
#import <AppKit/NSParagraphStyle.h>

@class NSString;
@class NSNotification;
@class NSCell;
@class NSFont;
@class NSEvent;
@class NSFormatter;
@class NSTextView;

@interface NSControl : NSView  <NSCoding>
{
	int _tag;
	id _cell;
	id _delegate;	// available for subclasses
	BOOL _ignoresMultiClick;
	BOOL _refusesFirstResponder;
}

+ (Class) cellClass;
+ (void) setCellClass:(Class) class;

- (BOOL) abortEditing;										// Field Editor
- (SEL) action;												// Target / Action
- (NSTextAlignment) alignment;								// Formatting Text
- (NSAttributedString *) attributedStringValue;
- (NSWritingDirection) baseWritingDirection;
- (void) calcSize;											// Sizing Control
- (id) cell;
- (NSText *) currentEditor;
- (double) doubleValue;										// Control's Value
- (void) drawCell:(NSCell *) aCell;							// Drawing control
- (void) drawCellInside:(NSCell *) aCell;
- (float) floatValue;
- (NSFont*) font;
- (id) formatter;
- (BOOL) ignoresMultiClick;
- (id) initWithFrame:(NSRect) frameRect;
- (int) intValue;
- (BOOL) isContinuous;
- (BOOL) isEnabled;
- (void) mouseDown:(NSEvent *) event;						// Tracking Mouse
- (id) objectValue;
- (void) performClick:(id) sender;
- (BOOL) refusesFirstResponder;
- (void) selectCell:(NSCell *) aCell;
- (id) selectedCell;										// Selected Cell
- (int) selectedTag;
- (BOOL) sendAction:(SEL) theAction to:(id) theTarget;
- (int) sendActionOn:(int) mask;
- (void) setAction:(SEL) aSelector;
- (void) setAlignment:(NSTextAlignment) mode;
- (void) setAttributedStringValue:(NSAttributedString *) aString;
- (void) setBaseWritingDirection:(NSWritingDirection) direction;
- (void) setCell:(NSCell *) aCell;							// Control's Cell
- (void) setContinuous:(BOOL) flag;
- (void) setDoubleValue:(double) aDouble;
- (void) setEnabled:(BOOL) flag;								// Enable / Disable
- (void) setFloatingPointFormat:(BOOL) autoRange left:(unsigned) leftDigits right:(unsigned) rightDigits;
- (void) setFloatValue:(float) aFloat;
- (void) setFont:(NSFont *) fontObject;
- (void) setFormatter:(NSFormatter *) newFormatter;
- (void) setIgnoresMultiClick:(BOOL) flag;
- (void) setIntValue:(int) anInt;
- (void) setNeedsDisplay;
- (void) setObjectValue:(id <NSCopying>) anObject;
- (void) setRefusesFirstResponder:(BOOL) flag;
- (void) setStringValue:(NSString *) aString;
- (void) setTag:(int) anInt;									// Assigning a Tag
- (void) setTarget:(id) anObject;
- (void) sizeToFit;
- (NSString *) stringValue;
- (int) tag;
- (void) takeDoubleValueFrom:(id) sender;					// Interaction
- (void) takeFloatValueFrom:(id) sender;
- (void) takeIntValueFrom:(id) sender;
- (void) takeObjectValueFrom:(id) sender;
- (void) takeStringValueFrom:(id) sender;
- (id) target;
- (void) updateCell:(NSCell *) aCell;
- (void) updateCellInside:(NSCell *) aCell;
- (void) validateEditing;

@end

// Sent by Control subclasses that allow text 
// editing such as NSTextField and NSMatrix.  
// These have delegates, NSControl doesn't (officially).

@interface NSObject (NSControlSubclassDelegate)			

- (BOOL) control:(NSControl *) control
		 didFailToFormatString:(NSString *) string
		 errorDescription:(NSString *) error;
- (BOOL) control:(NSControl *) control
		 didFailToValidatePartialString:(NSString *) string
		 errorDescription:(NSString *) error;
- (BOOL) control:(NSControl *) control
		 isValidObject:(id) object;
- (BOOL) control:(NSControl *) control
		 textShouldBeginEditing:(NSText *) fieldEditor;
- (BOOL) control:(NSControl *) control 
		 textShouldEndEditing:(NSText *) fieldEditor;
- (NSArray *) control:(NSControl *) control
			 textView:(NSTextView *) view
		  completions:(NSArray *) words
  forPartialWordRange:(NSRange) range
  indexOfSelectedItem:(int *) index;
- (BOOL) control:(NSControl *) control
		 textView:(NSTextView *) view
		 doCommandBySelector:(SEL) command;
- (void) controlTextDidBeginEditing:(NSNotification *) aNotification;
- (void) controlTextDidChange:(NSNotification *) aNotification;
- (void) controlTextDidEndEditing:(NSNotification *) aNotification;

@end

extern NSString *NSControlTextDidBeginEditingNotification;
extern NSString *NSControlTextDidChangeNotification;
extern NSString *NSControlTextDidEndEditingNotification;

#endif /* _mySTEP_H_NSControl */
