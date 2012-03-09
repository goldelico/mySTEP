//
//  Printing.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Printing.h"
#include "y.tab.h"

// this would be much easier to design if we had an inheritance hierarchy
// and could add some  -(int) precedence; to some nodes to automatically create () and {} if needed
// well, we could keep () and {} in explicit nodes as well

@implementation Node (Printing)

- (void) print:(int) level;
{
	NSString *t=[self type];
	if([t isEqualToString:@"identifier"])
		printf("%s", [[self value] UTF8String]);
	else if([t isEqualToString:@"constant"])
		printf("%s", [[self value] UTF8String]);
	else
		{
		[[self left] print:level+1];
		if([self left] || [self right])
			printf("%s", [t UTF8String]);
		[[self right] print:level+1];
		if([t isEqualToString:@"("])
			printf(")");
		else if([t isEqualToString:@"["])
			printf("]");
		else if([t isEqualToString:@"{"])
			printf("}");
		}
}

- (void) print;
{
	[self print:0];
}

@end
