//
//  Expression.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 12.03.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AST.h"

@interface Node (Expression)

- (id) deriveType;		// evaluate type
- (id) contantValue;	// evaluate constant value

@end
