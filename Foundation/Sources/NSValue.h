/* 
   NSValue.h

   Interface to NSNumber and NSValue

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSValue
#define _mySTEP_H_NSValue

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSDictionary;

@interface NSValue : NSObject  <NSCopying, NSCoding>

+ (NSValue *) value:(const void *) value
	   withObjCType:(const char *) type;
+ (NSValue *) valueWithBytes:(const void *) value
					objCType:(const char *) type;
+ (NSValue *) valueWithNonretainedObject:(id) anObject;
+ (NSValue *) valueWithPoint:(NSPoint) point;
+ (NSValue *) valueWithPointer:(const void *) pointer;
+ (NSValue *) valueWithRange:(NSRange) rect;
+ (NSValue *) valueWithRect:(NSRect) rect;
+ (NSValue *) valueWithSize:(NSSize) size;

- (void) getValue:(void *) value;
- (id) initWithBytes:(const void *) value
			objCType:(const char *) type;
- (BOOL) isEqualToValue:(NSValue *) other;
- (id) nonretainedObjectValue;														 
- (const char *) objCType;
- (void *) pointerValue;
- (NSPoint) pointValue;
- (NSRange) rangeValue;
- (NSRect) rectValue;
- (NSSize) sizeValue;

@end


@interface NSNumber : NSValue  <NSCopying, NSCoding>

+ (NSNumber *) numberWithBool:(BOOL) value; 
+ (NSNumber *) numberWithChar:(char) value;
+ (NSNumber *) numberWithDouble:(double) value;
+ (NSNumber *) numberWithFloat:(float) value;
+ (NSNumber *) numberWithInt:(int) value;
+ (NSNumber *) numberWithLong:(long) value;
+ (NSNumber *) numberWithLongLong:(long long) value;
+ (NSNumber *) numberWithShort:(short) value;
+ (NSNumber *) numberWithUnsignedChar:(unsigned char) value;
+ (NSNumber *) numberWithUnsignedInt:(unsigned int) value;
+ (NSNumber *) numberWithUnsignedLong:(unsigned long) value;
+ (NSNumber *) numberWithUnsignedLongLong:(unsigned long long) value;
+ (NSNumber *) numberWithUnsignedShort:(unsigned short) value;
+ (NSNumber *) numberWithInteger:(NSInteger) value;
+ (NSNumber *) numberWithUnsignedInteger:(NSUInteger) value;

- (BOOL) boolValue;
- (char) charValue;
- (NSComparisonResult) compare:(NSNumber *) otherNumber;
- (NSString *) descriptionWithLocale:(id) locale;
- (double) doubleValue;
- (float) floatValue;
- (id) initWithBool:(BOOL) value;
- (id) initWithChar:(char) value;
- (id) initWithDouble:(double) value;
- (id) initWithFloat:(float) value;
- (id) initWithInt:(int) value;
- (id) initWithInteger:(NSInteger) value;
- (id) initWithLong:(long) value;
- (id) initWithLongLong:(long long) value;
- (id) initWithShort:(short) value;
- (id) initWithUnsignedChar:(unsigned char) value;
- (id) initWithUnsignedInt:(unsigned int) value;
- (id) initWithUnsignedInteger:(NSUInteger) value;
- (id) initWithUnsignedLong:(unsigned long) value;
- (id) initWithUnsignedLongLong:(unsigned long long) value;
- (id) initWithUnsignedShort:(unsigned short) value;
- (int) intValue;
- (NSInteger) integerValue;
- (BOOL) isEqualToNumber:(NSNumber *) otherNumber;
- (long long) longLongValue;
- (long) longValue;
- (short) shortValue;
- (NSString *) stringValue;
- (unsigned char) unsignedCharValue;
- (unsigned int) unsignedIntValue;
- (NSUInteger) unsignedIntegerValue;
- (unsigned long long) unsignedLongLongValue;
- (unsigned long) unsignedLongValue;
- (unsigned short) unsignedShortValue;

@end

#endif /* _mySTEP_H_NSValue */
