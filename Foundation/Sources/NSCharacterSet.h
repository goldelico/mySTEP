/* 
   NSCharacterSet.h

   Interface for NSCharacterSet

   Copyright (C) 1995 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSCharacterSet
#define _mySTEP_H_NSCharacterSet

#import <Foundation/NSString.h>

typedef unsigned long UTF32Char;

@class NSData;

@interface NSCharacterSet : NSObject  <NSCoding, NSCopying, NSMutableCopying>

+ (id) alphanumericCharacterSet;		// standard character sets
+ (id) capitalizedLetterCharacterSet;
+ (id) characterSetWithBitmapRepresentation:(NSData *)data;
+ (id) characterSetWithCharactersInString:(NSString *)aString;
+ (id) characterSetWithContentsOfFile:(NSString*)file;
+ (id) characterSetWithRange:(NSRange)aRange;
+ (id) controlCharacterSet;
+ (id) decimalDigitCharacterSet;
+ (id) decomposableCharacterSet;
+ (id) illegalCharacterSet;
+ (id) letterCharacterSet;
+ (id) lowercaseLetterCharacterSet;
+ (id) newlineCharacterSet;
+ (id) nonBaseCharacterSet;
+ (id) punctuationCharacterSet;
+ (id) symbolCharacterSet;
+ (id) uppercaseLetterCharacterSet;
+ (id) whitespaceAndNewlineCharacterSet;
+ (id) whitespaceCharacterSet;

// custom character sets

- (NSData *) bitmapRepresentation;
- (BOOL) characterIsMember:(unichar)aCharacter;
- (BOOL) hasMemberInPlane:(unsigned char) plane;
- (NSCharacterSet *) invertedSet;
- (BOOL) isSupersetOfSet:(NSCharacterSet *) other;
- (BOOL) longCharacterIsMember:(UTF32Char) aCharacter;

@end


@interface NSMutableCharacterSet : NSCharacterSet <NSCopying, NSMutableCopying>
@end

@interface NSMutableCharacterSet (NSExtendedCharacterSet)

- (void) addCharactersInRange:(NSRange)aRange;
- (void) addCharactersInString:(NSString *)aString;
- (void) formIntersectionWithCharacterSet:(NSCharacterSet *)otherSet;
- (void) formUnionWithCharacterSet:(NSCharacterSet *)otherSet;
- (void) invert;
- (void) removeCharactersInRange:(NSRange)aRange;
- (void) removeCharactersInString:(NSString *)aString;

@end

#define UNICODE_SIZE	65536
#define BITMAP_SIZE		UNICODE_SIZE/8

#ifndef SETBIT
#define SETBIT(a,i)     ((a) |= 1<<(i))
#define CLRBIT(a,i)     ((a) &= ~(1<<(i)))
#define ISSET(a,i)      ((((a) & (1<<(i)))) > 0) ? YES : NO;
#endif

#endif /* _mySTEP_H_NSCharacterSet */
