//
//  objc2c.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 11.04.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "objc2c.h"


@implementation Node (ObjC2C)

- (void) compile_C_default;
{
	return;	// leave untouched
}

- (void) compile_C_stringliteral;
{
	// string value are children of type "string"
	// maybe multiple, unless simplify merges them

	// transform into NSConstantString predefined object
	/*
	 global:

	 struct NSConstantString L$$ = {
		.isa = NSConstantString;
		.data = "string....";
		.length = strlen(string);
	 }

	 und Verwenden als L$$
	 */
}

- (void) compile_C_interface;
{
	// transform into struct def
	// adding iVars of superclass
	// so we must build our own list of known classes

	/*
	 @interface $Class : $Superclass { $iVars }

	 => struct $Class {
	 alle iVars der $Superclass;  -> struct.Ketten von Linux vermeiden!
	 $iVars
	 };
	 
	 Sonderfall root class:

	 @ interface $Class { $iVars }

	 => struct $Class {
	 id isa;
	 $iVars
	 };
	 
	 Kategorien ignorieren (bzw. nur Methodenliste)

	 */
}

- (void) compile_C_classimp;
{
	// define class object
	// remember as current class

	/*
	 struct $Class Class_$(Class)
	 {
	 id isa;
	 dispatch table
	 }
	 
	 */
}

- (void) compile_C_methodimp;
{
	// transform into C function definition

	/*
	 - ($type) $method:($type1) $args1 $args:...

	 $type $Class_$method_$args(id self, char *_cmd, $type1 $args1, ...)
	 */

}

- (void) compile_C_methodcall;
{
	// transform into a call to objc_sendMsg(obj, selector, args...)

	/*
	 [$obj $method:$args1 $args:...]

	 objc_sendMsg($obj, "$method:$args:", $args1, ...)

	 wenn statischer Dispatch möglich:

	 $Class_$method_$args($obj, "$method:$args:", $args1, ...)
	 
	 */

}

@end
