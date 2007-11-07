/* 
   NSBox.h

   Box view that can display a border and title

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    March 2000

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4

   Author:	Fabian Spillner
   Date:	19. October 2007  
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSBox
#define _mySTEP_H_NSBox

#import <AppKit/NSView.h>

@class NSString;
@class NSFont;

typedef enum _NSTitlePosition
{
	NSNoTitle	  = 0,
	NSAboveTop	  = 1,
	NSAtTop		  = 2,
	NSBelowTop	  = 3,
	NSAboveBottom = 4,
	NSAtBottom	  = 5,
	NSBelowBottom = 6
} NSTitlePosition;

typedef NSUInteger NSBoxType;

enum _NSBoxType
{
	NSBoxPrimary=0,
	NSBoxSecondary,
	NSBoxSeparator,
	NSBoxOldStyle
};

@interface NSBox : NSView  <NSCoding>
{
	id _titleCell;
	id _contentView;
	NSSize _offsets;
	NSRect _borderRect;
	NSRect _titleRect;
    struct __boxFlags {
		TYPEDBITFIELD(NSBorderType, borderType, 2);
		TYPEDBITFIELD(NSBoxType, boxType, 2);
		TYPEDBITFIELD(NSTitlePosition, titlePosition, 3);
		UIBITFIELD(unsigned int, transparent, 1);
		UIBITFIELD(unsigned int, reserved, 8);
		} _bx;
}

- (NSColor *) borderColor; 
- (NSRect) borderRect;									// Border+Title attribs
- (NSBorderType) borderType;
- (CGFloat) borderWidth;
- (NSBoxType) boxType;
- (id) contentView;										// Content View
- (NSSize) contentViewMargins;
- (CGFloat) cornerRadius;
- (NSColor *) fillColor;
- (BOOL) isTransparent;
- (void) setBorderColor:(NSColor *) color;
- (void) setBorderType:(NSBorderType) type;
- (void) setBorderWidth:(CGFloat) width;
- (void) setBoxType:(NSBoxType) type;
- (void) setContentView:(NSView *) view;
- (void) setContentViewMargins:(NSSize) size;
- (void) setCornerRadius:(CGFloat) rad;
- (void) setFillColor:(NSColor *) color;
- (void) setFrameFromContentFrame:(NSRect) frame;
- (void) setTitle:(NSString *) title;
- (void) setTitleFont:(NSFont *) font;
- (void) setTitlePosition:(NSTitlePosition) pos;
- (void) setTitleWithMnemonic:(NSString *) title;
- (void) setTransparent:(BOOL) flag;
- (void) sizeToFit;										// Sizing the Box
- (NSString *) title;
- (id) titleCell;
- (NSFont *) titleFont;
- (NSTitlePosition) titlePosition;
- (NSRect) titleRect;

@end

#endif /* _mySTEP_H_NSBox */
