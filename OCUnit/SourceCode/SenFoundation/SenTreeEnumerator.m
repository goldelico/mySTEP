/*$Id: SenTreeEnumerator.m,v 1.5 2001/11/22 13:11:50 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenTreeEnumerator.h"
#import "SenUtilities.h"
#import "SenEmptiness.h"
#import <Foundation/NSArray.h>


/* FIXME
   Depthfirst is preorder only. Postorder would be some kind of reverse enumerator. Useful?
*/

@implementation SenTreeEnumerator

+ (SenTreeEnumerator *) enumeratorWithTree:(id <SenTrees>)aTree
{
    return [[[self alloc] initWithTree:aTree] autorelease];
}

+ (SenTreeEnumerator *) enumeratorWithTree:(id <SenTrees>)aTree traversalType:(SenTreeTraversalType)aTraversalType
{
    return [[[self alloc] initWithTree:aTree traversalType:aTraversalType] autorelease];
}

- (id) initWithTree:(id <SenTrees>)aTree traversalType:(SenTreeTraversalType)aTraversalType
{
    if(self = [super init]){
    	traversalType = aTraversalType;
        queue = [[NSArray allocWithZone:[self zone]] initWithObjects:aTree, nil];
    }
    
    return self;
}

- (id) initWithTree:(id <SenTrees>)aTree
{
    return [self initWithTree:aTree traversalType:SenTreeDepthFirst];
}

- (void) dealloc
{
    RELEASE(queue);
    
    [super dealloc];
}

- (void) setQueue:(NSArray *) value
{
    ASSIGN(queue, value);
}

- (BOOL) shouldEnter:(id <SenTrees>)aTree
{
    return YES;
}

- (id) nextObject
{
    id	car = nil;
    int	count = [queue count];

    if(count > 0){
        NSArray	*expand = nil;
        NSArray	*cdr = nil;

        car = [queue objectAtIndex:0];
        if([self shouldEnter:car])
            expand = [car children];
        else
            expand = nil;

        if(count > 1)
            cdr = [queue subarrayWithRange:NSMakeRange(1, count - 1)];

        if(traversalType == SenTreeDepthFirst)
            [self setQueue:[expand isEmpty] ? cdr : [expand arrayByAddingObjectsFromArray:cdr]];
        else
            [self setQueue:[cdr isEmpty] ? expand : [cdr arrayByAddingObjectsFromArray:expand]];
    }
    
    return car;
}

@end
