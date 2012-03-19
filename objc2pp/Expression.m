//
//  Expression.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 12.03.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Expression.h"

@implementation Node (Expression)

- (id) deriveType;		// evaluate type
{
	// identifier -> right
	// constant -> string, int, unsigned, float etc.
	// operators -> apply rules
}

- (id) contantValue;	// evaluate constant value
{
	// constant -> nsnumber or nsstring
	// operators -> calculate
	// others -> nil
}

@end
