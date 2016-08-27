/*$Id: SenMutableTree.h,v 1.1 2002/01/08 14:54:02 alain Exp $*/
/* Copyright (c) 1997, Sen:te Ltd.  All rights reserved. */

#import <Foundation/NSObject.h>
#import <SenFoundation/NSObject_SenTree.h>

@class NSMutableArray;

@interface SenMutableTree:NSObject <SenTrees, NSCopying, NSCoding>
{
    id parent;
    NSMutableArray *children;
}
@end


@interface SenMutableTree (MutableTreePrimitives)
- (void) setParent:anObject;
- (void) addChild:(id) anObject;
- (void) removeChild:(id) anObject;
@end


@interface SenMutableTree (EOCompatibility)
//- (void) setChildren:(NSMutableArray *) value;

- (void) addToChildren:(id) value;
- (void) removeFromChildren:(id) value;
@end


@interface NSObject (SenTree_PFSExtensions)
- (int) maximumDepth;
- (BOOL) isEmpty;
@end

