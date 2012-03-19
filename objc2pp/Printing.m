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
		{
		if([self left] || [self right])
			{
			printf("/* ");
			[[self left] print:level];	// storage class
			printf(" ");
			[[self right] print:level];	// type tree
			printf("*/");				
			}
		printf("%s", [[self value] UTF8String]);		
		}
	else if([t isEqualToString:@"constant"])
		printf("%s", [[self value] UTF8String]);
	else
		{
		int l=level;
		if([t isEqualToString:@"{"])
			printf("\n"), l++;
		[[self left] print:l];
		printf("%s", [t UTF8String]);
		[[self right] print:l];
		if([t isEqualToString:@"("])
			printf(")");
		else if([t isEqualToString:@"["])
			printf("]");
		else if([t isEqualToString:@"{"])
			printf("}\n");
		}
}

- (void) print;
{
	[self print:0];
}

@end
