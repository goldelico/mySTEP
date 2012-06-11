/* 
   NSAttributedString.h

   String class with attributes

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	ANOQ of the sun <anoq@vip.cybercity.dk>
   Date:	November 1997
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	07. April 2008 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSAttributedString
#define _mySTEP_H_NSAttributedString

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableString;


@interface NSAttributedString : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
	id _string;
	NSMutableArray *_attributes;
	NSMutableArray *_locations;
}

- (id) attribute:(NSString *) attributeName 
		 atIndex:(NSUInteger) index 
  effectiveRange:(NSRangePointer) aRange;
- (id) attribute:(NSString *) attributeName 
		 atIndex:(NSUInteger) index 
		 longestEffectiveRange:(NSRangePointer) aRange 
		 inRange:(NSRange)rangeLimit;
- (NSAttributedString *) attributedSubstringFromRange:(NSRange) aRange;
- (NSDictionary *) attributesAtIndex:(NSUInteger) index 	// attribute info
					 effectiveRange:(NSRangePointer) aRange;
- (NSDictionary *) attributesAtIndex:(NSUInteger) index 
			   longestEffectiveRange:(NSRangePointer) aRange 
							 inRange:(NSRange) rangeLimit;
- (id) initWithAttributedString:(NSAttributedString *) attributedString;
- (id) initWithString:(NSString *) aString;
- (id) initWithString:(NSString *) aString attributes:(NSDictionary *) attributes;
- (BOOL) isEqualToAttributedString:(NSAttributedString *) otherString;
- (NSUInteger) length;		// character info
- (NSString *) string;

@end


@interface NSMutableAttributedString : NSAttributedString

- (void) addAttribute:(NSString *) name value:(id) value range:(NSRange) aRange;
- (void) addAttributes:(NSDictionary *) attributes range:(NSRange) aRange;
- (void) appendAttributedString:(NSAttributedString *) attributedString;
- (void) beginEditing;
- (void) deleteCharactersInRange:(NSRange) aRange;
- (void) endEditing;
- (void) insertAttributedString:(NSAttributedString *) attributedString 
						atIndex:(NSUInteger) index;
- (NSMutableString *) mutableString;				// this allows to modify the attributed string; WARNING: does not yet correctly implement *all* NSString methods
- (void) removeAttribute:(NSString *) name range:(NSRange) aRange;
- (void) replaceCharactersInRange:(NSRange) aRange 
			 withAttributedString:(NSAttributedString *) attributedString;
- (void) replaceCharactersInRange:(NSRange) aRange 
					   withString:(NSString *) aString;
- (void) setAttributedString:(NSAttributedString *) attributedString;
- (void) setAttributes:(NSDictionary *) attributes range:(NSRange) aRange;

@end

#endif /* _mySTEP_H_NSAttributedString */
