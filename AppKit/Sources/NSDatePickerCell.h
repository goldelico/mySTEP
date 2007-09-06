//
//  NSDatePickerCell.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSDatePickerCell
#define _mySTEP_H_NSDatePickerCell

#import "AppKit/NSActionCell.h"

typedef enum _NSDatePickerStyle	
{
	NSTextFieldAndStepperDatePickerStyle,
	NSClockAndCalendarDatePickerStyle
} NSDatePickerStyle;

typedef enum _NSDatePickerMode
{
	NSSingleDateMode,
	NSRangeDateMode
} NSDatePickerMode;

typedef enum _NSDatePickerElementFlags
{
	NSHourMinuteDatePickerElementFlag			= 0x01,
	NSHourMinuteSecondDatePickerElementFlag		= 0x02,
	NSTimeZoneDatePickerElementFlag				= 0x04,
	NSYearMonthDatePickerElementFlag			= 0x08,
	NSYearMonthDayDatePickerElementFlag			= 0x10,
	NSEraDatePickerElementFlag					= 0x20
} NSDatePickerElementFlags;

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
- (BOOL) isBezeled;
- (BOOL) isBordered;
- (NSLocale *) locale;
- (NSDate *) maxDate;
- (NSDate *) minDate;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBezeled:(BOOL) flag;
- (void) setBordered:(BOOL) flag;
- (void) setCalendar:(NSCalendar *) calendar;
- (void) setDatePickerElements:(unsigned) flags;
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

#endif /* _mySTEP_H_NSDatePickerCell */
