//
//  objc2c.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 11.04.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (objc2c)

- (void) objc2c;	// translate objc 1.0 to standard C, i.e. expand class definitions, method names, method headers etc.

@end
