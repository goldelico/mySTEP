/* 
   NSTextFieldCell.h

   Text field cell class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSTextFieldCell
#define _mySTEP_H_NSTextFieldCell

#import <AppKit/NSActionCell.h>

@class NSColor;

typedef enum _NSTextFieldBezelStyle
{
	NSTextFieldSquareBezel = 0,
	NSTextFieldRoundedBezel
} NSTextFieldBezelStyle;

@interface NSTextFieldCell : NSActionCell  <NSCoding>
{
	NSColor *_backgroundColor;
	id _delegate;
	NSTextFieldBezelStyle _bezelStyle;
}

- (NSArray *) allowedInputSourceLocales; 
- (NSColor *) backgroundColor;							// Graphic Attributes
- (NSTextFieldBezelStyle) bezelStyle;
- (BOOL) drawsBackground;
- (NSAttributedString *) placeholderAttributedString;
- (NSString *) placeholderString;
- (void) setAllowedInputSourceLocales:(NSArray *) ids; 
- (void) setBackgroundColor:(NSColor *) aColor;
- (void) setBezelStyle:(NSTextFieldBezelStyle) bezelStyle; 
- (void) setDrawsBackground:(BOOL) flag;
- (void) setPlaceholderAttributedString:(NSAttributedString *) string;
- (void) setPlaceholderString:(NSString *) string;
- (void) setTextColor:(NSColor *) aColor;
- (NSText *) setUpFieldEditorAttributes:(NSText *) obj; 
- (void) setWantsNotificationForMarkedText:(BOOL) flag; 
- (NSColor *) textColor;

@end

#endif /* _mySTEP_H_NSTextFieldCell */
