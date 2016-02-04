/* 
   NSDictionary.m

   Associate a unique key with a value

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPropertyList.h>

#import "NSPrivate.h"

// Class variables
static Class _dictClass;
static Class _mutableDictClass;


@interface NSConcreteDictionary : NSDictionary
{
    NSMapTable *table;
}

- (NSMapEnumerator) _keyEnumerator;

@end

@interface NSConcreteMutableDictionary : NSConcreteDictionary
@end

//*****************************************************************************
//
// 		NSDictionary Enumerators 
//
//*****************************************************************************

@interface NSDictionaryObjectEnumerator : NSObject
{
    NSDictionary *_dict;
    NSEnumerator *_keys;
}

+ (id) enumeratorWithDictionary:(NSDictionary*)dict;
- (id) nextObject;

@end

@implementation NSDictionaryObjectEnumerator

+ (id) enumeratorWithDictionary:(NSDictionary*)dict
{
NSDictionaryObjectEnumerator *e = [self new];

    e->_dict = [dict retain];
    e->_keys = [[dict keyEnumerator] retain];

    return [e autorelease];
}

- (void) dealloc
{
    [_dict release];
    [_keys release];
    [super dealloc];
}

- (id) nextObject			{ return [_dict objectForKey:[_keys nextObject]]; }

@end /* NSDictionaryObjectEnumerator */


@interface GSDictionaryKeyEnumerator : NSObject
{
    NSDictionary *_dict;
    NSMapEnumerator	_enumerator;
}

+ (id) enumeratorWithDictionary:(NSDictionary*)dict;
- (id) nextObject;

@end

@implementation GSDictionaryKeyEnumerator

+ (id) enumeratorWithDictionary:(NSDictionary*)dict
{
GSDictionaryKeyEnumerator *e = [self new];

    e->_dict = [dict retain];
    e->_enumerator = [(NSConcreteDictionary*)dict _keyEnumerator];

    return [e autorelease];
}

- (void) dealloc
{
    [_dict release];
    [super dealloc];
}

- (id) nextObject
{
id key, value;

    return NSNextMapEnumeratorPair(&_enumerator, (void**)&key, 
									(void**)&value) == YES ? key : nil;
}

@end /* GSDictionaryKeyEnumerator */

//*****************************************************************************
//
// 		NSDictionary 
//
//*****************************************************************************

@implementation NSDictionary

+ (void) initialize
{
	if (self == [NSDictionary class])
		{
		_dictClass = [NSConcreteDictionary class];
		_mutableDictClass = [NSConcreteMutableDictionary class];
		}
}

+ (id) allocWithZone:(NSZone *) z
{
	return (id) NSAllocateObject(_dictClass, 0, z);
}

+ (id) dictionary
{
    return [[[self alloc] initWithDictionary:nil] autorelease];
}

+ (id) dictionaryWithContentsOfFile:(NSString*)path
{
#if 0
	NSLog(@"dictionaryWithContentsOfFile: %@", path);
#endif
	return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

+ (id) dictionaryWithContentsOfURL:(NSURL*)url
{
	return [[[self alloc] initWithContentsOfURL:url] autorelease];
}

+ (id) dictionaryWithObjects:(NSArray*)objects forKeys:(NSArray*)keys
{
    return [[[self alloc] initWithObjects:objects forKeys:keys] autorelease];
}

+ (id) dictionaryWithObjects:(id*)objects 
					 forKeys:(id*)keys 
					 count:(NSUInteger)count;
{
    return [[[self alloc] initWithObjects:objects
						  forKeys:keys 
						  count:count] autorelease];
}

+ (id) dictionaryWithObjectsAndKeys:(id)firstObject, ...
{
	id obj, *k, *v, dic;
	va_list va;
	int count;
    
    va_start(va, firstObject);
    for (count = 1, obj = firstObject; obj != nil; obj = va_arg(va, id), count++)
		{
		if (!va_arg(va,id))
			[NSException raise: NSInvalidArgumentException
						 format: @"-dictionaryWithObjectsAndKeys:... tried to add nil key to dictionary"];
		}
	va_end(va);

    k = objc_malloc(sizeof(id) * count);
    v = objc_malloc(sizeof(id) * count);
    
	va_start(va, firstObject);
	for (count = 0, obj = firstObject; obj; obj = va_arg(va, id)) 
		{
		k[count] = va_arg(va, id);
		v[count++] = obj;
		}
	va_end(va);

    dic = [[self alloc] initWithObjects:v forKeys:k count:count];

    objc_free(k);
    objc_free(v);

    return [dic autorelease];
}

+ (id) dictionaryWithDictionary:(NSDictionary*)aDict
{
    return [[[self alloc] initWithDictionary:aDict] autorelease];
}

+ (id) dictionaryWithObject:object forKey:key
{
    return [[[self alloc] initWithObjects:&object forKeys:&key count:1] autorelease];
}

- (id) initWithContentsOfFile:(NSString*)fileName
{
	NSString *err=nil;
	NSPropertyListFormat fmt=NSPropertyListAnyFormat;	// accept any format
	id o=[NSData dataWithContentsOfFile:fileName];
	if(!o)
		return nil;
#if 0
	NSLog(@"initWithContentsOfFile: %@", fileName);
#endif
	o=[NSPropertyListSerialization propertyListFromData:o
									   mutabilityOption:[self class] == _dictClass?NSPropertyListImmutable:NSPropertyListMutableContainers
												 format:&fmt
									   errorDescription:&err];
#if 0
	NSLog(@" err: %@", err);
#endif	
	if(!o)
		[NSException raise: NSParseErrorException format:@"NSDictionary %@ for file %@", err, fileName];
	if(![o isKindOfClass:_dictClass])
		[NSException raise: NSParseErrorException 
					format: @"%@ does not contain a %@ property list", fileName, NSStringFromClass([self class])];
	return [self initWithDictionary:o];
}

- (id) initWithContentsOfURL:(NSURL*)url
{
	NSString *err=nil;
	NSPropertyListFormat fmt=NSPropertyListAnyFormat;	// accept any format
	id o=[NSData dataWithContentsOfURL:url];
	if(!o)
		return nil;
	o=[NSPropertyListSerialization propertyListFromData:o
									   mutabilityOption:[self class] == _dictClass?NSPropertyListImmutable:NSPropertyListMutableContainers
												 format:&fmt
									   errorDescription:&err];
	[err autorelease];
	if(!o)
		[NSException raise: NSParseErrorException format: @"NSDictionary %@ for URL %@", err, url];
	if(![o isKindOfClass:_dictClass])
		[NSException raise: NSParseErrorException 
					format: @"%@ does not contain a property list: %@", url, NSStringFromClass([self class])];
	return [self initWithDictionary:o];
}

- (id) initWithDictionary:(NSDictionary*)dictionary copyItems:(BOOL)flag
{
NSEnumerator *keye = [dictionary keyEnumerator];
unsigned count = [dictionary count];
id *keys = objc_malloc(sizeof(id) * count);
id *values = objc_malloc(sizeof(id) * count);
id key;
    
    count = 0;
	if (flag)
		{
		while ((key = [keye nextObject])) 
			{
			keys[count] = [[key copy] autorelease];
			values[count] = [dictionary objectForKey:key];
			values[count] = [[values[count] copy] autorelease];
			count++;
			}
		}
	else
		{
		while ((key = [keye nextObject])) 
			{
			keys[count] = key;
			values[count] = [dictionary objectForKey:key];
			count++;
			}
		}
    [self initWithObjects:values forKeys:keys count:count];
    
    objc_free(keys);
    objc_free(values);

    return self;
}

- (id) initWithDictionary:(NSDictionary*)dictionary
{
    return [self initWithDictionary:dictionary copyItems:NO];
}

- (id) initWithObjectsAndKeys:(id)firstObject,...
{
id obj, *k, *v;
va_list va;
int count;
    
    va_start(va, firstObject);
    for (count = 1, obj = firstObject; obj; obj = va_arg(va, id), count++) 
		if (!va_arg(va, id))
			[NSException raise: NSInvalidArgumentException
						 format: @"Tried to add nil key to dictionary"];
	va_end(va);

    k = objc_malloc(sizeof(id) * count);
    v = objc_malloc(sizeof(id) * count);
    
	va_start(va, firstObject);
	for (count = 0, obj = firstObject; obj; obj = va_arg(va, id)) 
		{
		k[count] = va_arg(va, id);
		v[count++] = obj;
		}
	va_end(va);

    [self initWithObjects:v forKeys:k count:count];

    objc_free(k);
    objc_free(v);

    return self;
}

- (id) initWithObjects:(NSArray*)objects forKeys:(NSArray*)keys
{
unsigned int i, count = [objects count];
id *mkeys, *mobjs;

    if (count != [keys count])
		[NSException raise: NSInvalidArgumentException
					 format: @"NSDictionary initWithObjects:forKeys must \
		    					have both arguments of the same size"];

    mkeys = objc_malloc(sizeof(id) * count);
    mobjs = objc_malloc(sizeof(id) * count);

    for (i = 0; i < count; i++) 
		{
		mkeys[i] = [keys objectAtIndex:i];
		mobjs[i] = [objects objectAtIndex:i];
		}

    [self initWithObjects:mobjs forKeys:mkeys count:count];
    
    objc_free(mkeys);
    objc_free(mobjs);

    return self;
}

- (id) initWithObjects:(id*)objects 
			   forKeys:(id*)keys 
			   count:(NSUInteger)count				{ return SUBCLASS }
- (NSEnumerator*) keyEnumerator							{ return SUBCLASS }
- (id) objectForKey:(id)aKey							{ return SUBCLASS }

- (NSUInteger) count									{ SUBCLASS return 0; }

- (NSArray*) allKeys
{
	NSMapEnumerator e = [(NSConcreteDictionary*)self _keyEnumerator];
	int count = [self count];
	id key, value;
	NSMutableArray *keys=[NSMutableArray arrayWithCapacity:count];

    while (NSNextMapEnumeratorPair(&e, (void**)&key, (void**)&value))
			[keys addObject:key];

   return keys;	// should be made immutable
}

- (NSArray *) keysSortedByValueUsingSelector:(SEL) comp
{
	// FIXME: optimize if possible
	return [[self allKeys] sortedArrayUsingSelector:comp];
}

- (NSArray*) allKeysForObject:(id)object
{
	NSMapEnumerator e = [(NSConcreteDictionary*)self _keyEnumerator];
	int count = [self count];
	id key, value;
	NSMutableArray *keys=[NSMutableArray arrayWithCapacity:count];
	while (NSNextMapEnumeratorPair(&e, (void**)&key, (void**)&value))
		if ([value isEqual:object])
			[keys addObject:key];
    return keys;
}

- (NSArray*) allValues
{
	NSMapEnumerator e = [(NSConcreteDictionary*)self _keyEnumerator];
	int count = [self count];
	id key, value;
	NSMutableArray *values=[NSMutableArray arrayWithCapacity:count];

    while (NSNextMapEnumeratorPair(&e, (void**)&key, (void**)&value))
			[values addObject:value];

    return values;
}

- (NSEnumerator*) objectEnumerator
{
    return [NSDictionaryObjectEnumerator enumeratorWithDictionary:self];
}

- (void) getObjects:(id *) objects andKeys:(id *) keys;
{
	NSMapEnumerator e = [(NSConcreteDictionary*)self _keyEnumerator];
	id key, value;
	while (NSNextMapEnumeratorPair(&e, (void**)&key, (void**)&value))
		*objects++=value, *keys++=key;
}

- (NSArray*) objectsForKeys:(NSArray*)keys notFoundMarker:notFoundObj
{
	int count = [keys count];
	id *objs = objc_malloc(sizeof(id)*count);
	id ret;
	
	for (count--; count >= 0; count--) 
			{
				id ret = [self objectForKey:[keys objectAtIndex:count]];
				objs[count] = ret ? ret : notFoundObj;
			}
	
	ret = [[[NSArray alloc] initWithObjects:objs count:count] autorelease];
	objc_free(objs);
	
	return ret;
}

- (BOOL) isEqualToDictionary:(NSDictionary*)other
{
id keys, key;										// Comparing Dictionaries

    if( other == self )
		return YES;
    if ([self count] != [other count] || other == nil)
		return NO;
    keys = [self keyEnumerator];
    while ((key = [keys nextObject]))
		if ([[self objectForKey:key] isEqual:[other objectForKey:key]]==NO)
	    	return NO;

    return YES;
}

- (NSString*) descriptionWithLocale:(id)locale
							 indent:(NSUInteger)indent
{
	id pool, key, value, keys, kd, vd;
	NSMutableString *desc;
	NSString *indentation /*, *format */;
	unsigned indent1 = indent + 4;
	NSEnumerator *e;
	const char *s;

    if(!([self count])) 
		return @"{}";   // empty dictionary

	desc = [NSMutableString stringWithString:@"{\n"];
	indentation = [@"" stringByPaddingToLength:indent withString:@" " startingAtIndex:0];
//	NSLog(@"indentation=*%@*", indentation);

	pool = [NSAutoreleasePool new];
	keys = [[self allKeys] sortedArrayUsingSelector:@selector(compare:)];
    e = [keys objectEnumerator];
    while((key = [e nextObject])) 
		{
		if ([key respondsToSelector:@selector(descriptionWithLocale:indent:)])
			kd = [key descriptionWithLocale:locale indent:indent1];
		else 
			if ([key respondsToSelector:@selector(descriptionWithLocale:)])
				kd = [key descriptionWithLocale:locale];
			else
				kd = [key description];
											// if str with whitespc add quotes
		if(strpbrk([kd UTF8String], " %-\t") != NULL)
			kd = [NSString stringWithFormat: @"\"%@\"", kd];

		value = [self objectForKey:key];
		if([value respondsToSelector:@selector(descriptionWithLocale:indent:)])
			vd = [value descriptionWithLocale:locale indent:indent1];
		else 
			if ([value respondsToSelector:@selector(descriptionWithLocale:)])
				vd = [value descriptionWithLocale: locale];
			else
				vd = [value description];

		s = [vd UTF8String];					// if str with whitespc add quotes
		/// BUG: this doesn't work properly if vd was a NSStrings beginning with { ( or < !!!
		if(*s != '{' && *s != '(' && *s != '<')
			if((strpbrk(s, " %-\t") != NULL))
				vd = [NSString stringWithFormat: @"\"%@\"", vd];

		[desc appendFormat:@"%@    %@ = %@;\n", indentation, kd, vd];
		}
	[desc appendFormat:@"%@}", indentation];
    [pool release];
    return desc;
}

- (NSString*) descriptionInStringsFileFormat
{
id key, value;
NSEnumerator *enumerator;
NSMutableString *description = [[NSMutableString new] autorelease];
id pool = [NSAutoreleasePool new];
NSMutableArray *keys = [[[self allKeys] mutableCopy] autorelease];

    [keys sortUsingSelector:@selector(compare:)];
    enumerator = [keys objectEnumerator];

    while((key = [enumerator nextObject])) 
		{
		value = [self objectForKey:key];
		[description appendFormat:@"%@ = %@\n", key, value];
		}
    [pool release];

    return description;
}

- (NSString*) descriptionWithLocale:(id)locale
{
    return [self descriptionWithLocale:locale indent:0];
}

- (NSString*) description
{
    return [self descriptionWithLocale:nil indent:0];
}

- (NSString*) stringRepresentation
{
    return [self descriptionWithLocale:nil indent:0];
}

- (BOOL) writeToFile:(NSString*)path atomically:(BOOL)useAuxiliaryFile
{
	NSString *error;
	// optionally use NSPropertyListBinaryFormat_v1_0
	NSData *desc=[NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
//	NSString *desc=[self descriptionInStringsFileFormat];
#if 0
	NSLog(@"writeToFile:%@ %@", path, desc);
#endif
	return [desc writeToFile:path atomically:useAuxiliaryFile];
}

- (BOOL) writeToURL:(NSURL*)url atomically:(BOOL)useAuxiliaryFile
{
	return NO;
}

- (BOOL) isEqual:(id)anObject
{
	if ([anObject isKindOfClass:[NSDictionary class]] == NO)
		return NO;

    return [self isEqualToDictionary:anObject];
}

- (NSUInteger) hash					{ return [self count]; }
- (id) copyWithZone:(NSZone *) zone							{ return [self retain]; }

- (id) mutableCopyWithZone:(NSZone *) zone
{
    return [[NSMutableDictionary alloc] initWithDictionary:self];
}

- (Class) classForCoder				{ return [NSDictionary class]; }

- (void) encodeWithCoder:(NSCoder*)aCoder
{
int count = [self count];
NSEnumerator *enumerator = [self keyEnumerator];
id key, value;

    [aCoder encodeValueOfObjCType:@encode(int) at:&count];
    while((key = [enumerator nextObject])) 
		{
		value = [self objectForKey:key];
		[aCoder encodeObject:key];
		[aCoder encodeObject:value];
		}
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
	int i, count;
	id *keys, *values;

	if([aDecoder allowsKeyedCoding])
		{
#if 0
		NSLog(@"%@ initWithKeyedCoder", NSStringFromClass([self class]));
#endif
		return [self initWithObjects:[aDecoder decodeObjectForKey:@"NS.objects"] forKeys:[aDecoder decodeObjectForKey:@"NS.keys"]];
		}
    [aDecoder decodeValueOfObjCType:@encode(int) at:&count];
#if 0
	NSLog(@"NSDictionary initWithCoder count=%d", count);
#endif
	if(count > 0)
		{
		keys = objc_malloc(sizeof(id) * count);
		values = objc_malloc(sizeof(id) * count);

		for(i = 0; i < count; i++)
			{
			keys[i] = [aDecoder decodeObject];
			values[i] = [aDecoder decodeObject];
			}

		[self initWithObjects:values forKeys:keys count:count];

		objc_free(keys);
		objc_free(values);
		}
    return self;
}

@end /* NSDictionary */

//*****************************************************************************
//
// 		NSConcreteDictionary 
//
//*****************************************************************************

@implementation NSConcreteDictionary

+ (id) allocWithZone:(NSZone *) z
{
	return (id) NSAllocateObject(self, 0, z);
}
- (id) init							{ return [self initWithDictionary:nil]; }

- (id) initWithObjects:(id*)objects forKeys:(id*)keys count:(NSUInteger)count
{
    table = NSCreateMapTable(NSObjectMapKeyCallBacks,
							 NSObjectMapValueCallBacks, (count * 4) / 3);
    if (!count)
		return self;
    while(count--) 
		{
		if (!keys[count] || !objects[count])
			[NSException raise: NSInvalidArgumentException
						 format: @"Tried to add nil object to dictionary"];
		NSMapInsert(table, keys[count], objects[count]);
		}

    return self;
}

- (id) initWithDictionary:(NSDictionary*)dictionary
{
id key, keys = [dictionary keyEnumerator];

    table = NSCreateMapTable(NSObjectMapKeyCallBacks,
							NSObjectMapValueCallBacks, 
							([dictionary count] * 4) / 3);
	    
    while ((key = [keys nextObject]))
		NSMapInsert(table, key, [dictionary objectForKey:key]);
    
    return self;
}

- (void) dealloc
{
    if (table)
		NSFreeMapTable(table);
    [super dealloc];
}

- (NSEnumerator *) keyEnumerator				// Accessing keys and values
{
    return [GSDictionaryKeyEnumerator enumeratorWithDictionary:self];
}

- (id) objectForKey:(id)aKey		{ return (NSObject*)NSMapGet(table,aKey); }
- (NSUInteger) count				{ return NSCountMapTable(table); }
- (NSMapEnumerator) _keyEnumerator	{ return NSEnumerateMapTable(table); }

@end /* NSConcreteDictionary */

//*****************************************************************************
//
// 		NSMutableDictionary, NSConcreteMutableDictionary 
//
//*****************************************************************************

@implementation NSMutableDictionary

+ (id) allocWithZone:(NSZone *) z
{
#if 0
	NSLog(@"NSMutableDictionary alloc _mutableDictClass=%@", NSStringFromClass(_mutableDictClass));
#endif
	return (id) NSAllocateObject(_mutableDictClass, 0, z);
}

+ (id) dictionaryWithCapacity:(NSUInteger)aNumItems
{
    return [[[self alloc] initWithCapacity:aNumItems] autorelease];
}

- (void) addEntriesFromDictionary:(NSDictionary*)otherDictionary; { SUBCLASS; }
- (id) initWithCapacity:(NSUInteger)aNumItems; { return SUBCLASS; }
- (void) removeAllObjects; { SUBCLASS; }
- (void) removeObjectForKey:(id)theKey; { SUBCLASS; }
- (void) removeObjectsForKeys:(NSArray *)keyArray; { SUBCLASS; }
- (void) setDictionary:(NSDictionary *)otherDictionary; { SUBCLASS; }
- (void) setObject:(id)anObject forKey:(id)aKey; { SUBCLASS; }

@end /* NSMutableDictionary */


@implementation NSConcreteMutableDictionary	// subclass of NSConcreteDictionary and not NSMutableDictionary

// why do we need that? Perhaps if someone is calling [[self class] dictionaryWithCapacity]

+ (id) dictionaryWithCapacity:(unsigned int)aNumItems
{
    return [[[self alloc] initWithCapacity:aNumItems] autorelease];
}

- (id) initWithCapacity:(unsigned int)aNumItems
{
#if 0
	NSLog(@"NSConcreteMutableDictionary initWithCapacity:%d", aNumItems);
#endif
	table = NSCreateMapTable(NSObjectMapKeyCallBacks,
							NSObjectMapValueCallBacks, 
							(aNumItems * 4) / 3);
    return self;
}

- (id) init	{ return [self initWithCapacity:0]; }

- (id) copyWithZone:(NSZone *) zone
{
    return [[NSDictionary alloc] initWithDictionary:self copyItems:YES];
}

- (void) setObject:(id)anObject forKey:(id)aKey
{ // Modifying a dictionary (basic function)
    if (!aKey)
		{
#if 1
		NSLog(@"Tried to add nil key to dictionary %@ for object %@", self, anObject);
#endif
		[NSException raise: NSInvalidArgumentException
					format: @"Tried to add nil key to dictionary %@ for object %@", self, anObject];
		}
    if (!anObject)
		{
#if 1
		NSLog(@"Tried to add nil object to dictionary %@ for Key %@", self, aKey);
#endif
#if 0
		anObject=[NSNull null];
#else
		[NSException raise: NSInvalidArgumentException
					 format: @"Tried to add nil object to dictionary %@ forKey %@", self, aKey];
#endif
		}
    NSMapInsert(table, aKey, anObject);
}

- (void) addEntriesFromDictionary:(NSDictionary*)otherDict
{
	id key, nodes = [otherDict keyEnumerator];			// Add and Remove Entries
    while ((key = [nodes nextObject]))
		[self setObject:[otherDict objectForKey:key] forKey:key];
}

- (void) removeObjectForKey:(id)aKey	{ NSMapRemove(table, aKey); }
- (void) removeAllObjects				{ NSResetMapTable(table); }

- (void) removeObjectsForKeys:(NSArray *)keyArray;
{
	NSEnumerator *e=[keyArray objectEnumerator];
	id key;
	while((key=[e nextObject]))
		[self removeObjectForKey:key];
}

- (void) setDictionary:(NSDictionary*)otherDictionary
{
    [self removeAllObjects];
    [self addEntriesFromDictionary:otherDictionary];
}

- (Class) classForCoder					{ return [NSMutableDictionary class]; }

@end /* NSConcreteMutableDictionary */
