//
//  compile.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Compile.h"


@implementation Node (Compile)

- (void) registerAssign
{ // assign explicit 'register' and temporary stack variables
	
}

- (void) compile:(NSString *) target;
{ // translate to asm() statements
	Node *n=[Node node:@"asm"];
	[n addChild:[Node leaf:@"string" value:@"some asm statement"]];
	[self replaceBy:n];
}

@end
