//
//  NSLevelIndicatorCell.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSLevelIndicatorCell
#define _mySTEP_H_NSLevelIndicatorCell

#import "AppKit/NSActionCell.h"
#import "AppKit/NSSliderCell.h"

typedef enum _NSLevelIndicatorStyle
{
    NSRelevancyLevelIndicatorStyle=0,
    NSContinuousCapacityLevelIndicatorStyle=1,
    NSDiscreteCapacityLevelIndicatorStyle=2,
    NSRatingLevelIndicatorStyle=3
} NSLevelIndicatorStyle;

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
- (NSLevelIndicatorStyle) style;
- (double) maxValue;
- (double) minValue;
- (int) numberOfMajorTickMarks;
- (int) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(int) index;
- (void) setCriticalValue:(double) val;
- (void) setImage:(NSImage *) image;
- (void) setLevelIndicatorStyle:(NSLevelIndicatorStyle) style;
- (void) setMaxValue:(double) val;
- (void) setMinValue:(double) val;
- (void) setNumberOfMajorTickMarks:(int) count;
- (void) setNumberOfTickMarks:(int) count;
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;
- (void) setWarningValue:(double) val;
- (NSTickMarkPosition) tickMarkPosition;
- (double) tickMarkValueAtIndex:(int) index;
- (double) warningValue;

@end

#endif /* _mySTEP_H_NSLevelIndicatorCell */
