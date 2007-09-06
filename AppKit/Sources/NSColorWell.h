/* 
   NSColorWell.h

   Color selection and display control.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSColorWell
#define _mySTEP_H_NSColorWell

#import <AppKit/NSControl.h>

@class NSColor;

@interface NSColorWell : NSControl  <NSCoding>
{
	NSColor *_color;
	struct __ColorWellFlags {
		unsigned int isActive:1;
		unsigned int isBordered:1;
		unsigned int reserved:6;
		} _cw;
}

- (void) activate:(BOOL)exclusive;						// Activation
- (NSColor *) color;									// Managing Color
- (void) deactivate;
- (void) drawWellInside:(NSRect)insideRect;				// Drawing
- (BOOL) isActive;
- (BOOL) isBordered;									// Graphic attributes
- (void) setBordered:(BOOL)bordered;
- (void) setColor:(NSColor *)color;
- (void) takeColorFrom:(id)sender;

@end

#endif /* _mySTEP_H_NSColorWell */
