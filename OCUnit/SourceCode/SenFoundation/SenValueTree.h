/*$Id: SenValueTree.h,v 1.1 2002/01/08 14:54:02 alain Exp $*/
/* Copyright (c) 1997, Sen:te Ltd.  All rights reserved. */

#import "SenMutableTree.h"

// SenValueTree implements a tree with a value stored at each node.

@interface SenValueTree : SenMutableTree
{
    @private
    id value;
}

+ valueTreeWithPropertyList:(NSString *) aString;
- initWithPropertyList:(NSString *) aString;
- initWithSExpression:(NSArray *) anArray;
// Initializes a SenValueTree from a S-expression like property list.
// For instance: (a (b c))  ==>    a
//                                / \
//                               b   c

+ valueTreeWithOutlineString:(NSString *) aString;
- initWithOutlineString:(NSString *) aString;
// Initializes a SenValueTree from an indented outline.
// For instance: a     ==>    a
//                 b         / \
//                 c        b   c


- initWithValue:(id) aValue;
- (id) value;
- (void) setValue:(id) aValue;

@end
