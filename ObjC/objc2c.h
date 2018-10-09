//
//  objc2c.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 11.04.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (ObjC2C)

- (void) compile_C_interface;
- (void) compile_C_classimp;
- (void) compile_C_methodimp;
- (void) compile_C_methodcall;

@end
