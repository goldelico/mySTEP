/*
   NSSliderCell.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: September 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jul 2006 - aligned with 10.4
 
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
	id _knobCell;
	//	id _titleCell;	// deprecated
	float _minValue;	// we store only a float although external access is double!
	float _maxValue;
	//	float _floatValue;	// NSNumber in _contents
	float _altIncrementValue;
	int _numberOfTickMarks;
	NSRect _trackRect;
	NSSliderType _sliderType;
	NSTickMarkPosition _tickMarkPosition;
	BOOL _isVertical;
	BOOL _initializedVertical;
	BOOL _allowTickMarkValuesOnly;
}

+ (BOOL) prefersTrackingUntilMouseUp;

- (BOOL) allowsTickMarkValuesOnly;
- (double) altIncrementValue;							// cell's behavior
- (double) closestTickMarkValueToValue:(double) value;
- (void) drawBarInside:(NSRect)rect flipped:(BOOL)flipped;
- (void) drawKnob;
- (void) drawKnob:(NSRect)knobRect;
- (int) indexOfTickMarkAtPoint:(NSPoint) point;
- (int) isVertical;
- (NSRect) knobRectFlipped:(BOOL)flipped;
- (float) knobThickness;								// Graphic Attributes
- (double) maxValue;
- (double) minValue;									// Cell Limits
- (int) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(int) index;
- (void) setAllowsTickMarkValuesOnly:(BOOL) flag;
- (void) setAltIncrementValue:(double)increment;
- (void) setKnobThickness:(float)thickness;				// Set Attributes
- (void) setMaxValue:(double)aDouble;
- (void) setMinValue:(double)aDouble;
- (void) setNumberOfTickMarks:(int) num;
- (void) setSliderType:(NSSliderType) sliderType;
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;
- (NSSliderType) sliderType;
- (NSTickMarkPosition) tickMarkPosition;
- (double) tickMarkValueAtIndex:(int) index;
- (NSRect) trackRect;

// deprecated

- (void) setTitle:(NSString*)title;
- (void) setTitleCell:(NSCell*)aCell;
- (void) setTitleColor:(NSColor*)color;
- (void) setTitleFont:(NSFont*)font;
- (NSString*) title;
- (id) titleCell;
- (NSColor*) titleColor;
- (NSFont*) titleFont;

@end

#endif /* _mySTEP_H_NSSliderCell */
