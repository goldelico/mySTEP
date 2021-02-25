//
//  objc2c.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 11.01.21.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "objc2c.h"


@implementation Node (ObjC2PHP)

- (void) compile_PHP_unknown;
{
	NSLog(@"unknown how to translate `%@`", [self type]);
}

- (void) compile_PHP_public;
{
	// translate ObjC to PHP for mySTEP.php
}

// FIXME: identifiers can appear in different context: function name, variable name, type name...

- (void) compile_PHP_identifier;
{ // prefix with $
	NSString *ident=[self value];
	if([ident isEqualToString:@"this"])
		ident=@"do not use 'this'";	// should replace this node by an error...
	else if([ident isEqualToString:@"self"])
		ident=@"this";
	[self setValue:[@"$" stringByAppendingString:ident]];
}

- (void) compile_PHP_stringliteral;
{
	return; // unchanged
}

- (void) compile_PHP_interface;
{
	/*
	 @interface $Class : $Superclass { $iVars }

	 just store, no code...

	 */
}

- (void) compile_PHP_classimp;
{
	// define class object
	// remember as current class

	/*
	 class $Class extends $superclass
		{
		write all iVars
		}

	 */
}

- (void) compile_PHP_methodimp;
{
	// transform into PHP function definition

	/*
	 - ($type) $method:($type1) $args1 $args:...
	=>
	 public function $method$args($args1, ...)
		+ block
	 */

}

- (void) compile_PHP_message;
{
	// transform into a call to objc_sendMsg(obj, selector, args...)

	// check for [Class method] -> Class::method
	// [obj method] -> $obj->method
	// special case: [Class alloc] -> new Class

	/*
	 [$obj $method:$args1 $args:...]
	=>
	 $obj->$method$args($args1, ...)

	 */

}

@end
