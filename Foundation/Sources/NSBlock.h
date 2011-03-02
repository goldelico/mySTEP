/* 
    NSBlock.h

    Copyright (C) 2011. H. N. Schaller
    All rights reserved.

    This file is part of the mySTEP Library and is provided under the 
    terms of the libFoundation BSD type license (See the Readme file).
 
    see: http://stackoverflow.com/questions/4731940/is-it-possible-to-create-a-category-of-the-block-object-in-objective-c
*/

#ifndef _mySTEP_H_NSBlock
#define _mySTEP_H_NSBlock

#import <Foundation/NSObject.h>

@interface NSBlock : NSObject
{
	NSDictionary *_dict;
}

+ (NSBlock *) createBlock:(id) valuesAndKeys, ...;	// pass variables (e.g. as NSNumber or value) and names
- (id) run;	// the block method
- (id) valueForKey:(NSString *) key;	// fetch environment variable

@end

@class __NSStackBlock__, __NSMallocBlock__, __NSAutoBlock__;	// N/A subclasses of NSBlock

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

#endif /* _mySTEP_H_NSBlock */
