/*
	NSPointerArray.h
	Foundation
 
	Created by Fabian Spillner on 21.07.08.
	Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
	Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSPointerFunctions.h>

@class NSArray;

@interface NSPointerArray : NSObject {

}

+ (id) pointerArrayWithOptions:(NSPointerFunctionsOptions) opts;
+ (id) pointerArrayWithPointerFunctions:(NSPointerFunctions *) functs;
+ (id) pointerArrayWithStrongObjects;
+ (id) pointerArrayWithWeakObjects;

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

@end
