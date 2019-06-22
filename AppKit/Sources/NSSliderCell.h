/*
   NSSliderCell.h

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

#ifndef _mySTEP_H_NSSliderCell
#define _mySTEP_H_NSSliderCell

#import <AppKit/NSActionCell.h>

@class NSString;
@class NSColor;
@class NSFont;
@class NSImage;

typedef enum _NSSliderType
{
	NSLinearSlider = 0,
	NSCircularSlider
} NSSliderType;

typedef enum _NSTickMarkPosition
{
	NSTickMarkBelow = 0,
	NSTickMarkAbove = 1,
	NSTickMarkRight = NSTickMarkBelow,
	NSTickMarkLeft  = NSTickMarkAbove
} NSTickMarkPosition;

@interface NSSliderCell : NSActionCell  <NSCoding>
{
	NSRect _slotRect;
	id _knobCell;
	//	id _titleCell;	// deprecated
	CGFloat _minValue;	// we store only a float although external access is double!
	CGFloat _maxValue;
	//	float _floatValue;	// NSNumber in _contents
	CGFloat _altIncrementValue;
	NSInteger _numberOfTickMarks;
	NSSliderType _sliderType;
	NSTickMarkPosition _tickMarkPosition;
	BOOL _isVertical;
	BOOL _allowTickMarkValuesOnly;
}

+ (BOOL) prefersTrackingUntilMouseUp;

- (BOOL) allowsTickMarkValuesOnly;
- (double) altIncrementValue;							// cell's behavior
- (double) closestTickMarkValueToValue:(double) value;
- (void) drawBarInside:(NSRect) rect flipped:(BOOL) flipped;
- (void) drawKnob;
- (void) drawKnob:(NSRect) knobRect;
- (NSInteger) indexOfTickMarkAtPoint:(NSPoint) point;
- (NSInteger) isVertical;	// not official!
- (NSRect) knobRectFlipped:(BOOL) flipped;
- (CGFloat) knobThickness;								// Graphic Attributes
- (double) maxValue;
- (double) minValue;									// Cell Limits
- (NSInteger) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(NSInteger) index;
- (void) setAllowsTickMarkValuesOnly:(BOOL) flag;
- (void) setAltIncrementValue:(double) increment;
- (void) setKnobThickness:(CGFloat) thickness;				// Set Attributes
- (void) setMaxValue:(double) aDouble;
- (void) setMinValue:(double) aDouble;
- (void) setNumberOfTickMarks:(NSInteger) num;
- (void) setSliderType:(NSSliderType) sliderType;
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;
- (NSSliderType) sliderType;
- (NSTickMarkPosition) tickMarkPosition;
- (double) tickMarkValueAtIndex:(NSInteger) index;

// deprecated

- (void) setTitle:(NSString *) title;
- (void) setTitleCell:(NSCell *) aCell;
- (void) setTitleColor:(NSColor *) color;
- (void) setTitleFont:(NSFont *) font;
- (NSString *) title;
- (id) titleCell;
- (NSColor *) titleColor;
- (NSFont *) titleFont;

@end

#endif /* _mySTEP_H_NSSliderCell */
