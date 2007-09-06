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

@end

