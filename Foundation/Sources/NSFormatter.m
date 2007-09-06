/* 
   NSFormatter.m

   Implementation of NSFormatter text formatting class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date: January 2000

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSFormatter.h>


@implementation NSFormatter

- (NSAttributedString*) attributedStringForObjectValue:(id)anObject
								 withDefaultAttributes:(NSDictionary*)attr
{
	return nil;	// default to indicate that it is not available
}

- (NSString*) stringForObjectValue:(id)anObject		{ return SUBCLASS; }

- (NSString*) editingStringForObjectValue:(id)anObject	
{ 
	return [self stringForObjectValue: anObject]; 
}

- (BOOL) getObjectValue:(id*)anObject
			  forString:(NSString*)string
			  errorDescription:(NSString**)error	{ SUBCLASS return NO; }

- (BOOL) isPartialStringValid:(NSString*)partialString
			 newEditingString:(NSString**)newString
			 errorDescription:(NSString**)error
{
	*newString = nil;
	*error = nil;

	return YES;
}

- (BOOL) isPartialStringValid:(NSString **)partialStringPtr
		proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
			   originalString:(NSString *)origString
		originalSelectedRange:(NSRange)origSelRange
			 errorDescription:(NSString **)error;
{
	return NO;
}

- (id) copyWithZone:(NSZone *) zone											{ return SUBCLASS }
- (void) encodeWithCoder:(NSCoder*)aCoder			{ SUBCLASS }
- (id) initWithCoder:(NSCoder*)aCoder				{ return SUBCLASS }

@end
