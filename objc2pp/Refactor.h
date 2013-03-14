//
//  Refactor.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "AST.h"

@interface Node (Refactor)

- (Node *) refactor:(NSDictionary *) substitutions;	// replace symbols by dictionary content

@end
