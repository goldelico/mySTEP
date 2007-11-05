/* 
   NSScanner.h

   Definitions for NSScanner class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Eric Norum <eric@skatter.usask.ca>
   Date:	1996
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSScanner
#define _mySTEP_H_NSScanner

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSDictionary;
@class NSCharacterSet;
@class NSString;


@interface NSScanner : NSObject  <NSCopying>
{
	NSString *string;
	NSCharacterSet *charactersToBeSkipped;
	NSDictionary *locale;
	NSRange scanRange;
	unsigned int len;
	BOOL caseSensitive;
}

+ (id) localizedScannerWithString:(NSString *)aString;
+ (id) scannerWithString:(NSString *)aString;

- (BOOL) caseSensitive;
- (NSCharacterSet *) charactersToBeSkipped;
- (id) initWithString:(NSString *)aString;
- (BOOL) isAtEnd;
- (NSDictionary *) locale;
- (BOOL) scanCharactersFromSet:(NSCharacterSet *)aSet
					intoString:(NSString **)value;
// - (BOOL) scanDecimal:(NSDecimal *) decimalValue;	-- defined in NSDecimalNumber.h
- (BOOL) scanDouble:(double *)value;
- (BOOL) scanFloat:(float *)value;
- (BOOL) scanHexInt:(unsigned *)value;
- (BOOL) scanInt:(int *)value;
- (BOOL) scanInteger:(NSInteger *) ptr;
- (unsigned) scanLocation;
- (BOOL) scanLongLong:(long long *)value;
- (BOOL) scanString:(NSString *)string intoString:(NSString **)value;
- (BOOL) scanUpToCharactersFromSet:(NSCharacterSet *)aSet 
						intoString:(NSString **)value;
- (BOOL) scanUpToString:(NSString *)string intoString:(NSString **)value;
- (void) setCaseSensitive:(BOOL)flag;
- (void) setCharactersToBeSkipped:(NSCharacterSet *)aSet;
- (void) setLocale:(NSDictionary *) localeDictionary;
- (void) setScanLocation:(unsigned int)anIndex;
- (NSString *) string;

@end

#endif /* _mySTEP_H_NSScanner */
