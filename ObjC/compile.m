//
//  compile.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Compile.h"

// here we can simplify the tree before any processing
// a -> b   ===> (*a).b
// a[b]		===> *(a+b)

@implementation Node (Compile)

+ (NSArray *) compileTargets;
{
	static NSArray *targets=nil;
	if(!targets)
		targets=[[NSArray alloc] initWithObjects:
				 @"C",		// translate (expand) to standard C code
				 @"objc1",	// translate (expand) to ObjC-1.0
				 @"objc2",	// translate (simplify) to ObjC-2.0
				 @"pretty",	// no translation, just pretty print
				 @"arm",	// translate to ARM asm statements
				 @"PHP",	// translate to PHP code for mySTEP.php
				 nil];
	return targets;
}

- (void) registerAssign
{ // assign explicit 'register' and temporary stack variables
	
}

- (void) compileForTarget:(NSString *) target;
{
	target=[@"compile_" stringByAppendingString:target];
	// check if target exists...
	[self treeWalk:target];
}

- (void) compile_arm_unknown;
{ // translate to asm() statements
	Node *n=[Node node:@"asm"];
	[n addChild:[Node leaf:@"string" value:[NSString stringWithFormat:@"some asm statement for %@", [self type]]]];
	[self replaceBy:n];
}

@end
