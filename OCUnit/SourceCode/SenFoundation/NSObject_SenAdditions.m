/*$Id: NSObject_SenAdditions.m,v 1.5 2001/11/22 13:11:47 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "NSObject_SenAdditions.h"
#import "SenCollection.h"
#import <Foundation/Foundation.h>


@implementation NSObject (SenAdditions)
- (void) performSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection
{
    NSEnumerator *collectionEnumerator = [aCollection objectEnumerator];
    id each;
    while (each = [collectionEnumerator nextObject]) {
        [self performSelector:aSelector withObject:each];
    }
}


- (void) performSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection withObject:(id) anObject
{
    NSEnumerator *collectionEnumerator = [aCollection objectEnumerator];
    id each;
    while (each = [collectionEnumerator nextObject]) {
        [self performSelector:aSelector withObject:each withObject:anObject];
    }
}


- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection
{
    NSMutableArray *resultingCollection = [NSMutableArray array];
    NSEnumerator *collectionEnumerator = [aCollection objectEnumerator];
    id each;
    while (each = [collectionEnumerator nextObject]) {
        id result = [self performSelector:aSelector withObject:each];
        if (result != nil) {
            [resultingCollection addObject:result];
        }
    }
    return resultingCollection;
}


- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection withObject:(id) anObject
{
    NSMutableArray *resultingCollection = [NSMutableArray array];
    NSEnumerator *collectionEnumerator = [aCollection objectEnumerator];
    id each;
    while (each = [collectionEnumerator nextObject]) {
        id result = [self performSelector:aSelector withObject:each withObject:anObject];
        if (result != nil) {
            [resultingCollection addObject:result];
        }
    }
    return resultingCollection;
}
@end
