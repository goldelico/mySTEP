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

}

+ (id)pointerFunctionsWithOptions:(NSPointerFunctionsOptions) opts;

- (id)initWithOptions:(NSPointerFunctionsOptions) opts;

@property void *(* acquireFunction) (const void * source, NSUInteger (* size)(const void * item), BOOL shouldCopyFlag);
@property NSString *(* descriptionFunction) (const void * item);
@property NSUInteger (* hashFunction) (const void * item, NSUInteger (* size)(const void * item));
@property BOOL (* isEqualFunction) (const void * item1, const void * item2, NSUInteger (* size)(const void * item));
@property void (* relinquishFunction) (const void * item, NSUInteger (* size)(const void * item));
@property NSUInteger (* sizeFunction) (const void * item);
@property BOOL usesStrongWriteBarrier;
@property BOOL usesWeakReadAndWriteBarriers;


@end
