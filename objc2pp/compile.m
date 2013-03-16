//
//  compile.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Compile.h"


@implementation Node (Compile)

- (Node *) registerAssign
{ // assign explicit 'register' and temporary stack variables
	
}

- (Node *) compile:(NSString *) target;
{ // translate to asm() statements
	return self;
}

@end
