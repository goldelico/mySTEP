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
										 effectiveRange:&effectiveRange];	// first attribute at index 0
	[attributeArray replaceObjectAtIndex:0 withObject:attributeDict];
	
	while ((m = NSMaxRange(effectiveRange)) < NSMaxRange(aRange))
		{
		attributeDict = [attributedString attributesAtIndex:m
											 effectiveRange:&effectiveRange];
		[attributeArray addObject:attributeDict];
		[locateArray addObject: [NSNumber numberWithUnsignedInt: effectiveRange.location - aRange.location]];
		}
#if 0
	NSLog(@"_setAttributesFrom -> locations=%@", locateArray);
#endif
}

NSDictionary *
_attributesAtIndexEffectiveRange(unsigned int index,
								 NSRange *aRange,  // may be NULL
								 unsigned int strLength,
								 NSMutableArray *attributeArray,
								 NSMutableArray *locateArray,
								 unsigned int *foundIndex)
{ // locate by binary search for efficiency in huge attributed strings
	int low, high, cnt;
	unsigned int used, foundLoc, nextLoc;
	NSDictionary *foundDict;
#if 0
	NSLog(@"_attributesAtIndexEffectiveRange %d, len=%d", index, strLength);
	NSLog(@"attributeArray=%@", attributeArray);
	NSLog(@"locateArray=%@", locateArray);
#endif
	if(strLength > 0 && index >= strLength)
		[NSException raise:NSRangeException
					format: @"index out of range in \
		 _attributesAtIndexEffectiveRange(%d, %@, %d, ...)",
		 index, aRange?NSStringFromRange(*aRange):(NSString *)@"NULL", strLength];
	
	used = [attributeArray count];
	low = 0;
	high = used - 1;
	while(low <= high)
		{
		cnt = (low + high) / 2;
#if 0
		NSLog(@"low %d cnt %d high %d", low, cnt, high);
#endif
		foundDict = [attributeArray objectAtIndex:cnt];
		foundLoc = [[locateArray objectAtIndex:cnt] unsignedIntValue];
		
		if(foundLoc > index)
			high = cnt-1;
		else
			{
			if(cnt >= used - 1)
				nextLoc = strLength;	// applies to all characters up to end of string
			else
				{
				nextLoc = [[locateArray objectAtIndex:cnt+1] unsignedIntValue];
				NSCAssert1(nextLoc > foundLoc, @"locateArray must be ascending (%@)", locateArray);
				}
			if(foundLoc == index || index < nextLoc)
				{ // found
					if(aRange)
						{
						aRange->location = foundLoc;
						aRange->length = nextLoc - foundLoc;
						}
					if(foundIndex)
						*foundIndex = cnt;
#if 0
					NSLog(@"found %@ at %d", NSStringFromRange(NSMakeRange(foundLoc, nextLoc-foundLoc)), cnt);
#endif
					return foundDict;
				}
			else
				low = cnt+1;
			}
		}
	NSCAssert(NO, @"Error in binary search algorithm");
	return nil;
}

@interface NSMutableStringProxyForMutableAttributedString : NSMutableString
{ // returned by [astring mutableString]
	NSMutableAttributedString *_astring;	// original
}

- (id) initWithAttributedString:(NSAttributedString *) astring;

@end

@implementation NSMutableStringProxyForMutableAttributedString	// this is a subclass of NSMutableString and implements all methods as a wrapper

+ (id) allocWithZone:(NSZone *) z
{
	return (id) NSAllocateObject(self, 0, z);
}

+ (id) alloc
{
	return (id) NSAllocateObject(self, 0, NSDefaultMallocZone());
}

- (id) initWithAttributedString:(NSAttributedString *) astring;
{
	// we don't call super init!
	_astring=(NSMutableAttributedString *) [astring retain];
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	return [[_astring string] retain];	// convert us to an immutable NSString
}

- (void) dealloc
{
	[_astring release];
	[super dealloc];	// this is NSMutableString's dealloc
}

- (void) getCharacters:(unichar*)buffer				{ [[_astring string] getCharacters:buffer]; }
- (void) getCharacters:(unichar*)buffer range:(NSRange)aRange
													{ [[_astring string] getCharacters:buffer range:aRange]; }

- (unichar) characterAtIndex:(NSUInteger) index; { return [[_astring string] characterAtIndex:index]; }
- (NSUInteger) length; { return [[_astring string] length]; }
- (NSMutableString *) mutableString; { return [_astring mutableString]; }

// subclass responsibility of NSMutableString

- (void) deleteCharactersInRange:(NSRange) range;
{
	[_astring replaceCharactersInRange:range withString:@""];
}

- (void) insertString:(NSString *) aString atIndex:(NSUInteger) index;
{
	[_astring replaceCharactersInRange:NSMakeRange(index,0) withString:aString];
}

- (void) replaceCharactersInRange:(NSRange) range withString:(NSString *) aString;
{
	[_astring replaceCharactersInRange:range withString:aString];	
}

- (void) setString:(NSString *) str
{
	[_astring replaceCharactersInRange:NSMakeRange(0, [_astring length]) withString:str];	// retains attributes of first character
}

@end

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
	// FIXME: how does this copy the attributes?
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
#if 0
		NSLog(@"initWithString %@ attributes %@", aString, attributes);
		NSLog(@"  -> _locations=%@", _locations);
#endif
		}
	return self;
}

- (NSString *) description
{
	// FIXME: should print attribute runs + string
	return [self string];
}

- (void) dealloc
{
	[_string release];
	[_attributes release];
	[_locations release];
	[super dealloc];
}

- (NSUInteger) length						{ return [_string length]; }

- (NSString *) string
{ 
#if 0
	NSLog(@"%@: %@", NSStringFromClass([_string class]), _string);
#endif
	return _string;
}

- (NSDictionary *) attributesAtIndex:(NSUInteger)index
					  effectiveRange:(NSRange *)aRange
{
	unsigned cnt=[self length];
	if(index >= cnt)
		[NSException raise:NSRangeException 
					format:@"RangeError in -attributesAtIndex:%u effectiveRange:* - length=%u", index, cnt];
#if 0
	NSLog(@"atrributed string %@", _string);
#endif
	return _attributesAtIndexEffectiveRange( index, aRange, cnt, _attributes, _locations, NULL);
}

- (NSDictionary *) attributesAtIndex:(NSUInteger)index
			   longestEffectiveRange:(NSRange *)aRange 
							 inRange:(NSRange)rangeLimit
{
	NSDictionary *attrDictionary;
	unsigned idx, i, cnt=[self length];
	if(NSMaxRange(rangeLimit) > cnt)
		[NSException raise:NSRangeException 
					format:@"RangeError in -attributesAtIndex:%u longestEffectiveRange:* inRange:%@ - length=%u",
		 index, NSStringFromRange(rangeLimit), cnt];
	attrDictionary=_attributesAtIndexEffectiveRange(index, aRange, cnt, _attributes, _locations, &idx);
	if(!aRange)
		return attrDictionary;
	for(i=idx; i > 0; i--)
		{
		if([[_locations objectAtIndex:i] unsignedIntValue] < rangeLimit.location)
			break;	// check if we look before range limit - then we can stop comparing full dictionaries
		if(![[_attributes objectAtIndex:i-1] isEqualToDictionary:attrDictionary])
			break;	// get first one that still has same dict value
		}
	for(cnt=[_attributes count], idx++; idx < cnt; idx++)
		{
		if([[_locations objectAtIndex:idx] unsignedIntValue] > NSMaxRange(rangeLimit))
			break;	// check if we look behind range limit - then we can stop comparing full dictionaries
		if(![[_attributes objectAtIndex:idx] isEqualToDictionary:attrDictionary])
			break;	// get first one that no longer has same dict value
		}
	aRange->location=[[_locations objectAtIndex:i] unsignedIntValue];	// first
	if(idx == cnt)
		aRange->length=[self length]-aRange->location;	// remainder
	else
		aRange->length=[[_locations objectAtIndex:idx] unsignedIntValue]-aRange->location;	// last
	*aRange = NSIntersectionRange(*aRange, rangeLimit);	// clip to rangeLimit
	return attrDictionary;
}

- (id) attribute:(NSString *)attributeName 
		 atIndex:(NSUInteger)index
  effectiveRange:(NSRange *)aRange
{
	NSDictionary *tmpDictionary;
	tmpDictionary = [self attributesAtIndex:index effectiveRange:aRange]; // Raises exception if index is out of range
	if(!attributeName)
		{		
			// If attributeName is nil, then the attribute will not exist in the
			// entire text - therefore aRange of the entire text must be correct
			if(aRange)
				*aRange = NSMakeRange(0, [self length]);
			return nil;
		}
	return [tmpDictionary objectForKey:attributeName];
}

- (id) attribute:(NSString *)attributeName 
		 atIndex:(NSUInteger)index
longestEffectiveRange:(NSRange *)aRange 
		 inRange:(NSRange)rangeLimit
{
	NSDictionary *tmpDictionary;
	id attrValue, tmpAttrValue;
	NSRange tmpRange;
	
	if(NSMaxRange(rangeLimit) > [self length])
		[NSException raise:NSRangeException 
					format:@"RangeError in -attribute:%@ atIndex:%u longestEffectiveRange:* inRange:%@ -- length=%u",
		 attributeName, index, NSStringFromRange(rangeLimit), [self length]];
	if(!attributeName && !aRange)
		return nil;
	
	attrValue = [self attribute:attributeName 
						atIndex:index 
				 effectiveRange:aRange]; // Raises exception if index is out of range
	if(attributeName)
		{
		if(!aRange)
			return attrValue;
		
		while(aRange->location > rangeLimit.location)
			{ // Check extend range backwards
				tmpDictionary = [self attributesAtIndex:aRange->location - 1
										 effectiveRange:&tmpRange];
				tmpAttrValue = [tmpDictionary objectForKey:attributeName];
				if(tmpAttrValue == attrValue)
					aRange->location = tmpRange.location;
				else
					break;
			}
		while(NSMaxRange(*aRange) < NSMaxRange(rangeLimit))
			{ // Check extend range forwards
				//				NSLog(@"aRange=%@ rangeLimit=%@", NSStringFromRange(*aRange), NSStringFromRange(rangeLimit));
				tmpDictionary = [self attributesAtIndex:NSMaxRange(*aRange)
										 effectiveRange:&tmpRange];
				tmpAttrValue = [tmpDictionary objectForKey:attributeName];
				//				NSLog(@"tmpDict=%@ tmpAttrValue=%@", tmpDictionary, tmpAttrValue);
				if(tmpAttrValue == attrValue)
					aRange->length = NSMaxRange(tmpRange) - aRange->location;	// extend
				else
					break;
			}
		}
	*aRange = NSIntersectionRange(*aRange, rangeLimit);	// Clip to rangeLimit
	
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
	NSLog(@"%@ initWithCoder: %@", NSStringFromClass([self class]), aCoder);
	NSLog(@"NSAttributes=%@", [aCoder decodeObjectForKey:@"NSAttributes"]);
	NSLog(@"NSString=%@", [aCoder decodeObjectForKey:@"NSString"]);
	NSLog(@"NSAttributeInfo=%@", [aCoder decodeObjectForKey:@"NSAttributeInfo"]);	// NSData(!)
#endif
	self = [super initWithCoder:aCoder];
	if([aCoder allowsKeyedCoding])
		{
		if([aCoder containsValueForKey:@"NSAttributeInfo"])
			{ // we have several attribute runs and NSAttributes is an Array of the attributes
				const unsigned char *p, *end;
				unsigned int pos;
				NSArray *attribs=[aCoder decodeObjectForKey:@"NSAttributes"];	// array of unique attributes
				/* format of the info
				 1 byte length of the run; if >=128 this are the low order 7 bits and the next bytes defines 8 (or 7?) more bits
				 1 byte index of into the attributes array
				 */
				NSData *info=[aCoder decodeObjectForKey:@"NSAttributeInfo"];
#if 0
				NSLog(@"info=%@", info);
#endif
				self=[self initWithString:[aCoder decodeObjectForKey:@"NSString"] attributes:nil];
				p=[info bytes];
				end=p+[info length];
				pos=0;
				[_locations removeAllObjects];	// will be replaced
				[_attributes removeAllObjects];	// will be replaced
				while(p < end)
					{ // process encoded runs
						unsigned len, idx;
						len=*p++;
						if(len >= 128)
							{ // handle multibyte value
								//	NSLog(@"len = %d [%d] %@", len, [self length], info);
								// unknown: format for strings longer than 16k (i.e. if second byte is also >= 128)
								len=(len-128)+128*(*p++);	// next byte is MSB
								//	NSLog(@"=> len=%d", len);
							}
						idx=*p++;
						if(idx >= 128)
							{ // handle multibyte value
								//	NSLog(@"idx = %d [%d] %@", len, [self length], info);
								// unknown: does this happen at all for more than 128 different attributes?
								// to test this we must create an attrib string where every second character has a different attribute set...
							}
						[_attributes addObject:[attribs objectAtIndex:idx]];
						[_locations addObject:[NSNumber numberWithUnsignedInt:pos]];
						pos+=len;
					}
#if 0
				NSLog(@"initWithCoder -> %@", _locations);
				NSLog(@"initWithCoder: attributes=%@", _attributes);
				NSLog(@"initWithCoder: locations=%@", _locations);
#endif
				return self;
			}
		else	// single attribute run
			return [self initWithString:[aCoder decodeObjectForKey:@"NSString"]
							 attributes:[aCoder decodeObjectForKey:@"NSAttributes"]];
		}
	[aCoder decodeValueOfObjCType: @encode(id) at: &_string];
	[aCoder decodeValueOfObjCType: @encode(id) at: &_attributes];
	[aCoder decodeValueOfObjCType: @encode(id) at: &_locations];
#if 0
	NSLog(@"initWithCoder: attributes=%@", _attributes);
	NSLog(@"initWithCoder: locations=%@", _locations);
#endif
	return self;
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

- (NSMutableString *) mutableString			{ return [[[NSMutableStringProxyForMutableAttributedString alloc] initWithAttributedString:self] autorelease]; }
- (void) beginEditing						{ return; }
- (void) endEditing							{ return; }

- (void) deleteCharactersInRange:(NSRange)aRange
{
	[self replaceCharactersInRange:aRange withString:nil];
}

/*	Primitive method! Sets attributes and values for a given range of
 characters, replacing any previous attributes and values for that range.
 
 Sets the attributes for the characters in aRange to attributes. These new
 attributes replace any attributes previously associated with the characters 
 aRange. Raises an NSRangeException if any part of aRange lies beyond the 
 end of the receiver's characters. 
 See also: - addAtributes:range:, - removeAttributes:range:
 */

- (void) setAttributes:(NSDictionary *)attributes range:(NSRange)range
{
	unsigned int tmpLength, arrayIndex, arraySize, location;
	NSRange effectiveRange;
	NSNumber *afterRangeLocation, *beginRangeLocation;
	NSDictionary *attrs;
#if 0
	NSLog(@"setAttributes:%@ range:%@ of %@", attributes, NSStringFromRange(range), self);
	NSLog(@"  _locations = %@", _locations);
#endif
	if(range.length == 0)
		return;	// ignore empty range
	if(!attributes)
		attributes = [NSDictionary dictionary];
	tmpLength = [self length];
	if(NSMaxRange(range) > tmpLength)
		[NSException raise:NSRangeException
					format:@"Range Error in setAttributes:... range:%@ larger than {0, %u}", NSStringFromRange(range), tmpLength];
	
	arraySize = [_locations count];
	if(NSMaxRange(range) < tmpLength)
		{
		attrs = _attributesAtIndexEffectiveRange( NSMaxRange(range),
												 &effectiveRange,tmpLength,_attributes,_locations,&arrayIndex);
		afterRangeLocation = [NSNumber numberWithUnsignedInt:NSMaxRange(range)];
		if(effectiveRange.location > range.location)
			[_locations replaceObjectAtIndex:arrayIndex withObject:afterRangeLocation];
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
#if 0
	NSLog(@"arrayIndex=%u", arrayIndex);
#endif
	while(arrayIndex > 0 && [[_locations objectAtIndex:arrayIndex-1] unsignedIntValue] >= range.location)
		{
#if 0
		NSLog(@"arrayIndex %d", arrayIndex);
#endif
		[_locations removeObjectAtIndex:arrayIndex];
		[_attributes removeObjectAtIndex:arrayIndex];
		arrayIndex--;
		}
	beginRangeLocation = [NSNumber numberWithUnsignedInt:range.location];
	location = [[_locations objectAtIndex:arrayIndex] unsignedIntValue];
#if 0
	NSLog(@"beginRangeLocation=%@", beginRangeLocation);
	NSLog(@"location=%u", location);
	NSLog(@"range=%@", NSStringFromRange(range));
#endif
#if 0
	NSLog(@"a) locations = %@", _locations);
#endif
	if(location >= range.location)
		{
		if(location > range.location)
			[_locations replaceObjectAtIndex:arrayIndex
								  withObject:beginRangeLocation];
		[_attributes replaceObjectAtIndex:arrayIndex withObject:attributes];
#if 0
		NSLog(@"b) locations = %@", _locations);
#endif
		}
	else
		{
		arrayIndex++;
		[_attributes insertObject:attributes atIndex:arrayIndex];
		[_locations insertObject:beginRangeLocation atIndex:arrayIndex];
#if 0
		NSLog(@"c) locations = %@", _locations);
#endif
		}
#if 0
	NSLog(@"setAttributes -> %@", _locations);
#endif
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
						atIndex:(NSUInteger)index
{
	[self replaceCharactersInRange:NSMakeRange(index,0) withAttributedString:attributedString];
}

- (void) replaceCharactersInRange:(NSRange)aRange withAttributedString:(NSAttributedString *)attributedString
{
	NSRange effectiveRange, clipRange, ownRange;
	NSDictionary *attrDict;
#if 0
	NSLog(@"astr[%d] replaceCharactersInRange:%@ withAttributedString:str[%d]", [self length], NSStringFromRange(aRange), [attributedString length]);
	NSLog(@"  locations=%@", _locations);
#endif
	[self replaceCharactersInRange:aRange withString:[attributedString string]];
	effectiveRange = NSMakeRange(0,0);
	clipRange = NSMakeRange(0,[attributedString length]);
	
	while(NSMaxRange(effectiveRange) < NSMaxRange(clipRange))
		{
#if 0
		NSLog(@"eff range in=%@", NSStringFromRange(effectiveRange));
#endif
		attrDict = [attributedString attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange];
#if 0
		NSLog(@"eff range=%@", NSStringFromRange(effectiveRange));
#endif
		ownRange = NSIntersectionRange(clipRange,effectiveRange);
		ownRange.location += aRange.location;
#if 0
		NSLog(@"own range=%@", NSStringFromRange(ownRange));
#endif
		[self setAttributes:attrDict range:ownRange];
		effectiveRange.location += effectiveRange.length;	// take next chunk
		}
#if 0
	NSLog(@"replaceCharactersInRange -> locations=%@", _locations);
#endif
}

- (void) replaceCharactersInRange:(NSRange)range withString:(NSString *)aString
{
	unsigned int tmpLength, arrayIndex, arraySize, moveLocations;
	NSDictionary *attrs;
#if 0
	NSLog(@"astr[%d] replaceCharactersInRange:%@ withString:str[%d]", [self length], NSStringFromRange(range), [aString length]);
	NSLog(@"  locations -> %@", _locations);
#endif
	if(!aString)
		aString = @"";
	tmpLength = [self length];
#if 0
	NSLog(@"maxrange=%u tmpLength=%u", NSMaxRange(range), tmpLength);
#endif
	if(NSMaxRange(range) > tmpLength)
		{ // beyond end of string
#if 0
			NSLog(@"range=%@", NSStringFromRange(range));
			NSLog(@"current string=%@", [self string]);
			NSLog(@"new string=%@", aString);
#endif
			[NSException raise:NSRangeException
						format:@"RangeError in -replaceCharactersInRange:%@ withString:%@", NSStringFromRange(range), aString];
		}
	arraySize = [_locations count];
	if(NSMaxRange(range) < tmpLength)
		{ // adjust locations
			NSRange effectiveRange;
			attrs = _attributesAtIndexEffectiveRange(NSMaxRange(range), &effectiveRange, tmpLength, _attributes, _locations, &arrayIndex);

			moveLocations = [aString length] - range.length;	// how much we have to add
			if(moveLocations != 0)
				{
				NSNumber *afterRangeLocation;
				unsigned int cnt;
				afterRangeLocation = [NSNumber numberWithUnsignedInt:NSMaxRange(range)+moveLocations];
#if 0
				NSLog(@"arrayIndex = %u", arrayIndex);
				NSLog(@"effectiveRange = %@", NSStringFromRange(effectiveRange));
				NSLog(@"moveLocations = %u", moveLocations);
				NSLog(@"afterRangeLocation = %@", afterRangeLocation);
				NSLog(@"  loc1 = %@", _locations);
#endif
				if(effectiveRange.location > range.location)
					[_locations replaceObjectAtIndex:arrayIndex withObject:afterRangeLocation];
				else
					{
					arrayIndex++;
					[_attributes insertObject:attrs atIndex:arrayIndex];
					[_locations insertObject:afterRangeLocation atIndex:arrayIndex];
					arraySize++;	// has now one more element
					}
#if 0
				NSLog(@"  loc1.5 = %@", _locations);
#endif

				for(cnt = arrayIndex + 1; cnt < arraySize; cnt++)
					{
					unsigned int newLocation = [[_locations objectAtIndex:cnt] unsignedIntValue] + moveLocations;
					[_locations replaceObjectAtIndex:cnt withObject:[NSNumber numberWithUnsignedInt:newLocation]];
					}
				arrayIndex--;
				}
#if 0
			NSLog(@"  loc2 = %@", _locations);
#endif
		}
	else
		{ // replace at or after last character; no change of attribs: last attribute run simply extends to new length
			arrayIndex = arraySize - 1;
		}
#if 0
	NSLog(@"arrayIndex = %u range.location = %u", arrayIndex, range.location);
	NSLog(@"  loc3 = %@", _locations);
#endif
	while(arrayIndex > 0 && [[_locations objectAtIndex:arrayIndex] unsignedIntValue] > range.location)
		{ // delete any location did change attributes in the replaced range
			[_locations removeObjectAtIndex:arrayIndex];
			[_attributes removeObjectAtIndex:arrayIndex];
			arrayIndex--;
		}
#if 0
	NSLog(@"  loc4 = %@", _locations);
#endif
#if 0
	NSLog(@"_string=%@ aString=%@", _string, aString);
	NSLog(@"len=%d + %d rng=%@", [_string length], [aString length], NSStringFromRange(range));
#endif
	if(!_string)
		_string=[aString mutableCopy];
	else
		[_string replaceCharactersInRange:range withString:aString];
#if 0
	NSLog(@"len=%d", [_string length]);
	NSLog(@"_string=%@", _string);
#endif
#if 0
	NSLog(@"replaceCharactersInRangeWithString -> %@", _locations);
#endif
}

- (void) setAttributedString:(NSAttributedString *)attributedString
{
	if(!attributedString)
		[NSException raise:NSInvalidArgumentException
					format:@"-setAttributedString:nil"];
	[_string setString: [attributedString string]];
	[_attributes removeAllObjects];	// remove all existing attributes
	[_locations removeAllObjects];
	[_attributes addObject:[NSDictionary dictionary]];		// create first attribute run
	[_locations addObject:[NSNumber numberWithUnsignedInt:0]];
	_setAttributesFrom(attributedString, NSMakeRange(0, [attributedString length]), _attributes, _locations);
}

@end /* NSMutableAttributedString */
