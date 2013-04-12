//
//  Print.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Print.h"

// implement doSelectorByType: methods!

// get operator precedence
// distinguish only between statement and expression (inline vs. block)
// i.e. each node type has several attributes:
//   int level
//   char *token
//   BOOL block
// and the formatter uses that information (e.g. levels to add implicit () and block to add \n )

@implementation Node (Print)

// allow to pass style options and max. line with

// expression objects ignore the level and line width and just return a string
// statement objects indent by level and return (wrapped) lines

- (NSString *) pretty;
{ // tree node(s) as NSString
	return [self prettyAtLevel:0];
}

- (int) level
{
	NSString *t=[self type];
	if([t isEqualToString:@"identifier"] || [t isEqualToString:@"constant"])
		return 10;
	if([t isEqualToString:@"*"] || [t isEqualToString:@"/"] || [t isEqualToString:@"%"])
		return 6;
	if([t isEqualToString:@"+"] || [t isEqualToString:@"-"])
		return 5;
	return 0;
}

- (NSString *) prettyAtLevel:(int) level;
{ // handle indentation level
#if 0
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
	if([self left])
		{
		if([[self left] level] < [self level])
			s=[s stringByAppendingFormat:@"(%@)", [[self left] prettyAtLevel:level]];
		else
			s=[s stringByAppendingString:[[self left] prettyAtLevel:level]];
		}
	s=[s stringByAppendingString:t];
	if([self right])
		{
		if([[self right] level] <= [self level])
			s=[s stringByAppendingFormat:@"(%@)", [[self right] prettyAtLevel:level]];	// includes same level for e.g. a+(b+c)
		else
			s=[s stringByAppendingString:[[self right] prettyAtLevel:level]];
		}
	if([t isEqualToString:@"("])
		s=[s stringByAppendingString:@")"];
	else if([t isEqualToString:@"["])
		s=[s stringByAppendingString:@"]"];
	else if([t isEqualToString:@"{"])
		s=[s stringByAppendingString:@"}\n"];
	return s;
#endif
	return @"";
}

@end
