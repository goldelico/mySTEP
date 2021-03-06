/*
	NSDatePickerCell.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner
	Date:	22. October 2007
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDatePickerCell
#define _mySTEP_H_NSDatePickerCell

#import "AppKit/NSActionCell.h"

enum {
	NSTextFieldAndStepperDatePickerStyle    = 0,
	NSClockAndCalendarDatePickerStyle       = 1,
	NSTextFieldDatePickerStyle              = 2
};
typedef NSUInteger NSDatePickerStyle;

enum {
	NSSingleDateMode = 0,
	NSRangeDateMode = 1
};
typedef NSUInteger NSDatePickerMode;

enum {
	NSHourMinuteDatePickerElementFlag       = 0x000c,
	NSHourMinuteSecondDatePickerElementFlag = 0x000e,
	NSTimeZoneDatePickerElementFlag        = 0x0010,
	
	NSYearMonthDatePickerElementFlag        = 0x00c0,
	NSYearMonthDayDatePickerElementFlag        = 0x00e0,
	NSEraDatePickerElementFlag            = 0x0100,
};
typedef NSUInteger NSDatePickerElementFlags;

@interface NSDatePickerCell : NSActionCell
{
	NSTimeZone *_timeZone;
	NSColor *_backgroundColor;
	NSCalendar *_calendar;
	NSDate *_dateValue;
	id _delegate;
	NSLocale *_locale;
	NSDate *_maxDate;
	NSDate *_minDate;
	NSTimeInterval _timeInterval;
	// FIXME: pack into a bitfield?
	NSDatePickerElementFlags _datePickerElements;
	NSDatePickerMode _datePickerMode;
	NSDatePickerStyle _datePickerStyle;
	BOOL _drawsBackground;
	BOOL _isBezeled;
	BOOL _isBordered;
}

- (NSColor *) backgroundColor;
- (NSCalendar *) calendar;
- (NSDatePickerElementFlags) datePickerElements;
- (NSDatePickerMode) datePickerMode;
- (NSDatePickerStyle) datePickerStyle;
- (NSDate *) dateValue;
- (id) delegate;
- (BOOL) drawsBackground;
- (BOOL) isBezeled; /* DOESNT EXIST IN API */
- (BOOL) isBordered; /* DOESNT EXIST IN API */
- (NSLocale *) locale;
- (NSDate *) maxDate;
- (NSDate *) minDate;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBezeled:(BOOL) flag; /* DOESNT EXIST IN API */
- (void) setBordered:(BOOL) flag; /* DOESNT EXIST IN API */
- (void) setCalendar:(NSCalendar *) calendar;
- (void) setDatePickerElements:(NSDatePickerElementFlags) flags;
- (void) setDatePickerMode:(NSDatePickerMode) mode;
- (void) setDatePickerStyle:(NSDatePickerStyle) style;
- (void) setDateValue:(NSDate *) date;
- (void) setDelegate:(id) obj;
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

@interface NSObject (NSDataPickerCellDelegate)

- (void)datePickerCell:(NSDatePickerCell *) aDatePickerCell 
validateProposedDateValue:(NSDate **) proposedDateValue 
		  timeInterval:(NSTimeInterval *) proposedTimeInterval;

@end

#endif /* _mySTEP_H_NSDatePickerCell */
