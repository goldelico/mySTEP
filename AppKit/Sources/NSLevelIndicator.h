//
//  NSLevelIndicator.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2006 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSLevelIndicator
#define _mySTEP_H_NSLevelIndicator

#import "AppKit/NSControl.h"
#import "AppKit/NSLevelIndicatorCell.h"

@interface NSLevelIndicator : NSControl

- (double) criticalValue;
- (double) maxValue;
- (double) minValue;
- (int) numberOfMajorTickMarks;
- (int) numberOfTickMarks;
- (NSRect) rectOfTickMarkAtIndex:(int) index;
- (void) setCriticalValue:(double) val;
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

#endif /* _mySTEP_H_NSLevelIndicator */
