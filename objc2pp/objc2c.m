//
//  objc2c.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 11.04.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "objc2c.h"


@implementation Node (objc2c)

- (void) objc2c;	// translate objc 1.0 to standard C, i.e. expand class definitions, method names, method headers etc.
{
	// check for objc code
	// id -> struct objc *
	// BOOL -> char
	// @selector -> get_sel("string")
	// @interface -> struct class { };
	// @implementation -> struct class *
	// [... ] -> objc_send(obj, "selector", args)
	// for(var in array) -> block type var; NSEnumerator *_e=[array objectEnumerator]; while((var=[_e nextObject]) body /block
	// etc.
}

@end
