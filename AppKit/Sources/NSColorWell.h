/* 
   NSColorWell.h

   Color selection and display control.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
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
	SEL _action;
	id _target;		// NSControl uses an NSCell but we don't have one!
	struct __ColorWellFlags {
		unsigned int isActive:1;
		unsigned int isBordered:1;
		unsigned int reserved:6;
		} _cw;
}

- (void) activate:(BOOL) exclusive;						// Activation
- (NSColor *) color;									// Managing Color
- (void) deactivate;
- (void) drawWellInside:(NSRect) insideRect;				// Drawing
- (BOOL) isActive;
- (BOOL) isBordered;									// Graphic attributes
- (void) setBordered:(BOOL) bordered;
- (void) setColor:(NSColor *) color;
- (void) takeColorFrom:(id) sender;

@end

#endif /* _mySTEP_H_NSColorWell */
