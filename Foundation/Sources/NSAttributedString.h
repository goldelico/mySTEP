/* 
   NSAttributedString.h

   String class with attributes

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	ANOQ of the sun <anoq@vip.cybercity.dk>
   Date:	November 1997
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
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


@interface NSAttributedString : NSObject <NSCoding,NSCopying,NSMutableCopying>
{
	id _string;
	NSMutableArray *_attributes;
	NSMutableArray *_locations;
}

- (id) attribute:(NSString *)attributeName 
		 atIndex:(unsigned int)index 
  effectiveRange:(NSRange *)aRange;
- (id) attribute:(NSString *)attributeName 
		 atIndex:(unsigned int)index 
		 longestEffectiveRange:(NSRange *)aRange 
		 inRange:(NSRange)rangeLimit;
- (NSAttributedString *) attributedSubstringFromRange:(NSRange)aRange;
- (NSDictionary*) attributesAtIndex:(unsigned int)index 	// attribute info
					 effectiveRange:(NSRange *)aRange;
- (NSDictionary*) attributesAtIndex:(unsigned int)index 
			  longestEffectiveRange:(NSRange *)aRange 
							inRange:(NSRange)rangeLimit;
- (id) initWithAttributedString:(NSAttributedString*)attributedString;
- (id) initWithString:(NSString*)aString;
- (id) initWithString:(NSString*)aString attributes:(NSDictionary*)attributes;
- (BOOL) isEqualToAttributedString:(NSAttributedString *)otherString;
- (unsigned int) length;		// character info
- (NSString *) string;

@end


@interface NSMutableAttributedString : NSAttributedString

- (void) addAttribute:(NSString *)name value:(id)value range:(NSRange)aRange;
- (void) addAttributes:(NSDictionary *)attributes range:(NSRange)aRange;
- (void) appendAttributedString:(NSAttributedString *)attributedString;
- (void) beginEditing;								// Group changes
- (void) deleteCharactersInRange:(NSRange)aRange;	// Change chars
- (void) endEditing;
- (void) insertAttributedString:(NSAttributedString *)attributedString 
						atIndex:(unsigned int)index;
- (NSMutableString *) mutableString;				// Retrieve char info
- (void) removeAttribute:(NSString *)name range:(NSRange)aRange;
- (void) replaceCharactersInRange:(NSRange)aRange 
			 withAttributedString:(NSAttributedString *)attributedString;
- (void) replaceCharactersInRange:(NSRange)aRange 
					   withString:(NSString *)aString;
- (void) setAttributedString:(NSAttributedString *)attributedString;
- (void) setAttributes:(NSDictionary *)attributes range:(NSRange)aRange;

@end

#endif /* _mySTEP_H_NSAttributedString */
