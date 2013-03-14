//
//  Refactor.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Refactor.h"

@implementation Node (Refactor)

- (Node *) refactor:(NSDictionary *) substitutions;	// replace symbols by dictionary content
{
	NSString *t=[self type];
	if([t isEqualToString:@"identifier"])
		{
		NSString *new=[substitutions objectForKey:[self value]];
		if(new)
			return [[[Node alloc] initWithType:t value:new] autorelease];
		}
	Node *nl=[left refactor:substitutions];
	Node *nr=[right refactor:substitutions];
	if(nl != left || nr != right)
		return [Node node:type left:nl right:nr];	// return a copy
	return self;	// not changed
}

@end
