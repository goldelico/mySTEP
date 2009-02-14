/* 
   NSNumber.m

   Object encapsulation of numbers
    
   Copyright (C) 1993, 1994, 1996 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	Mar 1995
   Rewrite:	Felipe A. Rodriguez <farz@mindspring.com>
   Date:	March 1999

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArchiver.h>

#define PRIMITIVE_ACCESSOR_METHODS_() \
	- (BOOL) boolValue					  { return data != NO; } \
	- (char) charValue					  { return (char)data; } \
	- (double) doubleValue				  { return (double)data; } \
	- (float) floatValue				  { return (float)data; } \
	- (int) intValue					  { return (int)data; } \
	- (long long) longLongValue			  { return (long long)data; } \
	- (long) longValue					  { return (long)data; } \
	- (short) shortValue				  { return (short)data; } \
	- (unsigned char) unsignedCharValue	  { return (unsigned char)data; } \
	- (unsigned int) unsignedIntValue	  { return (unsigned int)data; } \
	- (unsigned long) unsignedLongValue   { return (unsigned long)data; } \
	- (unsigned short) unsignedShortValue { return (unsigned short)data; } \
	- (unsigned long long) unsignedLongLongValue \
										  { return (unsigned long long)data; }

#define PRIVATE_NUMBER_CLASS_INTERFACE_(class_name, data_type) \
	@interface class_name : GSConcreteNumber	{ data_type data; } @end


@interface NSNumber (Private)

- (int) _nextOrder;
- (int) _typeOrder;
- (NSComparisonResult) _promotedCompare:(NSNumber*)other;

@end

@interface GSConcreteNumber : NSNumber
@end

PRIVATE_NUMBER_CLASS_INTERFACE_(GSBoolNumber,BOOL)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSIntNumber,int)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSCharNumber,char)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSShortNumber,short)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSLongNumber,long)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSLongLongNumber,long long)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSFloatNumber,float)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSDoubleNumber,double)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSUIntNumber,unsigned int)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSUCharNumber,unsigned char)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSUShortNumber,unsigned short)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSULongNumber,unsigned long)
PRIVATE_NUMBER_CLASS_INTERFACE_(GSULongLongNumber,unsigned long long)


@implementation GSConcreteNumber

+ (id) alloc;
{ // we can really alloc concrete numbers
#if 0
	NSLog(@"%@ alloc", NSStringFromClass([self class]));
#endif
	return NSAllocateObject(self, 0, NSDefaultMallocZone());
}

- (void) dealloc
{
	NSDeallocateObject(self);
	return;
	[super dealloc] /* make the compiler happy */;
}

@end

@implementation NSNumber

// FIXME:
// this simplifies [[NSNumber alloc] initWith...] so that initWith does not need to release if it returns a private instance
// but this also introduces a severe risk: [[NSNumber alloc] release] breaks everything

static NSNumber *__sharedNum = nil;

+ (void) initialize
{
	if (!__sharedNum && (self == [NSNumber class]))
		__sharedNum = (NSNumber *)NSAllocateObject(self, 0, NSDefaultMallocZone());
}

+ (id) allocWithZone: (NSZone*)z
{ // singleton
#if 0
	NSLog(@"%@ allocWithZone", NSStringFromClass([self class]));
#endif
	return __sharedNum;
}

+ (id) alloc;
{ // speed up singleton
#if 0
	NSLog(@"%@ alloc", NSStringFromClass([self class]));
#endif
	return __sharedNum;
}

- (void) dealloc
{
	return;
	[super dealloc] /* make the compiler happy */;
}

+ (NSValue *) value:(const void *)value withObjCType:(const char *)type
{
    switch (*type)
		{
		case _C_CHR:	return [self numberWithChar:*(char *)value];
		case _C_INT:	return [self numberWithInt:*(int *)value]; 
		case _C_SHT:	return [self numberWithShort:*(short *)value]; 
		case _C_LNG:	return [self numberWithLong:*(long *)value]; 
		case 'q':		return [self numberWithLongLong:*(long long *)value];
		case _C_FLT:	return [self numberWithFloat:*(float *)value]; 
		case _C_DBL:	return [self numberWithDouble:*(double *)value]; 
		case _C_UCHR: 
			return [self numberWithUnsignedChar:*(unsigned char *)value]; 
		case _C_USHT:	
			return [self numberWithUnsignedShort:*(unsigned short *)value];
		case _C_UINT:	
			return [self numberWithUnsignedInt:*(unsigned int *)value]; 
		case _C_ULNG:	
			return [self numberWithUnsignedLong:*(unsigned long *)value]; 
		case 'Q':		
		 return [self numberWithUnsignedLongLong:*(unsigned long long *)value]; 
		default:		
			break;
		}

	[NSException raise:NSInvalidArgumentException format:@"Invalid objc type"];

    return nil;
}

+ (NSNumber *) numberWithBool:(BOOL)value
{
	static NSNumber *cache[2]; 
	NSNumber *num=cache[value != 0]; 
	if(!num) 
		num=cache[value != 0]=[[GSBoolNumber alloc] initWithBool:value]; // cache (never release)
	return num; 
}

+ (NSNumber *) numberWithChar:(char) value
{
	int ival=value;
#define LOWER_LIMIT	-2
#define UPPER_LIMIT	3
	if(ival >= LOWER_LIMIT && ival < UPPER_LIMIT)
		{ 
		static NSNumber *cache[UPPER_LIMIT-LOWER_LIMIT]; 
		NSNumber *num=cache[ival-LOWER_LIMIT]; 
		if(!num) 
			num=cache[ival-LOWER_LIMIT]=[[GSCharNumber alloc] initWithChar:ival]; // cache (never release)
		return num; 
		}
#undef LOWER_LIMIT
#undef UPPER_LIMIT
    return [[[GSCharNumber alloc] initWithChar:ival] autorelease];
}

+ (NSNumber *) numberWithDouble:(double)value
{
    return [[[GSDoubleNumber alloc] initWithDouble:value] autorelease];
}

+ (NSNumber *) numberWithFloat:(float)value
{
    return [[[GSFloatNumber alloc] initWithFloat:value]	autorelease];
}

+ (NSNumber *) numberWithInt:(int)ival
{
#if 0
	NSLog(@"NSNumber numberWithInt:%d", ival);
#endif
#define LOWER_LIMIT	-2
#define UPPER_LIMIT	11
	if(ival >= LOWER_LIMIT && ival < UPPER_LIMIT) 
		{ 
		static NSNumber *cache[UPPER_LIMIT-LOWER_LIMIT]; 
		NSNumber *num=cache[ival-LOWER_LIMIT]; 
		if(!num) 
			num=cache[ival-LOWER_LIMIT]=[[GSIntNumber alloc] initWithInt:ival]; // cache (never release)
		return num;
		}
#undef LOWER_LIMIT
#undef UPPER_LIMIT
    return [[[GSIntNumber alloc] initWithInt:ival] autorelease];
}

+ (NSNumber *) numberWithInteger:(NSInteger)ival
{
#if 0
	NSLog(@"NSNumber numberWithInt:%d", ival);
#endif
#define LOWER_LIMIT	0
#define UPPER_LIMIT	15
	if(ival >= LOWER_LIMIT && ival < UPPER_LIMIT) 
			{ 
				static NSNumber *cache[UPPER_LIMIT-LOWER_LIMIT]; 
				NSNumber *num=cache[ival-LOWER_LIMIT]; 
				if(!num) 
					num=cache[ival-LOWER_LIMIT]=[[GSIntNumber alloc] initWithInteger:ival]; // cache (never release)
				return num;
			}
#undef LOWER_LIMIT
#undef UPPER_LIMIT
	return [[[GSIntNumber alloc] initWithInteger:ival] autorelease];
}

+ (NSNumber *) numberWithLong:(long)value
{
    return [[[GSLongNumber alloc] initWithLong:value] autorelease];
}

+ (NSNumber *) numberWithLongLong:(long long)value
{
    return [[[GSLongLongNumber alloc] initWithLongLong:value] autorelease];
}

+ (NSNumber *) numberWithShort:(short)value
{
    return [[[GSShortNumber alloc] initWithShort:value]	autorelease];
}

+ (NSNumber *) numberWithUnsignedChar:(unsigned char)value
{
    return [[[GSUCharNumber alloc] initWithUnsignedChar:value] autorelease];
}

+ (NSNumber *) numberWithUnsignedInt:(unsigned int)value
{
    return [[[GSUIntNumber alloc] initWithUnsignedInt:value] autorelease];
}

+ (NSNumber *) numberWithUnsignedInteger:(NSUInteger)value
{
	return [[[GSUIntNumber alloc] initWithUnsignedInteger:value] autorelease];
}

+ (NSNumber *) numberWithUnsignedShort:(unsigned short)value
{
	return [[[GSUShortNumber alloc] initWithUnsignedShort:value] autorelease];
}

+ (NSNumber *) numberWithUnsignedLong:(unsigned long)value
{
    return [[[GSULongNumber alloc] initWithUnsignedLong:value] autorelease];
}

+ (NSNumber *) numberWithUnsignedLongLong:(unsigned long long)value
{
	NSNumber *n = [[GSULongLongNumber alloc] initWithUnsignedLongLong:value];
	return [n autorelease];
}

+ (id) valueFromString:(NSString *)string
{
	const char *str = [string UTF8String];
	if(strchr(str, '.') != NULL || strchr(str, 'e') != NULL || strchr(str, 'E') != NULL)
		return [NSNumber numberWithDouble:atof(str)];
	if(strchr(str, '-') != NULL)
		return [NSNumber numberWithInt:atoi(str)];
	return [NSNumber numberWithUnsignedInt:atoi(str)];
}

- (id) initWithBool:(BOOL)value
{
	// FIXME: we should release self or not?
    return [[GSBoolNumber alloc] initWithBool:value];
}

- (id) initWithChar:(char)value
{
    return [[GSCharNumber alloc] initWithChar:value];
}

- (id) initWithDouble:(double)value
{
    return [[GSDoubleNumber alloc] initWithDouble:value];
}

- (id) initWithFloat:(float)value
{
    return [[GSFloatNumber alloc] initWithFloat:value];
}

- (id) initWithInt:(int)value
{
    return [[GSIntNumber alloc] initWithInt:value];
}

- (id) initWithInteger:(NSInteger)value
{
	return [[GSIntNumber alloc] initWithInt:value];
}

- (id) initWithLong:(long)value
{
    return [[GSLongNumber alloc] initWithLong:value];
}

- (id) initWithLongLong:(long long)value
{
    return [[GSLongLongNumber alloc] initWithLongLong:value];
}

- (id) initWithShort:(short)value
{
    return [[GSShortNumber alloc] initWithShort:value];
}

- (id) initWithUnsignedChar:(unsigned char)value
{
    return [[GSUCharNumber alloc] initWithUnsignedChar:value];
}

- (id) initWithUnsignedInt:(unsigned int)value
{
    return [[GSUIntNumber alloc] initWithUnsignedInt:value];
}

- (id) initWithUnsignedInteger:(NSUInteger)value
{
	return [[GSUIntNumber alloc] initWithUnsignedInt:value];
}

- (id) initWithUnsignedShort:(unsigned short)value
{
    return [[GSUShortNumber alloc] initWithUnsignedShort:value];
}

- (id) initWithUnsignedLong:(unsigned long)value
{
    return [[GSULongNumber alloc] initWithUnsignedLong:value];
}

- (id) initWithUnsignedLongLong:(unsigned long long)value
{
    return [[GSULongLongNumber alloc] initWithUnsignedLongLong:value];
}

- (BOOL) isEqualToNumber:(NSNumber*)other
{
	return ([self compare: other] == NSOrderedSame) ? YES : NO;
}

- (BOOL) isEqual:(id)other
{
	if ([other isKindOfClass: [NSNumber class]])
		return [self isEqualToNumber: (NSNumber*)other];

	return [super isEqual: other];
}
							// Because of the rule that two numbers which are 
- (unsigned) hash			// the same according to [-isEqual:] must generate
{							// the same hash, we must generate the hash from
union {						// the most general representation of the number.
    double d;
    unsigned char c[sizeof(double)];
} val;
unsigned hash = 0;
int i;

	val.d = [self doubleValue];
	for (i = 0; i < sizeof(double); i++)
		hash += val.c[i];

	return hash;
}

- (id) copyWithZone:(NSZone *) zone					{ return [self retain]; }
- (NSString*) stringValue							{ return [self descriptionWithLocale: nil]; }
- (NSString*) description							{ return [self descriptionWithLocale: nil]; }
- (NSString*) descriptionWithLocale:(id)locale { return SUBCLASS }
- (Class) classForCoder								{ return [NSNumber class]; }
- (NSComparisonResult) compare:(NSNumber *)other	{ SUBCLASS; return 0; }
- (id) initWithCoder:(NSCoder *)coder				{ return self; }
- (void) encodeWithCoder:(NSCoder *)coder			{ SUBCLASS; }

- (BOOL) boolValue					  { SUBCLASS; return 0; }
- (char) charValue					  { SUBCLASS; return 0; }
- (double) doubleValue				  { SUBCLASS; return 0; }
- (float) floatValue				  { SUBCLASS; return 0; }
- (int) intValue					  { SUBCLASS; return 0; }
- (NSInteger) integerValue					  { SUBCLASS; return 0; }
- (long long) longLongValue			  { SUBCLASS; return 0; }
- (long) longValue					  { SUBCLASS; return 0; }
- (short) shortValue				  { SUBCLASS; return 0; }
- (unsigned char) unsignedCharValue	  { SUBCLASS; return 0; }
- (unsigned int) unsignedIntValue	  { SUBCLASS; return 0; }
- (NSUInteger) unsignedIntegerValue	  { SUBCLASS; return 0; }
- (unsigned long) unsignedLongValue   { SUBCLASS; return 0; }
- (unsigned short) unsignedShortValue { SUBCLASS; return 0; }
- (unsigned long long) unsignedLongLongValue { SUBCLASS; return 0; }

@end


NSComparisonResult _compareNumbers(NSNumber *o, NSNumber *s)
{
	int	k;

    if ((k = [s _nextOrder]) <= [o _typeOrder])
		switch([o compare: s])
			{
			case NSOrderedAscending:	return NSOrderedDescending;
			case NSOrderedDescending:	return NSOrderedAscending;
			default:					return NSOrderedSame;
			}

    if (k >= [o _nextOrder]) 
		return [s _promotedCompare: o];
	else 
		switch([o _promotedCompare: s])
			{
			case NSOrderedAscending:	return NSOrderedDescending;
			case NSOrderedDescending:	return NSOrderedAscending;
			default:					return NSOrderedSame;
			}
}

//*****************************************************************************
//
// 		GSBoolNumber 
//
//*****************************************************************************

@implementation GSBoolNumber

- (id) initWithBool:(BOOL)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
short v0 = [self shortValue];
short v1 = [other shortValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 4; }
- (int) _typeOrder						{ return 0; }
- (const char *) objCType				{ return @encode(BOOL); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        BOOL a = [other boolValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%d", (unsigned int)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSUCharNumber 
//
//*****************************************************************************

@implementation GSUCharNumber

- (id) initWithUnsignedChar:(unsigned char)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
short v0 = [self shortValue];
short v1 = [other shortValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 4; }
- (int) _typeOrder						{ return 1; }
- (const char *) objCType				{ return @encode(unsigned char); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

    if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        unsigned char a = [other unsignedCharValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%uc", (unsigned char)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSCharNumber 
//
//*****************************************************************************

@implementation GSCharNumber

- (id) initWithChar:(char)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
short v0 = [self shortValue];
short v1 = [other shortValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 4; }
- (int) _typeOrder						{ return 2; }
- (const char *) objCType				{ return @encode(char); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        char a = [other charValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%c", (char)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSUShortNumber 
//
//*****************************************************************************

@implementation GSUShortNumber

- (id) initWithUnsignedShort:(unsigned short)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
int	v0 = [self intValue];
int	v1 = [other intValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 6; }
- (int) _typeOrder						{ return 3; }
- (const char *) objCType				{ return @encode(unsigned short); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        unsigned short a = [other unsignedShortValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%hu", (unsigned short)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSShortNumber 
//
//*****************************************************************************

@implementation GSShortNumber

- (id) initWithShort:(short)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
int	v0 = [self intValue];
int	v1 = [other intValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 6; }
- (int) _typeOrder						{ return 4; }
- (const char *) objCType				{ return @encode(short); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        short a = [other shortValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%hd", (short)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSUIntNumber 
//
//*****************************************************************************

@implementation GSUIntNumber

- (id) initWithUnsignedInt:(unsigned int)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
long v0 = [self longValue];
long v1 = [other longValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 8; }
- (int) _typeOrder						{ return 5; }
- (const char *) objCType				{ return @encode(unsigned int); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        unsigned int a = [other unsignedIntValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%u", (unsigned int)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSIntNumber 
//
//*****************************************************************************

@implementation GSIntNumber

- (id) initWithInt:(int)value
{
	data = value;
#if 0
	NSLog(@"initWithInt = %@", self);
#endif
    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
long v0 = [self longValue];
long v1 = [other longValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 8; }
- (int) _typeOrder						{ return 6; }
- (const char *) objCType				{ return @encode(int); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        int a = [other intValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
	return [NSString stringWithFormat:@"%d", (int)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSULongNumber 
//
//*****************************************************************************

@implementation GSULongNumber

- (id) initWithUnsignedLong:(unsigned long)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
long long v0 = [self longLongValue];
long long v1 = [other longLongValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 10; }
- (int) _typeOrder						{ return 7; }
- (const char *) objCType				{ return @encode(unsigned long); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        unsigned long a = [other unsignedLongValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%lu", (unsigned long)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSLongNumber 
//
//*****************************************************************************

@implementation GSLongNumber

- (id) initWithLong:(long)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
long long v0 = [self longLongValue];
long long v1 = [other longLongValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 10; }
- (int) _typeOrder						{ return 8; }
- (const char *) objCType				{ return @encode(long); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        long a = [other longValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%ld", (long)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSULongLongNumber 
//
//*****************************************************************************

@implementation GSULongLongNumber

- (id) initWithUnsignedLongLong:(unsigned long long)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
double v0 = [self doubleValue];
double v1 = [other doubleValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 12; }
- (int) _typeOrder						{ return 9; }
- (const char *) objCType				{ return @encode(unsigned long long); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        unsigned long long a = [other unsignedLongLongValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
	return [NSString stringWithFormat:@"%llu",(unsigned long long)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSLongLongNumber 
//
//*****************************************************************************

@implementation GSLongLongNumber

- (id) initWithLongLong:(long long)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
double v0 = [self doubleValue];
double v1 = [other doubleValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 12; }
- (int) _typeOrder						{ return 10; }
- (const char *) objCType				{ return @encode(long long); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        long long a = [other longLongValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
	return [NSString stringWithFormat:@"%lld", (long long)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSFloatNumber 
//
//*****************************************************************************

@implementation GSFloatNumber

- (id) initWithFloat:(float)value
{
	data = value;

    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
double v0 = [self doubleValue];
double v1 = [other doubleValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 12; }
- (int) _typeOrder						{ return 11; }
- (const char *) objCType				{ return @encode(float); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        float a = [other floatValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%f", (float)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end

//*****************************************************************************
//
// 		GSDoubleNumber 
//
//*****************************************************************************

@implementation GSDoubleNumber

- (id) initWithDouble:(double)value
{
	data = value;
    return self;
}

- (NSComparisonResult) _promotedCompare:(NSNumber*)other
{
	double v0 = [self doubleValue];
	double v1 = [other doubleValue];

    if (v0 == v1)
		return NSOrderedSame;

	return (v0 < v1) ?  NSOrderedAscending : NSOrderedDescending;
}

- (int) _nextOrder						{ return 12; }
- (int) _typeOrder						{ return 12; }
- (const char *) objCType				{ return @encode(double); }

PRIMITIVE_ACCESSOR_METHODS_()

- (NSComparisonResult) compare:(NSNumber *)other
{
int	o = [self _typeOrder];

	if (o == [other _typeOrder] || o >= [other _nextOrder]) 
		{
        double a = [other doubleValue];
    
        if (data == a)
    	    return NSOrderedSame;

		return (data < a) ? NSOrderedAscending : NSOrderedDescending;
		}

	return _compareNumbers(other, self);
}

- (NSString *) descriptionWithLocale:(id)locale
{
    return [NSString stringWithFormat:@"%lg", (double)data];
}

- (void) getValue:(void *)value							// Override NSValue's
{
    if (!value)
		[NSException raise:NSInvalidArgumentException
					 format:@"Cannot copy value into NULL pointer"];

    memcpy(value, &data, objc_sizeof_type([self objCType]));
}

- (id) initWithCoder:(id)coder							// NSCoding protocol
{
	[coder decodeValueOfObjCType: [self objCType] at: &data];
	return self;
}

- (void) encodeWithCoder:(id)coder
{
	[coder encodeValueOfObjCType: [self objCType] at: &data];
}

@end
