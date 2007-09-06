/* 
   NSValue.m

   Object encapsulation for C types.

   Copyright (C) 1993, 1994, 1996 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	Mar 1995

   Author:	H.N.Schaller - GSRangeValue added
   Date:	Jan 2006

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSValue.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>


@interface GSNonretainedObjectValue : NSValue	{ id data; }		@end
@interface GSPointValue				: NSValue	{ NSPoint data; }	@end
@interface GSPointerValue			: NSValue	{ void *data; }		@end
@interface GSRectValue				: NSValue	{ NSRect data; }	@end
@interface GSSizeValue				: NSValue	{ NSSize data; }	@end
@interface GSRangeValue				: NSValue	{ NSRange data; }	@end


@implementation NSValue

+ (NSValue *) value:(const void *)value withObjCType:(const char *)type
{										
	if (!value || !type)
		{
    	NSLog(@"Tried to create NSValue with NULL value or type");
		return nil;
		}

	if (strcmp(@encode(id), type) == 0)
    	return [self valueWithNonretainedObject:(id)value];
	if (strcmp(@encode(NSPoint), type) == 0)
		return [self valueWithPoint: *(NSPoint *)value];
	if (strcmp(@encode(void *), type) == 0)
    	return [self valueWithPointer:value];
	if (strcmp(@encode(NSRect), type) == 0)
    	return [self valueWithRect: *(NSRect *)value];
	if (strcmp(@encode(NSSize), type) == 0)
		return [self valueWithSize: *(NSSize *)value];
    
    return [NSNumber value:value withObjCType:type];
}
		
+ (NSValue *) valueWithNonretainedObject:(id)anObject
{
GSNonretainedObjectValue *v = [GSNonretainedObjectValue alloc];

    return [[v initWithBytes:&anObject objCType:@encode(id)] autorelease];
}
	
+ (NSValue *) valueWithPoint:(NSPoint)point
{
GSPointValue *v = [GSPointValue alloc];

    return [[v initWithBytes:&point objCType:@encode(NSPoint)] autorelease];
}
 
+ (NSValue *) valueWithPointer:(const void *)pointer
{
GSPointerValue *v = [GSPointerValue alloc];

    return [[v initWithBytes:&pointer objCType:@encode(void *)] autorelease];
}

+ (NSValue *) valueWithRect:(NSRect)rect
{
GSRectValue *v = [GSRectValue alloc];

    return [[v initWithBytes:&rect objCType:@encode(NSRect)] autorelease];
}

+ (NSValue *) valueWithSize:(NSSize)size
{
GSSizeValue *v = [GSSizeValue alloc];

    return [[v initWithBytes:&size objCType:@encode(NSSize)] autorelease];
}

+ (NSValue *) valueWithRange:(NSRange)range
{
	GSRangeValue *v = [GSRangeValue alloc];
	return [[v initWithBytes:&range objCType:@encode(NSRange)] autorelease];
}

+ (id) valueFromString:(NSString *)string
{
NSDictionary *dict = [string propertyList];

	if (dict)
		{
		if ([dict objectForKey: @"width"])
			{
			NSSize size = {[[dict objectForKey:@"width"] floatValue],
							[[dict objectForKey: @"height"] floatValue]};

			if ([dict objectForKey: @"x"])
				{
				NSRect rect = { {[[dict objectForKey: @"x"] floatValue],
					[[dict objectForKey: @"y"] floatValue], },
					{ size.width, size.height } };
		
				return [NSValue valueWithRect: rect];
				}

			return [NSValue valueWithSize: size];
			}
		else 
			if ([dict objectForKey: @"x"])
				{
				NSPoint p = {[[dict objectForKey: @"x"] floatValue],
							[[dict objectForKey: @"y"] floatValue]};

				return [NSValue valueWithPoint: p];
		}		}

	return nil;
}

+ (NSValue *) valueWithBytes:(const void *)value 
				objCType:(const char *)type
{										
    return [self value:value withObjCType:type];
}

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type		{ SUBCLASS return nil; }

- (BOOL) isEqual:(id)other
{
    if ([other isKindOfClass: [self class]])
		return [self isEqualToValue: other];

    return NO;
}

- (BOOL) isEqualToValue:(NSValue*)other		{ SUBCLASS return NO; }
- (id) copyWithZone:(NSZone *) z									{ return [self retain]; }
- (void) getValue:(void *)value				{ SUBCLASS }
- (const char *) objCType					{ SUBCLASS return 0; }
- (id) nonretainedObjectValue				{ SUBCLASS return nil; }
- (void *) pointerValue						{ SUBCLASS return 0; }
- (NSRect) rectValue						{ SUBCLASS return NSZeroRect; }
- (NSSize) sizeValue						{ SUBCLASS return NSZeroSize; }
- (NSPoint) pointValue						{ SUBCLASS return NSZeroPoint;}
- (NSRange) rangeValue						{ SUBCLASS return NSMakeRange(0, 0);}
- (id) initWithCoder:(NSCoder *)coder		{ SUBCLASS return nil;}
- (void) encodeWithCoder:(NSCoder *)coder	{ [super encodeWithCoder:coder]; }

@end /* NSValue */

//*****************************************************************************
//
// 		GSPointerValue 
//
//*****************************************************************************

@implementation GSPointerValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
    memcpy(&data, value, objc_sizeof_type(type));

	return self;
}

- (void) getValue:(void *)value								// Accessing Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL buffer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]) );
}

- (BOOL) isEqualToValue:(NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]]) 
		return (data == [aValue pointerValue]) ? YES : NO;

    return NO;
}

- (const char *) objCType					{ return @encode(void *); }
- (void *) pointerValue						{ return data; }

- (NSString *) description
{
	return [NSString stringWithFormat: @"{pointer = %p;}", data];
}

- (id) initWithCoder:(NSCoder *)coder
{
	[coder decodeValueOfObjCType: @encode(void *) at: &data];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
const char *type = [self objCType];

    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

@end /* GSPointerValue */

//*****************************************************************************
//
// 		GSNonretainedObjectValue 
//
//*****************************************************************************

@implementation GSNonretainedObjectValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
    memcpy(&data, value, objc_sizeof_type(type));

	return self;
}

- (void) getValue:(void *)value								// Accessing Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL buffer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]) );
}

- (BOOL) isEqualToValue:(NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]]) 
		return [data isEqual: [aValue nonretainedObjectValue]];

    return NO;
}

- (const char *) objCType					{ return @encode(id); }
- (id) nonretainedObjectValue				{ return data; }

- (NSString *) description
{
	return [NSString stringWithFormat: @"{object = %@;}", [data description]];
}

- (void) encodeWithCoder:(NSCoder *)coder						// NSCoding
{
const char *type = [self objCType];

    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

- (id) initWithCoder:(NSCoder *)coder
{
	[coder decodeValueOfObjCType:@encode(id) at:&data];
    return self;
}

@end /* GSNonretainedObjectValue */

//*****************************************************************************
//
// 		GSPointValue 
//
//*****************************************************************************

@implementation GSPointValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
    memcpy(&data, value, objc_sizeof_type(type));

	return self;
}

- (void) getValue:(void *)value								// Accessing Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL buffer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]) );
}

- (BOOL) isEqualToValue:(NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]]) 
		return NSEqualPoints(data, [aValue pointValue]);

    return NO;
}

- (const char *) objCType					{ return @encode(NSPoint); }
- (NSPoint) pointValue						{ return data; }
- (NSString *) description					{ return NSStringFromPoint(data); }

- (void) encodeWithCoder:(NSCoder *)coder
{
const char *type = [self objCType];

    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

- (id) initWithCoder:(NSCoder *)coder
{
	[coder decodeValueOfObjCType: @encode(NSPoint) at: &data];
    return self;
}

@end /* GSPointValue */

//*****************************************************************************
//
// 		GSRectValue 
//
//*****************************************************************************

@implementation GSRectValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
    memcpy(&data, value, objc_sizeof_type(type));

	return self;
}

- (void) getValue:(void *)value								// Accessing Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL buffer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]) );
}

- (BOOL) isEqualToValue: (NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]]) 
		return NSEqualRects(data, [aValue rectValue]);

    return NO;
}

- (const char *) objCType					{ return @encode(NSRect); }
- (NSRect) rectValue						{ return data; }
- (NSString *) description					{ return NSStringFromRect(data); }

- (void) encodeWithCoder:(NSCoder *)coder
{
const char *type = [self objCType];

    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

- (id) initWithCoder:(NSCoder *)coder
{
	[coder decodeValueOfObjCType: @encode(NSRect) at: &data];
    return self;
}

@end /* GSRectValue */

//*****************************************************************************
//
// 		GSSizeValue 
//
//*****************************************************************************

@implementation GSSizeValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
    memcpy(&data, value, objc_sizeof_type(type));

	return self;
}

- (void) getValue:(void *)value								// Access Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL buffer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]) );
}

- (BOOL) isEqualToValue: (NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]]) 
		return NSEqualSizes(data, [aValue sizeValue]);

    return NO;
}

- (const char *) objCType					{ return @encode(NSSize); }
- (NSSize) sizeValue						{ return data; }
- (NSString *) description					{ return NSStringFromSize(data); }

- (void) encodeWithCoder:(NSCoder *)coder
{
const char *type = [self objCType];

    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

- (id) initWithCoder:(NSCoder *)coder
{
	[coder decodeValueOfObjCType: @encode(NSSize) at: &data];
    return self;
}

@end /* GSSizeValue */

//*****************************************************************************
//
// 		GSRangeValue 
//
//*****************************************************************************

@implementation GSRangeValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
    memcpy(&data, value, objc_sizeof_type(type));
	
	return self;
}

- (void) getValue:(void *)value								// Access Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					format:@"Cannot copy value into NULL buffer"];
	
    memcpy(value, &data, objc_sizeof_type([self objCType]) );
}

- (BOOL) isEqualToValue: (NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]]) 
		return NSEqualRanges(data, [aValue rangeValue]);
	
    return NO;
}

- (const char *) objCType					{ return @encode(NSRange); }
- (NSRange) rangeValue						{ return data; }
- (NSString *) description					{ return NSStringFromRange(data); }

- (void) encodeWithCoder:(NSCoder *)coder
{
	const char *type = [self objCType];
	
    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

- (id) initWithCoder:(NSCoder *)coder
{
	[coder decodeValueOfObjCType: @encode(NSRange) at: &data];
    return self;
}

@end /* GSRangeValue */
