//
//  Evaluate.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Simplify.h"

/*
 * evaluate statements
 * by maintaining a stack, global heap and variables
 * calling methods and functions, etc.
 * and processing if, while, for etc.
 *
 * what do we do with syscalls and libc?
 *
 */

@implementation Node (Evaluate)

- (void) evaluate;
{
	id machine=nil;
	[self treeWalk:@"evaluate" withObject:machine];	// recursive
}

- (void) evaluate_default:(id) machine
{
	NSLog(@"can't evaluate");
}

- (void) evaluate_const:(id) machine
{
	NSLog(@"can't evaluate");
	// push value on stack
}

- (void) evaluate_ident:(id) machine
{
	NSLog(@"can't evaluate");
	// push reference to variable storage
}

@end
