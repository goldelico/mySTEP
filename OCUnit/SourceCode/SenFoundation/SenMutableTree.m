/*$Id: SenMutableTree.m,v 1.1 2002/01/08 14:54:02 alain Exp $*/
/* Copyright (c) 1997, Sen:te Ltd.  All rights reserved. */

#import "SenMutableTree.h"
#import <SenFoundation/SenFoundation.h>
#import <Foundation/Foundation.h>
#import "SenUtilities.h"


@interface SenMutableTree (_Private)
- (void) _setParent:anObject;
- (void) _setChildren:(NSMutableArray *) value;
@end


@implementation SenMutableTree
- init
{
    [super init];
    children = [[NSMutableArray alloc] init];
    parent = nil;
    return self;
}


- (void) dealloc
{
    RELEASE(children);
    [super dealloc];
}


// @implementation SenMutableTree (SenTreesProtocol)
- parent
{
    return parent;
}


- (NSArray *) children
{
    return children;
}


- (void) _setParent:(id) anObject
{
    //SEN_TRACE;
    //RETAIN (parent, anObject);
    parent = anObject;
}


#if 0
- (void) _setChildren:(NSMutableArray *) value
{
    //SEN_TRACE;
    RELEASE (children);
    children = [value mutableCopy];
    [children makeObjectsPerformSelector:@selector(_setParent:) withObject:self];
}
#endif
// @end


- (id) copy
{
    return [self copyWithZone:[self zone]];
}


- (id) copyWithZone:(NSZone *)zone
{
    id newObject;

    newObject=[[[self class] allocWithZone:zone] init];
    [newObject _setChildren:[children copyWithZone:zone]];

    return newObject;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    senassert (NO);
}


- (id)initWithCoder:(NSCoder *)decoder
{
    senassert (NO);
    return [super init];
}
@end


@implementation SenMutableTree (MutableTreePrimitives)
- (void) setParent:anObject
{
    //SEN_TRACE;
    [self _setParent:anObject];
}


- (void) addChild:(id) anObject
{
    [children addObject:anObject];
    [anObject _setParent:self];
}


- (void) removeChild:(id) anObject;
{
    [anObject _setParent:nil];
    [children removeObject:anObject];
}
@end


@implementation SenMutableTree (NSMutableArrayPrimitives)
- (void) addObject:(id) anObject
{
    [self addChild:anObject];
}


- (void) replaceObjectAtIndex:(unsigned) index withObject:(id) anObject;
{
    [[children objectAtIndex:index] _setParent:nil];
    [children replaceObjectAtIndex:index withObject:anObject];
    [anObject _setParent:self];
}


- (void) removeLastObject
{
    [[children lastObject] _setParent:nil];
    [children removeLastObject];
}


- (void) removeObjectAtIndex:(unsigned) index
{
    [[children objectAtIndex:index] _setParent:nil];
    [children removeObjectAtIndex:index];
}


- (void) insertObject:(id) anObject atIndex:(unsigned) index;
{
    [children insertObject:anObject atIndex:index];
    [anObject _setParent:self];
}
@end


@implementation SenMutableTree (EOCompatibility)

- (void) _setParent:(id) anObject
{
    RETAIN (parent, anObject);
    // should not retain, but breaks w/ EOF
}

- (void) setParent:anObject
{
    //[self willChange];
    SELF_WILL_CHANGE;
    [self _setParent:anObject];
}


#if 0
- (void) setChildren:(NSArray *) value
{
    SELF_WILL_CHANGE;
    //[self willChange];
    [self _setChildren];

    // RETAIN (children,value);
    // should _setParent (see _setChildren), but breaks w/ EOF
}
#endif



- (void) addToChildren:(id) value
{
    //SEN_TRACE;
    //[self willChange];
    SELF_WILL_CHANGE;
    [children addObject:value];
}


- (void) removeFromChildren:(id) value
{
    //SEN_TRACE;
    //[self willChange];
    SELF_WILL_CHANGE;
    [children removeObject:value];
}
@end


@implementation NSObject (SenTree_PFSExtensions)
- (int) maximumDepth
{
    int maximumDepth = 0;
    NSEnumerator *treeEnumerator = [self depthFirstEnumerator];
    id each;
    while (each = [treeEnumerator nextObject]) {
        maximumDepth = MAX (maximumDepth, [each depth]);
    }
    return maximumDepth;
}

- (BOOL) isEmpty
{
    return isNilOrEmpty ([self children]);
}

@end

