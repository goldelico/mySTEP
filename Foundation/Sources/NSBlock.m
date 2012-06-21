/* 
    NSBlock.m

    Copyright (C) 2011. H. N. Schaller
    All rights reserved.

    This file is part of the mySTEP Library and is provided under the 
    terms of the libFoundation BSD type license (See the Readme file).
 
    see: http://stackoverflow.com/questions/4731940/is-it-possible-to-create-a-category-of-the-block-object-in-objective-c
*/

#import <Foundation/NSBlock.h>

@implementation NSBlock

+ (NSBlock *) createBlock:(id) valuesAndKeys, ...;	// pass variables (e.g. as NSNumber or value) and names
{
	return NIMP;
}

- (id) run;	// the block method
{
	return NIMP;
}

- (id) valueForKey:(NSString *) key;	// fetch environment variable
{
	return [_dict valueForKey:key];
}

@end

/*
 * this is a simple way to get the same functionality as ObjC-2 blocks
 * but much simpler avoiding the cryptic syntax with ^block variables and block literals
 * but with less compiler support
 *
 * how to use:
 *
 * for each block literal make a subclass of NSBlock
 *
 * @interface Lit1 : NSBlock
 * @end
 *
 * and overwrite the run method
 *
 * @implementation Lit1
 * - (id) run { your literal goes here }
 * @end
 *
 * replace ^var with
 * Lit1 *var
 *
 * replace var = { code... }
 * by e.g. var=[NSBlock createBlock:var1, @"var1", [NSNumber numberWithInt:var2], @"var2", nil];
 * to capture the environment
 *
 * replace var() with [var run]
 */

@implementation NSBlockHandler

- (id) initWithDelegate:(id) d action:(SEL) a
{
	if((self=[self init]))
		{
		delegate=d;
		action=a;
		}
	return self;
}

+ (NSBlockHandler *) handlerWithDelegate:(id) d action:(SEL) a;
{
	return [[[self alloc] initWithDelegate:d action:a] autorelease];
}

- (id) perform;
{
	return [delegate performSelector:action];
}

- (id) performWithObject:(id) obj;
{
	return [delegate performSelector:action withObject:obj];
}

- (id) performWithObject:(id) obj1 withObject:(id) obj2;
{
	return [delegate performSelector:action withObject:obj1 withObject:obj2];
}

@end
