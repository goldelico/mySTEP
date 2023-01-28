/*$Id: NSObject_SenTree.m,v 1.13 2002/01/04 14:23:34 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "NSObject_SenTree.h"
#import "SenTreeEnumerator.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSValue.h>


@implementation NSObject(SenTree)
- (id) parent
{
    return nil;
}

- (NSArray *) children
{
    return nil;
}

- (BOOL) isLeaf
{
    NSArray	*children = [self children];
    
    return (children == nil) || ([children count] == 0);
}

- (BOOL) isRoot
{
    return ([self parent] == nil);
}

-  root
{
    return ([self isRoot]) ? self : [[self parent] root];
}

- (BOOL) isDescendantOf:anAncestor
{
    id	parent = [self parent];

	return (parent != nil) && ((parent == anAncestor) || [parent isDescendantOf:anAncestor]);
}

- (int) rank
{
    return ([self isRoot]) ? 0 : [[[self parent] children] indexOfObjectIdenticalTo:self];
}

- (unsigned) count
{
    id	children = [self children];
    return children ? [children count] : 0;
}


- (unsigned) deepCount
{
	unsigned count = 1;
	NSEnumerator *childEnumerator = [[self children] objectEnumerator];
	id each;
	while (each = [childEnumerator nextObject]) {
		count += [each deepCount];
	}
	return count;
}


- (int) depth
{
    return [self isRoot] ? 0 : (1 + [[self parent] depth]);
}

- (NSEnumerator *) objectEnumeratorWithTraversalType:(SenTreeTraversalType) traversalType
{
    return [SenTreeEnumerator enumeratorWithTree:(id <SenTrees>)self traversalType:traversalType];
}


- (NSEnumerator *) depthFirstEnumerator
{
    return [self objectEnumeratorWithTraversalType:SenTreeDepthFirst];
}

- (NSEnumerator *) breadthFirstEnumerator
{
    return [self objectEnumeratorWithTraversalType:SenTreeBreadthFirst];
}

- (NSArray *) pathAsNodes
{
    NSMutableArray *result = [NSMutableArray array];
    id each = self;
    while (each != nil) {
        [result insertObject:each atIndex:0];
        each = [each parent];
    }
    return result;
}

- (NSArray *) pathAsRanks
{
    NSMutableArray *result = [NSMutableArray array];
    id each = self;
    while (![each isRoot]) {
        [result insertObject:[NSNumber numberWithInt:[each rank]] atIndex:0];
        each = [each parent];
    }
    return result;
}

- (BOOL) isEqualToTree:(NSObject *) anotherTree
{
    if (![self isEqualToNode:anotherTree]) {
		return NO;
	}
    return [self areChildren:[self children] equalToChildren:[anotherTree children]];
}

- (BOOL) areChildren:(NSArray *) ourChildren equalToChildren:(NSArray *) otherChildren
{
    if ([otherChildren count] != [ourChildren count]) {
		return NO;
	}
    else {
        id enumerator =  [ourChildren objectEnumerator];
		id otherEnumerator = [otherChildren objectEnumerator];
        id eachChild, eachOtherChild;

        while (eachChild = [enumerator nextObject]) {
            eachOtherChild = [otherEnumerator nextObject];
            if (![eachChild isEqualToNode:eachOtherChild]) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL) isEqualToNode:(NSObject *) anotherNode
{
    return YES;
}
@end


@implementation NSObject(SenTreeTraversals)
- (id) traversePreorder:(SEL) aSelector withObject:(id) anObject withObject:(id) anotherObject
{
    NSEnumerator *childEnumerator = [[self children] objectEnumerator];
    id child;

    if ([self respondsToSelector:aSelector] &&
		[self performSelector:aSelector withObject:anObject withObject:anotherObject] == nil) {
		return self;
	}

    while (child = [childEnumerator nextObject]) {
        [child traversePreorder:aSelector withObject:anObject withObject:anotherObject];
	}
    return self;
}

- (id) traversePreorder:(SEL) aSelector withObject:(id) anObject
{
    return [self traversePreorder:aSelector withObject:anObject withObject:nil];
}

- (id) traversePreorder:(SEL) aSelector
{
    return [self traversePreorder:aSelector withObject:nil withObject:nil];
}

- (id) traversePostorder:(SEL) aSelector withObject:(id) anObject withObject:(id) anotherObject
{
    NSEnumerator *childEnumerator = [[self children] objectEnumerator];
    id child;

    while (child = [childEnumerator nextObject]) {
        [child traversePostorder:aSelector withObject:anObject withObject:anotherObject];
	}

    if ([self respondsToSelector:aSelector]) {
        [self performSelector:aSelector withObject:anObject withObject:anotherObject];
	}
    return self;
}

- (id) traversePostorder:(SEL) aSelector withObject:(id) anObject
{
    return [self traversePostorder:aSelector withObject:anObject withObject:nil];
}

- (id) traversePostorder:(SEL) aSelector
{
    return [self traversePostorder:aSelector withObject:nil withObject:nil];
}
@end
