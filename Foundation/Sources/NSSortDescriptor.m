/* 
   NSSortDescriptor.h

   Secure Text field control class for data entry

   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: Dec 2004
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import "Foundation/Foundation.h"

@implementation NSSortDescriptor 

- (BOOL) ascending; { return ascending; }

	/// FIXME: we should probably use IMP!

- (NSComparisonResult) compareObject:(id) a toObject:(id) b;
{
	return (NSComparisonResult) [a performSelector:selector withObject:b];
}

- (id) initWithKey:(NSString *) k ascending:(BOOL) a;
{
	return [self initWithKey:k ascending:a selector:@selector(compare:)];
}

- (NSString *) key; { return key; }
- (SEL) selector; { return selector; }

- (id) initWithKey:(NSString *) k ascending:(BOOL) a selector:(SEL) s;
{
	self=[super init];
	if(self)
		{
		key=[k retain];
		ascending=a;
		selector=s;
		}
	return self;
}

- (void) dealloc;
{
	[key release];
	[super dealloc];
}

- (id) reversedSortDescriptor;
{
	return [[[NSSortDescriptor alloc] initWithKey:key ascending:!ascending selector:selector] autorelease];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: key=%@ direction=%@ selector=%@", NSStringFromClass([self class]), key, ascending?@"ascending":@"descnending", NSStringFromSelector(selector)];
}

- (id) copyWithZone:(NSZone *) z;
{
	NSSortDescriptor *c=[isa allocWithZone:z];
	c->key=[key retain];	// shared
	c->ascending=ascending;
	c->selector=selector;
	return c;
}

- (void) encodeWithCoder:(NSCoder*) coder
{ 
	[coder encodeObject:key];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&ascending];
	[coder encodeValueOfObjCType:@encode(SEL) at:&selector];
}

- (id) initWithCoder:(NSCoder*) coder
{
	if([coder allowsKeyedCoding])
		{
		key=[[coder decodeObjectForKey:@"NSKey"] retain];
		ascending=[coder decodeBoolForKey:@"NSAscending"];
		selector=NSSelectorFromString([coder decodeObjectForKey:@"NSSelector"]);
		}
	else
		{
		key=[[coder decodeObject] retain];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&ascending];
		[coder decodeValueOfObjCType:@encode(SEL) at:&selector];
		}
	return self;
}


@end
