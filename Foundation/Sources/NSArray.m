/*
 NSArray.m

 Array object which stores other objects.

 Copyright (C) 1995, 1996 Free Software Foundation, Inc.

 Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	March 1995
 mySTEP:	Felipe A. Rodriguez <far@pcmagic.net>
 Date:	Mar 1999

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#include <string.h>
#include <limits.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSData.h>

#import "NSPrivate.h"

//
// Class variables
//
static Class __mutableArrayClass = Nil;
static Class __arrayClass = Nil;
static Class __stringClass = Nil;


//*****************************************************************************
//
// 		NSArrayEnumeratorReverse, NSArrayEnumerator
//
//*****************************************************************************

// CHECKME: what is with mutable arrays? adding objects may change the _contents reference!
// if we don't cache anArray->_contents but use _array->_contents and _array->_count we can even protect against problems

@interface NSArrayEnumeratorReverse : NSEnumerator
{
	NSArray *_array;
	NSInteger _index;
}
@end

@implementation NSArrayEnumeratorReverse

+ (id) allocWithZone:(NSZone *)z
{
	id o=[super allocWithZone:z];
#if 0
	NSLog(@"NSArrayEnumeratorReverse %p alloc", o);
#endif
	return o;
}

- (id) _initWithArray:(NSArray*)anArray
{
	_array = [anArray retain];
	_index = _array->_count - 1;
#if 0
	NSLog(@"NSArrayEnumeratorReverse %p initWithArray array: %p %@", self, _array, _array);
#endif
	return self;
}

- (void) _reset
{
	_index = _array->_count - 1;
}

- (void) dealloc
{
#if 0
	NSLog(@"NSArrayEnumeratorReverse %p dealloc", self);
	NSLog(@"  array: %p", _array);
	NSLog(@"  contents: %p", _contents);
	NSLog(@"  a->contents: %p", _array->_contents);
	NSLog(@"  array->class: %@", NSStringFromClass(*(Class *) _array));
	NSLog(@"  array: %@", [_array description]);
	NSLog(@"  again: %p %@", _array, _array);
	NSLog(@"  retainCount=%u", [_array retainCount]);
	NSLog(@"  class=%@", NSStringFromClass([_array class]));
#endif
	[_array release];
	[super dealloc];
}

- (NSArray *) allObjects	{ NSArray *all=[_array subarrayWithRange:NSMakeRange(0, _index)]; _index= -1; return all; }

- (id) nextObject
{
	if(_index < 0)
		return nil;	// done
	if(_index >= _array->_count)
		[NSException raise:NSInternalInconsistencyException format:@"Mutable NSArray changed during enumeration"];
	return _array->_contents[_index--];
}

@end /* NSArrayEnumeratorReverse */


@interface NSArrayEnumerator : NSArrayEnumeratorReverse
{
	int _count;
}
@end

@implementation NSArrayEnumerator

- (id) _initWithArray:(NSArray*)anArray
{
	_array = [anArray retain];
	_count = _array->_count;
#if 0
	NSLog(@"NSArrayEnumerator %p initWithArray array: %p %@", self, _array, _array);
	NSLog(@"  contents: %p", _contents);
	NSLog(@"  a->contents: %p", _array->_contents);
#endif
	return self;
}

- (void) _reset
{
	_index = 0;
}

- (id) nextObject
{
	if(_index > _array->_count)
		[NSException raise:NSInternalInconsistencyException format:@"Mutable NSArray changed during enumeration"];
	return (_index >= _array->_count) ? nil : _array->_contents[_index++];
}

- (id) _previousObject	// inofficial!
{
	return (_index < 0) ? nil : _array->_contents[_index--];
}

- (NSArray *) allObjects	{ NSArray *all=[_array subarrayWithRange:NSMakeRange(_index, _array->_count-_index)]; _index=_array->_count; return all; }

@end /* NSArrayEnumerator */

//*****************************************************************************
//
// 		NSArray
//
//*****************************************************************************

@implementation NSArray

+ (void) initialize
{
	if (self == (__arrayClass = [NSArray class]))
		{
		__mutableArrayClass = [NSMutableArray class];
		__stringClass = [NSString class];
		}
}

+ (id) array { return [[self new] autorelease]; }

+ (id) arrayWithArray:(NSArray*)array
{
	return [[[self alloc] initWithArray: array] autorelease];
}

+ (id) arrayWithContentsOfFile:(NSString*)file
{
	return [[[self alloc] initWithContentsOfFile: file] autorelease];
}

+ (id) arrayWithContentsOfURL:(NSURL*)url
{
	return [[[self alloc] initWithContentsOfURL: url] autorelease];
}

+ (id) arrayWithObject:(id)anObject
{
	if (anObject == nil)
		[NSException raise:NSInvalidArgumentException
					format:@"arrayWithObject:nil"];

	return [[(NSArray *)[self alloc] initWithObjects:&anObject count:1] autorelease];
}

+ (id) arrayWithObjects:(id*)objects count:(NSUInteger)count
{
	return [[(NSArray *)[self alloc] initWithObjects: objects count: count] autorelease];
}

+ (id) arrayWithObjects: (id) firstObject, ...
{
	id obj, *k, array;
	va_list va;
	NSUInteger count;

	va_start(va, firstObject);
	for (count = 1, obj = firstObject; obj; obj = va_arg(va, id), count++);
	va_end(va);

	if (!OBJC_MALLOC(k, id, count))
		[NSException raise: NSMallocException format:@"malloc failed in NSArray -initWithObjects:"];

	va_start(va, firstObject);
	for (count = 0, obj = firstObject; obj; obj = va_arg(va, id))
		k[count++] = obj;
	va_end(va);

	array = [(NSArray *)[self alloc] initWithObjects:k count:count];

	objc_free(k);

	return [array autorelease];
}

- (id) initWithObjects:(id) firstObject, ...
{
	id obj;
	va_list va;
	NSUInteger count;

	va_start(va, firstObject);
	for (count = 1, obj = firstObject; obj; obj = va_arg(va, id), count++);
	va_end(va);

	if ((_contents = objc_malloc(sizeof(id) * count)) == 0)
		[NSException raise: NSMallocException format:@"malloc failed in NSArray -initWithObjects:"];

	va_start(va, firstObject);
	for (_count = 0, obj = firstObject; obj; obj = va_arg(va, id))
		_contents[_count++] = [obj retain];
	va_end(va);

	return self;
}

- (id) initWithContentsOfFile:(NSString*)fileName
{
	NSString *err=nil;
	NSPropertyListFormat fmt=NSPropertyListAnyFormat;	// accept any format
	id o=[NSData dataWithContentsOfFile:fileName];
	if(!o)
		return nil;
	o=[NSPropertyListSerialization propertyListFromData:o
									   mutabilityOption:[self class] == __arrayClass?NSPropertyListImmutable:NSPropertyListMutableContainers
												 format:&fmt
									   errorDescription:&err];
	[err autorelease];
	if(!o)
		[NSException raise: NSParseErrorException format: @"NSArray %@ for file %@", err, fileName];
	if(![o isKindOfClass:__arrayClass])
		[NSException raise: NSParseErrorException
					format: @"%@ does not contain a %@ property list", fileName, NSStringFromClass([self class])];
	return [self initWithArray:o];
}

- (id) initWithContentsOfURL:(NSURL*)url
{
	NSString *err=nil;
	NSPropertyListFormat fmt=NSPropertyListAnyFormat;	// accept any format
	id o=[NSData dataWithContentsOfURL:url];
	if(!o)
		return nil;
	o=[NSPropertyListSerialization propertyListFromData:o
									   mutabilityOption:[self class] == __arrayClass?NSPropertyListImmutable:NSPropertyListMutableContainers
												 format:&fmt
									   errorDescription:&err];
	[err autorelease];
	if(!o)
		[NSException raise: NSParseErrorException format: @"NSArray %@ for URL %@", err, url];
	if(![o isKindOfClass:__arrayClass])
		[NSException raise: NSParseErrorException
					format: @"%@ does not contain a %@ property list", url, NSStringFromClass([self class])];
	return [self initWithArray:o];
}

- (id) initWithArray:(NSArray*)array
{
	return [self initWithObjects:array->_contents count:array->_count];
}

- (id) init { return [self initWithObjects: NULL count: 0]; }

- (id) initWithObjects:(id*)objects count:(NSUInteger)count
{
	if (count > 0)									// designated initializer
		{
		unsigned i;

		if ((_contents = objc_malloc(sizeof(id) * count)) == 0)
			[NSException raise: NSMallocException format:@"malloc failed in NSArray -initWithObjects:count:"];

		for (i = 0; i < count; i++)
			{
			if ((_contents[i] = [objects[i] retain]) == nil)
				{
				_count = i;
				[self release];
				[NSException raise: NSInvalidArgumentException
							format: @"NSArray initWithObjects: Tried to add nil"];
				}
			}
		_count = count;
		}

	return self;
}

- (void) dealloc
{
#if 0
	NSLog(@"NSArray dealloc %p", self);
#endif
	while(_count--)
		[_contents[_count] release];
	if (_contents)
		objc_free(_contents);

	[super dealloc];
}

- (NSUInteger) count					{ return _count; }
- (NSUInteger) hash					{ return _count; }	// different size means different
- (id *) _contents					{ return _contents; }

- (id) lastObject
{
	return (_count == 0) ? nil : _contents[_count-1];
}

- (id) objectAtIndex:(NSUInteger)idx
{
	if (idx >= _count)
		{
#if 0	// empty array also raises exceptions
		if(idx == 0 && _count == 0)
			return nil;
#endif
#if 1	// useful for debugging...
		NSLog(@"index %lu out of bounds (%lu) of %@", (unsigned long)idx, (unsigned long)_count, self);
#endif
		[NSException raise:NSRangeException format:@"objectAtIndex: Index out of bounds"];
		}

	return _contents[idx];
}

- (void) encodeWithCoder:(NSCoder*)aCoder
{
	[aCoder encodeValueOfObjCType: @encode(unsigned) at: &_count];
	if (_count > 0)
		[aCoder encodeArrayOfObjCType:@encode(id) count:_count at:_contents];
}

- (id) initWithCoder:(NSCoder*)aCoder
{
#if 0
	NSLog(@"NSArray initWithCoder:%@", aCoder);
#endif
	if([aCoder allowsKeyedCoding])
		{
#if 0
		NSLog(@"%@ initWithKeyedCoder", NSStringFromClass([self class]));
#endif
		[self release];
		return [[aCoder decodeObjectForKey:@"NS.objects"] retain];
		}
	[aCoder decodeValueOfObjCType: @encode(unsigned) at: &_count];
#if 0
	NSLog(@"  count=%d", _count);
#endif
	if ((_contents = objc_calloc(MAX(_count, 1), sizeof(id))) == 0)
		[NSException raise:NSMallocException format:@"Unable to malloc array"];
	if (_count > 0)
		[aCoder decodeArrayOfObjCType:@encode(id) count:_count at:_contents];	// objects will be retained by decodeArray
#if 0
	NSLog(@"done - array = %@", self);
#endif
	return self;
}

// FIXME: is this correct? And how big is the stack???

- (id) copyWithZone:(NSZone *) zone														// NSCopying
{
	id oldObjects[_count], newObjects[_count];
	NSArray *newArray;
	BOOL needCopy = NO;
	NSUInteger i;

	[self getObjects: oldObjects];
	for (i = 0; i < _count; i++)
		{
		newObjects[i] = [oldObjects[i] copy];
		if (newObjects[i] != oldObjects[i])
			needCopy = YES;
		}
	if (needCopy || [self isKindOfClass: __mutableArrayClass])
		{													// a deep copy is
			newArray = [[self class] alloc];					// required
			if(_count > 0)
				newArray = [newArray initWithObjects:newObjects count:_count];
			else
				newArray = [newArray init];
		}
	else
		newArray = [self retain];

	for (i = 0; i < _count; i++)
		[newObjects[i] release];

	return newArray;
}

- (id) mutableCopyWithZone:(NSZone *) zone
{ // NSMutableCopying a shallow copy
	return [[__mutableArrayClass alloc] initWithArray:self];
}

- (NSArray*) arrayByAddingObject:(id)anObject
{
	NSUInteger c = _count + 1;
	id objects[c];

	[self getObjects: objects];
	objects[_count] = anObject;

	return [[[NSArray alloc] initWithObjects:objects count: c] autorelease];
}

- (NSArray*) arrayByAddingObjectsFromArray:(NSArray*)anotherArray
{
	NSUInteger c = _count + [anotherArray count];
	id objects[c];

	[self getObjects: objects];
	[anotherArray getObjects: &objects[_count]];

	return [NSArray arrayWithObjects: objects count: c];
}

- (void) getObjects:(id*)aBuffer
{
	memcpy(aBuffer, _contents, _count * sizeof(id*));
}

- (void) getObjects:(id*)aBuffer range:(NSRange)r
{
	if (NSMaxRange(r) > _count)
		[NSException raise: NSRangeException format: @"getObjects: Range out of bounds"];
	memcpy(aBuffer, _contents + r.location, r.length * sizeof(id*));
}

- (NSUInteger) indexOfObjectIdenticalTo:(id)anObject
{
	NSUInteger i;

	for (i = 0; i < _count; i++)
		if (anObject == _contents[i])
			return i;

	return NSNotFound;
}

- (NSUInteger) indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)aRange
{
	NSUInteger i, e = MIN(NSMaxRange(aRange), _count);

	for (i = aRange.location; i < e; i++)
		if (anObject == _contents[i])
			return i;

	return NSNotFound;
}

- (NSUInteger) indexOfObject:(id)anObject
{
	NSUInteger i;

	if (anObject == nil)
		return NSNotFound;

	if (_count > 8)							// For large arrays, speed things
		{									// up a bit by caching the method.
			SEL	sel = @selector(isEqual:);
			BOOL (*imp)(id,SEL,id);

			imp = (BOOL (*)(id,SEL,id))[anObject methodForSelector: sel];

			for (i = 0; i < _count; i++)
				if ((*imp)(anObject, sel, _contents[i]))
					return i;
		}
	else
		{
		for (i = 0; i < _count; i++)
			if ([anObject isEqual: _contents[i]])
				return i;
		}

	return NSNotFound;
}

- (NSUInteger) indexOfObject:(id)anObject inRange:(NSRange)aRange
{
	NSUInteger i, e = MIN(NSMaxRange(aRange), _count);

	for (i = aRange.location; i < e; i++)
		{
		id o = _contents[i];

		if (anObject == o || [o isEqual: anObject])
			return i;
		}

	return NSNotFound;
}

- (BOOL) containsObject:(id)anObject
{
	return ([self indexOfObject:anObject] != NSNotFound);
}

- (BOOL) isEqual:(id)anObject
{
	if ([anObject isKindOfClass:__arrayClass])
		return [self isEqualToArray:anObject];

	return NO;
}

- (BOOL) isEqualToArray:(NSArray*)otherArray
{
	NSUInteger i;

	if (_count != [otherArray count])
		return NO;
	for (i = 0; i < _count; i++)
		if (![_contents[i] isEqual: [otherArray objectAtIndex: i]])
			return NO;

	return YES;
}

- (void) makeObjectsPerformSelector:(SEL)aSelector
{
	NSUInteger i = _count;

	while (i-- > 0)
		[_contents[i] performSelector: aSelector];
}

- (void) makeObjectsPerformSelector:(SEL)aSelector withObject:argument
{
	NSUInteger i = _count;

	while (i-- > 0)
		[_contents[i] performSelector:aSelector withObject:argument];
}

static NSInteger compare_function(id elem1, id elem2, void* comparator)
{
	return (NSInteger)[elem1 performSelector:comparator withObject:elem2];
}

- (NSArray*) sortedArrayUsingSelector:(SEL)comparator
{
	return [self sortedArrayUsingFunction:compare_function context:(void*)comparator];
}

- (NSArray*) sortedArrayUsingFunction:(NSInteger(*)(id,id,void*))comparator
							  context:(void*)context
{
	SEL s = @selector(sortUsingFunction:context:);
	IMP im = [NSMutableArray instanceMethodForSelector: s];
	NSArray *sortedArray = [NSArray arrayWithArray: self];

	(*im)(sortedArray, s, comparator, context);

	return sortedArray;
}

- (NSData*) sortedArrayHint				{ return nil; }

- (NSArray*) sortedArrayUsingFunction:(NSInteger(*)(id,id,void*))comparator
							  context:(void*)context
							  hint:(NSData*)hint
{
	return [self sortedArrayUsingFunction:comparator context:context];
}

- (NSString*) componentsJoinedByString:(NSString*)separator
{
	NSUInteger i;
	id s = [NSMutableString stringWithCapacity:2]; 			// arbitrary capacity

	if (_count < 1)
		return s;

	[s appendString:[_contents[0] description]];
	for (i = 1; i < _count; i++)
		{
		[s appendString:separator];
		[s appendString:[_contents[i] description]];
		}

	return s;
}

- (NSArray*) pathsMatchingExtensions:(NSArray*)extensions
{
	NSUInteger i;
	NSMutableArray *a = [NSMutableArray arrayWithCapacity: 1];

	for (i = 0; i < _count; i++)
		{
		id o = _contents[i];
		if ([o isKindOfClass: __stringClass] && [extensions containsObject: [o pathExtension]])
			[a addObject: o];
		}

	return a;
}

- (id) firstObjectCommonWithArray:(NSArray*)otherArray
{
	NSUInteger i;

	for (i = 0; i < _count; i++)
		if ([otherArray containsObject:_contents[i]])
			return _contents[i];

	return nil;
}

- (NSArray*) subarrayWithRange:(NSRange)range
{
	NSUInteger c = _count - 1;					// If array is empty or start is
	NSUInteger i = range.location, j;				// beyond end of array then return
												// an empty array
	if ((_count == 0) || (range.location > c))
		return [NSArray array];

	j = NSMaxRange(range);							// Check if length extends
	j = (j > c) ? c : j - 1;						// beyond end of array

	return [NSArray arrayWithObjects: _contents+i count: j-i+1];
}

- (NSEnumerator*) objectEnumerator
{
	// cache if array is large enough
	return [[[NSArrayEnumerator alloc] _initWithArray:self] autorelease];
}

- (NSEnumerator*) reverseObjectEnumerator
{
	// cache
	return [[[NSArrayEnumeratorReverse alloc] _initWithArray:self] autorelease];
}

- (NSString*) description
{
	return [self descriptionWithLocale:nil indent:0];
}

- (NSString*) descriptionWithLocale:(id)locale
{
	return [self descriptionWithLocale:locale indent:0];
}

- (NSString*) descriptionWithLocale:(id)locale
							 indent:(NSUInteger)level
{
	NSMutableString	*result;
	NSUInteger indentSize;
	NSUInteger indentBase;
	NSMutableString	*iBaseString;
	NSMutableString	*iSizeString;
	NSAutoreleasePool *arp = [NSAutoreleasePool new];
	NSUInteger count;
	NSUInteger i;
	// Indentation is at four space
	// intervals using tab characters
	// to replace multiples of eight
	indentBase = level << 2;				// spaces.
	count = indentBase >> 3;				// Calc the size of the strings
	if ((indentBase % 4) == 0) 				// needed to achieve this and
		indentBase = count;					// build strings to make up the
	else 									// indentation.
		indentBase = count + 4;

	iBaseString = [NSMutableString stringWithCapacity: indentBase];
	for (i = 1; i < count; i++)
		[iBaseString appendString: @"\t"];

	//    if (count != indentBase)
	//		[iBaseString appendString: @"    "];

	level++;
	indentSize = level << 2;
	count = indentSize >> 3;
	if ((indentSize % 4) == 0)
		indentSize = count;
	else
		indentSize = count + 4;

	iSizeString = [NSMutableString stringWithCapacity: indentSize];
	for (i = 1; i < count; i++)
		[iSizeString appendString: @"\t"];

	//    if (count != indentSize)
	//		[iSizeString appendString: @"    "];

	count = _count;
	result = [[NSMutableString alloc] initWithCapacity:20*count];
	[result appendString: count < 3?@"(":@"(\n"];
	for (i = 0; i < count; i++)
		{
		id item = [self objectAtIndex:i];
		const char *s;

		if(!item)
			continue;	// should not be possible - but just to be safe!
#if 0
		fprintf(stderr, "NSArray descriptionWithLocale item %d %p\n", i, item);
#endif
		if (![item isKindOfClass: __stringClass])
			{
				if ([item respondsToSelector:
					 @selector(descriptionWithLocale:indent:)])
					item = [item descriptionWithLocale: locale indent: level];
				else if([item respondsToSelector:@selector(descriptionWithLocale:)])
					item = [item descriptionWithLocale: locale];
				else
					item = [item description];
			}

		s = [item UTF8String];		// if str with whitespc add quotes
		if((*s != '{' && *s != '(' && *s != '<') && (strpbrk(s, " %-\t") != NULL))
			item = [NSString stringWithFormat:@"\"%@\"", item];

		[result appendString: iSizeString];
		[result appendString: item];
		if(count < 3)
			{
			if(i < count - 1)
				[result appendString: @", "];
			}
		else if(i == count - 1)
			[result appendString: @"\n"];
		else
			[result appendString: @",\n"];
		}
	[result appendString: iBaseString];
	[result appendString: @")"];
	[arp release];
	return [result autorelease];
}

- (id) valueForKey:(NSString *)key;
{
	// make a copy where valueForKey is called on each element
	// substitute NSNull where nil is returned
	return NIMP;
}

- (void) setValue:(id)value forKey:(NSString *)key;
{
	unsigned i = _count;
	while (i-- > 0)
		[_contents[i] setValue:value forKey:key];
}

@end /* NSArray */

//*****************************************************************************
//
// 		NSMutableArray
//
//*****************************************************************************

@implementation NSMutableArray

- (id) initWithCapacity:(NSUInteger)cap
{
	_capacity = (cap == 0) ? 1 : cap;
	if ((_contents = objc_malloc(sizeof(id) * _capacity)) == 0)
		{
		[self release];
		[NSException raise:NSMallocException format:@"malloc failed in NSMutableArray -initWithCapacity:"];
		}
	return self;
}

- (id) initWithObjects:(id*)objects count:(NSUInteger)count
{
	NSUInteger i;
	_capacity = (count == 0) ? 1 : count;
	if ((_contents = objc_malloc(sizeof(id) * _capacity)) == 0)
		{
		[NSException raise:NSMallocException format:@"malloc failed in NSMutableArray -initWithObjects:count:"];
		[self release];
		}
	for (i = 0; i < count; i++)
		{
		if ((_contents[i] = [objects[i] retain]) == nil)
			{
			[self release];
			[NSException raise: NSInvalidArgumentException format: @"NSMutableArray initWithObjects: Tried to add nil"];
			}
		}
	_count = i;
	return self;
}

- (id) initWithCoder:(NSCoder*)aCoder
{
	if([aCoder allowsKeyedCoding])
		{
#if 0
		NSLog(@"%@ initWithKeyedCoder", NSStringFromClass([self class]));
#endif
		[self release];
		return [[aCoder decodeObjectForKey:@"NS.objects"] mutableCopy];
		}
	self=[super initWithCoder: aCoder];
	_capacity = _count;
	if(!_capacity)
		_contents = objc_malloc(sizeof(id) * (_capacity=1));	// at least one entry
	return self;
}

- (void) addObject:(id)anObject
{
	if (anObject == nil)
		{
#if 0
		NSLog(@"NSMutableArray addObject: Tried to add nil to %@", self);
		return;
#endif
		[NSException raise: NSInvalidArgumentException
					format: @"NSMutableArray addObject: Tried to add nil to %@", self];
		}
	if (_count >= _capacity)
		{
		id *ptr;
		unsigned newcapacity = 2*_count+2;	// exponentially grow
		if ((ptr = objc_realloc(_contents, newcapacity * sizeof(id))) == 0)
			[NSException raise: NSMallocException format: @"Unable to grow %@", self];
		_capacity = newcapacity;
		_contents = ptr;
		}

	_contents[_count++] = [anObject retain];
}

- (void) insertObject:(id)anObject atIndex:(NSUInteger)idx
{
	if (!anObject)
		[NSException raise: NSInvalidArgumentException
					format: @"Tried to insert nil into %@", self];

	if (idx > _count)
		[NSException raise: NSRangeException
					format: @"insertObject:atIndex:, index %d is out of range", idx];

	if (_count == _capacity)
		{ // needs more space
			id *ptr;
			unsigned newcapacity = 2*_count+2;	// exponentially grow
			if ((ptr = objc_realloc(_contents, newcapacity * sizeof(id))) == 0)
				[NSException raise: NSMallocException format: @"Unable to grow %@", self];
			_capacity = newcapacity;
			_contents = ptr;
		}
	memmove(&_contents[idx+1], &_contents[idx], sizeof(_contents[0])*(_count-idx));
	_count++;
	_contents[idx] = [anObject retain];
}

- (void) replaceObjectAtIndex:(NSUInteger)idx withObject:(id)anObject
{
	if (anObject == nil)
		[NSException raise: NSInvalidArgumentException
					format: @"Tried to replace with nil (index=%u): %@", idx, self];
	if (idx >= _count)
		[NSException raise: NSRangeException
					format: @"in replaceObjectAtIndex:withObject:, \
		 index %d is out of range: %@", idx, self];

	if(_contents[idx] == anObject)
		return;	// already the same object
	[anObject retain];
	[_contents[idx] release];
	_contents[idx] = anObject;
}

- (void) exchangeObjectAtIndex:(NSUInteger) i1 withObjectAtIndex:(NSUInteger) i2;
{
	id tmp;
	if (i1 >= _count || i2 >= _count)
		[NSException raise: NSRangeException
					format: @"in exchangeObjectAtIndex:withObjectAtIndex:, index %d, %d is out of range", i1, i2];

	tmp = _contents[i1];
	_contents[i1] = _contents[i2];
	_contents[i2] = tmp;
}

- (void) removeObjectIdenticalTo:(id) anObject inRange:(NSRange)aRange
{
	NSUInteger i = MIN(NSMaxRange(aRange), _count);
	id o;

	while (i-- > aRange.location)
		{
		if ((o = _contents[i]) == anObject)
			{
			_count--;
			memmove(&_contents[i], &_contents[i+1], sizeof(_contents[0])*(_count-i));
			[o release];
			}
		}
}

- (void) removeObjectIdenticalTo:(id) anObject
{ // remove all occurrences!
	NSUInteger i = _count;
	id o;

	while (i-- > 0)
		{
		if ((o = _contents[i]) == anObject)
			{
			_count--;
			memmove(&_contents[i], &_contents[i+1], sizeof(_contents[0])*(_count-i));
#if 0
			NSLog(@"removeObjectIdenticalTo: releasing %@", o);
#endif
			[o release];
			}
		}
}

- (void) removeObjectAtIndex:(NSUInteger)idx
{
	id o;

	if (idx >= _count)
		[NSException raise: NSRangeException
					format:@"removeObjectAtIndex: %d is out of range", idx];

	o = _contents[idx];
	_count--;
	memmove(&_contents[idx], &_contents[idx+1], sizeof(_contents[0])*(_count-idx));
	[o release];
}

- (void) replaceObjectsInRange:(NSRange)aRange
		  withObjectsFromArray:(NSArray*)anArray
{
	NSEnumerator *e;
	id o;
	if ([self count] < NSMaxRange(aRange))
		[NSException raise: NSRangeException
					format: @"replaceObjectsInRange: Replacing objects beyond end of array."];
	e = [anArray reverseObjectEnumerator];
	while ((o = [e nextObject]))
		[self insertObject: o atIndex: aRange.location];
	aRange.location += aRange.length;
	[self removeObjectsInRange: aRange];
}

- (void) replaceObjectsInRange:(NSRange)aRange
		  withObjectsFromArray:(NSArray*)anArray
						 range:(NSRange)anotherRange
{
	[self replaceObjectsInRange: aRange
		   withObjectsFromArray: [anArray subarrayWithRange: anotherRange]];
}

- (void) removeObject:(id) anObject inRange:(NSRange)aRange
{
	NSUInteger i = MIN(NSMaxRange(aRange), _count);
	id o;

	while (i-- > aRange.location)
		{
		if ((o = _contents[i]) == anObject || [o isEqual: anObject])
			{
			_count--;
			memmove(&_contents[i], &_contents[i+1], sizeof(_contents[0])*(_count-i));
			[o release];
			}
		}
}

@end

@implementation NSMutableArray (NonCore)

+ (id) arrayWithCapacity:(NSUInteger)numItems
{
	return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (id) init							{ return [self initWithCapacity:2]; }

- (void) removeObject:(id) anObject
{ // removes all occurrences!
	NSUInteger i = _count;
	id o;

	while (i-- > 0)
		{
		if ((o = _contents[i]) == anObject || [o isEqual: anObject])
			{
			_count--;
			memmove(&_contents[i], &_contents[i+1], sizeof(_contents[0])*(_count-i));
#if 0
			NSLog(@"removeObject: releasing %@", o);
#endif
			[o release];
			}
		}
}

- (BOOL) writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile
{
	NSString *error;
	// optionally use NSPropertyListBinaryFormat_v1_0
	NSData *desc=[NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
#if 0
	NSLog(@"writeToFile:%@ %@", path, desc);
#endif
	return [desc writeToFile:path atomically:useAuxiliaryFile];
}

- (void) addObjectsFromArray:(NSArray*)otherArray
{
	NSUInteger i, c = [otherArray count];
	for (i = 0; i < c; i++)
		[self addObject: [otherArray objectAtIndex: i]];
}

- (void) setArray:(NSArray *)otherArray
{
	[self removeAllObjects];
	[self addObjectsFromArray: otherArray];
}

- (void) removeAllObjects
{
	NSUInteger i;
	for(i=0; i < _count; i++)
		[_contents[i] release];
	_count = 0;
}

- (void) removeLastObject
{
	if (_count == 0)
		[NSException raise: NSRangeException
					format: @"Trying to removeLastObject from an empty array."];
	_count--;
	[_contents[_count] release];
}

- (void) removeObjectsFromIndices:(NSUInteger *) indices
					   numIndices:(NSUInteger) count
{
	while (count--)
		[self removeObjectAtIndex:indices[count]];
}

- (void) removeObjectsInArray:(NSArray*)otherArray
{
	NSUInteger i, c = [otherArray count];
	for (i = 0; i < c; i++)
		[self removeObject:[otherArray objectAtIndex:i]];
}

/* not very efficient! */

- (void) removeObjectsInRange:(NSRange)aRange
{
	NSUInteger i = MIN(NSMaxRange(aRange), [self count]);
	while (i-- > aRange.location)
		[self removeObjectAtIndex: i];
}

- (void) removeObjectsAtIndexes:(NSIndexSet *)indexes
{
	NSUInteger i;
	for (i = [indexes firstIndex]; i != NSNotFound; i=[indexes indexGreaterThanIndex:i])
		[self removeObjectAtIndex: i];
}

- (void) insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
	NSUInteger i=[indexes firstIndex], j=0, count=[objects count];
	// assert(count, [indexes count]
	for(j=0; j<count && i != NSNotFound; j++, i=[indexes indexGreaterThanIndex:i])
		[self insertObject:[objects objectAtIndex:j] atIndex:i];
}

- (void) replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
{
	NSUInteger i=[indexes firstIndex], j=0, count=[objects count];
	// assert(count, [indexes count]
	for(j=0; j<count && i != NSNotFound; j++, i=[indexes indexGreaterThanIndex:i])
		[self replaceObjectAtIndex:i withObject:[objects objectAtIndex:j]];
}

/*
 qsort is taken from GNU C Library (also LGPL)
 This file is part of the GNU C Library.
 Written by Douglas C. Schmidt (schmidt@ics.uci.edu).

 Adapted to mySTEP by H. N. Schaller
 FIXME: improve further since we know SIZE=sizeof(id) -
 this can be used to optimize the SWAP macro and reduce argument passing

 */

#include <stdlib.h>
#include <string.h>

/* Byte-wise swap two items of size SIZE. */

#define SWAP(a, b, size) \
do \
{ \
register size_t __size = (size); \
register char *__a = (a), *__b = (b); \
do \
{ \
char __tmp = *__a; \
*__a++ = *__b; \
*__b++ = __tmp; \
} while (--__size > 0); \
} while (0)

/* Discontinue quicksort algorithm when partition gets below this size.
 This particular magic number was chosen to work best on a Sun 4/260. */
#define MAX_THRESH 4

/* Stack node declarations used to store unfulfilled partition obligations. */
typedef struct
{
	char *lo;
	char *hi;
} stack_node;

/* The next 4 #defines implement a very fast in-line stack abstraction. */
#define STACK_SIZE	(8 * sizeof(unsigned long int))
#define PUSH(low, high)	((void) ((top->lo = (low)), (top->hi = (high)), ++top))
#define	POP(low, high)	((void) (--top, (low = top->lo), (high = top->hi)))
#define	STACK_NOT_EMPTY	(stack < top)


/* Order size using quicksort.  This implementation incorporates
 four optimizations discussed in Sedgewick:

 1. Non-recursive, using an explicit stack of pointer that store the
 next array partition to sort.  To save time, this maximum amount
 of space required to store an array of MAX_INT is allocated on the
 stack.  Assuming a 32-bit integer, this needs only 32 *
 sizeof(stack_node) == 136 bits.  Pretty cheap, actually.

 2. Chose the pivot element using a median-of-three decision tree.
 This reduces the probability of selecting a bad pivot value and
 eliminates certain extraneous comparisons.

 3. Only quicksorts TOTAL_ELEMS / MAX_THRESH partitions, leaving
 insertion sort to order the MAX_THRESH items within each partition.
 This is a big win, since insertion sort is faster for small, mostly
 sorted array segments.

 4. The larger of the two sub-partitions is always pushed onto the
 stack first, with the algorithm then concentrating on the
 smaller partition.  This *guarantees* no more than log (n)
 stack size is needed (actually O(1) in this case)!  */

void qsort3(void *const pbase, size_t total_elems, size_t size, int (*cmp)(id, id, void *), void *context)
{
	register char *base_ptr = (char *) pbase;

	/* Allocating SIZE bytes for a pivot buffer facilitates a better
	 algorithm below since we can do comparisons directly on the pivot. */
	char *pivot_buffer = (char *) alloca(size);
	const size_t max_thresh = MAX_THRESH * size;

	if (total_elems == 0)
		/* Avoid lossage with unsigned arithmetic below.  */
		return;

	if (total_elems > MAX_THRESH)
		{
		char *lo = base_ptr;
		char *hi = &lo[size * (total_elems - 1)];
		/* Largest size needed for 32-bit int!!! */
		stack_node stack[STACK_SIZE];
		stack_node *top = stack + 1;

		while (STACK_NOT_EMPTY)
			{
			char *left_ptr;
			char *right_ptr;

			char *pivot = pivot_buffer;

			/* Select median value from among LO, MID, and HI. Rearrange
				LO and HI so the three values are sorted. This lowers the
				probability of picking a pathological pivot value and
				skips a comparison for both the LEFT_PTR and RIGHT_PTR. */

			char *mid = lo + size * ((hi - lo) / size >> 1);

			if ((*cmp) (*(id *) mid, *(id *) lo, context) < 0)
				SWAP (mid, lo, size);
			if ((*cmp) (*(id *) hi, *(id *) mid, context) < 0)
				SWAP (mid, hi, size);
			else
				goto jump_over;
			if ((*cmp) (*(id *) mid, *(id *) lo, context) < 0)
				SWAP (mid, lo, size);
			jump_over:;
			memcpy (pivot, mid, size);
			pivot = pivot_buffer;

			left_ptr  = lo + size;
			right_ptr = hi - size;

			/* Here's the famous ``collapse the walls'' section of quicksort.
				Gotta like those tight inner loops!  They are the main reason
				that this algorithm runs much faster than others. */
			do
				{
				while ((*cmp) (*(id *) left_ptr, *(id *) pivot, context) < 0)
					left_ptr += size;

				while ((*cmp) (*(id *) pivot, *(id *) right_ptr, context) < 0)
					right_ptr -= size;

				if (left_ptr < right_ptr)
					{
					SWAP (left_ptr, right_ptr, size);
					left_ptr += size;
					right_ptr -= size;
					}
				else if (left_ptr == right_ptr)
					{
					left_ptr += size;
					right_ptr -= size;
					break;
					}
				}
			while (left_ptr <= right_ptr);

			/* Set up pointers for next iteration.  First determine whether
				left and right partitions are below the threshold size.  If so,
				ignore one or both.  Otherwise, push the larger partition's
				bounds on the stack and continue sorting the smaller one. */

			if ((size_t) (right_ptr - lo) <= max_thresh)
				{
				if ((size_t) (hi - left_ptr) <= max_thresh)
					/* Ignore both small partitions. */
					POP (lo, hi);
				else
					/* Ignore small left partition. */
					lo = left_ptr;
				}
			else if ((size_t) (hi - left_ptr) <= max_thresh)
				/* Ignore small right partition. */
				hi = right_ptr;
			else if ((right_ptr - lo) > (hi - left_ptr))
				{
				/* Push larger left partition indices. */
				PUSH (lo, right_ptr);
				lo = left_ptr;
				}
			else
				{
				/* Push larger right partition indices. */
				PUSH (left_ptr, hi);
				hi = right_ptr;
				}
			}
		}

	/* Once the BASE_PTR array is partially sorted by quicksort the rest
		is completely sorted using insertion sort, since this is efficient
		for partitions below MAX_THRESH size. BASE_PTR points to the beginning
		of the array to sort, and END_PTR points at the very last element in
		the array (*not* one beyond it!). */

#define min(x, y) ((x) < (y) ? (x) : (y))

	{
	char *const end_ptr = &base_ptr[size * (total_elems - 1)];
	char *tmp_ptr = base_ptr;
	char *thresh = min(end_ptr, base_ptr + max_thresh);
	register char *run_ptr;

	/* Find smallest element in first threshold and place it at the
	 array's beginning.  This is the smallest array element,
	 and the operation speeds up insertion sort's inner loop. */

	for (run_ptr = tmp_ptr + size; run_ptr <= thresh; run_ptr += size)
		if ((*cmp) (*(id *) run_ptr, *(id *) tmp_ptr, context) < 0)
			tmp_ptr = run_ptr;

	if (tmp_ptr != base_ptr)
		SWAP (tmp_ptr, base_ptr, size);

	/* Insertion sort, running from left-hand-side up to right-hand-side.  */

	run_ptr = base_ptr + size;
	while ((run_ptr += size) <= end_ptr)
		{
		tmp_ptr = run_ptr - size;
		while ((*cmp) (*(id *) run_ptr, *(id *) tmp_ptr, context) < 0)
			tmp_ptr -= size;

		tmp_ptr += size;
		if (tmp_ptr != run_ptr)
			{
			char *trav;

			trav = run_ptr + size;
			while (--trav >= run_ptr)
				{
				char c = *trav;
				char *hi, *lo;

				for (hi = lo = trav; (lo -= size) >= tmp_ptr; hi = lo)
					*hi = *lo;
				*hi = c;
				}
			}
		}
	}
}

// good value for stride factor is not well
#define STRIDE_FACTOR 3		// understood 3 is a fairly good choice (Sedgewick)

- (void) sortUsingFunction:(NSInteger(*)(id,id,void*))compare context:(void*)context
{
	NSUInteger c, d, stride = 1;							// Shell sort algorithm
														// from SortingInAction, a
	if(_count > 20)
		{ // use quick sort instead
			qsort3(_contents, _count, sizeof(_contents[0]), (int(*)(id,id,void*))compare, context);
			return;
		}
	while (stride <= _count)						// NeXT example
		stride = stride * STRIDE_FACTOR + 1;

	while(stride > (STRIDE_FACTOR - 1)) 			// loop to sort for each
		{											// value of stride
			stride = stride / STRIDE_FACTOR;
			for (c = stride; c < _count; c++)
				{
				BOOL found = NO;

				if (stride > c)
					break;
				d = c - stride;
				while (!found) 							// move to left until the
					{									// correct place is found
						id a = _contents[d + stride];
						id b = _contents[d];

						if ((*compare)(a, b, context) == NSOrderedAscending)
							{
							_contents[d + stride] = b;		// swap values
							_contents[d] = a;
							if (stride > d)
								break;
							d -= stride;					// jump by stride factor
							}
						else
							found = YES;
					}
				}
		}
}

static NSInteger selector_compare(id elem1, id elem2, void* comparator)
{
	return (NSInteger)(long)[elem1 performSelector:(SEL)comparator withObject:elem2];
}

- (void) sortUsingSelector:(SEL)comparator
{
	[self sortUsingFunction:selector_compare context:(void*)comparator];
}

@end /* NSMutableArray */
