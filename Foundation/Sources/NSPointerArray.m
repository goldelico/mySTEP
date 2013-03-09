//
//  NSPointerArray.m
//  Foundation
//
//  Created by Fabian Spillner on 21.07.08.
//  Copyright 2008 Privat. All rights reserved.
//

#import "NSPointerArray.h"


@implementation NSPointerArray

#if 0
+ (id) pointerArrayWithOptions:(NSPointerFunctionsOptions) opts; { return [[[self alloc] initWithOptions:opts] autorelease]; }
+ (id) pointerArrayWithPointerFunctions:(NSPointerFunctions *) functs;
+ (id) pointerArrayWithStrongObjects; { return [[[self alloc] initWithOptions:NSPointerFunctionsStrongMemory] autorelease]; }
+ (id) pointerArrayWithWeakObjects; { return [[[self alloc] initWithOptions:0] autorelease]; }

- (void) addPointer:(void *) pt;
- (NSArray *) allObjects;
- (void) compact;
- (NSUInteger) count;
- (id) initWithOptions:(NSPointerFunctionsOptions) opts;
- (id) initWithPointerFunctions:(NSPointerFunctions *) functs;
- (void) insertPointer:(void *) item atIndex:(NSUInteger) idx;
- (void *) pointerAtIndex:(NSUInteger) idx;
- (NSPointerFunctions *) pointerFunctions;
- (void) removePointerAtIndex:(NSUInteger) idx;
- (void) replacePointerAtIndex:(NSUInteger) idx withPointer:(void *) pt;
- (void) setCount:(NSUInteger) count;
#endif

@end
