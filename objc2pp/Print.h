//
//  Print.h
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/AST.h>

@interface Node (Print)

- (void) print;	// print the tree

/* pretty print the tree */

- (NSString *) description;	// tree node(s) as NSString
- (NSString *) descriptionAtLevel:(int) level;	// handle indentation level

@end
