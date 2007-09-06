//
//  ABMultiValue.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>

@implementation ABMultiValue

- (id) init;
{
	self=[super init];
	if(self)
		{
		values=[[NSMutableArray array] retain];
		labels=[[NSMutableArray array] retain];
		identifiers=[[NSMutableArray array] retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	ABMultiValue *c=[isa allocWithZone:zone];
	if(c)
		{
		c->primaryIdentifier=[primaryIdentifier retain];
		c->propertyType=propertyType;
		c->values=[values retain];
		c->labels=[labels retain];
		c->identifiers=[identifiers retain];
		}
	return c;
}

- (id) mutableCopyWithZone:(NSZone *) zone;
{
	ABMutableMultiValue *c=(ABMutableMultiValue *) [isa allocWithZone:zone];
	c->primaryIdentifier=[primaryIdentifier copyWithZone:zone];
	c->propertyType=propertyType;
	c->values=[values mutableCopy];
	c->labels=[labels mutableCopy];
	c->identifiers=[identifiers mutableCopyWithZone:zone];
	return c;
}

- (void) dealloc;
{
	[primaryIdentifier release];
	[values release];
	[labels release];
	[identifiers release];
	[super dealloc];
}

- (unsigned int) count; { return [values count]; }
- (id) valueAtIndex:(int) index; { return [values objectAtIndex:index]; }
- (NSString *) labelAtIndex:(int) index; { return [labels objectAtIndex:index]; }
- (NSString *) identifierAtIndex:(int) index; { return [identifiers objectAtIndex:index]; }
- (int) indexForIdentifier:(NSString *) identifier; { return [identifiers indexOfObject:identifier]; }
- (NSString *) primaryIdentifier; { return primaryIdentifier; }
- (ABPropertyType) propertyType; { return propertyType; }

@end

@implementation ABMutableMultiValue

- (id) init;
{
	self=[super init];
	if(self)
		{
		}
	return self;
}

- (void) dealloc;
{
	[super dealloc];
}


- (NSString *) addValue:(id) value withLabel:(NSString *) label;
{
	NSString *identifier=[[NSProcessInfo processInfo] globallyUniqueString]; // assign new unique id
	[values addObject:value];
	[labels addObject:label];
	[identifiers addObject:identifier];
	return identifier;
}

- (NSString *) insertValue:(id) value withLabel:(NSString *) label atIndex:(int) index;
{
	NSString *identifier=[[NSProcessInfo processInfo] globallyUniqueString]; // assign new unique id
	[values insertObject:value atIndex:index];
	[labels insertObject:label atIndex:index];
	[identifiers insertObject:identifier atIndex:index];
	return identifier;
}

- (BOOL) removeValueAndLabelAtIndex:(int) index;
{
	[values removeObjectAtIndex:index];
	[labels removeObjectAtIndex:index];
	[identifiers removeObjectAtIndex:index];
	return YES;
}

- (BOOL) replaceValueAtIndex:(int) index withValue:(id) value;
{
	[values replaceObjectAtIndex:index withObject:value];
	return YES;
}

- (BOOL) replaceLabelAtIndex:(int) index withLabel:(NSString*) label;
{
	[labels replaceObjectAtIndex:index withObject:label];
	return YES;
}

- (BOOL) setPrimaryIdentifier:(NSString *) identifier;
{
	[primaryIdentifier autorelease];
	primaryIdentifier=[identifier retain];
	return identifier != nil;
}

- (void) encodeWithCoder:(id)aCoder
{
	[aCoder encodeObject: primaryIdentifier];
	[aCoder encodeObject: values];
	[aCoder encodeObject: labels];
	[aCoder encodeObject: identifiers];
	[aCoder encodeValueOfObjCType: @encode(ABPropertyType) at: &propertyType];
}

- (id) initWithCoder:(id)aDecoder
{
	primaryIdentifier = [[aDecoder decodeObject] retain];
	values = [[aDecoder decodeObject] retain];
	labels = [[aDecoder decodeObject] retain];
	identifiers = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType: @encode(ABPropertyType) at: &propertyType];	
	return self;
}

@end
