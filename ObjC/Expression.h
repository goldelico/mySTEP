//
//  Expression.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 12.03.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (Expression)

- (Node *) deriveType;		// evaluate type (tree)
- (Node *) constantValue;	// evaluate constant value(s)

@end
