//
//  Objc10.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (Objc10)

- (void) compile_objc1_default;
- (void) compile_objc1_synchronized;
- (void) compile_objc1_synthesize;
- (void) compile_objc1_autorelease;
- (void) compile_objc1_try;
- (void) compile_objc1_catch;
- (void) compile_objc1_finaly;
- (void) compile_objc1_box;
- (void) compile_objc1_arrayliteral;
- (void) compile_objc1_dictliteral;
- (void) compile_objc1_index;

@end
