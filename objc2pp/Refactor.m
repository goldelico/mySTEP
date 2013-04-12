//
//  Refactor.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Refactor.h"

@implementation Node (Refactor)

- (void) refactor:(NSDictionary *) substitutions;	// replace symbols by dictionary content
{
	NSString *t=[self type];
	if([t isEqualToString:@"identifier"])
		{
		NSString *new=[substitutions objectForKey:[self value]];
		if(new)
			[self setValue:new];	// replace identifier
		}
	else
		[self performSelectorForAllChildren:_cmd withObject:substitutions];
}

@end
