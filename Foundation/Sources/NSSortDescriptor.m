/* 
   NSSortDescriptor.h

   NSSortDescriptor to specify complex ORDER BY rules

   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: Dec 2004, Sept 2009 (completed)
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import "Foundation/Foundation.h"

NSInteger _descriptorComparator(id val1, id val2, void *context)
{ // sort using descriptors
	NSEnumerator *e=[(NSArray *) context objectEnumerator];
	NSSortDescriptor *desc;
	while((desc=[e nextObject]))
		{
			NSComparisonResult r=[desc compareObject:val1 toObject:val2];
			if(r != NSOrderedSame)
				return r;	// decided
		}
	return NSOrderedSame;
}

@implementation NSSortDescriptor 

- (BOOL) ascending; { return ascending; }

- (NSComparisonResult) compareObject:(id) a toObject:(id) b;
{
	NSComparisonResult r = (NSComparisonResult) [[a valueForKeyPath:key] performSelector:selector withObject:[b valueForKeyPath:key]];
	return ascending?r:-r;	// assuming NSComparisonResult is signed...
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
{ // same key and selector but ascending reversed
	return [[[NSSortDescriptor alloc] initWithKey:key ascending:!ascending selector:selector] autorelease];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: key=%@ direction=%@ selector=%@", NSStringFromClass([self class]), key, ascending?@"ascending":@"descending", NSStringFromSelector(selector)];
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

@implementation NSArray (NSSortDecriptor)

- (NSArray *) sortedArrayUsingDescriptors:(NSArray *) sortDescriptors;
{
	return [self sortedArrayUsingFunction:_descriptorComparator context:(void *)sortDescriptors];
}

@end

@implementation NSMutableArray (NSSortDescriptor)

- (void) sortUsingDescriptors:(NSArray *) sortDescriptors;
{
	return [self sortUsingFunction:_descriptorComparator context:(void *)sortDescriptors];
}

@end
