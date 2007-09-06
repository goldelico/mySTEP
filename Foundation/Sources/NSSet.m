/* 
   NSSet.m

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSEnumerator.h>
#import "NSPrivate.h"


//*****************************************************************************
//
// 		NSSetEnumerator 
//
//*****************************************************************************

typedef enum {setEnumHash, setEnumMap} SetEnumMode;

@interface NSSetEnumerator : NSObject
{
    id set;
    SetEnumMode	mode;
    union {
			NSMapEnumerator map;
			NSHashEnumerator hash;
		} enumerator;
}

- (id) initWithSet:(NSSet*)_set mode:(SetEnumMode)_mode;
- (id) nextObject;

@end

@implementation NSSetEnumerator

- (id) initWithSet:(NSSet*)_set mode:(SetEnumMode)_mode;
{
    set = [_set retain];
    mode = _mode;
    if (mode == setEnumHash)
		[set __setObjectEnumerator:&(enumerator.hash)];
    if (mode == setEnumMap)
		[set __setObjectEnumerator:&(enumerator.map)];

    return self;
}

- (void) dealloc
{
    [set release];
    [super dealloc];
}

- (id) nextObject
{
    if (mode == setEnumHash) 
		return (id)NSNextHashEnumeratorItem(&(enumerator.hash));

    if (mode == setEnumMap) 
		{
		id key, value;

		return NSNextMapEnumeratorPair(&(enumerator.map), (void**)&key, 
										(void**)&value) == YES ? key : nil;
    	}

    return nil;
}

@end /* NSSetEnumerator */

//*****************************************************************************
//
// 		NSSet 
//
//*****************************************************************************

@implementation NSSet

+ (id) allocWithZone:(NSZone *) z
{
	return NSAllocateObject((self==[NSSet class]) ? [NSConcreteSet class] : self,
							0, z);
}

+ (id) set
{
    return [[[self alloc] init] autorelease];
}

+ (id) setWithArray:(NSArray*)array
{
    return [[[self alloc] initWithArray:array] autorelease];
}

+ (id) setWithObject:(id)anObject
{
    return [[[self alloc] initWithObjects:anObject, nil] autorelease];
}

+ (id) setWithObjects:(id)firstObj,...
{
id set;
va_list va;

    va_start(va, firstObj);
    set = [[[self alloc] initWithObject:firstObj arglist:va] autorelease];
    va_end(va);

    return set;
}

+ (id) setWithObjects:(id*)objects count:(unsigned int)count
{
    return [[[self alloc] initWithObjects:objects count:count] autorelease];
}

+ (id) setWithSet:(NSSet*)aSet
{
    return [[[self alloc] initWithSet:aSet] autorelease];
}

- (id) init												{ return SUBCLASS }
- (id) initWithObjects:(id*)objects 
				 count:(unsigned int)count 				{ return SUBCLASS }

- (id) initWithArray:(NSArray*)array
{
	int i, n = [array count];
	id *objects = objc_malloc(sizeof(id)*n);

    for (i = 0; i < n; i++)
		objects[i] = [array objectAtIndex:i];
	    
    [self initWithObjects:objects count:n];
    objc_free(objects);

    return self;
}

- (id) initWithObjects:(id)firstObj,...
{
va_list va;

    va_start(va, firstObj);
    [self initWithObject:firstObj arglist:va];
    va_end(va);

    return self;
}

- (id) initWithObject:(id)firstObject arglist:(va_list)argList
{
id object;
id *objs;
va_list va = argList;
int count = 0;
    
    for (object = firstObject; object; object = va_arg(va,id))
		count++;
    
    objs = objc_malloc(sizeof(id)*count);
    
    for (count = 0, object = firstObject; object; object = va_arg(argList,id)) 
		{
		objs[count] = object;
		count++;
		}

    [self initWithObjects:objs count:count];
    objc_free(objs);

    return self;
}

- (id)initWithSet:(NSSet*)set copyItems:(BOOL)flag;
{
NSEnumerator *keys = [set objectEnumerator];
id key;
unsigned i = 0;
id *objs = objc_malloc(sizeof(id) * [set count]);

    while((key = [keys nextObject]))
		objs[i++] = flag ? [[key copy] autorelease] : key;
    
    [self initWithObjects:objs count:i];
    objc_free(objs);

    return self;
}

- (id)initWithSet:(NSSet*)aSet
{
    return [self initWithSet:aSet copyItems:NO];
}

- (NSArray*) allObjects
{
unsigned i = 0, count = [self count];
id *objs = objc_malloc(sizeof(id) * count);
id array, key, keys = [self objectEnumerator];

    while ((key = [keys nextObject]))
		objs[i++] = key;

    array = [[[NSArray alloc] initWithObjects:objs count:count] autorelease];
    objc_free(objs);

    return array;
}

- (id) anyObject
{
    return [[self objectEnumerator] nextObject];
}

- (BOOL) containsObject:(id)anObject
{
    return [self member:anObject] ? YES : NO;
}

- (unsigned int) count									{ SUBCLASS return 0; }
- (id) member:(id)anObject								{ return SUBCLASS }
- (NSEnumerator*) objectEnumerator						{ return SUBCLASS }

- (void) makeObjectsPerformSelector:(SEL)aSelector
{
id key, keys = [self objectEnumerator];

    while ((key = [keys nextObject]))
		[key performSelector:aSelector];
}

- (void) makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
id key, keys = [self objectEnumerator];

    while ((key = [keys nextObject]))
		[key performSelector:aSelector withObject:anObject];
}

- (void) makeObjectsPerform:(SEL)aSelector				// Obsolete methods ?
{
id key, keys = [self objectEnumerator];

    while ((key = [keys nextObject]))
		[key performSelector:aSelector];
}

- (void) makeObjectsPerform:(SEL)aSelector withObject:(id)anObject
{
id key, keys = [self objectEnumerator];

    while ((key = [keys nextObject]))
		[key performSelector:aSelector withObject:anObject];
}

- (BOOL) intersectsSet:(NSSet*)otherSet				// Comparing Sets
{
id key, keys = [self objectEnumerator];

	if ([self count] == 0) 
		return NO;

    while ((key = [keys nextObject]))				// sets intersect if any
		if ([otherSet member: key])    				// element of self is also
			return YES;								// in the other set

    return NO;
}

- (BOOL) isEqualToSet:(NSSet*)otherSet
{
id key, keys = [self objectEnumerator];

	if ([self count] != [otherSet count])
		return NO;
    
	while ((key = [keys nextObject]))
		if (![otherSet member: key])
			return NO;
    
	return YES;
}

- (BOOL) isSubsetOfSet:(NSSet*)otherSet
{
id key, keys = [self objectEnumerator];

	if ([self count] > [otherSet count]) 			// subset must not exceed
		return NO;									// the size of other set

    while ((key = [keys nextObject]))				// all of our members must
		if (![otherSet member: key])				// exist in other set for
			return NO;								// self to be a subset

	return YES;
}
													// ret a String Description
- (NSString*) descriptionWithLocale:(NSDictionary*)locale
{
    return [self descriptionWithLocale:locale indent:0];
}

- (NSString*) description
{
    return [self descriptionWithLocale:nil indent:0];
}

- (NSString*) descriptionWithLocale:(NSDictionary*)locale
							 indent:(unsigned int)indent;
{
NSMutableString *description = [NSMutableString stringWithCString:"(\n"];
unsigned int indent1 = indent + 4;
NSMutableString *indentation = [NSString stringWithFormat:
						[NSString stringWithFormat:@"%%%dc", indent1], ' '];
unsigned int count = [self count];
SEL sel = @selector(appendString:);
IMP imp = [description methodForSelector:sel];

    if(count) 
		{
		id pool = [NSAutoreleasePool new];
		id object, stringRepresentation;
		id enumerator = [self objectEnumerator];

		object = [enumerator nextObject];
		if ([object respondsToSelector:
				@selector(descriptionWithLocale:indent:)])
	    	stringRepresentation = [object descriptionWithLocale:locale
										   indent:indent1];
		else 
			if ([object respondsToSelector:@selector(descriptionWithLocale:)])
				stringRepresentation = [object descriptionWithLocale:locale];
			else
				stringRepresentation = [object description];

		(*imp)(description, sel, indentation);
		(*imp)(description, sel, stringRepresentation);

		while((object = [enumerator nextObject]))
			{
			if ([object respondsToSelector:
		    		@selector(descriptionWithLocale:indent:)])
				stringRepresentation = [object descriptionWithLocale:locale
											   indent:indent1];
			else
				if ([object respondsToSelector: 
						@selector(descriptionWithLocale:)])
				stringRepresentation = [object descriptionWithLocale:locale];
				else
					stringRepresentation = [object description];

			(*imp)(description, sel, @",\n");
			(*imp)(description, sel, indentation);
			(*imp)(description, sel, stringRepresentation);
			}

		[pool release];
		}

    (*imp)(description, sel, indent ? [NSMutableString stringWithFormat:
					[NSString stringWithFormat:@"\n%%%dc)", indent], ' ']
	    			: [NSMutableString stringWithCString:"\n)"]);

    return description;
}

- (unsigned) hash							{ return [self count]; }

- (BOOL) isEqual:(id)anObject
{
    if ([anObject isKindOfClass:[NSSet class]] == NO)
	    return NO;
    return [self isEqualToSet:anObject];
}
												// NSCopying, NSMutableCopying
- (id) copyWithZone:(NSZone *) z					{ return [self retain]; }
- (id) mutableCopyWithZone:(NSZone *) z			{ return [[NSMutableSet alloc] initWithSet:self]; }
- (Class) classForCoder		{ return [NSSet class]; }

- (void) encodeWithCoder:(NSCoder*)aCoder
{
NSEnumerator *enumerator = [self objectEnumerator];
int count = [self count];
id object;

    [aCoder encodeValueOfObjCType:@encode(int) at:&count];
    while((object = [enumerator nextObject]))
		[aCoder encodeObject:object];
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
	int i, count;
	id *objects;

	if([aDecoder allowsKeyedCoding])
		{
#if 0
		NSLog(@"%@ initWithKeyedCoder", NSStringFromClass([self class]));
#endif
		return [self initWithArray:[aDecoder decodeObjectForKey:@"NS.objects"]];
		}
    [aDecoder decodeValueOfObjCType:@encode(int) at:&count];
    objects = objc_malloc(sizeof(id) * count);
    for(i = 0; i < count; i++)
		objects[i] = [aDecoder decodeObject];

    [self initWithObjects:objects count:count];
    objc_free(objects);

    return self;
}

@end /* NSSet */

//*****************************************************************************
//
// 		NSMutableSet 
//
//*****************************************************************************

@implementation NSMutableSet

+ (id) allocWithZone:(NSZone *) z
{
    return NSAllocateObject((self == [NSMutableSet class]) ? [NSConcreteMutableSet class] : self,
							0, z);
}

+ (id) setWithCapacity:(unsigned)numItems
{
    return [[[[self class] alloc] initWithCapacity:numItems] autorelease];
}

- (id) initWithCapacity:(unsigned)numItems				{ return SUBCLASS }
- (void) addObject:(id)object							{ SUBCLASS }
- (void) removeObject:(id)object						{ SUBCLASS }

- (void) addObjectsFromArray:(NSArray*)array
{
int i, n = [array count];

    for (i = 0; i < n; i++)
		[self addObject:[array objectAtIndex:i]];
}

- (void) unionSet:(NSSet*)other
{
id key, keys = [other objectEnumerator];

    while ((key = [keys nextObject]))
		[self addObject:key];
}

- (void) setSet:(NSSet*)other
{
    [self removeAllObjects];
    [self unionSet:other];
}

- (void)intersectSet:(NSSet*)other						// Removing Objects
{
id key, keys = [self objectEnumerator];

    while ((key = [keys nextObject]))
		if ([other containsObject:key] == NO)
			[self removeObject:key];
}

- (void) minusSet:(NSSet*)other
{
id key, keys = [other objectEnumerator];

    while ((key = [keys nextObject]))
		[self removeObject:key];
}

- (void) removeAllObjects
{
id key, en = [self objectEnumerator];

    while ((key = [en nextObject]))
		[self removeObject:key];
}

- (id) copyWithZone:(NSZone *) z
{
    return [[NSSet alloc] initWithSet:self copyItems:YES];
}

- (Class) classForCoder				{ return [NSMutableSet class]; }

@end /* NSMutableSet */

//*****************************************************************************
//
// 		NSConcreteSet 
//
//*****************************************************************************

@implementation NSConcreteSet

- (id) init
{
    table = NSCreateHashTable(NSObjectHashCallBacks, 0);
    return self;
}

- (id) initWithObjects:(id*)objects count:(unsigned int)count
{
unsigned i;

	table = NSCreateHashTable(NSObjectHashCallBacks, count);
    for (i = 0; i < count; i++)
		NSHashInsert(table, objects[i]);

    return self;
}

- (id) initWithSet:(NSSet *)set copyItems:(BOOL)flag
{
id obj, en = [set objectEnumerator];

    table = NSCreateHashTable(NSObjectHashCallBacks, [set count]);
    while((obj = [en nextObject]))
		NSHashInsert(table, flag ? [[obj copy] autorelease] : obj);

    return self;
}

- (void) dealloc
{
    NSFreeHashTable(table);
    [super dealloc];
}

- (id) copyWithZone:(NSZone *) z						{ return [self retain]; }
- (unsigned int) count			{ return NSCountHashTable(table); }
- (id) member:(id)anObject		{ return (NSObject*)NSHashGet(table,anObject);}

- (NSEnumerator *) objectEnumerator
{
	return [[[NSSetEnumerator alloc] initWithSet:self 
									 mode:setEnumHash] autorelease];
}

- (void) __setObjectEnumerator:(void*)en;					// Private methods
{
    *((NSHashEnumerator*)en) = NSEnumerateHashTable(table);
}

@end /* NSConcreteSet */

//*****************************************************************************
//
// 		NSConcreteMutableSet 
//
//*****************************************************************************

@implementation NSConcreteMutableSet					

- (id) init
{
    table = NSCreateHashTable(NSObjectHashCallBacks, 0);
    return self;
}

- (id) initWithObjects:(id*)objects count:(unsigned int)count
{
	unsigned i;
	table = NSCreateHashTable(NSObjectHashCallBacks, count);
    for (i = 0; i < count; i++)
		NSHashInsert(table, objects[i]);
#if 0
	NSLog(@"NSConcreteMutableSet initWithObjects -> %@", self);
#endif
    return self;
}

- (id) initWithSet:(NSSet *)set copyItems:(BOOL)flag
{
id obj, en = [set objectEnumerator];

    table = NSCreateHashTable(NSObjectHashCallBacks, [set count]);
    while((obj = [en nextObject]))
		NSHashInsert(table, flag ? [[obj copy] autorelease] : obj);

    return self;
}

- (id) initWithCapacity:(unsigned int)numItems
{
	table = NSCreateHashTable(NSObjectHashCallBacks, numItems);
	return self;
}

- (void) dealloc
{
    NSFreeHashTable(table);
    [super dealloc];
}

- (id) member:(id)anObject						// Accessing keys and values
{ 
	return (NSObject*)NSHashGet(table, anObject);
}

- (NSEnumerator *) objectEnumerator
{
    return [[[NSSetEnumerator alloc] initWithSet:self 
									 mode:setEnumHash] autorelease];
}

- (void) addObject:(id)object		{ NSHashInsert(table, object); }
- (void) removeObject:(id)object	{ NSHashRemove(table, object); }
- (void) removeAllObjects			{ NSResetHashTable(table); }
- (unsigned int) count				{ return NSCountHashTable(table); }

- (void) __setObjectEnumerator:(void*)en;					// Private methods
{
    *((NSHashEnumerator*)en) = NSEnumerateHashTable(table);
}

@end /* NSConcreteMutableSet */

//*****************************************************************************
//
// 		NSCountedSet 
//
//*****************************************************************************

@implementation NSCountedSet

- (id) init						{ return [self initWithCapacity:0]; }

- (id) initWithObjects:(id*)objects 
				 count:(unsigned int)count
{
	unsigned int i;
	for(i=0; i<count; i++)
		[self addObject:objects[i]];
	return self;
}

- (id) initWithArray:(NSArray *) array
{
	id obj, en = [array objectEnumerator];
    [self initWithCapacity:[array count]];
    while((obj = [en nextObject]))
		[self addObject:obj];
    return self;
}

- (id) initWithSet:(NSSet *)set
{
	id obj, en = [set objectEnumerator];
    [self initWithCapacity:[set count]];
    while((obj = [en nextObject]))
		[self addObject:obj];
    return self;
}

- (id) initWithCapacity:(unsigned int)aNumItems
{
	table = NSCreateMapTable(NSObjectMapKeyCallBacks,
							 NSIntMapValueCallBacks,
							 aNumItems);
	return self;
}

- (void) dealloc
{
    NSFreeMapTable(table);
    [super dealloc];
}

- (id) mutableCopyWithZone:(NSZone *) z												// NSCopying
{
    return [[NSCountedSet alloc] initWithSet:self];
}

- (unsigned int) count					{ return NSCountMapTable(table); }

- (id) member:(id)anObject
{
id k, v;

    return NSMapMember(table,(void*)anObject,(void**)&k, (void**)&v) ? k : nil;
}

- (unsigned) countForObject:(id)anObject
{
    return (unsigned)(unsigned long)NSMapGet(table, anObject);
}

- (NSEnumerator *) objectEnumerator
{
    return [[[NSSetEnumerator alloc] initWithSet:self 
									 mode:setEnumMap] autorelease];
}

- (void) addObject:(id)object
{
	NSMapInsert(table,object,(void*)((unsigned long)NSMapGet(table,object)+1));
}

- (void) removeObject:(id)object		{ NSMapRemove(table, object); }
- (void) removeAllObjects				{ NSResetMapTable(table); }

- (NSString*) descriptionWithLocale:(NSDictionary*)locale
							 indent:(unsigned int)level;
{
int count = [self count];
NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:count];
NSEnumerator *enumerator = [self objectEnumerator];
id key;
    
    while((key = [enumerator nextObject]))
		[d setObject: [NSNumber numberWithUnsignedInt:[self 
							countForObject:key]] forKey:key];
    
    return [d descriptionWithLocale:locale indent:level];
}

- (void) __setObjectEnumerator:(void*)en;					// Private methods
{
    *((NSMapEnumerator*)en) = NSEnumerateMapTable(table);
}

@end /* NSCountedSet */
