//
//  objc10.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "objc10.h"


@implementation Node (objc10)

- (Node *) objc10;	// translate objc 2.0 idioms to objc 1.0
{
	// check for idioms
	// . notation for KVC
	// @try, @catch
	// @synchronized
	// @synthesize
	// @autorelease
	// ARC
	Node *nl=[left objc10];
	Node *nr=[right objc10];
	if(nl != left || nr != right)
		return [Node node:type left:nl right:nr];	// return a copy
	return self;	// not changed
}

@end
