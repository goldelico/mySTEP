/* 
   NSSecureTextField.m

   Secure Text field control class for data entry

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:    Dec 1999
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#import <AppKit/NSSecureTextField.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>

#import "NSAppKitPrivate.h"

//*****************************************************************************
//
// 		NSSecureTextFieldCell 
//
//*****************************************************************************

@implementation NSSecureTextFieldCell

- (id) initTextCell:(NSString *)aString
{
	_c.secure = YES;
	return [super initTextCell:aString];
}

- (NSText*) setUpFieldEditorAttributes:(NSText*)textObject
{
	[textObject _setSecure:YES];
	return [super setUpFieldEditorAttributes:textObject];
}

- (void) endEditing:(NSText*)textObject
{
	[super endEditing:textObject];
	[textObject _setSecure:NO];
}

// overwrite drawWithFrame:inView: to show Shift-Lock status

@end /* NSSecureTextFieldCell */

//*****************************************************************************
//
// 		NSSecureTextField 
//
//*****************************************************************************

@implementation NSSecureTextField

+ (Class) cellClass
{ 
	return [NSSecureTextFieldCell class]; 
}

+ (void) setCellClass:(Class)class
{ 
	[NSException raise:NSInvalidArgumentException
				 format:@"NSSecureTextField only uses NSSecureTextFieldCells"];
}

- (id) initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if(self)
		{
//		[self setCell: [[NSSecureTextFieldCell new] autorelease]];	// FIXME: should be redundant!
		[_cell setFont:[NSFont userFixedPitchFontOfSize:0]];
		}
	return self;
}

- (void) flagsChanged:(NSEvent *)event
{
	// call private method to track shift lock
	// or make cell being redrawn
	NSLog(@"flags changed for NSSecureTextField");
	// should we also forward to nextResponder???
}

@end /* NSSecureTextField */
