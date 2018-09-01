/* 
   NSCharacterSet.m

   Character set holder object.

   Copyright (C) 1995, 1996, 1997, 1998 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	Apr 1995

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSCoder.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSBundle.h>

#import "NSPrivate.h"

							// A simple array for caching standard bitmap sets 
static NSCharacterSet *cache_set[12];
static NSLock *__cacheLock = nil;
static NSString *__charSetPath = @"CharacterSets";

@interface NSBitmapCharSet : NSCharacterSet
{
    char data[BITMAP_SIZE];
}

- (id) initWithBitmap:(NSData *)bitmap;

@end

@interface NSMutableBitmapCharSet : NSMutableCharacterSet
{
    char data[BITMAP_SIZE];
}

- (id) initWithBitmap:(NSData *)bitmap;

@end

//*****************************************************************************
//
// 		NSCharacterSet 
//
//*****************************************************************************

@implementation NSCharacterSet

+ (id) allocWithZone:(NSZone *) z
{ // Provide a default object for alloc
	return (id) NSAllocateObject([NSBitmapCharSet self], 0, z);
}

+ (NSCharacterSet *) _bitmapForSet:(NSString *)setname number:(int)number
{
	NSCharacterSet *set=nil;				// Creating standard character sets
	NSString *systemPath;
	NSAssert(number >= 0 && number < sizeof(cache_set)/sizeof(cache_set[0]), @"NSCharacterSet cache is too small");
#if 0
	NSLog(@"NSCharacterSet _bitmapForSet:%@", setname);
#endif
	if(!__cacheLock)
		__cacheLock = [NSLock new];
#if 0
	NSLog(@"NSCharacterSet: __cacheLock lock");
#endif
	[__cacheLock lock];

	if (cache_set[number] == nil)
		{
      	NS_DURING									// Search the system path
			{
				NSBundle *bundle=[NSBundle bundleForClass:[self class]];
#if 0
				NSLog(@"a");
#endif
				systemPath = [bundle pathForResource:setname
											  ofType:@"charSet"
										 inDirectory:__charSetPath];
#if 0
				NSLog(@"b path=%@", systemPath);
#endif
				if(systemPath != nil && [systemPath length] != 0)
					{ // Load the character set file
					NS_DURING 
#if 0
						NSLog(@"c");
#endif
						set = [self characterSetWithBitmapRepresentation: 
							[NSData dataWithContentsOfFile: systemPath]];
					NS_HANDLER
						NSLog(@"Unable to read NSCharacterSet file %@", systemPath);
						set=nil;
					NS_ENDHANDLER
					}
				if(!set)
					{ // If we didn't load a set then raise an exception
					[NSException raise:NSGenericException
								format:@"Could not find bitmap file %@ at %@ [%@ - %@]",
						setname, systemPath, [[NSBundle bundleForClass:[self class]] bundlePath], __charSetPath];
					}
				else
					cache_set[number] = [set retain];		// else cache the set
			}
		NS_HANDLER
			[__cacheLock unlock];
			[localException raise];
			set=nil;
		NS_ENDHANDLER
		}
	else
		set = cache_set[number];	// fetch from cache
#if 0
	NSLog(@"d");
#endif	
	[__cacheLock unlock];
#if 0
	NSLog(@"e");
#endif	
	return set;
}

+ (id) alphanumericCharacterSet
{
	return [self _bitmapForSet:@"alphanum" number: 0];
}

+ (id) controlCharacterSet
{
	return [self _bitmapForSet:@"control" number: 1];
}

+ (id) decimalDigitCharacterSet
{
	return [self _bitmapForSet:@"decimal" number: 2];
}

+ (id) decomposableCharacterSet
{
	NSLog(@"Warning: Decomposable set not yet fully specified");
	return [self _bitmapForSet:@"decomposable" number: 3];
}

+ (id) illegalCharacterSet
{
	NSLog(@"Warning: Illegal set not yet fully specified\n");
	return [self _bitmapForSet:@"illegal" number: 4];
}

+ (id) letterCharacterSet
{
	return [self _bitmapForSet:@"letterchar" number: 5];
}

+ (id) lowercaseLetterCharacterSet
{
	return [self _bitmapForSet:@"lowercase" number: 6];
}

+ (id) newlineCharacterSet
{
#if 1
	fprintf(stderr, "newlineCharacterSet\n");
#endif
//	return [self characterSetWithCharactersInString:@"\n\r"];	// makes some problem
//	return [self _bitmapForSet:@"newline" number: 11];
	static NSCharacterSet *nl;	// cache
	if(!nl)
		nl=[[self characterSetWithCharactersInString:@"\n\r"] retain];	// should also include \U0085
	return nl;
}

+ (id) nonBaseCharacterSet
{
	return [self _bitmapForSet:@"nonbase" number: 7];
}

+ (id) punctuationCharacterSet;
{
	return NIMP;
}

+ (id) symbolCharacterSet;
{
	return NIMP;
}

+ (id) capitalizedLetterCharacterSet;
{
	return NIMP;
}

+ (id) uppercaseLetterCharacterSet
{
	return [self _bitmapForSet:@"uppercase" number: 8];
}

+ (id) whitespaceAndNewlineCharacterSet
{
	return [self _bitmapForSet:@"whitespaceandnl" number: 9];
}

+ (id) whitespaceCharacterSet
{
	return [self _bitmapForSet:@"whitespace" number: 10];
}

// Creating custom character sets

+ (id) characterSetWithBitmapRepresentation:(NSData *)data
{
	return [[[NSBitmapCharSet alloc] initWithBitmap:data] autorelease];
}

+ (id) characterSetWithCharactersInString:(NSString *)aString
{
	int i, length;
	NSMutableData *bitmap = [NSMutableData dataWithLength:BITMAP_SIZE];
	char *bytes = [bitmap mutableBytes];

	if (!aString)
		[NSException raise:NSInvalidArgumentException
					 format:@"Creating character set with nil string"];
	
	length = [aString length];
	for (i = 0; i < length; i++)
		{
		unsigned letter = [aString characterAtIndex:i];
		if (letter >= UNICODE_SIZE)
			[NSException raise:NSInvalidArgumentException
						format:@"Specified string exceeds character set"];
		SETBIT(bytes[letter/8], letter%8);
		}
	
	return [self characterSetWithBitmapRepresentation:bitmap];
}

+ (id) characterSetWithRange:(NSRange)aRange
{
int i;
NSMutableData *bitmap = [NSMutableData dataWithLength:BITMAP_SIZE];
char *bytes = (char *)[bitmap mutableBytes];

	if (NSMaxRange(aRange) > UNICODE_SIZE)
		[NSException raise:NSInvalidArgumentException
					 format:@"Specified range exceeds character set"];
	
	for (i = aRange.location; i < NSMaxRange(aRange); i++)
		SETBIT(bytes[i/8], i % 8);
	
	return [self characterSetWithBitmapRepresentation:bitmap];
}

+ (id) characterSetWithContentsOfFile: (NSString *)aFile
{
	if ([@"bitmap" isEqual: [aFile pathExtension]])
		{
		NSData *bitmap = [NSData dataWithContentsOfFile: aFile];

		return [self characterSetWithBitmapRepresentation: bitmap];
		}

	return nil;
}

- (NSData *) bitmapRepresentation					{ SUBCLASS return nil; }
- (BOOL) characterIsMember:(unichar)aCharacter		{ SUBCLASS return NO;  }
- (void) encodeWithCoder: (NSCoder*)aCoder			{ SUBCLASS }
- (id) initWithCoder: (NSCoder*)aCoder				{ SUBCLASS return nil; }

- (BOOL) isEqual: (id)anObject
{
	if (anObject == self)
		return YES;
	if ([anObject isKindOfClass:[NSCharacterSet class]])
		{
		int	i;
	
		for (i = 0; i <= 0xffff; i++)
			// FIXME: we should directly compare the bytes by memcmp()
			if ([self characterIsMember: (unichar)i] !=
					[anObject characterIsMember: (unichar)i])
				return NO;

		return YES;
		}

	return NO;
}

- (BOOL) hasMemberInPlane:(unsigned char) plane;
{
	NIMP;
	return NO;
}

- (NSCharacterSet *) invertedSet
{
	NSMutableData *bitmap =[[[self bitmapRepresentation] mutableCopy] autorelease];
	int i, length = [bitmap length];
	char *bytes = [bitmap mutableBytes];

	for (i = 0; i < length; i++)
		bytes[i] = ~bytes[i];
	
	return [[self class] characterSetWithBitmapRepresentation:bitmap];
}

- (BOOL) isSupersetOfSet:(NSCharacterSet *) other;
{
	NIMP;
	return NO;
}

- (BOOL) longCharacterIsMember:(UTF32Char) aCharacter;
{
	NIMP;
	return NO;
}

// NSCopying, NSMutableCopying

- (id) copyWithZone:(NSZone *) zone	{ return [self retain]; }	// if immutable

- (id) mutableCopyWithZone:(NSZone *) zone
{
	return [[NSMutableBitmapCharSet allocWithZone:zone] initWithBitmap:[self bitmapRepresentation]];
}

@end /* NSMutableCharacterSet */


@implementation NSMutableCharacterSet

+ (id) allocWithZone:(NSZone *) z
{ // Provide a default object for allocation
	return (id) NSAllocateObject([NSMutableBitmapCharSet self], 0, z);
}
 
+ (NSCharacterSet *) characterSetWithBitmapRepresentation:(NSData *)data
{ // Override this from NSCharacterSet to create the correct class
	return [[[NSMutableBitmapCharSet alloc] initWithBitmap:data] autorelease];
}										

- (id) copyWithZone:(NSZone *) zone
{ // make immutable copy
	return [[NSBitmapCharSet alloc] initWithBitmap:[self bitmapRepresentation]];
}

- (id) mutableCopyWithZone:(NSZone *) zone
{
	return [[NSMutableBitmapCharSet alloc] initWithBitmap:[self bitmapRepresentation]];
}

@end /* NSCharacterSet */

//*****************************************************************************
//
// 		NSBitmapCharSet 
//
//*****************************************************************************

@implementation NSBitmapCharSet

- (id) init						{ return [self initWithBitmap:NULL]; }

- (id) initWithBitmap:(NSData *)bitmap
{													// Designated initializer
	if((self=[super init]))
		{
		[bitmap getBytes:data length:BITMAP_SIZE];
		}
	return self;
}

- (NSData *) bitmapRepresentation
{
	return [NSData dataWithBytes:data length:BITMAP_SIZE];
}

- (BOOL) characterIsMember:(unichar)aCharacter
{
	return ISSET(data[aCharacter/8], aCharacter%8);
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
	[aCoder encodeObject: [self bitmapRepresentation]];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
	NSData *rep;
#if 0
	NSLog(@"%@ initWithCoder:%@", self, aCoder);
#endif
	if([aCoder allowsKeyedCoding])
		{
		[self autorelease];
		return [[[self class] characterSetWithCharactersInString:[aCoder decodeObjectForKey:@"NSString"]] copy];
		}
	rep=[aCoder decodeObject];
    self = [self initWithBitmap: rep];

    return self;
}

@end /* NSBitmapCharSet */

//*****************************************************************************
//
// 		NSMutableBitmapCharSet 
//
//*****************************************************************************

@implementation NSMutableBitmapCharSet

- (id) init	{ return [self initWithBitmap:NULL]; }

- (id) initWithBitmap:(NSData *)bitmap
{												// Designated initializer
	if((self=[super init]))
		{
		[bitmap getBytes:data length:BITMAP_SIZE];
		}
	return self;
}

- (void) encodeWithCoder:(NSCoder*)aCoder
{
    [aCoder encodeObject: [self bitmapRepresentation]];
}

- (id) initWithCoder:(NSCoder*)aCoder
{
	NSData *rep;
#if 0
	NSLog(@"%@ initWithCoder:%@", self, aCoder);
#endif
	if([aCoder allowsKeyedCoding])
		{
		[self autorelease];
		return [[[self class] characterSetWithCharactersInString:[aCoder decodeObjectForKey:@"NSString"]] mutableCopy];
		}
	rep=[aCoder decodeObject];
	self = [self initWithBitmap: rep];

	return self;
}

- (NSData *) bitmapRepresentation		// Need to implement the next two 
{										// methods just like NSBitmapCharSet
	return [NSData dataWithBytes:data length:BITMAP_SIZE];
}

- (BOOL) characterIsMember:(unichar)aCharacter
{
	return ISSET(data[aCharacter/8], aCharacter%8);
}

- (void) addCharactersInRange:(NSRange)aRange
{
	int i;

	if (NSMaxRange(aRange) > UNICODE_SIZE)
		[NSException raise:NSInvalidArgumentException
					 format:@"Specified range exceeds character set"];

	for (i = aRange.location; i < NSMaxRange(aRange); i++)
		SETBIT(data[i/8], i % 8);
}

- (void) addCharactersInString:(NSString *)aString
{
	int i, length;

	if (!aString)
		[NSException raise:NSInvalidArgumentException
					 format:@"Adding characters from nil string"];

	length = [aString length];
	for (i = 0; i < length; i++)
		{
		unsigned letter = [aString characterAtIndex:i];
		if (letter >= UNICODE_SIZE)
			[NSException raise:NSInvalidArgumentException
						format:@"Specified string exceeds character set"];
		SETBIT(data[letter/8], letter%8);
		}
}

- (void) formUnionWithCharacterSet:(NSCharacterSet *)otherSet
{
	int i;
	const char *other_bytes = [[otherSet bitmapRepresentation] bytes];

	for (i = 0; i < BITMAP_SIZE; i++)
		data[i] = (data[i] || other_bytes[i]);
}

- (void) formIntersectionWithCharacterSet:(NSCharacterSet *)otherSet
{
	int i;
	const char *other_bytes = [[otherSet bitmapRepresentation] bytes];

	for (i = 0; i < BITMAP_SIZE; i++)
		data[i] = (data[i] && other_bytes[i]);
}

- (void) removeCharactersInRange:(NSRange)aRange
{
	int i;

	if (NSMaxRange(aRange) > UNICODE_SIZE)
		[NSException raise:NSInvalidArgumentException
					 format:@"Specified range exceeds character set"];

	for (i=aRange.location; i < NSMaxRange(aRange); i++)
		CLRBIT(data[i/8], i % 8);
}

- (void) removeCharactersInString:(NSString *)aString
{
	int i, length;

	if (!aString)
		[NSException raise:NSInvalidArgumentException
					 format:@"Removing characters from nil string"];

	length = [aString length];
	for (i = 0; i < length; i++)
		{
		unsigned letter = [aString characterAtIndex:i];
		if (letter >= UNICODE_SIZE)
			[NSException raise:NSInvalidArgumentException
						format:@"Specified string exceeds character set"];
		CLRBIT(data[letter/8], letter%8);
		}
}

- (void) invert
{
	int i;
	for (i = 0; i < BITMAP_SIZE; i++)
		data[i] = ~data[i];
}

@end /* NSMutableBitmapCharSet */
