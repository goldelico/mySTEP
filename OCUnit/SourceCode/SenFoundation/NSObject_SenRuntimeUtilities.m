/*$Id: NSObject_SenRuntimeUtilities.m,v 1.10 2001/11/22 13:11:47 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "NSObject_SenRuntimeUtilities.h"
#import "SenEmptiness.h"
#import "SenAssertion.h"
#import "SenCollection.h"
#import "SenInvocationEnumerator.h"
#import "SenClassEnumerator.h"
#import <Foundation/Foundation.h>
#import <objc/objc-class.h>

NSString *SenMethodName (id self, SEL _cmd)
{
    return [NSString stringWithFormat:@"%c[%@ %@]", (self == [self class]) ? "+" : "-", [self class], NSStringFromSelector(_cmd)];
}


#if defined (GNUSTEP)

@interface Object (PrivateRuntimeUtilities)
+ (BOOL)respondsToSelector:(SEL)sel;
@end

@implementation Object (PrivateRuntimeUtilities)
+ (BOOL)respondsToSelector:(SEL)sel
{
  return (IMP)class_get_instance_method(self, sel) != (IMP)0;
}
@end

#endif

@interface NSObject (SenPrivateRuntimeUtilities)
+ (BOOL) isASubclassOfClass:(Class) aClass;
+ (BOOL) isASuperclassOfClass:(Class) aClass;
@end


@implementation NSObject (SenRuntimeUtilities)
+ (NSEnumerator *) instanceInvocationEnumerator
{
    return [SenInvocationEnumerator instanceInvocationEnumeratorForClass:self];
}


+ (NSEnumerator *) classEnumerator
{
    return [SenClassEnumerator classEnumerator];
}


+ (NSString *) className
{
    return NSStringFromClass (self);
}


- (NSString *) className
{
    return NSStringFromClass ([self class]);
}


+ (NSArray *) allSuperclasses
{
    static NSMutableDictionary *superclassesClassVar = nil;
    NSString *key = NSStringFromClass (self);

    if (superclassesClassVar == nil) {
        superclassesClassVar = [[NSMutableDictionary alloc] init];
    }
    if ([superclassesClassVar objectForKey:key] == nil) {
        NSMutableArray *superclasses = [NSMutableArray array];
        Class currentClass = self;
        while (currentClass != nil) {
            [superclasses addObject:currentClass];
            currentClass = [currentClass superclass];
        }
        [superclassesClassVar setObject:superclasses forKey:key];
    }
    return [superclassesClassVar objectForKey:key];
}


- (NSArray *) allSuperclasses
{
    return [[self class] allSuperclasses];
}


+ (NSArray *) allSuperclassNames
{
    return [[[self allSuperclasses] collectionByPerformingSelector:@selector(className)] asArray];
}


- (NSArray *) allSuperclassNames
{
    return [[[self allSuperclasses] collectionByPerformingSelector:@selector(className)] asArray];
}


+ (BOOL) isASubclassOfClass:(Class) aClass
{
    return  (aClass != self) && [[self allSuperclasses] containsObject:aClass];
}

+ (BOOL) isASuperclassOfClass:(Class) aClass
{
    // Some classes don't inherit from NSObject, nor do they implement <NSObject> protocol, thus probably don't respond to @selector(respondsToSelector:)
    // We check if the class responds to @selector(respondsToSelector:) using Objective-C low-level function calls.
    return  (aClass != self) &&
        (class_getClassMethod(aClass, @selector(respondsToSelector:)) != NULL) &&
        [aClass respondsToSelector:@selector(allSuperclasses)] &&
        [[aClass allSuperclasses] containsObject:self];
}


+ (NSArray *) allSubclasses
{
    NSMutableArray *subclasses = [NSMutableArray array];
    NSEnumerator *classEnumerator = [self classEnumerator];
    id eachClass = nil;

    while (eachClass = [classEnumerator nextObject]) {
        NS_DURING
            if ([self isASuperclassOfClass:eachClass]) {
                [subclasses addObject:eachClass];
            }
            ;
        NS_HANDLER
            SEN_DEBUG (([NSString stringWithFormat:@"Skipping %@ (%@)", NSStringFromClass(eachClass), localException]));
        NS_ENDHANDLER
    }
    return [subclasses isEmpty] ? nil : subclasses;
}


+ (NSArray *) allSubclassNames;
{
    return [[[self allSubclasses] collectionByPerformingSelector:@selector(className)] asArray];
}


- (NSArray *) allSubclasses
{
    return [[self class] allSubclasses];
}


- (NSArray *) allSubclassNames
{
    return [[[self allSubclasses] collectionByPerformingSelector:@selector(className)] asArray];
}


+ (NSArray *) instanceInvocations
{
    return [[self instanceInvocationEnumerator] allObjects];
}


+ (NSArray *) allInstanceInvocations
{    
    if ([self superclass] == nil) {
        return [self instanceInvocations];
    }
    else {
        NSMutableSet *result = [NSMutableSet setWithArray:[[self superclass] allInstanceInvocations]];
        [result addObjectsFromArray: [self instanceInvocations]];
        return [result asArray];
    }
}


- (NSArray *) instanceInvocations
{
    return [[self class] instanceInvocations];
}


- (NSArray *) allInstanceInvocations
{
    return [[self class] allInstanceInvocations];
}
@end
