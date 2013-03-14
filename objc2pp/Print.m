//
//  Print.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Print.h"
#include "build/y.tab.h"

// this would be much easier to design if we had an inheritance hierarchy
// and could add some  -(int) precedence; to some nodes to automatically create () and {} if needed
// well, we could keep () and {} in explicit nodes as well

@implementation Node (Print)

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

// allow to pass style options and max. line with

// expression objects ignore the level and line width and just return a string
// statement objects indent by level and return (wrapped) lines

- (NSString *) description;
{ // tree node(s) as NSString
	return [self descriptionAtLevel:0];
}

- (NSString *) descriptionAtLevel:(int) level;
{ // handle indentation level
	NSString *t=[self type];
	NSString *s;
	if([t isEqualToString:@"identifier"])
		{
		if([self left] || [self right])
			{ // type & storage class
			return [NSString stringWithFormat:@"/* %@ %@ */", [self left], [self right], [self value]];
			}
		return [self value];
		}
	else if([t isEqualToString:@"constant"])
		return [self value];
	if([t isEqualToString:@"{"])
		s=@"\n", level++;
	else
		s=@"";
	s=[s stringByAppendingFormat:@"%@%@%@", [[self left] descriptionAtLevel:level], t, [[self right] descriptionAtLevel:level]];
	if([t isEqualToString:@"("])
		s=[s stringByAppendingString:@")"];
	else if([t isEqualToString:@"["])
		s=[s stringByAppendingString:@"]"];
	else if([t isEqualToString:@"{"])
		s=[s stringByAppendingString:@"}\n"];
	return s;
}

@end
