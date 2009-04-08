/* 
 NSDatePicker.m
 
 Text field control and cell classes
 
 Author:  Nikolaus Schaller <hns@computer.org>
 Date:    April 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#import <AppKit/NSDatePickerCell.h>
#import <AppKit/NSDatePicker.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

@implementation NSDatePickerCell

- (void) encodeWithCoder:(NSCoder *) aCoder
{ 
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder		// NSCoding protocol
{
	if((self=[super initWithCoder:coder]))
		{
		[coder decodeDoubleForKey:@"NSTimeInterval"];
		[coder decodeIntForKey:@"NSDatePickerElements"];
		[coder decodeIntForKey:@"NSDatePickerType"];
		[coder decodeObjectForKey:@"NSBackgroundColor"];
		}
	return self;
}

@end

@implementation NSDatePicker

- (NSColor *) backgroundColor; { return [_cell backgroundColor]; }
- (NSCalendar *) calendar; { return [_cell calendar]; }
- (NSDatePickerElementFlags) datePickerElements; { return [_cell datePickerElements]; }
- (NSDatePickerMode) datePickerMode; { return [_cell datePickerMode]; }
- (NSDatePickerStyle) datePickerStyle; { return [_cell datePickerStyle]; }
- (NSDate *) dateValue; { return [_cell dateValue]; }
- (id) delegate; { return [_cell delegate]; }
- (BOOL) drawsBackground; { return [_cell drawsBackground]; }
- (BOOL) isBezeled; { return [_cell isBezeled]; }
- (BOOL) isBordered; { return [_cell isBordered]; }
- (NSLocale *) locale; { return [_cell locale]; }
- (NSDate *) maxDate; { return [_cell maxDate]; }
- (NSDate *) minDate; { return [_cell minDate]; }
- (void) setBackgroundColor:(NSColor *) color; { [_cell setBackgroundColor:color]; }
- (void) setBezeled:(BOOL) flag; { [_cell setBezeled:flag]; }
- (void) setBordered:(BOOL) flag; { [_cell setBordered:flag]; }
- (void) setCalendar:(NSCalendar *) calendar; { [_cell setCalendar:calendar]; }
- (void) setDatePickerElements:(NSDatePickerElementFlags) flags; { [_cell setDatePickerElements:flags]; }
- (void) setDatePickerMode:(NSDatePickerMode) mode; { [_cell setDatePickerMode:mode]; }
- (void) setDatePickerStyle:(NSDatePickerStyle) style; { [_cell setDatePickerStyle:style]; }
- (void) setDateValue:(NSDate *) date; { [_cell setDateValue:date]; }
- (void) setDelegate:(id) obj; { [_cell setDelegate:obj]; }
- (void) setDrawsBackground:(BOOL) flag; { [_cell setDrawsBackground:flag]; }
- (void) setLocale:(NSLocale *) locale; { [_cell setLocale:locale]; }
- (void) setMaxDate:(NSDate *) date; { [_cell setMaxDate:date]; }
- (void) setMinDate:(NSDate *) date; { [_cell setMinDate:date]; }
- (void) setTextColor:(NSColor *) color; { [_cell setTextColor:color]; }
- (void) setTimeInterval:(NSTimeInterval) interval; { [_cell setTimeInterval:interval]; }
- (void) setTimeZone:(NSTimeZone *) zone; { [_cell setTimeZone:zone]; }
- (NSColor *) textColor; { return [_cell textColor]; }
- (NSTimeInterval) timeInterval; { return [_cell timeInterval]; }
- (NSTimeZone *) timeZone; { return [_cell timeZone]; }

- (void) encodeWithCoder:(NSCoder *) coder
{
}

- (id) initWithCoder:(NSCoder *) coder
{
	self=[super initWithCoder:coder];
	//
	return self;
}

@end

