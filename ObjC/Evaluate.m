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

- (id) evaluate;
{
	id machine=nil;
#if 1
	NSLog(@"evaluate %@", self);
#endif
	[self treeWalk:@"evaluate" withObject:machine];	// recursive
}

- (id) evaluate_default:(id) machine
{
	NSLog(@"can't evaluate");
	return nil;
}

- (id) evaluate_const:(id) machine
{
	return self;
}

- (id) evaluate_ident:(id) machine
{
	// make a reference so that we can be a Lvalue
	return self;
}

// FIXME: a block must open a fresh range of variables
// or can we simply use the attributes of the identifier?

- (id) fetch
{
	// if reference (e.g. identifier), getVar:name
	return self;
}

- (void) store:(id) val
{
	// if not a reference -> not a Lvalue -> can't assign
	// store value
}

- (id) evaluate_add:(id) machine
{
	// dereference children
	// add [child intValue]
	// return [NSNumber numberWithInt:sum];
}

- (id) evaluate_functioncall:(id) machine
{ // function call
	// dereference children
	// push on stack
	// check for built-in (NSLog)
	// call function
	// return result
}

- (id) evaluate_methodcall:(id) machine
{
	// dereference children
	SEL sel=@selector(selectorOfCalledMethod);
	id target=nil;	// should be "self/super" of current method
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	id ret;
	[i setTarget:target];
	[i setSelector:sel];
	// setup method arguments
	NS_DURING
		[i invoke];
	NS_HANDLER
	// ???
	NS_ENDHANDLER
	[i getReturnValue:&ret];
	return ret;
}

@end
