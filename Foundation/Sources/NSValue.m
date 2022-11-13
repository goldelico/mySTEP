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


@interface GSValue					: NSValue	{ void *data; char *dataType; unsigned int dataSize; }		@end	// store arbitrary value
@interface GSNonretainedObjectValue : NSValue	{ id data; }		@end
@interface GSPointValue				: NSValue	{ NSPoint data; }	@end
@interface GSPointerValue			: NSValue	{ void *data; }		@end
@interface GSRectValue				: NSValue	{ NSRect data; }	@end
@interface GSSizeValue				: NSValue	{ NSSize data; }	@end
@interface GSRangeValue				: NSValue	{ NSRange data; }	@end


@implementation NSValue

+ (NSValue *) value:(const void *)value withObjCType:(const char *)type
{ // decode special variants and fall back to the universal only if no special version is found						
	if (!value || !type)
		{
    	NSLog(@"NSValue: tried to create NSValue with NULL value or type");
		return nil;
		}
	
    switch (*type) {
		case _C_CLASS:
		case _C_ID:		return [self valueWithNonretainedObject:*(id *)value];
		case _C_CHR:	return [NSNumber numberWithChar:*(char *)value];
		case _C_INT:	return [NSNumber numberWithInt:*(int *)value];
		case _C_SHT:	return [NSNumber numberWithShort:*(short *)value];
		case _C_LNG:	return [NSNumber numberWithLong:*(long *)value];
		case 'q':		return [NSNumber numberWithLongLong:*(long long *)value];
		case _C_FLT:	return [NSNumber numberWithFloat:*(float *)value];
		case _C_DBL:	return [NSNumber numberWithDouble:*(double *)value];
		case _C_UCHR: 
			return [NSNumber numberWithUnsignedChar:*(unsigned char *)value];
		case _C_USHT:	
			return [NSNumber numberWithUnsignedShort:*(unsigned short *)value];
		case _C_UINT:	
			return [NSNumber numberWithUnsignedInt:*(unsigned int *)value];
		case _C_ULNG:	
			return [NSNumber numberWithUnsignedLong:*(unsigned long *)value];
		case 'Q':		
			return [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)value];
		case _C_SEL:
		case _C_ATOM:
		case _C_PTR:
		case _C_CHARPTR:
			return [self valueWithPointer:*(void **)value];
		default:
			break;
	}
	
	if (strcmp(@encode(NSPoint), type) == 0)
		return [self valueWithPoint: *(NSPoint *)value];
	if (strcmp(@encode(NSRect), type) == 0)
    	return [self valueWithRect: *(NSRect *)value];
	if (strcmp(@encode(NSSize), type) == 0)
		return [self valueWithSize: *(NSSize *)value];
	if (strcmp(@encode(NSRange), type) == 0)
		return [self valueWithRange: *(NSRange *)value];
	
	return [[[GSValue alloc] initWithBytes:value objCType:type] autorelease];

//	[NSException raise:NSInvalidArgumentException format:@"-[NSValue value:withObjCType:] unrecognized objc type %s", type];
}

+ (NSValue *) valueWithNonretainedObject:(id)anObject
{
GSNonretainedObjectValue *v = [GSNonretainedObjectValue alloc];

    return [[v initWithBytes:&anObject objCType:@encode(void *)] autorelease];
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

// CHECKME: is this an official method?

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
- (id) copyWithZone:(NSZone *) z			{ return [self retain]; }
- (void) getValue:(void *)value				{ SUBCLASS }
- (const char *) objCType					{ SUBCLASS return 0; }
- (id) nonretainedObjectValue				{ return nil; }	// result is undefined if not available
- (void *) pointerValue						{ return NULL; }	// result is undefined if not available
- (NSRect) rectValue						{ SUBCLASS return NSZeroRect; }
- (NSSize) sizeValue						{ SUBCLASS return NSZeroSize; }
- (NSPoint) pointValue						{ SUBCLASS return NSZeroPoint;}
- (NSRange) rangeValue						{ SUBCLASS return NSMakeRange(0, 0);}

// FIXME - shouldn't we have a generic encoder and classForCoder?

- (id) initWithCoder:(NSCoder *)coder		{ SUBCLASS return nil;}
- (void) encodeWithCoder:(NSCoder *)coder	{ [super encodeWithCoder:coder]; }

@end /* NSValue */

//*****************************************************************************
//
// 		GSValue 
//
//*****************************************************************************

@implementation GSValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{ /* store a copy of type and data */
	unsigned long tsize = strlen(type);
	dataType = objc_malloc(tsize+1);
	strcpy(dataType, type);
	dataSize = objc_sizeof_type(dataType);
	data = objc_malloc(dataSize);
    memcpy(data, value, dataSize);
	return self;
}

- (void) dealloc
{
	objc_free(data);
	objc_free(dataType);
	[super dealloc];
}

- (void) getValue:(void *)value								// Accessing Data
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					format:@"Cannot copy value into NULL buffer"];
	
    memcpy(value, data, dataSize);
}

- (BOOL) isEqualToValue:(NSValue*)aValue
{
    if ([aValue isKindOfClass: [self class]])
		{
		if(dataSize != ((GSValue *) aValue) -> dataSize)
			return NO;	// different length
		return memcmp(data, ((GSValue *) aValue) -> data, dataSize) == 0;	// same contents?
		}
    return NO;
}

- (const char *) objCType					{ return dataType; }
- (void *) pointerValue						{ return data; }

- (NSString *) description
{
	return [NSString stringWithFormat: @"{pointer = %p; size = %d; type = %s; %@%@;}", data, dataSize, dataType, [NSData dataWithBytes:data length:MIN(dataSize, 30)], dataSize>30?@"...":@""];
}

- (id) initWithCoder:(NSCoder *)coder
{
	// decode type and data
	// initialize size from type
	NIMP;
    return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
	// encode type and data - size is not necessary

	const char *type = [self objCType];
	
    [super encodeWithCoder:coder];
	NIMP;
    [coder encodeValueOfObjCType:@encode(char *) at:&type];
    [coder encodeValueOfObjCType:type at:&data];
}

@end /* GSValue */

//*****************************************************************************
//
// 		GSPointerValue 
//
//*****************************************************************************

@implementation GSPointerValue

- (id) initWithBytes:(const void *)value
			objCType:(const char *)type
{
	data = *(void **) value;
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
- (id) nonretainedObjectValue				{ return data; }

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
#if 0
	NSLog(@"value=%p", value);
	NSLog(@"type=%s", type);
	NSLog(@"data=%@", data);
#endif	
	
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
#if 0
	NSLog(@"data=%@", data);
	NSLog(@"self=%@", self);
	NSLog(@"aValue=%@", aValue);
#endif	
    if ([aValue isKindOfClass: [self class]])
		{
		id adata=[aValue nonretainedObjectValue];
		// treat nil values as isEqual:
		return (data == adata) || [data isEqual:adata];
		}

    return NO;
}

- (const char *) objCType					{ return @encode(void *); }
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
