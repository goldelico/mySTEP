//
//  Expression.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 12.03.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Expression.h"

@implementation Node (Expression)

- (Node *) deriveType;		// evaluate type
{
	// identifier -> right
	// constant -> string, int, unsigned, float etc.
	// operators -> apply rules
}

- (Node *) constantValue;	// evaluate constant value
{
	// operators -> calculate
	// others -> unchanged
}

@end
