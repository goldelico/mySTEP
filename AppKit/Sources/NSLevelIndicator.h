/*
  NSLevelIndicator.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2006 DSITRI.

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:	13. November 2007 - aligned with 10.5   
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSLevelIndicator
#define _mySTEP_H_NSLevelIndicator

#import "AppKit/NSControl.h"
#import "AppKit/NSLevelIndicatorCell.h"

@interface NSLevelIndicator : NSControl

- (double) criticalValue;
- (double) maxValue;
- (double) minValue;
- (NSInteger) numberOfMajorTickMarks;
- (NSInteger) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(NSInteger) index;
- (void) setCriticalValue:(double) val;
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

#endif /* _mySTEP_H_NSLevelIndicator */
