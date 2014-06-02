//
//  objc10.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "objc10.h"


@implementation Node (Objc10)

- (void) compile_objc1_default;
{
	return;	// leave untouched
}

// check for idioms
// . notation for KVC
// ARC

- (void) compile_objc1synchronized
{
	// NSLock
}

- (void) compile_objc1synthesize
{
	// create getters/setters
}

- (void) compile_objc1autorelease
{
	// -> { NSAutoreleasePool *arp=[NSAutoreleasepool new]; $1; [arp release]; }
}

- (void) compile_objc1try
{
	// -> NS_DURING
}

- (void) compile_objc1catch
{
	// -> NS_HANDLER
}

- (void) compile_objc1finaly
{
	// -> NS_ENDHANDLER
}

- (void) compile_objc1box
{
	// box -> [NSNUmber numberWith<type>:$1]
	
}

- (void) compile_objc1arrayliteral
{
	// arrayliteral -> { id values[]={$1,$2,...}; [NSArray arrayWithObjects:values count:$#] }
	
}

- (void) compile_objc1dictliteral
{
	// dictliteral -> { id keys[]={$1,$3,...}, values[]={$2,$4,...}; [NSDictionary dictionaryWithObjects:values forKeys:keys count:$#/2] }
	
}

- (void) compile_objc1index
{
	// handle <object>[index] -> [object objectAtIndex:index] or [object objectForKey:index] depending on whether index is an C integer or an object (id)
	
}

@end
