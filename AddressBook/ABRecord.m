//
//  ABRecord.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "Private.h"

@implementation ABRecord (private)

- (BOOL) _decodeWithVCardScanner:(NSScanner *) sc;
{ // parse lines and handle nesting
	NSDictionary *d=[self _parseLine:sc];
	NSString *key=[d objectForKey:@"TAG"];
	NSArray *val=[d objectForKey:@"VALUE"];
#if 0
	NSLog(@"d=%@", d);
#endif
	if(![key isEqualToString:@"BEGIN"])
		return NO;
#if 1
	NSLog(@"tag=%@", [self _vCardTag]);
	NSLog(@"key=%@ & val=%@", key, val);
#endif
	if([val count] != 1 || ![[val objectAtIndex:0] isEqualToString:[self _vCardTag]])
		return NO;
	while((d=[self _parseLine:sc]))
		{
		if([[d objectForKey:@"TAG"] isEqualToString:@"END"])
			{
			NSArray *val=[d objectForKey:@"VALUE"];
			return [val count] == 1 && [[val objectAtIndex:0] isEqualToString:[self _vCardTag]];	// proper nesting?
			}
		[self _decodeLine:d];
		}
	return NO;	// some scanning error
}

- (NSString *) _vCardTag; { return @"_vCardTag should be redefined in subclass"; }

- (BOOL) _decodeLine:(NSDictionary *) line;
{
	NSLog(@"%@ does not process %@:%@", NSStringFromClass([self class]), [line objectForKey:@"TAG"], [[line objectForKey:@"VALUE"] objectAtIndex:0]);
	return NO;
}

- (void) _encodeLine:(NSString *) line to:(NSMutableString *) dest;
{ // fold overlong lines
	while([line length] >= 75)
		{
		[dest appendFormat:@"%@\r\n ", [line substringToIndex:75]];	// create fragment with continuation indicator
		line=[line substringFromIndex:75];
		}
	[dest appendFormat:@"%@\r\n", line];	// last fragment up to end of line
}

- (void) _encodeTag:(NSString *) tag attributes:(NSDictionary *) attribs value:(id) val to:(NSMutableString *) dest;
{
	NSMutableString *t=[NSMutableString stringWithString:tag];
	NSEnumerator *e=[attribs keyEnumerator];
	NSString *key;
	id oval;
	int pos;
	BOOL first=YES;
	if([val isKindOfClass:[ABMultiValue class]])
		{ // list of attributed values
		}
	while((key=[e nextObject]))
		{
		id aval=[attribs objectForKey:key];
		if([aval isKindOfClass:[NSArray class]])
			{ // make ;ATTRIB=VALUE,... - escaping \, and \; and \:
			[t appendFormat:@";%@=", key];
			pos=[t length];
			[t appendString:aval];
			[t replaceOccurrencesOfString:@";" withString:@"\\;" options:0 range:NSMakeRange(pos, [t length]-pos)];
			[t replaceOccurrencesOfString:@":" withString:@"\\:" options:0 range:NSMakeRange(pos, [t length]-pos)];
			[t replaceOccurrencesOfString:@"," withString:@"\\," options:0 range:NSMakeRange(pos, [t length]-pos)];
			[t replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(pos, [t length]-pos)];
			}
		else
			[t appendFormat:@";%@", aval];	// append unescaped - should be NSString
		}
	if(![val isKindOfClass:[NSArray class]])
		val=[NSArray arrayWithObject:val];	// put into array
	e=[val objectEnumerator];
	while((oval=[e nextObject]))
		{
		pos=[t length]+1;	// don't replace : or ,
		[t appendFormat:first?@":%@":@",%@", val];
		first=NO;
		[t appendString:oval];
		[t replaceOccurrencesOfString:@"," withString:@"\\," options:0 range:NSMakeRange(pos, [t length]-pos)];
		[t replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(pos, [t length]-pos)];
		}
	[self encodeLine:t to:dest];
}

- (void) _encodeProperty:(NSString *) property as:(NSString *) vCalProperty to:(NSMutableString *) dest;
{
	id val=[self valueForProperty:property];
	if(!val)
		return;	// ignore
				// decode format and specify attributes
	[self _encodeTag:vCalProperty attributes:nil value:val to:dest];
}

- (void) _encodeVCard:(NSMutableString *) dest; { NSLog(@"_encodeVCard should be redefined in subclass"); }

- (NSDictionary *) _parseLine:(NSScanner *) sc;
{ // scan next line
	static NSCharacterSet *tagEnd;
	static NSCharacterSet *attribNameEnd;
	static NSCharacterSet *attribEnd;
	static NSCharacterSet *valEnd;
	NSString *tag;
	NSMutableDictionary *attribs=[NSMutableDictionary dictionaryWithCapacity:3];
	NSMutableArray *value=[NSMutableArray array];
	NSString *val;
	[sc setCharactersToBeSkipped:nil];	// just to be sure
	if(!tagEnd) tagEnd=[[NSCharacterSet characterSetWithCharactersInString:@":;\r\n"] retain];
	if(![sc scanUpToCharactersFromSet:tagEnd intoString:&tag])
		return nil;	// invalid - missing tag
	while([sc scanString:@";" intoString:NULL])
		{ // get attributes ;ATTRIB=VALUE,...
		NSString *key;
#if 0
		NSLog(@"attrib");
#endif
		if(!attribNameEnd) attribNameEnd=[[NSCharacterSet characterSetWithCharactersInString:@"=\r\n"] retain];
		if(![sc scanUpToCharactersFromSet:attribNameEnd intoString:&key])
			return nil;	// invalid - missing key
#if 0
		NSLog(@"key=%@", key);
#endif
		if(![sc scanString:@"=" intoString:NULL])
			return nil;	// invalid - no =
		if([sc scanString:@"\"" intoString:NULL])
			{ // quoted attribute
			static NSCharacterSet *quoteEnd;
			if(!quoteEnd) quoteEnd=[[NSCharacterSet characterSetWithCharactersInString:@"\"\r\n"] retain];
			val=@"";
			while(YES)
				{
				NSString *val2=@"";
				[sc scanUpToCharactersFromSet:quoteEnd intoString:&val2];
				val=[val stringByAppendingString:val2];	// merge next fragment
				if([sc scanString:@"\r\n " intoString:NULL])
					{ // continuation line - just skip
					}
				else
					break;
				}
#if 0
			NSLog(@"quoted: %@", val);
#endif
			if(![sc scanString:@"\"" intoString:NULL])
				return nil;	// invalid - no closing "
			if(![attribs objectForKey:key])
				[attribs setObject:[NSMutableArray array] forKey:key];	// create container
			[[attribs objectForKey:key] addObject:val];	// append value
			continue;
			}
		if(!attribEnd) attribEnd=[[NSCharacterSet characterSetWithCharactersInString:@",;:\\\r\n"] retain];
		while(YES)
			{
			val=@"";
			[sc scanUpToCharactersFromSet:attribEnd intoString:&val];
#if 0
			NSLog(@"val=%@", val);
#endif
			while(YES)
				{
				NSString *val2=@"";
				if([sc scanString:@"\r\n " intoString:NULL])
					{ // continuation line
					  // just skip sequence
					}
				else if([sc scanString:@"\\" intoString:NULL])
					{ // process escaped character
					if([sc scanString:@"\\" intoString:NULL])
						val=[val stringByAppendingString:@"\\"];
					else if([sc scanString:@"," intoString:NULL])
						val=[val stringByAppendingString:@","];
					else if([sc scanString:@"n" intoString:NULL])
						val=[val stringByAppendingString:@"\n"];
					}
				else
					break;
				[sc scanUpToCharactersFromSet:attribEnd intoString:&val2];
				val=[val stringByAppendingString:val2];	// merge next fragment
				}
#if 0
			NSLog(@"%@=%@", key, val);
#endif
			if(![attribs objectForKey:key])
				[attribs setObject:[NSMutableArray array] forKey:key];	// create container
			[[attribs objectForKey:key] addObject:val];	// append value (,-separated list)
			if(![sc scanString:@"," intoString:NULL])
				break;	// not , separated multi-values
			}
		}
	if(![sc scanString:@":" intoString:NULL])
		return nil;	// invalid
	if(!valEnd) valEnd=[[NSCharacterSet characterSetWithCharactersInString:@",\\\r\n"] retain];
	while(YES)
		{
		val=@"";
		[sc scanUpToCharactersFromSet:valEnd intoString:&val];
		while(YES)
			{
			NSString *val2=@"";
			if([sc scanString:@"\r\n " intoString:NULL])
				{ // continuation line
				  // just skip sequence
				}
			else if([sc scanString:@"\\" intoString:NULL])
				{ // process escaped character
				if([sc scanString:@"\\" intoString:NULL])
					val=[val stringByAppendingString:@"\\"];
				else if([sc scanString:@"," intoString:NULL])
					val=[val stringByAppendingString:@","];
				else if([sc scanString:@"n" intoString:NULL])
					val=[val stringByAppendingString:@"\n"];
				}
			else
				break;
			[sc scanUpToCharactersFromSet:valEnd intoString:&val2];
			val=[val stringByAppendingString:val2];	// merge next fragment
			}
		[value addObject:val];	// append value (,-separated list)
		if(![sc scanString:@"," intoString:NULL])
			break;	// not , separated multi-values
		}
	if(![sc scanString:@"\r\n" intoString:NULL])
		return nil;	// invalid
	return [NSDictionary dictionaryWithObjectsAndKeys:tag, @"TAG", attribs, @"ATTRIBUTES", value, @"VALUES", nil];
}

// touch should only be called if we are stored in an Address book!
// we should reference the address book we are stored in: _setAddressBook:(ABAddressBook *) ab; called by addRecord

- (void) _touch; { [[ABAddressBook sharedAddressBook] _touch]; }

- (NSMutableDictionary *) _properties;
{
	return [[[ABAddressBook sharedAddressBook] _properties] objectForKey:NSStringFromClass([self class])];
}

+ (NSMutableDictionary *) _properties;
{
	return [[[ABAddressBook sharedAddressBook] _properties] objectForKey:NSStringFromClass([self class])];
}

@end

@implementation ABRecord

- (id) initWithUniqueId:(NSString *) uid;
{
	self=[super init];
	if(self)
		{
		data=[[NSMutableDictionary dictionary] retain];
		[self setValue:uid forProperty:kABUIDProperty];
		}
	return self;
	}

- (id) init;
{
	return [self initWithUniqueId:
		[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingFormat:@":%@",
						NSStringFromClass([self class])]];
}

- (void) dealloc;
{
	[data release];
	[super dealloc];
}

- (BOOL) removeValueForProperty:(NSString *) property;
{
	if(![[self _properties] objectForKey:property])
		return NO;  // unknown property
	[data removeObjectForKey:property];
	[self _touch];
	return YES;
}
 
- (BOOL) setValue:(id) value forProperty:(NSString *) property;
{
	ABPropertyType type=[[[self _properties] objectForKey:property] intValue];
	NSLog(@"type(%@)=%d", property, type);
	if(!type)
		return NO;  // unknown property
	NSLog(@"setValue %@ forProperty %@", value, property);
	if(value)
		{
		// check if property data type is ok for assignment
		[data setObject:value forKey:property];
		}
	else
		[data removeObjectForKey:property];
	[self _touch];
	return YES;
}

- (NSString *) uniqueId; { return [self valueForProperty:kABUIDProperty]; }

- (id) valueForProperty:(NSString *) property; { return [data objectForKey:property]; }

// implemented here - public interface resides in ABPerson and ABGroup

+ (int) addPropertiesAndTypes:(NSDictionary *) properties;
	// different for ABGroup and ABPerson?
// YES!!!
// Doc says: The only predefined property of a group is its name. 
// so we need a dictionary of properties
{
	unsigned int c=[[self _properties] count];
	[[self _properties] addEntriesFromDictionary:properties];
	[[ABAddressBook sharedAddressBook] _touch];
	return [[self _properties] count]-c;	// how many added
}

+ (int) removeProperties:(NSArray *) properties;
{
	unsigned int c=[[self _properties] count];
	[[self _properties] removeObjectsForKeys:properties];
	[[ABAddressBook sharedAddressBook] _touch];
	return c-[[self _properties] count];	// how many removed
}

+ (NSArray *) properties; { return [[self _properties] allKeys]; }

+ (ABPropertyType) typeOfProperty:(NSString *) property;
{
	return [[[self _properties] objectForKey:property] intValue];   // should be NSNumber or numeric NSString to work
}

+ (ABSearchElement *) searchElementForProperty:(NSString *)property label:(NSString *)label key:(NSString *)key value:(id)value comparison:(ABSearchComparison)comparison;
{
	return [ABSearchElement _searchElementForClass:[self class] property:property label:label key:key value:value comparison:comparison];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject: data];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	data = [[aDecoder decodeObject] retain];
	return self;
}

@end