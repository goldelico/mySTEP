/*
	NSStepper.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	12. December 2007 - aligned with 10.5   
  
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSStepper
#define _mySTEP_H_NSStepper

#import "AppKit/NSControl.h"

@interface NSStepper : NSControl
{
}

- (BOOL) autorepeat;
- (double) increment; 
- (double) maxValue; 
- (double) minValue; 
- (void) setAutorepeat:(BOOL) flag; 
- (void) setIncrement:(double) incr; 
- (void) setMaxValue:(double) val; 
- (void) setMinValue:(double) val; 
- (void) setValueWraps:(BOOL) flag; 
- (BOOL) valueWraps; 

@end

#endif /* _mySTEP_H_NSStepper */
