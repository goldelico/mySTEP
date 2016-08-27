/*$Id: SenInvocationEnumerator.m,v 1.7 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenInvocationEnumerator.h"

@implementation SenInvocationEnumerator

+ (id) instanceInvocationEnumeratorForClass:(Class) aClass
{
    return [[[self alloc] initForClass:aClass] autorelease];
}


- (void) goNextMethodList
{
#if defined (GNUSTEP)
   if (iterator == NULL)
     mlist = iterator = class->methods;
   else
     mlist = iterator = mlist->method_next;
#else
    mlist = class_nextMethodList (class, &iterator);
#endif
    count = (mlist != NULL) ? mlist->method_count - 1 : -1;
}


- (id) initForClass:(Class) aClass
{
    self = [super init];
    class = aClass;
    iterator = NULL;
    [self goNextMethodList];
    return self;
}


- (id) nextObject
{
    if (mlist == NULL) {
        return nil;
    }
    else {
        SEL nextSelector = mlist->method_list[count].method_name;
        count--;
        if (count == -1) {
            [self goNextMethodList];
        }
#if defined (GNUSTEP)
        if (sel_is_mapped(nextSelector)) {
#else
        if (sel_isMapped(nextSelector)) {
#endif
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[class instanceMethodSignatureForSelector:nextSelector]];
            [invocation setSelector:nextSelector];
            return invocation;
        }
        else {
            return [self nextObject];
        }
    }
}

- (NSArray *) allObjects
{
    NSMutableArray *array = [NSMutableArray array];
    id each;

    while (each = [self nextObject]) {
        [array addObject:each];
    }
    return array;
}

@end
