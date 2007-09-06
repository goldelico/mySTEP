/* 
   NSTextFieldCell.h

   Text field cell class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
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

- (NSColor *) backgroundColor;							// Graphic Attributes
- (NSTextFieldBezelStyle) bezelStyle;
- (BOOL) drawsBackground;
- (NSString *) placeholderString;
- (NSAttributedString *) placeholderAttributedString;
- (void) setBackgroundColor:(NSColor *)aColor;
- (void) setDrawsBackground:(BOOL)flag;
- (void) setTextColor:(NSColor *)aColor;
- (void) setPlaceholderString:(NSString *) string;
- (void) setPlaceholderAttributedString:(NSAttributedString *) string;
- (NSColor *) textColor;

@end

#endif /* _mySTEP_H_NSTextFieldCell */
