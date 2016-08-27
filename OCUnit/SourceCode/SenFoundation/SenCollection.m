/*$Id: SenCollection.m,v 1.5 2001/11/22 13:11:48 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenCollection.h"
#import "SenUtilities.h"

@interface NSObject (MethodSignatures)
- (double) doubleMethod;
- (unsigned int) unsignedIntMethod;
@end


@implementation NSArray (SenCollectionCompletion)
- (NSArray *) asArray
{
    return self;
}


- (NSSet *) asSet
{
    return [NSSet setWithArray:self];
}
@end


@implementation NSSet (SenCollectionCompletion)
- (NSArray *) asArray
{
    return [self allObjects];
}


- (NSSet *) asSet
{
    return self;
}
@end


@implementation NSDictionary (SenCollectionCompletion)
- (BOOL) containsObject:(id) anObject
{
    return [[self asArray] containsObject:anObject];
}


- (void) makeObjectsPerformSelector:(SEL) aSelector
{
    [[self asArray] makeObjectsPerformSelector:aSelector];
}


- (void) makeObjectsPerformSelector:(SEL) aSelector with:(id) anObject
{
    [[self asArray] makeObjectsPerformSelector:aSelector with:anObject];
}


- (NSArray *) asArray
{
    return [self allValues];
}


- (NSSet *) asSet
{
    return [[self asArray] asSet];
}
@end


@interface NSObject (SelectingInvocations)
- (NSInvocation *) filteringInvocationForSelector:(SEL) aSelector;
- (NSInvocation *) filteringInvocationForSelector:(SEL) aSelector withArgument:(id) anObject;
@end


@implementation NSObject (Sum) 
- (unsigned int) sumWithUnsignedIntSelector:(SEL) aSelector
{
    unsigned int sum = 0;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NSObject instanceMethodSignatureForSelector:@selector(unsignedIntMethod)]];
    NSEnumerator *objectEnumerator = [(id <SenCollection>) self objectEnumerator];
    id each;

    [invocation setSelector:aSelector];
    while (each = [objectEnumerator nextObject]) {
        unsigned int result;
        [invocation invokeWithTarget:each];
        [invocation getReturnValue:&result];
        sum += result;
    }
    return sum;;
}


- (double) sumWithDoubleSelector:(SEL) aSelector
{
    double sum = 0;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NSObject instanceMethodSignatureForSelector:@selector(doubleMethod)]];
    NSEnumerator *objectEnumerator = [(id <SenCollection>) self objectEnumerator];
    id each;
    [invocation setSelector:aSelector];
    while (each = [objectEnumerator nextObject]) {
        double result;
        [invocation invokeWithTarget:each];
        [invocation getReturnValue:&result];
        sum += result;
    }
    return sum;;
}
@end


@implementation NSObject (Detection)
- (id) firstObjectDetectedWithInvocation:(NSInvocation *) anInvocation byRejecting:(BOOL) shouldBeRejected
{
    NSEnumerator *objectEnumerator = [(id <SenCollection>) self objectEnumerator];
    id each;
    while (each = [objectEnumerator nextObject]) {
        BOOL result;
        [anInvocation invokeWithTarget:each];
        [anInvocation getReturnValue:&result];
        if (result != shouldBeRejected) {
            return each;
        }
    }
    return nil;
}


- (id) firstObjectDetectedBySelector:(SEL)aSelector
{
    return [self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector] byRejecting:NO];
}


- (id) firstObjectDetectedBySelector:(SEL)aSelector with:(id) anObject
{
    return [self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector withArgument:anObject] byRejecting:NO];
}


- (id) firstObjecRejectedBySelector:(SEL)aSelector
{
    return [self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector] byRejecting:YES];
}

- (id) firstObjecRejectedBySelector:(SEL)aSelector with:(id) anObject
{
    return [self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector withArgument:anObject] byRejecting:YES];
}

- (BOOL)existsObjectSatisfyingSelector:(SEL)aSelector
{
    return ([self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector] byRejecting:NO] != nil);
}

- (BOOL)existsObjectSatisfyingSelector:(SEL)aSelector with:(id) anObject
{
    return ([self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector withArgument:anObject] byRejecting:NO] != nil);
}

- (BOOL)existsObjectNotSatisfyingSelector:(SEL)aSelector
{
    return ([self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector] byRejecting:YES] != nil);
}

- (BOOL)existsObjectNotSatisfyingSelector:(SEL)aSelector with:(id) anObject
{
    return ([self firstObjectDetectedWithInvocation:[self filteringInvocationForSelector:aSelector withArgument:anObject] byRejecting:YES] != nil);
}

@end


@implementation NSObject (CollectionCollection)

- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector;
{
    NSMutableArray *collection = [NSMutableArray arrayWithCapacity:[(id <SenCollection>)self count]];
    NSEnumerator *objectEnumerator = [(id <SenCollection>) self objectEnumerator];
    id each;
    while (each = [objectEnumerator nextObject]) {
        id result = [each performSelector:aSelector];
        if (result != nil) {
            [collection addObject:result];
        }
    }
    return collection;
}


- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector withObject:(id) anObject
{
    NSMutableArray *collection = [NSMutableArray arrayWithCapacity:[(id <SenCollection>)self count]];
    NSEnumerator *objectEnumerator = [(id <SenCollection>) self objectEnumerator];
    id each;
    while (each = [objectEnumerator nextObject]) {
        id result = [each performSelector:aSelector withObject:anObject];
        if (result != nil) {
            [collection addObject:result];
        }
    }
    return collection;
}
@end


@implementation NSObject (CollectionSelection)
- (id) collectionByFilteringWithInvocation:(NSInvocation *) anInvocation byRejecting:(BOOL) shouldBeRejected
{
    NSMutableArray *collection = [NSMutableArray array];
    NSEnumerator *objectEnumerator = [(id <SenCollection>) self objectEnumerator];
    id each;
    while (each = [objectEnumerator nextObject]) {
        BOOL isFiltered;
        [anInvocation invokeWithTarget:each];
        [anInvocation getReturnValue:&isFiltered];
        if (isFiltered != shouldBeRejected) {
            [collection addObject:each];
        }
    }
    return collection;
}


- (id <SenCollection>) collectionBySelectingWithSelector:(SEL) aSelector
{
    return [self collectionByFilteringWithInvocation:[self filteringInvocationForSelector:aSelector] byRejecting:NO];
}


- (id <SenCollection>) collectionBySelectingWithSelector:(SEL) aSelector withObject:(id) anObject
{
    return [self collectionByFilteringWithInvocation:[self filteringInvocationForSelector:aSelector withArgument:anObject] byRejecting:NO];
}


- (id <SenCollection>) collectionByRejectingWithSelector:(SEL) aSelector
{
    return [self collectionByFilteringWithInvocation:[self filteringInvocationForSelector:aSelector] byRejecting:YES];
}


- (id <SenCollection>) collectionByRejectingWithSelector:(SEL) aSelector withObject:(id) anObject
{
    return [self collectionByFilteringWithInvocation:[self filteringInvocationForSelector:aSelector withArgument:anObject] byRejecting:YES];
}
@end


@implementation NSObject (SelectingInvocations)
- (BOOL) filteringPrototypeWithNoArguments {return YES;}
- (BOOL) filteringPrototypeWithArgument:(id) anObject {return YES;}

- (NSMethodSignature *) filteringSignatureWithNoArguments
{
    return [self methodSignatureForSelector:@selector(filteringPrototypeWithNoArguments)];
}


- (NSMethodSignature *) filteringSignatureWithOneArguments
{
    return [self methodSignatureForSelector:@selector(filteringPrototypeWithArgument:)];
}


- (NSInvocation *) filteringInvocationForSelector:(SEL) aSelector
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self filteringSignatureWithNoArguments]];
    [invocation setSelector:aSelector];
    return invocation;
}


- (NSInvocation *) filteringInvocationForSelector:(SEL) aSelector withArgument:(id) anObject
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self filteringSignatureWithOneArguments]];
    [invocation setSelector:aSelector];
    [invocation setArgument:&anObject atIndex:2];
    return invocation;
}
@end


@implementation NSObject (MethodSignatures)
- (double) doubleMethod
{
    return 0.0;
}


- (unsigned int) unsignedIntMethod
{
    return 0;
}
@end
