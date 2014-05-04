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

static float spaciness=0.5;

+ (void) setSpaciness:(float) factor;	// 0...1 - controls if(a+b>c) ... if (a+b > c) ... if (a + b > c)
{
	spaciness=factor;
}

static float bracketiness=0.5;

+ (void) setBracketiness:(float) factor;	// 0..1 - controls if() { ... }\n ... if\n{\n...\n}
{
	bracketiness=factor;
}

static unsigned maxLineLength=80;

+ (void) setMaxLineLength:(unsigned) width;
{
	maxLineLength=width;
}

// allow to pass style options and max. line with

// expression objects ignore the level and line width and just return a string
// statement objects indent by level and return (wrapped) lines

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

- (NSString *) indentedPrettyObjC;
{ // indent by one (more) tab
	NSEnumerator *cd=[[[self prettyObjC] componentsSeparatedByString:@"\n"] objectEnumerator];
	NSString *cdc;
	NSString *s=@"";
	while((cdc=[cd nextObject]))
		if([cdc length] > 0)
			s=[s stringByAppendingFormat:@"\t%@\n", cdc];	// indent each line of the (sub) component
	return s;
}

- (NSString *) prettyObjC;
{
	NSString *t=[self type];
	NSString *s=@"";
	if([t isEqualToString:@"identifier"])
		return [self value];
	else if([t isEqualToString:@"constant"])
		return [self value];
	if([t isEqualToString:@"block"])
		{
		NSEnumerator *e=[self childrenEnumerator];
		Node *n;
		// we can have different variants, i.e. if { itself is indented or not
		s=@"{\n";
		while((n=[e nextObject]))
			s=[s stringByAppendingString:[n indentedPrettyObjC]];
		s=[s stringByAppendingString:@"}\n"];
		return s;
		}
//	if([t isEqualToString:@"forwardclass"])
//	if([t isEqualToString:@"@interface"])
	if([t isEqualToString:@"unit"])
		{
		NSEnumerator *e=[self childrenEnumerator];
		Node *n;
		s=@"";
		while((n=[e nextObject]))
			s=[s stringByAppendingString:[n prettyObjC]];
		return s;
		}
	return t;
}

@end
