/* 
   NSAttributedString.m

   Implementation of string class with attributes

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	ANOQ of the sun <anoq@vip.cybercity.dk>
   Date:	November 1997
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

//FIXME: 1) The NSMutableString object returned from the -mutableString method
//       in NSMutableAttributedString is NOT tracked for changes to update
//       NSMutableAttributedString's attributes as it should.

// ranges are defined as 0..length-1 according to NSRange

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSValue.h>

#import "NSPrivate.h"

static Class __attrStrClass;
static Class __mutableAttrStrClass;


void
_setAttributesFrom( NSAttributedString *attributedString,
					NSRange aRange,
					NSMutableArray *attributeArray,
					NSMutableArray *locateArray)
{ // always called immediately after -initWithString:attributes: or by setAttributedString:
	NSRange effectiveRange;
	NSDictionary *attributeDict;
	unsigned m;

	if(aRange.length == 0)
		return;										// No attributes

	attributeDict = [attributedString attributesAtIndex:aRange.location
									  effectiveRange:&effectiveRange];
	[attributeArray replaceObjectAtIndex:0 withObject:attributeDict];
	
	while ((m = NSMaxRange(effectiveRange)) < NSMaxRange(aRange))
		{
		attributeDict = [attributedString attributesAtIndex:m
										  effectiveRange:&effectiveRange];
		[attributeArray addObject:attributeDict];
		[locateArray addObject: [NSNumber numberWithUnsignedInt: effectiveRange.location - aRange.location]];
		}
}

NSDictionary *
_attributesAtIndexEffectiveRange(unsigned int index,
								  NSRange *aRange,  // may be NULL
								  unsigned int tmpLength,
								  NSMutableArray *attributeArray,
								  NSMutableArray *locateArray,
								  unsigned int *foundIndex)
{
	unsigned int low, high, used, cnt, foundLoc, nextLoc;
	NSDictionary *foundDict;

	if(tmpLength > 0 && index >= tmpLength)
		[NSException raise:NSRangeException
					 format: @"index out of range in \
							_attributesAtIndexEffectiveRange(%d, %@, %d, ...)",
			index, aRange?NSStringFromRange(*aRange):(NSString *)@"NULL", tmpLength];

				// Binary search for efficiency in huge attributed strings
	used = [attributeArray count];
	low = 0;
	high = used - 1;
	while(low <= high)
		{
		cnt = (low + high) / 2;
		foundDict = [attributeArray objectAtIndex:cnt];
		foundLoc = [[locateArray objectAtIndex:cnt] unsignedIntValue];

		if(foundLoc > index)
			high = cnt-1;
		else
			{
			if(cnt >= used - 1)
				nextLoc = tmpLength;
			else
				nextLoc = [[locateArray objectAtIndex:cnt+1] unsignedIntValue];

			if(foundLoc == index || index < nextLoc)
				{											// Found
				if(aRange)
					{
					aRange->location = foundLoc;
					aRange->length = nextLoc - foundLoc;
					}
				if(foundIndex)
					*foundIndex = cnt;

				return foundDict;
				}
			else
				low = cnt+1;
			}
		}

	NSLog(@"Error in binary search algorithm");
// NSCAssert(NO,@"Error in binary search algorithm");

	return nil;
}

@implementation NSAttributedString

+ (void) initialize
{
	if (self == [NSAttributedString class])
		{
		__attrStrClass = [NSAttributedString class];
		__mutableAttrStrClass = [NSMutableAttributedString class];
		}
}

- (id) copyWithZone:(NSZone *) zone							// NSCopying protocol
{
	if ([self isKindOfClass: [NSMutableAttributedString class]])
		return [[NSAttributedString alloc] initWithAttributedString:self];

	return [self retain];
}
												// NSMutableCopying protocol
- (id) mutableCopyWithZone:(NSZone *) zone
{
	return [[NSMutableAttributedString alloc] initWithAttributedString:self];
}

- (id) init
{
	return [self initWithString:nil attributes:nil];
}

- (id) initWithString:(NSString *)aString
{
	return [self initWithString:aString attributes:nil];
}

- (id) initWithAttributedString:(NSAttributedString *)attributedString
{
		if((self=[self initWithString:[attributedString string] attributes:nil]))
				{
			_setAttributesFrom(attributedString, NSMakeRange(0, [attributedString length]), _attributes, _locations);
		}
	return self;
}

- (id) initWithString:(NSString *)aString attributes:(NSDictionary *)attributes
{
	if((self=[super init]))
		{
		_string = [aString copy];
		_attributes = [[NSMutableArray alloc] initWithCapacity:3];
		_locations = [[NSMutableArray alloc] initWithCapacity:3];
		if(!attributes)
			attributes = [NSDictionary dictionary];
		[_attributes addObject:attributes];
		[_locations addObject:[NSNumber numberWithUnsignedInt:0]];
		}
	return self;
}

- (NSString *) description
{
	return [self string];
}

- (void) dealloc
{
	[_string release];
	[_attributes release];
	[_locations release];
	[super dealloc];
}

- (unsigned int) length						{ return [_string length]; }
- (NSString *) string						{ return _string; }

- (NSDictionary *) attributesAtIndex:(unsigned int)index
					  effectiveRange:(NSRange *)aRange
{
	return _attributesAtIndexEffectiveRange( index, aRange, 
				[self length], _attributes, _locations, NULL);
}

- (NSDictionary *) attributesAtIndex:(unsigned int)index 
				   longestEffectiveRange:(NSRange *)aRange 
				   inRange:(NSRange)rangeLimit
{
	NSDictionary *attrDictionary, *tmpDictionary;
	NSRange tmpRange;

	if(NSMaxRange(rangeLimit) > [self length])
		[NSException raise:NSRangeException 
			format:@"RangeError in -attributesAtIndex:%d longestEffectiveRange:%@ inRange:%@",
			index, NSStringFromRange(*aRange), NSStringFromRange(rangeLimit)];

	attrDictionary = [self attributesAtIndex:index effectiveRange:aRange];
	if(!aRange)
		return attrDictionary;
  
	while(aRange->location > rangeLimit.location)
		{ // Check extend range backwards
		tmpDictionary = [self attributesAtIndex:aRange->location-1
							  effectiveRange:&tmpRange];
		if([tmpDictionary isEqualToDictionary:attrDictionary])
			aRange->location = tmpRange.location;
		else
			break;	// different
		}
	while(NSMaxRange(*aRange) < NSMaxRange(rangeLimit))
		{ // Check extend range forwards
		tmpDictionary = [self attributesAtIndex:NSMaxRange(*aRange)
							  effectiveRange:&tmpRange];
		if([tmpDictionary isEqualToDictionary:attrDictionary])
			aRange->length = NSMaxRange(tmpRange) - aRange->location;
		else
			break;	// different
		}
	*aRange = NSIntersectionRange(*aRange, rangeLimit);	// Clip to rangeLimit

	return attrDictionary;
}

- (id) attribute:(NSString *)attributeName 
		 atIndex:(unsigned int)index 
		 effectiveRange:(NSRange *)aRange
{
	NSDictionary *tmpDictionary;

	tmpDictionary = [self attributesAtIndex:index effectiveRange:aRange];
								// Raises exception if index is out of range
	if(!attributeName)
		{
		if(aRange)
			*aRange = NSMakeRange(0,[self length]);

      // If attributeName is nil, then the attribute will not exist in the
      // entire text - therefore aRange of the entire text must be correct
    
		return nil;
		}

	return [tmpDictionary objectForKey:attributeName];
}

- (id) attribute:(NSString *)attributeName 
		 atIndex:(unsigned int)index 
		 longestEffectiveRange:(NSRange *)aRange 
		 inRange:(NSRange)rangeLimit
{
	NSDictionary *tmpDictionary;
	id attrValue, tmpAttrValue;
	NSRange tmpRange;

	if(NSMaxRange(rangeLimit) > [self length])
			[NSException raise:NSRangeException 
				format:@"RangeError in -attribute:%@ atIndex:%d longestEffectiveRange:%@ inRange:%@",
				attributeName, index, NSStringFromRange(*aRange), NSStringFromRange(rangeLimit)];
			
	attrValue = [self attribute:attributeName 
					  atIndex:index 
					  effectiveRange:aRange]; // Raises exception if index is out of range
	if(!attributeName)
		return nil;		// attribute:atIndex:effectiveRange: handles this case.
	if(!aRange)
		return attrValue;
  
	while(aRange->location > rangeLimit.location)
		{										// Check extend range backwards
		tmpDictionary = [self attributesAtIndex:aRange->location - 1
							  effectiveRange:&tmpRange];
		tmpAttrValue = [tmpDictionary objectForKey:attributeName];
		if(tmpAttrValue == attrValue)
			aRange->location = tmpRange.location;
		}
	while(NSMaxRange(*aRange) < NSMaxRange(rangeLimit))
		{										// Check extend range forwards
		tmpDictionary = [self attributesAtIndex:NSMaxRange(*aRange)
							  effectiveRange:&tmpRange];
		tmpAttrValue = [tmpDictionary objectForKey:attributeName];
		if(tmpAttrValue == attrValue)
			aRange->length = NSMaxRange(tmpRange) - aRange->location;
		}

	*aRange = NSIntersectionRange(*aRange,rangeLimit);	// Clip to rangeLimit

	return attrValue;
}
												// Comparing attributed strings
- (BOOL) isEqualToAttributedString:(NSAttributedString *)otherString
{
NSRange ownEffectiveRange,otherEffectiveRange;
unsigned int length;
NSDictionary *ownDictionary,*otherDictionary;
BOOL result;

	if(!otherString)
		return NO;
	if(![[otherString string] isEqual:[self string]])
		return NO;
  
	length = [otherString length];
	if(length <= 0)
		return YES;

	ownDictionary = [self attributesAtIndex:0
						  effectiveRange:&ownEffectiveRange];
	otherDictionary = [otherString attributesAtIndex:0
								   effectiveRange:&otherEffectiveRange];
	result = YES;
    
	while(YES)
		{
		if(NSIntersectionRange(ownEffectiveRange,otherEffectiveRange).length >0 
				&& ![ownDictionary isEqualToDictionary:otherDictionary])
			{
			result = NO;
			break;
			}
		if(NSMaxRange(ownEffectiveRange) < NSMaxRange(otherEffectiveRange))
			{
			ownDictionary = [self
			attributesAtIndex:NSMaxRange(ownEffectiveRange)
			effectiveRange:&ownEffectiveRange];
			}
		else
			{
			if(NSMaxRange(otherEffectiveRange) >= length)
				break;										// End of strings
			otherDictionary = [otherString attributesAtIndex: 
										NSMaxRange(otherEffectiveRange)
										effectiveRange:&otherEffectiveRange];
		}	}

	return result;
}

- (BOOL) isEqual:(id)anObject
{
	if (anObject == self)
		return YES;
	if ([anObject isKindOfClass:[NSAttributedString class]])
		return [self isEqualToAttributedString:anObject];
	return NO;
}

- (NSAttributedString *) attributedSubstringFromRange:(NSRange)aRange
{
NSAttributedString *newAttrString;						// Extract a substring

	if(NSMaxRange(aRange) > [self length])
		[NSException raise:NSRangeException
					 format:@"RangeError in -attributedSubstringFromRange:%@", NSStringFromRange(aRange)];

	newAttrString = [[[NSAttributedString alloc] initWithString:[_string substringWithRange:aRange] attributes:nil] autorelease];
	_setAttributesFrom(newAttrString, aRange,
				((NSAttributedString *)newAttrString)->_attributes, 
				((NSAttributedString *)newAttrString)->_locations);

	return newAttrString;
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_string];
	[aCoder encodeObject:_attributes];
	[aCoder encodeObject:_locations];
}

- (id) initWithCoder:(NSCoder *)aCoder
{
#if 0
	NSLog(@"%@ initWithCoder: %@", NSStringFromClass([self class]), coder);
	NSLog(@"NSAttributes=%@", [coder decodeObjectForKey:@"NSAttributes"]);
	NSLog(@"NSString=%@", [coder decodeObjectForKey:@"NSString"]);
	NSLog(@"NSAttributeInfo=%@", [coder decodeObjectForKey:@"NSAttributeInfo"]);	// NSData(!)
	NSLog(@"NSDelegate=%@", [coder decodeObjectForKey:@"NSDelegate"]);
#endif
	self = [super initWithCoder:aCoder];
	if([aCoder allowsKeyedCoding])
		{
		// FIXME!!!
			// may be a int [] of the locations
		NSLog(@"NSAttributeInfo=%@", [aCoder decodeObjectForKey:@"NSAttributeInfo"]);	// NSData(!)
		// how are mixed attribs decoded, i.e. what do we do with NSAttributeInfo? 
		return [self initWithString:[aCoder decodeObjectForKey:@"NSString"]
						 attributes:[aCoder decodeObjectForKey:@"NSAttributes"]];
		}
	[aCoder decodeValueOfObjCType: @encode(id) at: &_string];
	[aCoder decodeValueOfObjCType: @encode(id) at: &_attributes];
	[aCoder decodeValueOfObjCType: @encode(id) at: &_locations];
	return self;
}

- (Class) classForPortCoder				{ return [self class]; }

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder
{ // default is to encode a proxy
	if([coder isBycopy])
		return self;
	return [super replacementObjectForPortCoder:coder];
}

@end /* NSAttributedString */

//*****************************************************************************
//
// 		NSMutableAttributedString 
//
//*****************************************************************************

@implementation NSMutableAttributedString

- (id) initWithString:(NSString *)aString attributes:(NSDictionary *)attributes
{
	if((self=[super initWithString:nil attributes:attributes]))
			{
				_string = [aString mutableCopy];
			}
	return self;
}

- (NSAttributedString *) attributedSubstringFromRange:(NSRange)aRange
{
NSAttributedString *newAttrString;						// Extract a substring
NSString *newSubstring;

	if(NSMaxRange(aRange) > [self length])
		[NSException raise:NSRangeException
					 format:@"RangeError in -attributedSubstringFromRange:%@", NSStringFromRange(aRange)];
	
	newSubstring = [[self string] substringWithRange:aRange];
	newAttrString = [[NSAttributedString alloc] initWithString:newSubstring 
												attributes:nil];
	[newAttrString autorelease];
	_setAttributesFrom(self, aRange, 
				((NSMutableAttributedString *)newAttrString)->_attributes, 
				((NSMutableAttributedString *)newAttrString)->_locations);

	return newAttrString;
}

- (NSMutableString *) mutableString			{ return _string; }
- (void) beginEditing						{ return; }
- (void) endEditing							{ return; }

- (void) deleteCharactersInRange:(NSRange)aRange
{
	[self replaceCharactersInRange:aRange withString:nil];
}

- (void) setAttributes:(NSDictionary *)attributes range:(NSRange)range
{
	unsigned int tmpLength, arrayIndex, arraySize, location;
	NSRange effectiveRange;
	NSNumber *afterRangeLocation, *beginRangeLocation;
	NSDictionary *attrs;
  
	if(!attributes)
		attributes = [NSDictionary dictionary];
	tmpLength = [self length];
	if(NSMaxRange(range) > tmpLength)
		abort(),
		[NSException raise:NSRangeException
					 format:@"Range Error in setAttributes:... range:%@ larger than {0, %u}", NSStringFromRange(range), tmpLength];

	arraySize = [_locations count];
	if(NSMaxRange(range) < tmpLength)
		{
		attrs = _attributesAtIndexEffectiveRange( NSMaxRange(range),
			&effectiveRange,tmpLength,_attributes,_locations,&arrayIndex);

		afterRangeLocation = [NSNumber numberWithUnsignedInt: 
								NSMaxRange(range)];
		if(effectiveRange.location > range.location)
			[_locations replaceObjectAtIndex:arrayIndex
							withObject:afterRangeLocation];
		else
			{
			arrayIndex++;
			[_attributes insertObject:attrs atIndex:arrayIndex];
			[_locations insertObject:afterRangeLocation atIndex:arrayIndex];
			}
		arrayIndex--;
		}
	else
		arrayIndex = arraySize - 1;
  
	while(arrayIndex > 0
		&& [[_locations objectAtIndex:arrayIndex-1] unsignedIntValue] >= range.location)
		{
		[_locations removeObjectAtIndex:arrayIndex];
		[_attributes removeObjectAtIndex:arrayIndex];
		arrayIndex--;
		}
	beginRangeLocation = [NSNumber numberWithUnsignedInt:range.location];
	location = [[_locations objectAtIndex:arrayIndex] unsignedIntValue];
	if(location >= range.location)
		{
		if(location > range.location)
			[_locations replaceObjectAtIndex:arrayIndex
						 withObject:beginRangeLocation];

		[_attributes replaceObjectAtIndex:arrayIndex withObject:attributes];
		}
	else
		{
		arrayIndex++;
		[_attributes insertObject:attributes atIndex:arrayIndex];
		[_locations insertObject:beginRangeLocation atIndex:arrayIndex];
		}
  
/*	Primitive method! Sets attributes and values for a given range of
	characters, replacing any previous attributes and values for that range.

	Sets the attributes for the characters in aRange to attributes. These new
	attributes replace any attributes previously associated with the characters 
	aRange. Raises an NSRangeException if any part of aRange lies beyond the 
	end of the receiver's characters. 
	See also: - addAtributes:range:, - removeAttributes:range:
*/
}

- (void) addAttribute:(NSString *)name value:(id)value range:(NSRange)aRange
{
	NSRange effectiveRange;
	NSDictionary *attrDict;
	NSMutableDictionary *newDict;
	unsigned int tmpLength = [self length];

	if(NSMaxRange(aRange) > tmpLength)
		[NSException raise:NSRangeException
					 format:@"RangeError in -addAttribute:%@ value:... range:%@", name, NSStringFromRange(aRange)];

	attrDict = [self attributesAtIndex:aRange.location
					 effectiveRange:&effectiveRange];

	while(effectiveRange.location < NSMaxRange(aRange))
		{
		effectiveRange = NSIntersectionRange(aRange,effectiveRange);
		
		newDict = [[NSMutableDictionary alloc] initWithDictionary:attrDict];
		[newDict autorelease];
		[newDict setObject:value forKey:name];
		[self setAttributes:newDict range:effectiveRange];
		
		if(NSMaxRange(effectiveRange) >= NSMaxRange(aRange))
			effectiveRange.location = NSMaxRange(aRange);	// stops the loop
		else if(NSMaxRange(effectiveRange) < tmpLength)
				attrDict = [self attributesAtIndex:NSMaxRange(effectiveRange)
								 effectiveRange:&effectiveRange];
		}
}

- (void) addAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
NSRange effectiveRange;
NSDictionary *attrDict;
NSMutableDictionary *newDict;
unsigned int tmpLength;
  
// cant use NSParameterAssert hereif is has to be an NSInvalidArgumentException
	if(!attributes)
		[NSException raise:NSInvalidArgumentException
					 format:@"attributes is nil in method -addAttributes:range: in class NSMutableAtrributedString"];

	tmpLength = [self length];
	if(NSMaxRange(aRange) > tmpLength)
   		[NSException raise:NSRangeException
					 format:@"RangeError in method -addAttributes:... range:%@", NSStringFromRange(aRange)];
  
	attrDict = [self attributesAtIndex:aRange.location
					 effectiveRange:&effectiveRange];

	while(effectiveRange.location < NSMaxRange(aRange))
		{
		effectiveRange = NSIntersectionRange(aRange,effectiveRange);
		
		newDict = [[NSMutableDictionary alloc] initWithDictionary:attrDict];
		[newDict autorelease];
		[newDict addEntriesFromDictionary:attributes];
		[self setAttributes:newDict range:effectiveRange];
		
		if(NSMaxRange(effectiveRange) >= NSMaxRange(aRange))
			effectiveRange.location = NSMaxRange(aRange); // stops the loop...
		else if(NSMaxRange(effectiveRange) < tmpLength)
				attrDict = [self attributesAtIndex:NSMaxRange(effectiveRange)
								 effectiveRange:&effectiveRange];
		}
}

- (void) removeAttribute:(NSString *)name range:(NSRange)aRange
{
NSRange effectiveRange;
NSDictionary *attrDict;
NSMutableDictionary *newDict;
unsigned int tmpLength = [self length];
  
	if(NSMaxRange(aRange) > tmpLength)
		[NSException raise:NSRangeException
					 format:@"RangeError in method -removeAttribute:%@ range:%@", name, NSStringFromRange(aRange)];

	attrDict = [self attributesAtIndex:aRange.location
    effectiveRange:&effectiveRange];

	while(effectiveRange.location < NSMaxRange(aRange))
		{
		effectiveRange = NSIntersectionRange(aRange,effectiveRange);
    
		newDict = [[NSMutableDictionary alloc] initWithDictionary:attrDict];
		[newDict autorelease];
		[newDict removeObjectForKey:name];
		[self setAttributes:newDict range:effectiveRange];
		
		if(NSMaxRange(effectiveRange) >= NSMaxRange(aRange))
			effectiveRange.location = NSMaxRange(aRange); // stops the loop...
		else if(NSMaxRange(effectiveRange) < tmpLength)
				attrDict = [self attributesAtIndex:NSMaxRange(effectiveRange)
								 effectiveRange:&effectiveRange];
		}
}
										// Changing characters and attributes
- (void) appendAttributedString:(NSAttributedString *)attributedString
{
	[self replaceCharactersInRange:NSMakeRange([self length],0) withAttributedString:attributedString];
}

- (void) insertAttributedString:(NSAttributedString *)attributedString 
					   atIndex:(unsigned int)index
{
	[self replaceCharactersInRange:NSMakeRange(index,0) withAttributedString:attributedString];
}

- (void) replaceCharactersInRange:(NSRange)aRange withAttributedString:(NSAttributedString *)attributedString
{
	NSRange effectiveRange, clipRange, ownRange;
	NSDictionary *attrDict;
  
	[self replaceCharactersInRange:aRange withString:[attributedString string]];
	effectiveRange = NSMakeRange(0,0);
	clipRange = NSMakeRange(0,[attributedString length]);

	while(NSMaxRange(effectiveRange) < NSMaxRange(clipRange))
		{
		attrDict = [attributedString attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange];
		ownRange = NSIntersectionRange(clipRange,effectiveRange);
		ownRange.location += aRange.location;
		[self setAttributes:attrDict range:ownRange];
		}
}

- (void) replaceCharactersInRange:(NSRange)range withString:(NSString *)aString
{
	unsigned int tmpLength, arrayIndex, arraySize, cnt, location, moveLocations;
	NSRange effectiveRange;
	NSDictionary *attrs;
	NSNumber *afterRangeLocation;
	if(!aString)
		aString = @"";
	tmpLength = [self length];
	if(NSMaxRange(range) > tmpLength)
		{
#if 1
		NSLog(@"range=%@", NSStringFromRange(range));
		NSLog(@"current string=%@", [self string]);
		NSLog(@"new string=%@", aString);
#endif
		[NSException raise:NSRangeException
				format:@"RangeError in -replaceCharactersInRange:%@ withString:%@", NSStringFromRange(range), aString];
		}
	arraySize = [_locations count];
	if(NSMaxRange(range) < tmpLength)
		{
		attrs = _attributesAtIndexEffectiveRange( NSMaxRange(range), &effectiveRange, tmpLength, _attributes, _locations, &arrayIndex);
    
		moveLocations = [aString length] - range.length;
		afterRangeLocation = [NSNumber numberWithUnsignedInt:NSMaxRange(range)+moveLocations];
    
		if(effectiveRange.location > range.location)
			[_locations replaceObjectAtIndex:arrayIndex withObject:afterRangeLocation];
		else
			{
			arrayIndex++;
			[_attributes insertObject:attrs atIndex:arrayIndex];
			[_locations insertObject:afterRangeLocation atIndex:arrayIndex];
			}
    
		for(cnt = arrayIndex + 1; cnt < arraySize; cnt++)
			{
			location = [[_locations objectAtIndex:cnt] unsignedIntValue] + moveLocations;
			[_locations replaceObjectAtIndex:cnt withObject:[NSNumber numberWithUnsignedInt:location]];
			}
		arrayIndex--;
		}
	else
		arrayIndex = arraySize - 1;

	while(arrayIndex > 0 && [[_locations objectAtIndex:arrayIndex] unsignedIntValue] > range.location)
		{
		[_locations removeObjectAtIndex:arrayIndex];
		[_attributes removeObjectAtIndex:arrayIndex];
		arrayIndex--;
		}
//	NSLog(@"_string=%@ aString=%@", _string, aString);
//	NSLog(@"len=%d + %d rng=%@", [_string length], [aString length], NSStringFromRange(range));
	if(!_string)
		_string=[aString mutableCopy];
	else
		[_string replaceCharactersInRange:range withString:aString];
//	NSLog(@"len=%d", [_string length]);
//	NSLog(@"_string=%@", _string);
}

- (void) setAttributedString:(NSAttributedString *)attributedString
{
	if(!attributedString)
		[NSException raise:NSInvalidArgumentException
								format:@"-setAttributedString:nil"];
	[_string setString: [attributedString string]];
	[_attributes removeAllObjects];	// remove all existing attributes
	[_locations removeAllObjects];
	[_attributes addObject:[NSDictionary dictionary]];
	[_locations addObject:[NSNumber numberWithUnsignedInt:0]];
	_setAttributesFrom(attributedString, NSMakeRange(0, [attributedString length]), _attributes, _locations);
}

@end /* NSMutableAttributedString */
