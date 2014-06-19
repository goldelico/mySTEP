//
//  Prepare.m
//  ObjCKit
//
//  Created by H. Nikolaus Schaller on 19.06.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Prepare.h"

@implementation Node (Prepare)

- (void) prepare;	// prepare tree for symbol table and semantic issues check
{
	// walk through all translation units
	// collect objects (global/local)
	// assign declarators/types to identifiers
	// handle @class
	// add globals to global symbol table
	// collect struct name spaces
	// create method-tables for @class and @protocols
	// check for duplicates/redefines
	// check for mismatch in storage class
	// ?? expand @synthesise ?
	// check/warn for declarations inserted between statements
}

@end