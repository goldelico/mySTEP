/* 
   NSCoder.m

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>

   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>


@implementation NSCoder

// #pragma mark generic coder can be overridden

- (NSZone *) objectZone; { return NSDefaultMallocZone(); }
- (void) setObjectZone:(NSZone *) zone; { return; }

- (unsigned int) systemVersion					{ return 104; }

- (NSInteger) versionForClassName:(NSString *) className 	
{ 
	SUBCLASS return NSNotFound; 
}

- (void) encodeArrayOfObjCType:(const char*)type
						 count:(NSUInteger)count
							at:(const void*)array
{
	unsigned	i;
	unsigned	size = objc_sizeof_type(type);
	const char	*where = array;
	IMP			imp = [self methodForSelector: @selector(encodeValueOfObjCType:at:)];
	for(i = 0; i < count; i++, where += size)
		(*imp)(self, @selector(encodeValueOfObjCType:at:), type, where);
}

- (void) decodeArrayOfObjCType:(const char*)type
						 count:(NSUInteger)count
							at:(void*)address
{
	unsigned	i;
	unsigned	size = objc_sizeof_type(type);
	char		*where = address;
	IMP			imp = [self methodForSelector: @selector(decodeValueOfObjCType:at:)];	
	for(i = 0; i < count; i++, where += size)
		(*imp)(self, @selector(decodeValueOfObjCType:at:), type, where);
}

- (void) encodeValuesOfObjCTypes:(const char*)types, ...
{
	va_list ap;
	IMP imp = [self methodForSelector:@selector(encodeValueOfObjCType:at:)];
	
    va_start(ap, types);
    for(; types && *types; types = objc_skip_typespec(types))
        (*imp)(self, @selector(encodeValueOfObjCType:at:),
			   types, va_arg(ap, void*));
    va_end(ap);
}

- (void) decodeValuesOfObjCTypes:(const char*)types, ...
{
	va_list ap;
	IMP imp = [self methodForSelector:@selector(decodeValueOfObjCType:at:)];
	
    va_start(ap, types);
    for(;types && *types; types = objc_skip_typespec(types))
        (*imp)(self, @selector(decodeValueOfObjCType:at:),
			   types, va_arg(ap, void*));
    va_end(ap);
}

- (void) encodeBycopyObject:(id)aObject			{ [self encodeObject:aObject];}
- (void) encodeByrefObject:(id)aObject			{ [self encodeObject:aObject];}
- (void) encodeConditionalObject:(id)aObject	{ [self encodeObject:aObject];}
- (void) encodeNXObject:(id) obj;				{ [self encodeObject:obj]; }
- (void) encodeObject:(id)anObject				{ [self encodeValueOfObjCType:@encode(id) at:&anObject]; }
- (void) encodePropertyList:(id)aPropertyList	{ [self encodeObject:aPropertyList]; }
- (void) encodeRootObject:(id)rootObject		{ [self encodeObject:rootObject]; }

- (id) decodeNXObject;							{ return [self decodeObject]; }
- (id) decodeObject								{ id obj; [self decodeValueOfObjCType:@encode(id) at:&obj]; return obj; }
- (id) decodePropertyList						{ return [self decodeObject]; }

- (void) encodePoint:(NSPoint)point
{
    [self encodeValueOfObjCType:@encode(NSPoint) at:&point];
}

- (void) encodeSize:(NSSize)size
{
    [self encodeValueOfObjCType:@encode(NSSize) at:&size];
}

- (void) encodeRect:(NSRect)rect
{
    [self encodeValueOfObjCType:@encode(NSRect) at:&rect];
}

- (NSPoint) decodePoint
{
	NSPoint point;
	
    [self decodeValueOfObjCType:@encode(NSPoint) at:&point];
	
    return point;
}

- (NSSize) decodeSize
{
	NSSize size;
	
    [self decodeValueOfObjCType:@encode(NSSize) at:&size];
	
    return size;
}

- (NSRect) decodeRect
{
	NSRect rect;
	
    [self decodeValueOfObjCType:@encode(NSRect) at:&rect];
	
    return rect;
}

// #pragma mark core encoding

- (void) encodeBytes:(const void *)address length:(NSUInteger)numBytes;
{
	// could encode as NSData object
	SUBCLASS;
}

- (void) encodeDataObject:(NSData *)data			{ SUBCLASS; }

- (void) encodeValueOfObjCType:(const char*)type
							at:(const void*)address			{ SUBCLASS }

// #pragma mark core decoding

- (void *) decodeBytesWithReturnedLength:(NSUInteger *)numBytes;
{
	// could decode NSData object and extract data
	SUBCLASS;
	return NULL;
}

- (NSData *) decodeDataObject					{ return SUBCLASS; }

- (void) decodeValueOfObjCType:(const char*)type
							at:(void*)address		{ SUBCLASS }

// #pragma mark keyed coder must overrride

- (BOOL) allowsKeyedCoding; { return NO; }	// default

// #pragma mark keyed encoding must be implemented in subclass if available

- (void) encodeSize:(NSSize) size forKey:(NSString *) key; { SUBCLASS }
- (void) encodeRect:(NSRect) rect forKey:(NSString *) key; { SUBCLASS }
- (void) encodePoint:(NSPoint) point forKey:(NSString *) key; { SUBCLASS }
- (void) encodeObject:(id) object forKey:(NSString *) key; { SUBCLASS }
- (void) encodeInt:(int) value forKey:(NSString *) key; { SUBCLASS }
- (void) encodeInteger:(NSInteger) value forKey:(NSString *) key; { SUBCLASS }
- (void) encodeInt64:(long long) value forKey:(NSString *) key; { SUBCLASS }
- (void) encodeInt32:(int32_t) value forKey:(NSString *) key; { SUBCLASS }
- (void) encodeFloat:(float) value forKey:(NSString *) key; { SUBCLASS }
- (void) encodeDouble:(double) value forKey:(NSString *) key; { SUBCLASS }
- (void) encodeConditionalObject:(id) object forKey:(NSString *) key; { SUBCLASS }
- (void) encodeBytes:(const unsigned char *) bytes length:(NSUInteger) len forKey:(NSString *) key; { SUBCLASS }
- (void) encodeBool:(BOOL) value forKey:(NSString *) key; { SUBCLASS }

// #pragma mark keyed decoding must be implemented in subclass if available

- (NSSize) decodeSizeForKey:(NSString *) key; { SUBCLASS; return NSZeroSize; }
- (NSRect) decodeRectForKey:(NSString *) key; { SUBCLASS; return NSZeroRect; }
- (NSPoint) decodePointForKey:(NSString *) key; { SUBCLASS; return NSZeroPoint; }
- (id) decodeObjectForKey:(NSString *) key; { return SUBCLASS; }
- (int) decodeIntForKey:(NSString *) key; { SUBCLASS; return 0; }
- (NSInteger) decodeIntegerForKey:(NSString *) key; { SUBCLASS; return 0; }
- (long long) decodeInt64ForKey:(NSString *) key; { SUBCLASS; return 0; }
- (int32_t) decodeInt32ForKey:(NSString *) key; { SUBCLASS; return 0; }
- (float) decodeFloatForKey:(NSString *) key; { SUBCLASS; return 0.0; }
- (double) decodeDoubleForKey:(NSString *) key; { SUBCLASS; return 0.0; }
- (const unsigned char *) decodeBytesForKey:(NSString *) key returnedLength:(NSUInteger *) num; { SUBCLASS; return NULL; }
- (BOOL) decodeBoolForKey:(NSString *) key; { SUBCLASS; return NO; }
- (BOOL) containsValueForKey:(NSString *) key; { SUBCLASS; return NO; }

@end /* NSCoder */
