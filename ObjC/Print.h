//
//  Print.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (Print)

+ (void) setSpaciness:(float) factor;	// 0...1 - controls if(a+b>c) ... if (a+b > c) ... if (a + b > c)
+ (void) setBracketiness:(float) factor;	// 0..1 - controls if() { ... }\n ... if\n{\n...\n}
+ (void) setMaxLineLength:(unsigned) width;

/* pretty print the tree */

- (NSString *) prettyObjC;	// tree node(s) as (Obj-)C NSString

- (void) compile_pretty_unknown;

@end
