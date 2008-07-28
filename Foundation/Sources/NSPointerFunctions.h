/*
    NSPointerFunctions.h
    Foundation

    Created by H. Nikolaus Schaller on 21.05.08.
    Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
	Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSObject.h>

enum
{
	NSPointerFunctionsStrongMemory				= 0 * (1 << 0),
	NSPointerFunctionsZeroingWeakMemory			= 1 * (1 << 0),
	NSPointerFunctionsOpaqueMemory				= 2 * (1 << 0),
	NSPointerFunctionsMallocMemory				= 3 * (1 << 0),
	NSPointerFunctionsMachVirtualMemory			= 4 * (1 << 0),
	NSPointerFunctionsObjectPersonality			= 0 * (1 << 8),
	NSPointerFunctionsOpaquePersonality			= 1 * (1 << 8),
	NSPointerFunctionsObjectPointerPersonality	= 2 * (1 << 8),
	NSPointerFunctionsCStringPersonality		= 3 * (1 << 8),
	NSPointerFunctionsStructPersonality			= 4	* (1 << 8),
	NSPointerFunctionsIntegerPersonality		= 5 * (1 << 8),
	NSPointerFunctionsCopyIn					= 1 * (1 << 16),
};

typedef NSUInteger NSPointerFunctionsOptions;

@interface NSPointerFunctions : NSObject
{
// add instance variables
}

+ (id) pointerFunctionsWithOptions:(NSPointerFunctionsOptions) opts;

- (id) initWithOptions:(NSPointerFunctionsOptions) opts;

- (void *(*) (const void * source, NSUInteger (* size)(const void * item), BOOL shouldCopyFlag)) acquireFunction;
- (NSString *(*) (const void * item)) descriptionFunction;
- (NSUInteger (*) (const void * item, NSUInteger (* size)(const void * item))) hashFunction;
- (BOOL (*) (const void * item1, const void * item2, NSUInteger (* size)(const void * item))) isEqualFunction;
- (void (*) (const void * item, NSUInteger (* size)(const void * item))) relinquishFunction;
- (NSUInteger (*) (const void * item)) sizeFunction;
- (BOOL) usesStrongWriteBarrier;
- (BOOL) usesWeakReadAndWriteBarriers;

// add setters

@end
