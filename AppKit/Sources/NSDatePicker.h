/*
	NSDatePicker.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner
	Date:	22. October 2007
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	7. November 2007 - aligned with 10.5
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDatePicker
#define _mySTEP_H_NSDatePicker

#import "AppKit/NSControl.h"
#import "AppKit/NSDatePickerCell.h"

@interface NSDatePicker : NSControl

- (NSColor *) backgroundColor;
- (NSCalendar *) calendar;
- (NSDatePickerElementFlags) datePickerElements;
- (NSDatePickerMode) datePickerMode;
- (NSDatePickerStyle) datePickerStyle;
- (NSDate *) dateValue;
- (id) delegate; /* DOESNT EXIST IN API */
- (BOOL) drawsBackground;
- (BOOL) isBezeled;
- (BOOL) isBordered;
- (NSLocale *) locale;
- (NSDate *) maxDate;
- (NSDate *) minDate;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBezeled:(BOOL) flag;
- (void) setBordered:(BOOL) flag;
- (void) setCalendar:(NSCalendar *) calendar;
- (void) setDatePickerElements:(NSDatePickerElementFlags) flags;
- (void) setDatePickerMode:(NSDatePickerMode) mode;
- (void) setDatePickerStyle:(NSDatePickerStyle) style;
- (void) setDateValue:(NSDate *) date;
- (void) setDelegate:(id) obj; /* DOESNT EXIST IN API */
- (void) setDrawsBackground:(BOOL) flag;
- (void) setLocale:(NSLocale *) locale;
- (void) setMaxDate:(NSDate *) date;
- (void) setMinDate:(NSDate *) date;
- (void) setTextColor:(NSColor *) color;
- (void) setTimeInterval:(NSTimeInterval) interval;
- (void) setTimeZone:(NSTimeZone *) zone;
- (NSColor *) textColor;
- (NSTimeInterval) timeInterval;
- (NSTimeZone *) timeZone;

@end

#endif /* _mySTEP_H_NSDatePicker */
