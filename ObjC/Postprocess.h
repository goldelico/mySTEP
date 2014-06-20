//
//  Prepare.h
//  ObjCKit
//
//  Created by H. Nikolaus Schaller on 19.06.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>


@interface Node (Postprocess)

- (void) postprocess;	// postprocess tree for symbol table and semantic issues check

@end
