/* 
   NSFormatter.h

   Interface to text formatting class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date: January 2000

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   Fabian Spillner, May 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSFormatter
#define _mySTEP_H_NSFormatter

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSAttributedString;
@class NSDictionary;

@interface NSFormatter : NSObject <NSCopying, NSCoding>

- (NSAttributedString *) attributedStringForObjectValue:(id) anObject
								  withDefaultAttributes:(NSDictionary *) attr;
- (NSString *) editingStringForObjectValue:(id) anObject;
- (BOOL) getObjectValue:(id *) anObject
			  forString:(NSString *) string
	   errorDescription:(NSString **) error;
- (BOOL) isPartialStringValid:(NSString *) partialString
			 newEditingString:(NSString **) newString
			 errorDescription:(NSString **) error;
- (BOOL) isPartialStringValid:(NSString **) partialStringPtr
		proposedSelectedRange:(NSRangePointer) proposedSelRangePtr
			   originalString:(NSString *) origString
		originalSelectedRange:(NSRange) origSelRange
			 errorDescription:(NSString **) error;
- (NSString *) stringForObjectValue:(id) anObject;

@end

#endif /* _mySTEP_H_NSFormatter */
