//
//  Simplify.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Simplify.h"

// NOTE: evaluation/simplification of constant float expression needs private IEEE FPU implementation!
// unless we want to require a FPU on the underlaying system

@implementation Node (Simplify)

- (Node *) simplify;
{
	Node *nl=[left simplify];
	Node *nr=[right simplify];
	// check if we can simplify everything
	// i.e. if nl == const and nr == const and type == + - * / % etc.
	// then return combined constant
	if(nl != left || nr != right)
		return [Node node:type left:nl right:nr];	// return a copy
	return self;	// not changed
}

@end
