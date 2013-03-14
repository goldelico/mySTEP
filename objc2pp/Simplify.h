//
//  Simplify.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (Simplify)

- (Node *) simplify;	// simplify the tree

@end
