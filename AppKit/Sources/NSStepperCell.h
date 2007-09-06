//
//  NSStepperCell.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSStepperCell
#define _mySTEP_H_NSStepperCell

#import "AppKit/NSActionCell.h"
#import "AppKit/NSButtonCell.h"

@class NSString;

@interface NSStepperCell : NSActionCell
{
	NSButtonCell *_upCell;
	NSButtonCell *_downCell;
	double _increment;
	double _maxValue;
	double _minValue;
	double _value;
	BOOL _autorepeat;
	BOOL _valueWraps;
}

- (BOOL) autorepeat;
- (double) increment;
- (double) maxValue;
- (double) minValue;
- (void) setAutorepeat:(BOOL) flag;
- (void) setIncrement:(double) val;
- (void) setMaxValue:(double) val;
- (void) setMinValue:(double) val;
- (void) setValueWraps:(BOOL) flag;
- (BOOL) valueWraps;

@end

#endif /* _mySTEP_H_NSStepperCell */
