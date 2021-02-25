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

// am besten über Tabelle steuern die type über NSDictionary in NSDict übersetzt
// wo alles drinsteht!
// Prefix, Infix, Postfix-Zeichen für Children
// Level

- (NSString *) prettyObjC;
{
	NSString *t=[self type];
	NSString *s=@"";
	NSEnumerator *e;
	Node *n;
	BOOL first;
	static NSDictionary *table=nil;
	NSDictionary *ctrl;
	if([t isEqualToString:@"identifier"])
		return [self value];
	else if([t isEqualToString:@"constant"])
		return [self value];
	else if([t isEqualToString:@"string"])
		// FIXME: alreydy contains the ""
		// multiple strings are children - should be handled by simplify!
		return [NSString stringWithFormat:@"\"%@\"", [self value]];	// correctly quote
	else if([t isEqualToString:@"stringliteral"])
		// string value are children of type "string"
		return [self value];
	e=[self childrenEnumerator];
	if(!table)
		table=[[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"pretty"] retain];
	ctrl=[table objectForKey:t];
	if(ctrl)
		{ // table driven
			NSString *c;
			c=[[ctrl objectForKey:@"prefix"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
			if(c)
				s=c;
			n=[e nextObject];
			s=[s stringByAppendingFormat:@"%@", [n prettyObjC]];
			c=[[ctrl objectForKey:@"infix-first"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
			if(c)
				s=[s stringByAppendingString:c];
			while(n=[e nextObject])
				{
				c=[[ctrl objectForKey:@"infix"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
				if(c)
					s=[s stringByAppendingFormat:@"%@%@", c, [n prettyObjC]];
				else
					s=[s stringByAppendingString:[n prettyObjC]];
				}
			c=[[ctrl objectForKey:@"suffix"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
			if(c)
				s=[s stringByAppendingString:c];
			return s;
		}
	if([t isEqualToString:@"symtab"])
		{ // all elements
		while((n=[e nextObject]))
			s=[s stringByAppendingString:[n indentedPrettyObjC]];
		return s;
		}
	if([t isEqualToString:@"block"])
		{
		// we can have different variants, i.e. if { itself is indented or not
		s=@"{\n";
		while((n=[e nextObject]))
			s=[s stringByAppendingString:[n indentedPrettyObjC]];
		s=[s stringByAppendingString:@"}\n"];
		return s;
		}
//	if([t isEqualToString:@"forwardclass"])
//	if([t isEqualToString:@"@interface"])
	if([t isEqualToString:@"functioncall"])
		{
		s=[s stringByAppendingFormat:@"%@(%@)", [[e nextObject] prettyObjC], [[e nextObject] prettyObjC]];
		return s;
		}
	if([t isEqualToString:@"parexpr"])
		{
		s=[s stringByAppendingFormat:@"(%@)", [[e nextObject] prettyObjC]];
		return s;
		}
	if([t isEqualToString:@"statementlist"])
		{
		while((n=[e nextObject]))
			s=[s stringByAppendingFormat:@"%@;\n", [n prettyObjC]];
		return s;
		}
	if([t isEqualToString:@"exprlist"])
		{
		while((n=[e nextObject]))
			{
			if([s length])
				s=[s stringByAppendingFormat:@", %@", [n prettyObjC]];
			else
				s=[n prettyObjC];
			}
		return s;
		}
	if([t isEqualToString:@"unit"] ||
	   [t isEqualToString:@"exprlist"])
		{
		while((n=[e nextObject]))
			s=[s stringByAppendingString:[n prettyObjC]];
		return s;
		}
	first=YES;
	while((n=[e nextObject]))
		{
		BOOL paren=[n level] > [self level];
		if(paren)
			s=@"(";
		// should know another property if we are prefix infix or postfix
		// and yet another property should know the C operator
		// get from lookup table (NSDict[type])
		if([self childrenCount] < 2)
			s=[s stringByAppendingFormat:@"%@ ", t];	// prefix
		else if(!first)
			// add spaciness here
			s=[s stringByAppendingString:t];	// infix
		first=NO;
		s=[s stringByAppendingString:[n prettyObjC]];
		if(paren)
			s=[s stringByAppendingString:@")"];
		}
	return s;
}

- (void) compile_pretty_unknown;
{ // no processing of tree nodes
	return;
}

@end
