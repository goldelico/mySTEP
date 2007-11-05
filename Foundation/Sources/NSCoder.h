/* 
   NSCoder.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSCoder
#define _mySTEP_H_NSCoder

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSData;

@interface NSCoder : NSObject

- (BOOL) allowsKeyedCoding;
- (BOOL) containsValueForKey:(NSString *)key;
- (void) decodeArrayOfObjCType:(const char*)types
						count:(unsigned)count
						   at:(void*)address;
- (BOOL) decodeBoolForKey:(NSString *)key;
- (const unsigned char *) decodeBytesForKey:(NSString *)key
							 returnedLength:(unsigned *)lengthp;
- (void *) decodeBytesWithReturnedLength:(unsigned *)numBytes;
- (NSData *) decodeDataObject;
- (double) decodeDoubleForKey:(NSString *)key;
- (float) decodeFloatForKey:(NSString *)key;
- (long) decodeInt32ForKey:(NSString *)key;
- (long long) decodeInt64ForKey:(NSString *)key;
- (int) decodeIntForKey:(NSString *)key;
- (NSInteger) decodeIntegerForKey:(NSString *)key;
- (id) decodeNXObject;
- (id) decodeObject;
- (id) decodeObjectForKey:(NSString *)key;
- (NSPoint) decodePoint;
- (NSPoint) decodePointForKey:(NSString *)key;
- (id) decodePropertyList;
- (NSRect) decodeRect;
- (NSRect) decodeRectForKey:(NSString *)key;
- (NSSize) decodeSize;
- (NSSize) decodeSizeForKey:(NSString *)key;
- (void) decodeValueOfObjCType:(const char*)type at:(void*)address;
- (void) decodeValuesOfObjCTypes:(const char*)types, ...;
- (void) encodeArrayOfObjCType:(const char*)types	
						 count:(unsigned int)count
							at:(const void*)array;
- (void) encodeBool:(BOOL)val forKey:(NSString *)key;
- (void) encodeBycopyObject:(id)anObject;
- (void) encodeByrefObject:(id)anObject;
- (void) encodeBytes:(const void *)address length:(unsigned)numBytes;
- (void) encodeBytes:(const unsigned char *)bytesp length:(unsigned)lenv forKey:(NSString *)key;
- (void) encodeConditionalObject:(id)anObject;
- (void) encodeConditionalObject:(id)obj forKey:(NSString *)key;
- (void) encodeDataObject:(NSData*)data;
- (void) encodeDouble:(double)val forKey:(NSString *)key;
- (void) encodeFloat:(float)val forKey:(NSString *)key;
- (void) encodeInt32:(long)val forKey:(NSString *)key;
- (void) encodeInt64:(long long)intv forKey:(NSString *)key;
- (void) encodeInt:(int)intv forKey:(NSString *)key;
- (void) encodeInteger:(NSInteger)intv forKey:(NSString *)key;
- (void) encodeNXObject:(id)object;
- (void) encodeObject:(id)anObject;
- (void) encodeObject:(id)val forKey:(NSString *)key;
- (void) encodePoint:(NSPoint)point;
- (void) encodePoint:(NSPoint)point forKey:(NSString *)key;
- (void) encodePropertyList:(id)aPropertyList;
- (void) encodeRect:(NSRect)rect;
- (void) encodeRect:(NSRect)rect forKey:(NSString *)key;
- (void) encodeRootObject:(id)rootObject;
- (void) encodeSize:(NSSize)size;
- (void) encodeSize:(NSSize)size forKey:(NSString *)key;
- (void) encodeValueOfObjCType:(const char*)type at:(const void*)address;
- (void) encodeValuesOfObjCTypes:(const char*)types, ...;
- (NSZone *) objectZone;
- (void) setObjectZone:(NSZone *)zone;
- (unsigned int) systemVersion;
- (unsigned int) versionForClassName:(NSString*)className;

@end

@interface NSObject (NSCoder)
- (id) awakeAfterUsingCoder:(NSCoder *) aDecoder;
- (Class) classForCoder;
- (id) replacementObjectForCoder:(NSCoder*) anEncoder;
@end

#endif /* _mySTEP_H_NSCoder */
