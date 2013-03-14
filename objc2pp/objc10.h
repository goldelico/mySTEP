//
//  objc10.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "AST.h"

@interface Node (objc10)

- (Node *) objc10;	// translate objc 2.0 idioms to objc 1.0

@end
