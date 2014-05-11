//
//  Compile.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (Compile)

- (void) compile:(NSString *) target_architecture;	// translate to asm() statements

@end
