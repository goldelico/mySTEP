/* 
   NSBox.h

   Box view that can display a border and title

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    March 2000

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4

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

typedef enum _NSBoxType
{
	NSBoxPrimary=0,
	NSBoxSecondary,
	NSBoxSeparator,
	NSBoxOldStyle
} NSBoxType;

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

- (NSRect) borderRect;									// Border+Title attribs
- (NSBorderType) borderType;
- (NSBoxType) boxType;
- (id) contentView;										// Content View
- (NSSize) contentViewMargins;
- (void) setBorderType:(NSBorderType)aType;
- (void) setBoxType:(NSBoxType)aType;
- (void) setContentView:(NSView *)aView;
- (void) setContentViewMargins:(NSSize)offsetSize;
- (void) setFrameFromContentFrame:(NSRect)contentFrame;
- (void) setTitle:(NSString *)aString;
- (void) setTitleFont:(NSFont *)fontObj;
- (void) setTitlePosition:(NSTitlePosition)aPosition;
- (void) setTitleWithMnemonic:(NSString *)aString;
- (void) sizeToFit;										// Sizing the Box
- (NSString *) title;
- (id) titleCell;
- (NSFont *) titleFont;
- (NSTitlePosition) titlePosition;
- (NSRect) titleRect;

@end

#endif /* _mySTEP_H_NSBox */
