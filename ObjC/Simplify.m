//
//  Simplify.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Simplify.h"

// NOTE: evaluation/simplification of constant float expression needs private IEEE FPU implementation!
// unless we want to require a FPU on the underlaying system

/*
 * evaluate constant expressions
 * remove dead code
 * expand static inline
 * loop unrolling/vectorization
 * evaluate common subexpressions only once
 * remove "parexpr"
 */

@implementation Node (Simplify)

- (void) redo
{
	// set redo flag
	// can be called as [self redo] or [parent redo]
}

- (void) simplify;
{ // main function
	// FIXME: should loop on each level individually!
	// should loop while something has been modified or a redo-indicator/attribute has been set
	[self treeWalk:@"simplify"];	// recursive
}

- (void) simplify_unknown
{
	return; // leave as is
}

- (void) simplify_string
{ // if there are children, merge strings together
	if([self childrenCount])
		{
		[self setValue:[[self value] stringByAppendingString:[[self firstChild] value]]];
		[self removeChildAtIndex:0];
		}
}

- (void) simplify_comment
{
	[self replaceBy:nil];	// delete
}

- (void) simplify_paraexpr
{
	[self replaceBy:[self firstChild]];	// remove braces node
}

- (void) simplify_block
{
	if([self childrenCount] == 0)
		[self replaceBy:nil];	// remove
}

- (void) simplify_if
{
	// check for constant condition
	// replace by then or else part
	if([self childrenCount] == 0)
		[self replaceBy:nil];	// statement has no effect - can be removed
}

- (void) simplify_while
{
	// check for constant condition
	// optionally remove whole loop
	/* should we eliminate empty while loops in any case? what with while(1); ? */
	if(/* condition is false */ [self childrenCount] == 0)
		[self replaceBy:nil];	// statement has no effect - can be removed
}

@end
