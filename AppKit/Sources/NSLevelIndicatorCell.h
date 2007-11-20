/*
  NSLevelIndicatorCell.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI.

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:	13. November 2007 - aligned with 10.5    
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSLevelIndicatorCell
#define _mySTEP_H_NSLevelIndicatorCell

#import "AppKit/NSActionCell.h"
#import "AppKit/NSSliderCell.h"

typedef NSUInteger NSLevelIndicatorStyle; 

enum
{
    NSRelevancyLevelIndicatorStyle=0,
    NSContinuousCapacityLevelIndicatorStyle=1,
    NSDiscreteCapacityLevelIndicatorStyle=2,
    NSRatingLevelIndicatorStyle=3
};

@interface NSLevelIndicatorCell : NSActionCell
{
	NSImage *_image;
	double _value;
	double _minValue;
	double _warningValue;	// switching to yellow
	double _criticalValue;	// switching to red
	double _maxValue;
	int _numberOfMajorTickMarks;
	int _numberOfTickMarks;
	NSLevelIndicatorStyle _style;
	NSTickMarkPosition _tickMarkPosition;
}

- (double) criticalValue;
- (id) initWithLevelIndicatorStyle:(NSLevelIndicatorStyle) style;
- (NSLevelIndicatorStyle) levelIndicatorStyle;
- (double) maxValue;
- (double) minValue;
- (NSInteger) numberOfMajorTickMarks;
- (NSInteger) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(NSInteger) index;
- (void) setCriticalValue:(double) val;
- (void) setImage:(NSImage *) image;
- (void) setLevelIndicatorStyle:(NSLevelIndicatorStyle) style;
- (void) setMaxValue:(double) val;
- (void) setMinValue:(double) val;
- (void) setNumberOfMajorTickMarks:(NSInteger) count;
- (void) setNumberOfTickMarks:(NSInteger) count;
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;
- (void) setWarningValue:(double) val;
- (NSTickMarkPosition) tickMarkPosition;
- (double) tickMarkValueAtIndex:(NSInteger) index;
- (double) warningValue;

@end

#endif /* _mySTEP_H_NSLevelIndicatorCell */
