/*
   NSSlider.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jul 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSSlider
#define _mySTEP_H_NSSlider

#import <AppKit/NSControl.h>
#import <AppKit/NSSliderCell.h>

@class NSString;
@class NSImage;
@class NSCell;
@class NSFont;
@class NSColor;
@class NSEvent;

@interface NSSlider : NSControl

- (BOOL) acceptsFirstMouse:(NSEvent *) event;
- (BOOL) allowsTickMarkValuesOnly;
- (double) altIncrementValue;							// cell's behavior
- (double) closestTickMarkValueToValue:(double) value;
- (NSImage *) image;
- (NSInteger) indexOfTickMarkAtPoint:(NSPoint) point;
- (BOOL) isVertical;
- (CGFloat) knobThickness;								// Graphic Attributes
- (double) maxValue;
- (double) minValue;									// Cell Limits
- (NSInteger) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(NSInteger) index;
- (void) setAllowsTickMarkValuesOnly:(BOOL) flag;
- (void) setAltIncrementValue:(double) increment;
- (void) setImage:(NSImage *) backgroundImage;
- (void) setKnobThickness:(CGFloat) thickness;				// Set Attributes
- (void) setMaxValue:(double) aDouble;
- (void) setMinValue:(double) aDouble;
- (void) setNumberOfTickMarks:(NSInteger) num;
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;
- (NSTickMarkPosition) tickMarkPosition;
- (double) tickMarkValueAtIndex:(NSInteger) index;

// deprecated
- (void) setTitle:(NSString *) aString;
- (void) setTitleCell:(NSCell *) aCell;
- (void) setTitleColor:(NSColor *) aColor;
- (void) setTitleFont:(NSFont *) fontObject;
- (NSString *) title;
- (id) titleCell;
- (NSColor *) titleColor;
- (NSFont *) titleFont;

@end

#endif /* _mySTEP_H_NSSlider */
